const express = require('express');
const { body, validationResult } = require('express-validator');
const Booking = require('../models/Booking');
const Parking = require('../models/Parking');
const Vehicle = require('../models/Vehicle');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const createBookingValidation = [
  body('parkingId')
    .isMongoId()
    .withMessage('Valid parking ID is required'),
  body('vehicleId')
    .isMongoId()
    .withMessage('Valid vehicle ID is required'),
  body('startTime')
    .isISO8601()
    .withMessage('Valid start time is required'),
  body('endTime')
    .isISO8601()
    .withMessage('Valid end time is required'),
  body('bookingType')
    .optional()
    .isIn(['hourly', 'daily', 'monthly'])
    .withMessage('Invalid booking type')
];

// @route   POST /api/bookings
// @desc    Create new booking
// @access  Private
router.post('/', protect, createBookingValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { parkingId, vehicleId, startTime, endTime, bookingType = 'hourly' } = req.body;

    // Validate start and end times
    const start = new Date(startTime);
    const end = new Date(endTime);
    const now = new Date();

    if (start <= now) {
      return res.status(400).json({
        success: false,
        message: 'Start time must be in the future'
      });
    }

    if (end <= start) {
      return res.status(400).json({
        success: false,
        message: 'End time must be after start time'
      });
    }

    // Check if parking exists and is available
    const parking = await Parking.findById(parkingId);
    if (!parking) {
      return res.status(404).json({
        success: false,
        message: 'Parking spot not found'
      });
    }

    if (!parking.isActive || !parking.isSpotAvailable()) {
      return res.status(400).json({
        success: false,
        message: 'Parking spot is not available'
      });
    }

    // Check if vehicle belongs to user
    const vehicle = await Vehicle.findOne({
      _id: vehicleId,
      owner: req.user._id
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found or not owned by user'
      });
    }

    // Check for conflicting bookings
    const conflictingBooking = await Booking.findOne({
      parking: parkingId,
      status: { $in: ['confirmed', 'active'] },
      $or: [
        {
          startTime: { $lt: end },
          endTime: { $gt: start }
        }
      ]
    });

    if (conflictingBooking) {
      return res.status(400).json({
        success: false,
        message: 'Parking spot is already booked for this time period'
      });
    }

    // Calculate pricing
    const durationMs = end - start;
    const durationHours = Math.ceil(durationMs / (1000 * 60 * 60));
    const hourlyRate = parking.pricing.hourly;
    const subtotal = durationHours * hourlyRate;
    const tax = subtotal * 0.19; // 19% Tunisian VAT
    const total = subtotal + tax;

    // Create booking
    const booking = new Booking({
      user: req.user._id,
      parking: parkingId,
      vehicle: vehicleId,
      bookingType,
      startTime: start,
      endTime: end,
      duration: { hours: durationHours },
      pricing: {
        rate: hourlyRate,
        subtotal,
        tax,
        total
      }
    });

    await booking.save();

    // Populate booking data for response
    await booking.populate([
      { path: 'parking', select: 'name address coordinates pricing' },
      { path: 'vehicle', select: 'make model licensePlate' }
    ]);

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/bookings
// @desc    Get user's bookings
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;

    const query = { user: req.user._id };
    if (status) {
      query.status = status;
    }

    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort: { createdAt: -1 },
      populate: [
        { path: 'parking', select: 'name address coordinates pricing' },
        { path: 'vehicle', select: 'make model licensePlate' }
      ]
    };

    const result = await Booking.paginate(query, options);

    res.json({
      success: true,
      data: {
        bookings: result.docs,
        pagination: {
          page: result.page,
          pages: result.totalPages,
          total: result.totalDocs,
          limit: result.limit
        }
      }
    });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/bookings/:id
// @desc    Get booking details
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      user: req.user._id
    }).populate([
      { path: 'parking', select: 'name address coordinates pricing contact' },
      { path: 'vehicle', select: 'make model licensePlate year color' }
    ]);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    res.json({
      success: true,
      data: { booking }
    });
  } catch (error) {
    console.error('Get booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/bookings/:id/cancel
// @desc    Cancel booking
// @access  Private
router.put('/:id/cancel', protect, async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      user: req.user._id
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if booking can be cancelled
    if (!['pending', 'confirmed'].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: 'Booking cannot be cancelled at this stage'
      });
    }

    // Check cancellation policy (e.g., 2 hours before start time)
    const now = new Date();
    const startTime = new Date(booking.startTime);
    const hoursUntilStart = (startTime - now) / (1000 * 60 * 60);

    if (hoursUntilStart < 2) {
      return res.status(400).json({
        success: false,
        message: 'Booking cannot be cancelled less than 2 hours before start time'
      });
    }

    await booking.cancel('user_cancelled');

    // Update parking availability
    await booking.parking.updateAvailability(1);

    res.json({
      success: true,
      message: 'Booking cancelled successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Cancel booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/bookings/:id/rate
// @desc    Rate completed booking
// @access  Private
router.put('/:id/rate', protect, async (req, res) => {
  try {
    const { parking: parkingRating, service: serviceRating, overall: overallRating, feedback } = req.body;

    const booking = await Booking.findOne({
      _id: req.params.id,
      user: req.user._id,
      status: 'completed'
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Completed booking not found'
      });
    }

    // Validate ratings
    const ratings = { parking: parkingRating, service: serviceRating, overall: overallRating };
    for (const [key, value] of Object.entries(ratings)) {
      if (value && (value < 1 || value > 5)) {
        return res.status(400).json({
          success: false,
          message: `${key} rating must be between 1 and 5`
        });
      }
    }

    await booking.addRating({ parking: parkingRating, service: serviceRating, overall: overallRating, feedback });

    res.json({
      success: true,
      message: 'Rating submitted successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Rate booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/bookings/active/count
// @desc    Get count of active bookings for user
// @access  Private
router.get('/active/count', protect, async (req, res) => {
  try {
    const count = await Booking.countDocuments({
      user: req.user._id,
      status: 'active'
    });

    res.json({
      success: true,
      data: { activeBookingsCount: count }
    });
  } catch (error) {
    console.error('Get active bookings count error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;