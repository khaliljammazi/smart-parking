const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Vehicle = require('../models/Vehicle');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const updateProfileValidation = [
  body('firstName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters'),
  body('lastName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters'),
  body('phone')
    .optional()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please provide a valid phone number'),
  body('dateOfBirth')
    .optional()
    .isISO8601()
    .withMessage('Please provide a valid date of birth')
];

const addVehicleValidation = [
  body('licensePlate')
    .trim()
    .isLength({ min: 1, max: 20 })
    .withMessage('License plate is required'),
  body('make')
    .trim()
    .isLength({ min: 1, max: 50 })
    .withMessage('Vehicle make is required'),
  body('model')
    .trim()
    .isLength({ min: 1, max: 50 })
    .withMessage('Vehicle model is required'),
  body('year')
    .isInt({ min: 1900, max: new Date().getFullYear() + 1 })
    .withMessage('Please provide a valid year'),
  body('color')
    .trim()
    .isLength({ min: 1, max: 30 })
    .withMessage('Vehicle color is required')
];

// @route   GET /api/users/profile
// @desc    Get user profile
// @access  Private
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('vehicles')
      .select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: { user }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', protect, updateProfileValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const allowedFields = [
      'firstName', 'lastName', 'phone', 'dateOfBirth', 'gender',
      'language', 'notifications', 'preferredPaymentMethod', 'defaultLocation'
    ];

    const updates = {};
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updates,
      { new: true, runValidators: true }
    ).populate('vehicles');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: { user }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/users/vehicles
// @desc    Add vehicle to user profile
// @access  Private
router.post('/vehicles', protect, addVehicleValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { licensePlate, make, model, year, color, fuelType, insuranceNumber, insuranceExpiry } = req.body;

    // Check if license plate already exists
    const existingVehicle = await Vehicle.findOne({ licensePlate: licensePlate.toUpperCase() });
    if (existingVehicle) {
      return res.status(400).json({
        success: false,
        message: 'Vehicle with this license plate already exists'
      });
    }

    // Create vehicle
    const vehicle = new Vehicle({
      owner: req.user._id,
      licensePlate: licensePlate.toUpperCase(),
      make,
      model,
      year,
      color,
      fuelType: fuelType || 'petrol',
      insuranceNumber,
      insuranceExpiry
    });

    await vehicle.save();

    // Add vehicle to user's vehicles array
    await User.findByIdAndUpdate(req.user._id, {
      $push: { vehicles: vehicle._id }
    });

    res.status(201).json({
      success: true,
      message: 'Vehicle added successfully',
      data: { vehicle }
    });
  } catch (error) {
    console.error('Add vehicle error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/users/vehicles
// @desc    Get user's vehicles
// @access  Private
router.get('/vehicles', protect, async (req, res) => {
  try {
    const vehicles = await Vehicle.find({ owner: req.user._id })
      .sort({ isDefault: -1, createdAt: -1 });

    res.json({
      success: true,
      data: { vehicles }
    });
  } catch (error) {
    console.error('Get vehicles error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/users/vehicles/:id
// @desc    Update vehicle
// @access  Private
router.put('/vehicles/:id', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({
      _id: req.params.id,
      owner: req.user._id
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found'
      });
    }

    const allowedFields = [
      'make', 'model', 'year', 'color', 'fuelType',
      'insuranceNumber', 'insuranceExpiry', 'photos'
    ];

    const updates = {};
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const updatedVehicle = await Vehicle.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Vehicle updated successfully',
      data: { vehicle: updatedVehicle }
    });
  } catch (error) {
    console.error('Update vehicle error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/users/vehicles/:id
// @desc    Delete vehicle
// @access  Private
router.delete('/vehicles/:id', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({
      _id: req.params.id,
      owner: req.user._id
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found'
      });
    }

    // Check if vehicle has active bookings
    const Booking = require('../models/Booking');
    const activeBooking = await Booking.findOne({
      vehicle: req.params.id,
      status: { $in: ['confirmed', 'active'] }
    });

    if (activeBooking) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete vehicle with active bookings'
      });
    }

    // Remove vehicle from user's vehicles array
    await User.findByIdAndUpdate(req.user._id, {
      $pull: { vehicles: req.params.id }
    });

    // Delete vehicle
    await Vehicle.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Vehicle deleted successfully'
    });
  } catch (error) {
    console.error('Delete vehicle error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/users/vehicles/:id/default
// @desc    Set vehicle as default
// @access  Private
router.put('/vehicles/:id/default', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({
      _id: req.params.id,
      owner: req.user._id
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found'
      });
    }

    await vehicle.makeDefault();

    res.json({
      success: true,
      message: 'Default vehicle updated successfully',
      data: { vehicle }
    });
  } catch (error) {
    console.error('Set default vehicle error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;