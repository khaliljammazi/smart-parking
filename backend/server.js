const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const passport = require('passport');
const path = require('path');
const schedule = require('node-schedule');
require('dotenv').config();

const app = express();

// Import routes
const authRoutes = require('./src/routes/auth');
const userRoutes = require('./src/routes/user');
const parkingRoutes = require('./src/routes/parking');
const bookingRoutes = require('./src/routes/booking');
const vehicleRoutes = require('./src/routes/vehicle');
const adminRoutes = require('./src/routes/admin');
const qrRoutes = require('./src/routes/qr');
const notificationRoutes = require('./src/routes/notification');
const deviceRoutes = require('./src/routes/device');
const ratingRoutes = require('./src/routes/rating');
const supportRoutes = require('./src/routes/support');

// Middleware
app.use(helmet());
app.use(cors({
  origin: true, // Allow all origins (Flutter web runs on dynamic ports)
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve uploaded files (avatars, etc.)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Passport middleware
app.use(passport.initialize());
require('./src/config/passport')(passport);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/parking', parkingRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/qr', qrRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/devices', deviceRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/support', supportRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : {}
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

// Database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/smart_parking')
.then(() => {
  console.log('MongoDB connected successfully');

  // ── Auto-cancel cron: every 5 minutes, cancel confirmed bookings that are 30+ min overdue ──
  const Booking = require('./src/models/Booking');
  const Parking = require('./src/models/Parking');

  schedule.scheduleJob('*/5 * * * *', async () => {
    try {
      const thirtyMinAgo = new Date(Date.now() - 30 * 60 * 1000);
      const expired = await Booking.find({
        status: 'confirmed',
        adminValidated: false,
        startTime: { $lt: thirtyMinAgo }
      });

      // Use updateMany to bypass Mongoose validators (startTime is in the past)
      const expiredIds = expired.map(b => b._id);
      if (expiredIds.length > 0) {
        await Booking.updateMany(
          { _id: { $in: expiredIds } },
          { $set: { status: 'cancelled', cancelledAt: new Date(), cancellationReason: 'expired' } }
        );
        // Release parking spots
        const parkingIds = [...new Set(expired.map(b => b.parking?.toString()).filter(Boolean))];
        for (const pid of parkingIds) {
          const count = expired.filter(b => b.parking?.toString() === pid).length;
          await Parking.findByIdAndUpdate(pid, { $inc: { availableSpots: count } });
        }
      }

      if (expired.length > 0) {
        console.log(`[CRON] Auto-cancelled ${expired.length} expired booking(s)`);
      }
    } catch (err) {
      console.error('[CRON] auto-cancel error:', err);
    }
  });
})
.catch(err => console.error('MongoDB connection error:', err));

// Start server
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;