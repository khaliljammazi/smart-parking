const express = require('express');
const QRCode = require('qrcode');
const nodemailer = require('nodemailer');
const Booking = require('../models/Booking');
const Parking = require('../models/Parking');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Configure nodemailer for receipt emails
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASS,
  },
});

// Helper to send checkout receipt email from QR scan
async function sendQRCheckoutReceipt(user, booking, parking, vehicle) {
  if (!process.env.GMAIL_USER || !process.env.GMAIL_PASS) return;

  const parkingAddress = parking?.address
    ? (typeof parking.address === 'object'
        ? `${parking.address.street || ''}, ${parking.address.city || ''}`.trim().replace(/^,\s*/, '')
        : parking.address)
    : 'Non spécifiée';

  const vehicleInfo = vehicle
    ? `${vehicle.make || ''} ${vehicle.model || ''} — ${vehicle.licensePlate || ''}`.trim()
    : 'Aucun véhicule';

  const checkIn = booking.checkInTime ? new Date(booking.checkInTime) : new Date(booking.startTime);
  const checkOut = booking.checkOutTime ? new Date(booking.checkOutTime) : new Date();
  const durationMs = checkOut - checkIn;
  const durationHours = Math.floor(durationMs / (1000 * 60 * 60));
  const durationMinutes = Math.round((durationMs % (1000 * 60 * 60)) / (1000 * 60));
  const durationStr = durationHours >= 1
    ? `${durationHours}h${durationMinutes > 0 ? ` ${durationMinutes}min` : ''}`
    : `${durationMinutes}min`;

  const pricing = booking.pricing || {};
  const rate = (pricing.rate || 0).toFixed(2);
  const subtotal = (pricing.subtotal || 0).toFixed(2);
  const tax = (pricing.tax || 0).toFixed(2);
  const total = (pricing.total || 0).toFixed(2);

  const checkInStr = checkIn.toLocaleString('fr-FR', { dateStyle: 'medium', timeStyle: 'short' });
  const checkOutStr = checkOut.toLocaleString('fr-FR', { dateStyle: 'medium', timeStyle: 'short' });

  const html = `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <style>
      body { font-family: 'Segoe UI', Tahoma, Geneva, sans-serif; background: #f4f6f9; margin: 0; padding: 0; }
      .container { max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
      .header { background: linear-gradient(135deg, #1b5e20, #2e7d32); padding: 30px; text-align: center; }
      .header h1 { color: #ffffff; margin: 0; font-size: 24px; }
      .header p { color: #c8e6c9; margin: 8px 0 0; font-size: 14px; }
      .icon { font-size: 48px; margin-bottom: 10px; }
      .body { padding: 30px; }
      .receipt-badge { background: #e8f5e9; color: #2e7d32; padding: 12px 20px; border-radius: 8px; text-align: center; font-weight: bold; font-size: 16px; margin-bottom: 24px; }
      .detail-card { background: #f8f9fa; border-radius: 12px; padding: 20px; margin-bottom: 16px; border-left: 4px solid #2e7d32; }
      .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #e9ecef; }
      .detail-row:last-child { border-bottom: none; }
      .detail-label { color: #666; font-size: 14px; }
      .detail-value { color: #1a237e; font-weight: 600; font-size: 14px; }
      .pricing-card { background: #fff8e1; border-radius: 12px; padding: 20px; margin-bottom: 16px; border-left: 4px solid #f9a825; }
      .pricing-row { display: flex; justify-content: space-between; padding: 6px 0; }
      .pricing-label { color: #555; font-size: 14px; }
      .pricing-value { color: #333; font-weight: 500; font-size: 14px; }
      .total-row { display: flex; justify-content: space-between; padding: 12px 0 0; margin-top: 8px; border-top: 2px solid #f9a825; }
      .total-label { color: #333; font-weight: bold; font-size: 18px; }
      .total-value { color: #2e7d32; font-weight: bold; font-size: 22px; }
      .footer { text-align: center; padding: 20px; color: #999; font-size: 12px; border-top: 1px solid #eee; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <div class="icon">🧾</div>
        <h1>Smart Parking</h1>
        <p>Reçu de stationnement</p>
      </div>
      <div class="body">
        <div class="receipt-badge">✅ Stationnement terminé</div>
        <p style="color:#333;">Bonjour <strong>${user.firstName || 'Client'}</strong>,</p>
        <p style="color:#555;">Voici le reçu de votre stationnement :</p>
        <div class="detail-card">
          <div class="detail-row"><span class="detail-label">🏢 Parking</span><span class="detail-value">${parking?.name || 'N/A'}</span></div>
          <div class="detail-row"><span class="detail-label">📍 Adresse</span><span class="detail-value">${parkingAddress}</span></div>
          <div class="detail-row"><span class="detail-label">🚗 Véhicule</span><span class="detail-value">${vehicleInfo}</span></div>
          <div class="detail-row"><span class="detail-label">📥 Check-in</span><span class="detail-value">${checkInStr}</span></div>
          <div class="detail-row"><span class="detail-label">📤 Check-out</span><span class="detail-value">${checkOutStr}</span></div>
          <div class="detail-row"><span class="detail-label">⏱️ Durée</span><span class="detail-value">${durationStr}</span></div>
        </div>
        <div class="pricing-card">
          <h3 style="margin:0 0 12px; color:#f9a825;">💰 Facturation</h3>
          <div class="pricing-row"><span class="pricing-label">Tarif horaire</span><span class="pricing-value">${rate} DT/h</span></div>
          <div class="pricing-row"><span class="pricing-label">Sous-total</span><span class="pricing-value">${subtotal} DT</span></div>
          <div class="pricing-row"><span class="pricing-label">TVA (19%)</span><span class="pricing-value">${tax} DT</span></div>
          <div class="total-row"><span class="total-label">TOTAL</span><span class="total-value">${total} DT</span></div>
        </div>
        <p style="color:#888; font-size:13px; text-align:center;">Merci d'avoir utilisé Smart Parking ! 🙏</p>
      </div>
      <div class="footer"><p>© ${new Date().getFullYear()} Smart Parking — Stationnement intelligent en Tunisie</p></div>
    </div>
  </body>
  </html>`;

  try {
    await transporter.sendMail({
      from: process.env.GMAIL_USER,
      to: user.email,
      subject: `🧾 Reçu de stationnement — ${parking?.name || 'Smart Parking'} (${total} DT)`,
      html,
    });
    console.log(`[Email] ✅ QR checkout receipt sent to ${user.email}`);
  } catch (emailError) {
    console.error('[Email] ❌ QR checkout receipt error:', emailError.message);
  }
}

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

    // Check if QR code is still valid (we removed the strict expiry check for demo friendliness)
    // QR is valid as long as booking endTime hasn't passed by more than 1 hour
    const graceEnd = new Date(booking.endTime.getTime() + (60 * 60 * 1000));
    if (graceEnd < new Date()) {
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
    if (booking.adminValidated && booking.status === 'active') {
      // Second scan → check-out
      booking.status = 'completed';
      booking.checkOutTime = new Date();
      await booking.save();

      // Calculate final pricing based on actual usage
      try {
        await booking.calculatePricing();
        await booking.save();
      } catch (pricingErr) {
        console.error('Pricing calculation error:', pricingErr);
      }

      // Release parking spot
      if (booking.parking && booking.parking._id) {
        const Parking = require('../models/Parking');
        await Parking.findByIdAndUpdate(booking.parking._id, { $inc: { availableSpots: 1 } });
      }

      const parkingAddr = booking.parking?.address;
      const addressStr = typeof parkingAddr === 'object' && parkingAddr
        ? `${parkingAddr.street || ''}, ${parkingAddr.city || ''}`.replace(/^, |, $/g, '')
        : (parkingAddr || '');

      // Calculate duration for display
      const checkIn = booking.checkInTime || booking.startTime;
      const checkOut = booking.checkOutTime;
      const durationMs = checkOut - checkIn;
      const durationHours = Math.ceil(durationMs / (1000 * 60 * 60));
      const durationMinutes = Math.round(durationMs / (1000 * 60));

      // Send checkout receipt email (async, don't block response)
      sendQRCheckoutReceipt(booking.user, booking, booking.parking, booking.vehicle).catch(() => {});

      return res.json({
        success: true,
        message: 'Check-out effectué avec succès',
        data: {
          action: 'checkout',
          booking: {
            id: booking._id,
            status: booking.status,
            checkInTime: booking.checkInTime,
            checkOutTime: booking.checkOutTime,
            pricing: booking.pricing,
            duration: {
              hours: durationHours,
              minutes: durationMinutes,
              display: durationHours >= 1 ? `${durationHours}h${durationMinutes % 60 > 0 ? ` ${durationMinutes % 60}min` : ''}` : `${durationMinutes}min`
            },
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
              address: addressStr
            }
          }
        }
      });
    }

    // Check if booking can be validated (first scan → check-in)
    if (booking.status !== 'confirmed') {
      return res.status(400).json({
        success: false,
        message: `La réservation n'est pas dans un état valide (statut: ${booking.status})`
      });
    }

    // First scan → Check-in: validate and set status to active
    booking.adminValidated = true;
    booking.adminValidatedAt = new Date();
    booking.status = 'active';
    booking.checkInTime = new Date();
    await booking.save();

    // Decrement available spots
    if (booking.parking && booking.parking._id) {
      const Parking = require('../models/Parking');
      await Parking.findByIdAndUpdate(booking.parking._id, { $inc: { availableSpots: -1 } });
    }

    const parkingAddr2 = booking.parking?.address;
    const addressStr2 = typeof parkingAddr2 === 'object' && parkingAddr2
      ? `${parkingAddr2.street || ''}, ${parkingAddr2.city || ''}`.replace(/^, |, $/g, '')
      : (parkingAddr2 || '');

    res.json({
      success: true,
      message: 'Check-in effectué — réservation activée',
      data: {
        action: 'checkin',
        booking: {
          id: booking._id,
          status: booking.status,
          checkInTime: booking.checkInTime,
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
            address: addressStr2
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