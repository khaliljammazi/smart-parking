const express = require('express');
const Booking = require('../models/Booking');
const User = require('../models/User');
const Parking = require('../models/Parking');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Middleware to check if user is admin
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Admin role required.'
    });
  }
  next();
};

// @route   GET /api/admin/revenue
// @desc    Get revenue statistics
// @access  Private (Admin only)
router.get('/revenue', protect, requireAdmin, async (req, res) => {
  try {
    const { startDate, endDate, period = 'month' } = req.query;

    // Set default date range (last 30 days)
    const end = endDate ? new Date(endDate) : new Date();
    const start = startDate ? new Date(startDate) : new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Get completed bookings within date range
    const bookings = await Booking.find({
      status: 'completed',
      checkOutTime: {
        $gte: start,
        $lte: end
      }
    }).populate('parking', 'name')
      .populate('user', 'firstName lastName email')
      .sort({ checkOutTime: -1 });

    // Calculate revenue statistics
    const totalRevenue = bookings.reduce((sum, booking) => sum + (booking.pricing?.total || 0), 0);
    const totalBookings = bookings.length;
    const averageRevenue = totalBookings > 0 ? totalRevenue / totalBookings : 0;

    // Group by parking
    const revenueByParking = {};
    bookings.forEach(booking => {
      const parkingName = booking.parking?.name || 'Unknown Parking';
      if (!revenueByParking[parkingName]) {
        revenueByParking[parkingName] = {
          parkingName,
          totalRevenue: 0,
          bookingCount: 0
        };
      }
      revenueByParking[parkingName].totalRevenue += booking.pricing?.total || 0;
      revenueByParking[parkingName].bookingCount += 1;
    });

    // Group by period (daily, weekly, monthly)
    const revenueByPeriod = {};
    bookings.forEach(booking => {
      let periodKey;
      const date = booking.checkOutTime;

      switch (period) {
        case 'day':
          periodKey = date.toISOString().split('T')[0];
          break;
        case 'week':
          const weekStart = new Date(date);
          weekStart.setDate(date.getDate() - date.getDay());
          periodKey = weekStart.toISOString().split('T')[0];
          break;
        case 'month':
        default:
          periodKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
          break;
      }

      if (!revenueByPeriod[periodKey]) {
        revenueByPeriod[periodKey] = {
          period: periodKey,
          totalRevenue: 0,
          bookingCount: 0
        };
      }
      revenueByPeriod[periodKey].totalRevenue += booking.pricing?.total || 0;
      revenueByPeriod[periodKey].bookingCount += 1;
    });

    res.json({
      success: true,
      data: {
        summary: {
          totalRevenue,
          totalBookings,
          averageRevenue,
          period: {
            start: start.toISOString(),
            end: end.toISOString()
          }
        },
        revenueByParking: Object.values(revenueByParking),
        revenueByPeriod: Object.values(revenueByPeriod).sort((a, b) => a.period.localeCompare(b.period)),
        recentBookings: bookings.slice(0, 10).map(booking => ({
          id: booking._id,
          user: `${booking.user?.firstName} ${booking.user?.lastName}`,
          parking: booking.parking?.name,
          amount: booking.pricing?.total || 0,
          checkOutTime: booking.checkOutTime,
          duration: booking.duration?.hours || 0
        }))
      }
    });
  } catch (error) {
    console.error('Get revenue error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/admin/dashboard
// @desc    Get admin dashboard data
// @access  Private (Admin only)
router.get('/dashboard', protect, requireAdmin, async (req, res) => {
  try {
    // Get overall statistics
    const totalUsers = await User.countDocuments({ role: 'user' });
    const totalParkings = await Parking.countDocuments();
    const totalBookings = await Booking.countDocuments();
    const activeBookings = await Booking.countDocuments({
      status: { $in: ['confirmed', 'active'] }
    });

    // Get recent activity
    const recentBookings = await Booking.find()
      .populate('user', 'firstName lastName')
      .populate('parking', 'name')
      .sort({ createdAt: -1 })
      .limit(5);

    // Get top parking spots by bookings
    const topParkings = await Booking.aggregate([
      {
        $match: { status: 'completed' }
      },
      {
        $group: {
          _id: '$parking',
          bookingCount: { $sum: 1 },
          totalRevenue: { $sum: '$pricing.total' }
        }
      },
      {
        $lookup: {
          from: 'parkings',
          localField: '_id',
          foreignField: '_id',
          as: 'parking'
        }
      },
      {
        $unwind: '$parking'
      },
      {
        $project: {
          name: '$parking.name',
          bookingCount: 1,
          totalRevenue: 1
        }
      },
      {
        $sort: { bookingCount: -1 }
      },
      {
        $limit: 5
      }
    ]);

    res.json({
      success: true,
      data: {
        statistics: {
          totalUsers,
          totalParkings,
          totalBookings,
          activeBookings
        },
        recentBookings: recentBookings.map(booking => ({
          id: booking._id,
          user: `${booking.user?.firstName} ${booking.user?.lastName}`,
          parking: booking.parking?.name,
          status: booking.status,
          createdAt: booking.createdAt
        })),
        topParkings
      }
    });
  } catch (error) {
    console.error('Get dashboard error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;