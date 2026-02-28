const express = require('express');
const { body, validationResult } = require('express-validator');
const nodemailer = require('nodemailer');
const Booking = require('../models/Booking');
const Parking = require('../models/Parking');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const schedule = require('node-schedule');
const pushUtil = require('../utils/push');

const router = express.Router();

// Configure nodemailer
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASS,
  },
});

// Helper to send reservation confirmation email
async function sendReservationEmail(user, booking, parking, vehicle) {
  if (!process.env.GMAIL_USER || !process.env.GMAIL_PASS) return;

  const startDate = new Date(booking.startTime).toLocaleDateString('fr-FR', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
  });
  const startTime = new Date(booking.startTime).toLocaleTimeString('fr-FR', {
    hour: '2-digit', minute: '2-digit'
  });

  const parkingAddress = parking.address
    ? `${parking.address.street || ''}, ${parking.address.city || ''}`.trim().replace(/^,\s*/, '')
    : 'Non spécifiée';

  const vehicleInfo = vehicle
    ? `${vehicle.make} ${vehicle.model} — ${vehicle.licensePlate}`
    : 'Aucun véhicule spécifié';

  const html = `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <style>
      body { font-family: 'Segoe UI', Tahoma, Geneva, sans-serif; background: #f4f6f9; margin: 0; padding: 0; }
      .container { max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
      .header { background: linear-gradient(135deg, #1a237e, #283593); padding: 30px; text-align: center; }
      .header h1 { color: #ffffff; margin: 0; font-size: 24px; }
      .header p { color: #b3c0ff; margin: 8px 0 0; font-size: 14px; }
      .icon { font-size: 48px; margin-bottom: 10px; }
      .body { padding: 30px; }
      .success-badge { background: #e8f5e9; color: #2e7d32; padding: 12px 20px; border-radius: 8px; text-align: center; font-weight: bold; font-size: 16px; margin-bottom: 24px; }
      .detail-card { background: #f8f9fa; border-radius: 12px; padding: 20px; margin-bottom: 16px; border-left: 4px solid #1a237e; }
      .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #e9ecef; }
      .detail-row:last-child { border-bottom: none; }
      .detail-label { color: #666; font-size: 14px; }
      .detail-value { color: #1a237e; font-weight: 600; font-size: 14px; }
      .qr-section { text-align: center; padding: 20px; background: #f0f4ff; border-radius: 12px; margin: 20px 0; }
      .qr-code { font-family: monospace; font-size: 18px; letter-spacing: 3px; color: #1a237e; background: #fff; padding: 12px 20px; border-radius: 8px; display: inline-block; border: 2px dashed #1a237e; }
      .info-box { background: #e3f2fd; border-radius: 8px; padding: 16px; margin-top: 20px; }
      .info-box p { margin: 4px 0; font-size: 13px; color: #1565c0; }
      .footer { text-align: center; padding: 20px; color: #999; font-size: 12px; border-top: 1px solid #eee; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <div class="icon">🅿️</div>
        <h1>Smart Parking</h1>
        <p>Confirmation de réservation</p>
      </div>
      <div class="body">
        <div class="success-badge">✅ Réservation confirmée !</div>

        <p style="color:#333;">Bonjour <strong>${user.firstName}</strong>,</p>
        <p style="color:#555;">Votre place de parking a été réservée avec succès. Voici les détails :</p>

        <div class="detail-card">
          <div class="detail-row">
            <span class="detail-label">🏢 Parking</span>
            <span class="detail-value">${parking.name}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">📍 Adresse</span>
            <span class="detail-value">${parkingAddress}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">📅 Date</span>
            <span class="detail-value">${startDate}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">🕐 Heure d'arrivée</span>
            <span class="detail-value">${startTime}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">⏱️ Durée</span>
            <span class="detail-value">Selon votre stationnement</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">🚗 Véhicule</span>
            <span class="detail-value">${vehicleInfo}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">💰 Tarif horaire</span>
            <span class="detail-value">${parking.pricing?.hourly || 0} DT/h</span>
          </div>
        </div>

        <div class="qr-section">
          <p style="font-weight:bold; color:#1a237e; margin-bottom:12px;">📱 Votre code QR</p>
          <div class="qr-code">${booking.qrCode || booking._id}</div>
          <p style="font-size:12px; color:#666; margin-top:10px;">Présentez ce code à l'entrée du parking</p>
        </div>

        <div class="info-box">
          <p>📌 Présentez le QR code à l'entrée du parking</p>
          <p>💵 Le paiement se fait en espèces à la sortie</p>
          <p>⏰ Le tarif est calculé selon la durée de stationnement</p>
        </div>
      </div>
      <div class="footer">
        <p>© ${new Date().getFullYear()} Smart Parking — Stationnement intelligent en Tunisie</p>
      </div>
    </div>
  </body>
  </html>`;

  try {
    await transporter.sendMail({
      from: process.env.GMAIL_USER,
      to: user.email,
      subject: `🅿️ Réservation confirmée — ${parking.name}`,
      html,
    });
  } catch (emailError) {
    console.error('Reservation email error:', emailError);
  }
}

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

// @route   POST /api/bookings/reserve
// @desc    Create immediate reservation with QR code
// @access  Private
router.post('/reserve', protect, async (req, res) => {
  try {
    const { parkingId, vehicleId } = req.body;

    if (!parkingId) {
      return res.status(400).json({
        success: false,
        message: 'Parking ID is required'
      });
    }

    // Check if parking exists and has available spots
    const parking = await Parking.findById(parkingId);
    if (!parking) {
      return res.status(404).json({
        success: false,
        message: 'Parking not found'
      });
    }

    if (!parking.isActive || !parking.isSpotAvailable()) {
      return res.status(400).json({
        success: false,
        message: 'No available spots at this parking'
      });
    }

    // Check if vehicle belongs to user (if vehicleId provided)
    let vehicle = null;
    if (vehicleId) {
      vehicle = await Vehicle.findOne({
        _id: vehicleId,
        owner: req.user._id
      });

      if (!vehicle) {
        return res.status(404).json({
          success: false,
          message: 'Vehicle not found or not owned by user'
        });
      }
    }

    // Create booking with immediate start time (set to 1 minute in future to pass validation)
    const now = new Date();
    const startTime = new Date(now.getTime() + 60 * 1000); // 1 minute from now
    const endTime = new Date(now.getTime() + 24 * 60 * 60 * 1000); // Default 24 hours

    const booking = new Booking({
      user: req.user._id,
      parking: parkingId,
      vehicle: vehicleId || null, // Allow null for immediate reservations
      bookingType: 'hourly',
      startTime: startTime,
      endTime: endTime,
      status: 'confirmed',
      pricing: {
        rate: parking.pricing.hourly,
        subtotal: 0, // Will be calculated at checkout
        tax: 0,
        total: 0
      },
      payment: {
        status: 'pending',
        method: 'cash'
      }
    });

    // Save booking (QR code will be generated in pre-save middleware)
    await booking.save();

    // Update parking availability
    parking.availableSpots -= 1;
    await parking.save();

    const populatedBooking = await Booking.findById(booking._id)
      .populate('parking', 'name address coordinates pricing')
      .populate('vehicle', 'licensePlate make model');

    // Send reservation confirmation email
    const user = await User.findById(req.user._id);
    if (user) {
      sendReservationEmail(user, populatedBooking, parking, vehicle);
    }

    // Schedule push reminder 30 minutes before start time
    try {
      const reminderTime = new Date(populatedBooking.startTime.getTime() - 30 * 60 * 1000);
      if (reminderTime > new Date()) {
        schedule.scheduleJob(`reminder_${booking._id}`, reminderTime, async () => {
          const u = await User.findById(booking.user);
          const tokens = (u.deviceTokens || []).map(t => t.token).filter(Boolean);
          if (tokens.length) {
            await pushUtil.sendPushToTokens(tokens, {
              notification: { title: 'Rappel réservation', body: `Votre place à ${parking.name} commence dans 30 minutes.` },
              data: { bookingId: booking._id.toString(), type: 'reminder' }
            });
          }
        });
      }

      // Schedule end-time notification
      const endTime = new Date(populatedBooking.endTime);
      if (endTime > new Date()) {
        schedule.scheduleJob(`expiry_${booking._id}`, endTime, async () => {
          const u = await User.findById(booking.user);
          const tokens = (u.deviceTokens || []).map(t => t.token).filter(Boolean);
          if (tokens.length) {
            await pushUtil.sendPushToTokens(tokens, {
              notification: { title: 'Fin de réservation', body: `Votre réservation à ${parking.name} est terminée.` },
              data: { bookingId: booking._id.toString(), type: 'expiry' }
            });
          }
        });
      }
    } catch (schedErr) {
      console.error('Scheduling push error:', schedErr);
    }

    res.status(201).json({
      success: true,
      message: 'Reservation created successfully',
      data: { booking: populatedBooking }
    });
  } catch (error) {
    console.error('Reserve parking error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create reservation',
      error: error.message
    });
  }
});

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

    // Schedule push reminder 30 minutes before start time
    try {
      const reminderTime = new Date(booking.startTime.getTime() - 30 * 60 * 1000);
      if (reminderTime > new Date()) {
        schedule.scheduleJob(`reminder_${booking._id}`, reminderTime, async () => {
          const u = await User.findById(booking.user);
          const tokens = (u.deviceTokens || []).map(t => t.token).filter(Boolean);
          if (tokens.length) {
            await pushUtil.sendPushToTokens(tokens, {
              notification: { title: 'Rappel réservation', body: `Votre place à ${booking.parking.name} commence dans 30 minutes.` },
              data: { bookingId: booking._id.toString(), type: 'reminder' }
            });
          }
        });
      }

      const endTime = new Date(booking.endTime);
      if (endTime > new Date()) {
        schedule.scheduleJob(`expiry_${booking._id}`, endTime, async () => {
          const u = await User.findById(booking.user);
          const tokens = (u.deviceTokens || []).map(t => t.token).filter(Boolean);
          if (tokens.length) {
            await pushUtil.sendPushToTokens(tokens, {
              notification: { title: 'Fin de réservation', body: `Votre réservation à ${booking.parking.name} est terminée.` },
              data: { bookingId: booking._id.toString(), type: 'expiry' }
            });
          }
        });
      }
    } catch (schedErr) {
      console.error('Scheduling push error:', schedErr);
    }

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

// @route   GET /api/bookings/my-stats
// @desc    Get user's parking statistics dashboard
// @access  Private
router.get('/my-stats', protect, async (req, res) => {
  try {
    const userId = req.user._id;

    const bookings = await Booking.find({ user: userId })
      .populate('parking', 'name address images rating')
      .sort({ createdAt: -1 });

    const completed = bookings.filter(b => b.status === 'completed');
    const active = bookings.filter(b => b.status === 'active' || b.status === 'confirmed');
    const cancelled = bookings.filter(b => b.status === 'cancelled');

    const totalSpent = completed.reduce((sum, b) => sum + (b.pricing?.total || 0), 0);

    let totalHours = 0;
    for (const b of completed) {
      const start = b.checkInTime || b.startTime;
      const end = b.checkOutTime || b.endTime;
      if (start && end) {
        totalHours += Math.max(1, Math.ceil((new Date(end) - new Date(start)) / (1000 * 60 * 60)));
      }
    }

    const avgDuration = completed.length > 0 ? Math.round((totalHours / completed.length) * 10) / 10 : 0;

    const parkingVisits = {};
    for (const b of bookings) {
      if (b.parking) {
        const pid = b.parking._id.toString();
        if (!parkingVisits[pid]) {
          parkingVisits[pid] = {
            parking: {
              id: pid,
              name: b.parking.name,
              address: b.parking.address,
              rating: b.parking.rating
            },
            visits: 0,
            totalSpent: 0
          };
        }
        parkingVisits[pid].visits++;
        if (b.status === 'completed') {
          parkingVisits[pid].totalSpent += (b.pricing?.total || 0);
        }
      }
    }
    const topParkings = Object.values(parkingVisits)
      .sort((a, b) => b.visits - a.visits)
      .slice(0, 5);

    const monthly = [];
    const now = new Date();
    for (let i = 11; i >= 0; i--) {
      const monthDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0, 23, 59, 59);
      const monthBookings = completed.filter(b => {
        const d = new Date(b.createdAt);
        return d >= monthDate && d <= monthEnd;
      });
      monthly.push({
        month: monthDate.toISOString().slice(0, 7),
        label: monthDate.toLocaleDateString('fr-FR', { month: 'short' }),
        spent: Math.round(monthBookings.reduce((s, b) => s + (b.pricing?.total || 0), 0) * 100) / 100,
        count: monthBookings.length,
        hours: monthBookings.reduce((s, b) => {
          const start = b.checkInTime || b.startTime;
          const end = b.checkOutTime || b.endTime;
          if (start && end) return s + Math.max(1, Math.ceil((new Date(end) - new Date(start)) / (1000 * 60 * 60)));
          return s;
        }, 0)
      });
    }

    const weekdays = [0, 0, 0, 0, 0, 0, 0];
    for (const b of bookings) {
      const day = new Date(b.startTime).getDay();
      weekdays[day]++;
    }

    res.json({
      success: true,
      data: {
        overview: {
          totalBookings: bookings.length,
          completedBookings: completed.length,
          activeBookings: active.length,
          cancelledBookings: cancelled.length,
          totalSpent: Math.round(totalSpent * 100) / 100,
          totalHours,
          avgDuration
        },
        topParkings,
        monthly,
        weekdayDistribution: weekdays
      }
    });
  } catch (error) {
    console.error('Get my stats error:', error);
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

// @route   PUT /api/bookings/:id/checkin
// @desc    Check in to parking spot (requires admin validation)
// @access  Private
router.put('/:id/checkin', protect, async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      user: req.user._id,
      status: 'confirmed'
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found or cannot be checked in'
      });
    }

    // Check if booking has been validated by admin
    if (!booking.adminValidated) {
      return res.status(400).json({
        success: false,
        message: 'Booking must be validated by admin before check-in'
      });
    }

    await booking.checkIn();
    // Send push confirming check-in
    try {
      const u = await User.findById(booking.user);
      const tokens = (u.deviceTokens || []).map(t => t.token).filter(Boolean);
      if (tokens.length) {
        await pushUtil.sendPushToTokens(tokens, {
          notification: { title: 'Check-in confirmé', body: `Vous êtes bien enregistré pour votre réservation.` },
          data: { bookingId: booking._id.toString(), type: 'checkin' }
        });
      }
    } catch (pushErr) {
      console.error('Check-in push error:', pushErr);
    }

    res.json({
      success: true,
      message: 'Checked in successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Check-in error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/bookings/:id/checkout
// @desc    Check out from parking spot
// @access  Private
router.put('/:id/checkout', protect, async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      user: req.user._id,
      status: 'active'
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Active booking not found'
      });
    }

    await booking.checkOut();

    res.json({
      success: true,
      message: 'Checked out successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Check-out error:', error);
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

module.exports = router;