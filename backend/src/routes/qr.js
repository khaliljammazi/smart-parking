const express = require('express');
const QRCode = require('qrcode');
const Booking = require('../models/Booking');
const Parking = require('../models/Parking');
const { protect } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/qr/generate/:bookingId
// @desc    Generate QR code for booking
// @access  Private
router.get('/generate/:bookingId', protect, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.bookingId)
      .populate('user', 'firstName lastName email')
      .populate('parking', 'name address')
      .populate('vehicle', 'make model licensePlate');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user owns this booking
    if (booking.user._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this booking'
      });
    }

    // Check if booking is valid for QR generation
    if (!['confirmed', 'active'].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: 'Booking is not active'
      });
    }

    // Check if QR code is still valid
    if (booking.qrCodeExpires < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'QR code has expired'
      });
    }

    // Generate QR code data
    const qrData = {
      bookingId: booking._id,
      qrCode: booking.qrCode,
      userId: booking.user._id,
      parkingId: booking.parking._id,
      vehicleId: booking.vehicle._id,
      startTime: booking.startTime,
      endTime: booking.endTime,
      expires: booking.qrCodeExpires
    };

    // Generate QR code image
    const qrCodeImage = await QRCode.toDataURL(JSON.stringify(qrData), {
      width: parseInt(process.env.QR_CODE_SIZE) || 256,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    res.json({
      success: true,
      data: {
        qrCode: qrCodeImage,
        qrData: qrData,
        booking: {
          id: booking._id,
          startTime: booking.startTime,
          endTime: booking.endTime,
          status: booking.status,
          parking: {
            name: booking.parking.name,
            address: booking.parking.address
          },
          vehicle: {
            make: booking.vehicle.make,
            model: booking.vehicle.model,
            licensePlate: booking.vehicle.licensePlate
          }
        }
      }
    });
  } catch (error) {
    console.error('QR generation error:', error);
    res.status(500).json({
      success: false,
      message: 'Error generating QR code'
    });
  }
});

// @route   POST /api/qr/verify
// @desc    Verify QR code and get booking info
// @access  Private
router.post('/verify', protect, async (req, res) => {
  try {
    const { qrCode } = req.body;

    if (!qrCode) {
      return res.status(400).json({
        success: false,
        message: 'QR code is required'
      });
    }

    // Find booking by QR code
    const booking = await Booking.findOne({ qrCode })
      .populate('parking', 'name address')
      .populate('vehicle', 'make model licensePlate');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Invalid QR code'
      });
    }

    // Check if QR code is expired
    if (booking.qrCodeExpires && booking.qrCodeExpires < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'QR code has expired'
      });
    }

    res.json({
      success: true,
      data: {
        booking: {
          id: booking._id,
          status: booking.status,
          startTime: booking.startTime,
          endTime: booking.endTime,
          checkInTime: booking.checkInTime,
          parking: booking.parking,
          vehicle: booking.vehicle
        }
      }
    });
  } catch (error) {
    console.error('QR verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Error verifying QR code'
    });
  }
});

// @route   POST /api/qr/scan
// @desc    Scan and validate QR code (admin validation)
// @access  Public (but requires valid QR)
router.post('/scan', async (req, res) => {
  try {
    const { qrCode } = req.body;

    if (!qrCode) {
      return res.status(400).json({
        success: false,
        message: 'QR code is required'
      });
    }

    // Find booking by QR code
    const booking = await Booking.findByQRCode(qrCode);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Invalid or expired QR code'
      });
    }

    // Check if booking is already validated
    if (booking.adminValidated) {
      return res.status(400).json({
        success: false,
        message: 'Booking already validated'
      });
    }

    // Check if booking can be validated
    if (booking.status !== 'confirmed') {
      return res.status(400).json({
        success: false,
        message: 'Booking is not in valid state for validation'
      });
    }

    // Validate the booking
    booking.adminValidated = true;
    booking.adminValidatedAt = new Date();
    // Note: adminValidatedBy would be set if we had admin authentication
    await booking.save();

    res.json({
      success: true,
      message: 'Booking validated successfully',
      data: {
        booking: {
          id: booking._id,
          status: booking.status,
          adminValidated: booking.adminValidated,
          adminValidatedAt: booking.adminValidatedAt,
          user: {
            name: `${booking.user.firstName} ${booking.user.lastName}`,
            email: booking.user.email
          },
          vehicle: booking.vehicle ? {
            make: booking.vehicle.make,
            model: booking.vehicle.model,
            licensePlate: booking.vehicle.licensePlate
          } : null,
          parking: {
            name: booking.parking.name,
            address: booking.parking.address
          }
        }
      }
    });

  } catch (error) {
    console.error('QR scan error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/qr/validate/:qrCode
// @desc    Validate QR code without performing action
// @access  Public
router.get('/validate/:qrCode', async (req, res) => {
  try {
    const booking = await Booking.findByQRCode(req.params.qrCode);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Invalid or expired QR code'
      });
    }

    res.json({
      success: true,
      message: 'QR code is valid',
      data: {
        booking: {
          id: booking._id,
          status: booking.status,
          startTime: booking.startTime,
          endTime: booking.endTime,
          user: {
            firstName: booking.user.firstName,
            lastName: booking.user.lastName,
            vehicle: {
              make: booking.vehicle.make,
              model: booking.vehicle.model,
              licensePlate: booking.vehicle.licensePlate
            }
          },
          parking: {
            name: booking.parking.name,
            address: booking.parking.address
          }
        }
      }
    });
  } catch (error) {
    console.error('QR validation error:', error);
    res.status(500).json({
      success: false,
      message: 'Error validating QR code'
    });
  }
});

module.exports = router;