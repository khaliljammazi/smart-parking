const express = require('express');
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Vehicle = require('../models/Vehicle');
const Booking = require('../models/Booking');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

// --- Multer setup for vehicle photos ---
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, '../../uploads/vehicles');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `vehicle_${req.user._id}_${Date.now()}${ext}`);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp/;
    const ext = allowed.test(path.extname(file.originalname).toLowerCase());
    const mime = allowed.test(file.mimetype) || file.mimetype === 'application/octet-stream';
    cb(null, ext || mime);
  }
});

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

// ────────────────────────────────────────────
//  IMPORTANT: put literal-path routes BEFORE
//  parameterized routes so Express matches them
//  first (e.g. /stats/summary before /:id).
// ────────────────────────────────────────────

// @route   GET /api/vehicles/stats/summary
// @desc    Get vehicle statistics for current user
// @access  Private
router.get('/stats/summary', protect, async (req, res) => {
  try {
    const vehicles = await Vehicle.find({ owner: req.user._id });
    const vehicleIds = vehicles.map(v => v._id);

    const bookingsPerVehicle = await Booking.aggregate([
      { $match: { vehicle: { $in: vehicleIds } } },
      { $group: {
        _id: '$vehicle',
        totalBookings: { $sum: 1 },
        totalSpent: { $sum: '$pricing.total' },
        completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } }
      }},
      { $lookup: { from: 'vehicles', localField: '_id', foreignField: '_id', as: 'vehicle' } },
      { $unwind: '$vehicle' },
      { $project: {
        vehicleId: '$_id',
        licensePlate: '$vehicle.licensePlate',
        make: '$vehicle.make',
        model: '$vehicle.model',
        totalBookings: 1,
        totalSpent: 1,
        completed: 1
      }},
      { $sort: { totalBookings: -1 } }
    ]);

    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const monthlyUsage = await Booking.aggregate([
      { $match: { vehicle: { $in: vehicleIds }, createdAt: { $gte: sixMonthsAgo } } },
      { $group: {
        _id: { month: { $month: '$createdAt' }, year: { $year: '$createdAt' } },
        count: { $sum: 1 },
        spent: { $sum: '$pricing.total' }
      }},
      { $sort: { '_id.year': 1, '_id.month': 1 } }
    ]);

    const mostUsed = bookingsPerVehicle.length > 0 ? bookingsPerVehicle[0] : null;
    const totalBookings = bookingsPerVehicle.reduce((s, v) => s + v.totalBookings, 0);
    const totalSpent = bookingsPerVehicle.reduce((s, v) => s + (v.totalSpent || 0), 0);

    res.json({
      success: true,
      data: {
        totalVehicles: vehicles.length,
        totalBookings,
        totalSpent,
        mostUsed,
        bookingsPerVehicle,
        monthlyUsage
      }
    });
  } catch (error) {
    console.error('Get vehicle stats error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Vehicle type → recommended slot type mapping
const VEHICLE_SLOT_MAP = {
  motorcycle: ['motorcycle', 'compact', 'standard', 'large'],
  car:        ['compact', 'standard', 'large'],
  electric:   ['ev_charging', 'compact', 'standard', 'large'],
  hybrid:     ['compact', 'standard', 'large', 'ev_charging'],
  van:        ['standard', 'large'],
  truck:      ['large']
};

// @route   GET /api/vehicles/slot-match/:vehicleId
// @desc    Get compatible parkings for a vehicle based on its type
// @access  Private
router.get('/slot-match/:vehicleId', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({ _id: req.params.vehicleId, owner: req.user._id });
    if (!vehicle) return res.status(404).json({ success: false, message: 'Véhicule non trouvé' });

    const vehicleType = vehicle.type || 'car';
    const compatibleSlots = VEHICLE_SLOT_MAP[vehicleType] || ['standard', 'large'];

    // Find active parkings that have at least one compatible slot available
    const Parking = require('../models/Parking');
    const parkings = await Parking.find({
      isActive: true,
      $or: [
        // Parkings with compatible slot types that have availability
        { 'slotTypes.type': { $in: compatibleSlots }, 'slotTypes.available': { $gt: 0 } },
        // Parkings without slot types defined (legacy) that have spots available
        { slotTypes: { $exists: true, $size: 0 }, availableSpots: { $gt: 0 } },
        { slotTypes: { $exists: false }, availableSpots: { $gt: 0 } }
      ]
    }).select('name address coordinates totalSpots availableSpots slotTypes pricing features rating').limit(50);

    // Annotate with compatibility info
    const results = parkings.map(p => {
      const parking = p.toObject();
      const slots = parking.slotTypes || [];
      const matchedSlots = slots.filter(s => compatibleSlots.includes(s.type) && s.available > 0);
      const hasSlotTypes = slots.length > 0;

      return {
        ...parking,
        compatibility: {
          vehicleType,
          recommendedSlots: compatibleSlots,
          matchedSlots: matchedSlots.map(s => ({ type: s.type, available: s.available })),
          isCompatible: !hasSlotTypes || matchedSlots.length > 0,
          hasSlotInfo: hasSlotTypes
        }
      };
    });

    res.json({
      success: true,
      data: {
        vehicle: { _id: vehicle._id, licensePlate: vehicle.licensePlate, type: vehicleType, make: vehicle.make, model: vehicle.model },
        recommendedSlotTypes: compatibleSlots,
        parkings: results
      }
    });
  } catch (error) {
    console.error('Slot match error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/vehicles
// @desc    Get user's vehicles
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const vehicles = await Vehicle.find({ owner: req.user._id })
      .sort({ isDefault: -1, createdAt: -1 });

    res.json({ success: true, data: vehicles });
  } catch (error) {
    console.error('Get vehicles error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/vehicles/:id
// @desc    Get single vehicle
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({ _id: req.params.id, owner: req.user._id });
    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }
    res.json({ success: true, data: vehicle });
  } catch (error) {
    console.error('Get vehicle error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
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

    const { licensePlate, make, model, year, color, type, fuelType, insuranceNumber, insuranceExpiry, isDefault } = req.body;

    // Duplicate plate check
    const existingVehicle = await Vehicle.findOne({ licensePlate: licensePlate.toUpperCase() });
    if (existingVehicle) {
      return res.status(409).json({
        success: false,
        message: 'Cette plaque d\'immatriculation existe déjà',
        code: 'DUPLICATE_PLATE'
      });
    }

    const vehicle = new Vehicle({
      owner: req.user._id,
      licensePlate: licensePlate.toUpperCase(),
      make, model, year, color,
      type: type || 'car',
      fuelType: fuelType || 'petrol',
      insuranceNumber: insuranceNumber || undefined,
      insuranceExpiry: insuranceExpiry || undefined,
      isDefault: isDefault || false
    });

    await vehicle.save();

    await User.findByIdAndUpdate(req.user._id, { $push: { vehicles: vehicle._id } });

    res.status(201).json({ success: true, data: vehicle, message: 'Vehicle created successfully' });
  } catch (error) {
    console.error('Create vehicle error:', error);
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'Cette plaque d\'immatriculation existe déjà',
        code: 'DUPLICATE_PLATE'
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   PUT /api/vehicles/:id
// @desc    Update vehicle
// @access  Private
router.put('/:id', protect, createVehicleValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
    }

    const vehicle = await Vehicle.findOne({ _id: req.params.id, owner: req.user._id });
    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    const { licensePlate, make, model, year, color, type, fuelType, insuranceNumber, insuranceExpiry } = req.body;

    if (licensePlate.toUpperCase() !== vehicle.licensePlate) {
      const dup = await Vehicle.findOne({ licensePlate: licensePlate.toUpperCase(), _id: { $ne: req.params.id } });
      if (dup) {
        return res.status(409).json({ success: false, message: 'Cette plaque d\'immatriculation existe déjà', code: 'DUPLICATE_PLATE' });
      }
    }

    vehicle.licensePlate = licensePlate.toUpperCase();
    vehicle.make = make;
    vehicle.model = model;
    vehicle.year = year;
    vehicle.color = color;
    if (type) vehicle.type = type;
    if (fuelType) vehicle.fuelType = fuelType;
    if (insuranceNumber !== undefined) vehicle.insuranceNumber = insuranceNumber;
    if (insuranceExpiry !== undefined) vehicle.insuranceExpiry = insuranceExpiry || null;

    await vehicle.save();

    res.json({ success: true, data: vehicle, message: 'Vehicle updated successfully' });
  } catch (error) {
    console.error('Update vehicle error:', error);
    if (error.code === 11000) {
      return res.status(409).json({ success: false, message: 'Cette plaque d\'immatriculation existe déjà', code: 'DUPLICATE_PLATE' });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   PUT /api/vehicles/:id/default
// @desc    Toggle default vehicle
// @access  Private
router.put('/:id/default', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({ _id: req.params.id, owner: req.user._id });
    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    vehicle.isDefault = !vehicle.isDefault;
    await vehicle.save();

    res.json({
      success: true,
      data: vehicle,
      message: vehicle.isDefault ? 'Véhicule défini par défaut' : 'Véhicule retiré des favoris'
    });
  } catch (error) {
    console.error('Toggle default vehicle error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   POST /api/vehicles/:id/photos
// @desc    Upload photos for a vehicle (max 3)
// @access  Private
router.post('/:id/photos', protect, upload.array('photos', 3), async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({ _id: req.params.id, owner: req.user._id });
    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ success: false, message: 'No photos provided' });
    }

    const currentCount = vehicle.photos ? vehicle.photos.length : 0;
    const maxNew = 3 - currentCount;
    const filesToAdd = req.files.slice(0, maxNew);

    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const photoUrls = filesToAdd.map(f => `${baseUrl}/uploads/vehicles/${f.filename}`);

    vehicle.photos = [...(vehicle.photos || []), ...photoUrls];
    await vehicle.save();

    res.json({ success: true, data: vehicle, message: `${filesToAdd.length} photo(s) uploaded` });
  } catch (error) {
    console.error('Upload vehicle photos error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/vehicles/:id/photos/:index
// @desc    Delete a vehicle photo by index
// @access  Private
router.delete('/:id/photos/:index', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({ _id: req.params.id, owner: req.user._id });
    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    const index = parseInt(req.params.index);
    if (isNaN(index) || index < 0 || index >= (vehicle.photos || []).length) {
      return res.status(400).json({ success: false, message: 'Invalid photo index' });
    }

    vehicle.photos.splice(index, 1);
    await vehicle.save();

    res.json({ success: true, data: vehicle, message: 'Photo deleted' });
  } catch (error) {
    console.error('Delete vehicle photo error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/vehicles/:id/history
// @desc    Get booking history for a specific vehicle
// @access  Private
router.get('/:id/history', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({ _id: req.params.id, owner: req.user._id });
    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    const bookings = await Booking.find({ vehicle: req.params.id })
      .populate('parking', 'name address pricePerHour')
      .sort({ createdAt: -1 });

    const totalSpent = bookings.reduce((sum, b) => sum + (b.pricing?.total || 0), 0);
    const completedBookings = bookings.filter(b => b.status === 'completed').length;

    res.json({
      success: true,
      data: {
        vehicle,
        bookings,
        stats: { totalBookings: bookings.length, completedBookings, totalSpent }
      }
    });
  } catch (error) {
    console.error('Get vehicle history error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/vehicles/:id
// @desc    Delete vehicle
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOneAndDelete({ _id: req.params.id, owner: req.user._id });
    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    await User.findByIdAndUpdate(req.user._id, { $pull: { vehicles: vehicle._id } });

    res.json({ success: true, message: 'Vehicle deleted successfully' });
  } catch (error) {
    console.error('Delete vehicle error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
