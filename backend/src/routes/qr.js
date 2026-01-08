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

// @route   POST /api/qr/scan
// @desc    Scan and validate QR code for check-in/check-out
// @access  Public (but requires valid QR)
router.post('/scan', async (req, res) => {
  try {
    const { qrCode, action } = req.body; // action: 'checkin' or 'checkout'

    if (!qrCode) {
      return res.status(400).json({
        success: false,
        message: 'QR code is required'
      });
    }

    if (!['checkin', 'checkout'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid action. Must be checkin or checkout'
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

    // Check booking status based on action
    if (action === 'checkin') {
      if (booking.status !== 'confirmed') {
        return res.status(400).json({
          success: false,
          message: 'Booking is not ready for check-in'
        });
      }

      // Check if check-in is within allowed time window
      const now = new Date();
      const startTime = new Date(booking.startTime);
      const timeDiff = (startTime - now) / (1000 * 60); // difference in minutes

      if (timeDiff > 15) { // Allow check-in 15 minutes early
        return res.status(400).json({
          success: false,
          message: 'Check-in not available yet'
        });
      }

      // Perform check-in
      await booking.checkIn();

      // Update parking availability
      await booking.parking.updateAvailability(-1);

      res.json({
        success: true,
        message: 'Check-in successful',
        data: {
          booking: {
            id: booking._id,
            status: booking.status,
            checkInTime: booking.checkInTime,
            parking: {
              name: booking.parking.name,
              availableSpots: booking.parking.availableSpots
            }
          }
        }
      });

    } else if (action === 'checkout') {
      if (booking.status !== 'active') {
        return res.status(400).json({
          success: false,
          message: 'Booking is not active for check-out'
        });
      }

      // Calculate final payment amount
      const now = new Date();
      const checkInTime = new Date(booking.checkInTime);
      const durationMs = now - checkInTime;
      const durationHours = Math.ceil(durationMs / (1000 * 60 * 60));

      // Calculate cost (minimum 1 hour)
      const hours = Math.max(1, durationHours);
      const totalAmount = hours * booking.parking.pricing.hourly;

      // Perform check-out
      await booking.checkOut();

      // Update parking availability
      await booking.parking.updateAvailability(1);

      res.json({
        success: true,
        message: 'Check-out successful',
        data: {
          booking: {
            id: booking._id,
            status: booking.status,
            checkInTime: booking.checkInTime,
            checkOutTime: booking.checkOutTime,
            duration: { hours },
            payment: {
              amount: totalAmount,
              currency: 'TND',
              status: 'pending' // Payment happens at exit terminal
            }
          }
        }
      });
    }

  } catch (error) {
    console.error('QR scan error:', error);
    res.status(500).json({
      success: false,
      message: 'Error processing QR code'
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