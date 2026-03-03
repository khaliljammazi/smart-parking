const express = require('express');
const { body, validationResult } = require('express-validator');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const createVehicleValidation = [
  body('licensePlate')
    .isLength({ min: 1, max: 20 })
    .withMessage('License plate is required and must be valid')
    .matches(/^[0-9]{1,3}\s?[A-Z]{1,3}\s?[0-9]{1,4}$/)
    .withMessage('Please enter a valid Tunisian license plate format'),
  body('make')
    .isLength({ min: 1, max: 50 })
    .withMessage('Vehicle make is required'),
  body('model')
    .isLength({ min: 1, max: 50 })
    .withMessage('Vehicle model is required'),
  body('year')
    .isInt({ min: 1900, max: new Date().getFullYear() + 1 })
    .withMessage('Please enter a valid year'),
  body('color')
    .isLength({ min: 1, max: 30 })
    .withMessage('Vehicle color is required')
];

// @route   GET /api/vehicles
// @desc    Get user's vehicles
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const vehicles = await Vehicle.find({ owner: req.user._id })
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: vehicles
    });
  } catch (error) {
    console.error('Get vehicles error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/vehicles
// @desc    Create a new vehicle
// @access  Private
router.post('/', protect, createVehicleValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { licensePlate, make, model, year, color } = req.body;

    // Check if license plate already exists
    const existingVehicle = await Vehicle.findOne({
      licensePlate: licensePlate.toUpperCase()
    });

    if (existingVehicle) {
      return res.status(400).json({
        success: false,
        message: 'License plate already exists'
      });
    }

    // Create vehicle
    const vehicle = new Vehicle({
      owner: req.user._id,
      licensePlate: licensePlate.toUpperCase(),
      make,
      model,
      year,
      color
    });

    await vehicle.save();

    // Add vehicle to user's vehicles array
    await User.findByIdAndUpdate(req.user._id, {
      $push: { vehicles: vehicle._id }
    });

    res.status(201).json({
      success: true,
      data: vehicle,
      message: 'Vehicle created successfully'
    });
  } catch (error) {
    console.error('Create vehicle error:', error);
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'License plate already exists'
      });
    }
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/vehicles/:id
// @desc    Update vehicle
// @access  Private
router.put('/:id', protect, createVehicleValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

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

    const { licensePlate, make, model, year, color } = req.body;

    // Check if new license plate conflicts with another vehicle
    if (licensePlate.toUpperCase() !== vehicle.licensePlate) {
      const existingVehicle = await Vehicle.findOne({
        licensePlate: licensePlate.toUpperCase(),
        _id: { $ne: req.params.id }
      });

      if (existingVehicle) {
        return res.status(400).json({
          success: false,
          message: 'License plate already exists'
        });
      }
    }

    // Update vehicle
    vehicle.licensePlate = licensePlate.toUpperCase();
    vehicle.make = make;
    vehicle.model = model;
    vehicle.year = year;
    vehicle.color = color;

    await vehicle.save();

    res.json({
      success: true,
      data: vehicle,
      message: 'Vehicle updated successfully'
    });
  } catch (error) {
    console.error('Update vehicle error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/vehicles/:id
// @desc    Delete vehicle
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOneAndDelete({
      _id: req.params.id,
      owner: req.user._id
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found'
      });
    }

    // Remove vehicle from user's vehicles array
    await User.findByIdAndUpdate(req.user._id, {
      $pull: { vehicles: vehicle._id }
    });

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

module.exports = router;