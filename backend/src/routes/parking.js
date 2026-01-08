const express = require('express');
const { body, validationResult } = require('express-validator');
const Parking = require('../models/Parking');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const createParkingValidation = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('address.street')
    .trim()
    .notEmpty()
    .withMessage('Street address is required'),
  body('coordinates.latitude')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Valid latitude is required'),
  body('coordinates.longitude')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Valid longitude is required'),
  body('totalSpots')
    .isInt({ min: 1 })
    .withMessage('Total spots must be at least 1'),
  body('pricing.hourly')
    .isFloat({ min: 0 })
    .withMessage('Hourly rate must be non-negative')
];

// @route   GET /api/parking
// @desc    Get all parking spots with filters
// @access  Public
router.get('/', async (req, res) => {
  try {
    const {
      latitude,
      longitude,
      radius = 5000, // 5km default
      available = false,
      features,
      minPrice,
      maxPrice,
      limit = 20,
      page = 1
    } = req.query;

    let query = { isActive: true };

    // Location-based search
    if (latitude && longitude) {
      query = {
        ...query,
        coordinates: {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [parseFloat(longitude), parseFloat(latitude)]
            },
            $maxDistance: parseInt(radius)
          }
        }
      };
    }

    // Availability filter
    if (available === 'true') {
      query.availableSpots = { $gt: 0 };
    }

    // Features filter
    if (features) {
      const featureArray = features.split(',');
      query.features = { $in: featureArray };
    }

    // Price filter
    if (minPrice || maxPrice) {
      query['pricing.hourly'] = {};
      if (minPrice) query['pricing.hourly'].$gte = parseFloat(minPrice);
      if (maxPrice) query['pricing.hourly'].$lte = parseFloat(maxPrice);
    }

    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort: { 'rating.average': -1, createdAt: -1 },
      select: 'name address coordinates pricing availableSpots features rating images'
    };

    const result = await Parking.paginate(query, options);

    res.json({
      success: true,
      data: {
        parkings: result.docs,
        pagination: {
          page: result.page,
          pages: result.totalPages,
          total: result.totalDocs,
          limit: result.limit
        }
      }
    });
  } catch (error) {
    console.error('Get parkings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/parking/:id
// @desc    Get parking spot details
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const parking = await Parking.findById(req.params.id)
      .populate('owner', 'firstName lastName email phone');

    if (!parking) {
      return res.status(404).json({
        success: false,
        message: 'Parking spot not found'
      });
    }

    res.json({
      success: true,
      data: { parking }
    });
  } catch (error) {
    console.error('Get parking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/parking
// @desc    Create new parking spot
// @access  Private
router.post('/', protect, createParkingValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const parkingData = {
      ...req.body,
      owner: req.user._id,
      availableSpots: req.body.totalSpots // Initially all spots are available
    };

    const parking = new Parking(parkingData);
    await parking.save();

    res.status(201).json({
      success: true,
      message: 'Parking spot created successfully',
      data: { parking }
    });
  } catch (error) {
    console.error('Create parking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/parking/:id
// @desc    Update parking spot
// @access  Private (Owner only)
router.put('/:id', protect, async (req, res) => {
  try {
    const parking = await Parking.findOne({
      _id: req.params.id,
      owner: req.user._id
    });

    if (!parking) {
      return res.status(404).json({
        success: false,
        message: 'Parking spot not found or not authorized'
      });
    }

    const allowedFields = [
      'name', 'description', 'address', 'coordinates', 'totalSpots',
      'pricing', 'features', 'operatingHours', 'contact', 'images'
    ];

    const updates = {};
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    // If totalSpots is being updated, adjust availableSpots accordingly
    if (updates.totalSpots && updates.totalSpots !== parking.totalSpots) {
      const difference = updates.totalSpots - parking.totalSpots;
      updates.availableSpots = Math.max(0, parking.availableSpots + difference);
    }

    const updatedParking = await Parking.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Parking spot updated successfully',
      data: { parking: updatedParking }
    });
  } catch (error) {
    console.error('Update parking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/parking/:id
// @desc    Delete parking spot
// @access  Private (Owner only)
router.delete('/:id', protect, async (req, res) => {
  try {
    const parking = await Parking.findOne({
      _id: req.params.id,
      owner: req.user._id
    });

    if (!parking) {
      return res.status(404).json({
        success: false,
        message: 'Parking spot not found or not authorized'
      });
    }

    // Check for active bookings
    const Booking = require('../models/Booking');
    const activeBookings = await Booking.find({
      parking: req.params.id,
      status: { $in: ['confirmed', 'active'] }
    });

    if (activeBookings.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete parking with active bookings'
      });
    }

    await Parking.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Parking spot deleted successfully'
    });
  } catch (error) {
    console.error('Delete parking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/parking/nearby
// @desc    Get nearby parking spots
// @access  Public
router.get('/nearby/search', async (req, res) => {
  try {
    const { latitude, longitude, radius = 2000 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const parkings = await Parking.findNearby(
      parseFloat(longitude),
      parseFloat(latitude),
      parseInt(radius)
    ).limit(10);

    res.json({
      success: true,
      data: { parkings }
    });
  } catch (error) {
    console.error('Nearby parking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/parking/owner/list
// @desc    Get parking spots owned by current user
// @access  Private
router.get('/owner/list', protect, async (req, res) => {
  try {
    const parkings = await Parking.find({ owner: req.user._id })
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: { parkings }
    });
  } catch (error) {
    console.error('Get owner parkings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;