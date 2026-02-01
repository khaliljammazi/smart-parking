const express = require('express');
const Booking = require('../models/Booking');
const User = require('../models/User');
const Parking = require('../models/Parking');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Middleware to check if user is admin or super_admin
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin' && req.user.role !== 'super_admin') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Admin role required.'
    });
  }
  next();
};

// Middleware to check if user is super_admin
const requireSuperAdmin = (req, res, next) => {
  if (req.user.role !== 'super_admin') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Super admin role required.'
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

// @route   GET /api/admin/users
// @desc    Get all users with pagination
// @access  Private (Admin only)
router.get('/users', protect, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 10, role, search } = req.query;
    const query = {};

    if (role) query.role = role;
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    const users = await User.find(query)
      .select('-password')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await User.countDocuments(query);

    res.json({
      success: true,
      data: {
        users,
        totalPages: Math.ceil(count / limit),
        currentPage: page,
        totalUsers: count
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/admin/users/:id
// @desc    Delete a user
// @access  Private (Admin only)
router.delete('/users/:id', protect, requireAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Prevent deleting super_admin or admin unless requester is super_admin
    if ((user.role === 'super_admin' || user.role === 'admin') && req.user.role !== 'super_admin') {
      return res.status(403).json({ success: false, message: 'Cannot delete admin users' });
    }

    await User.findByIdAndDelete(req.params.id);

    res.json({ success: true, message: 'User deleted successfully' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   PUT /api/admin/users/:id/role
// @desc    Update user role
// @access  Private (Super Admin only)
router.put('/users/:id/role', protect, requireSuperAdmin, async (req, res) => {
  try {
    const { role } = req.body;

    // Validate role
    const validRoles = ['user', 'parking_operator', 'admin', 'super_admin'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid role. Must be one of: user, parking_operator, admin, super_admin' 
      });
    }

    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Prevent changing super_admin role unless requester is super_admin
    if (user.role === 'super_admin' && req.user.role !== 'super_admin') {
      return res.status(403).json({ success: false, message: 'Cannot modify super admin role' });
    }

    // Update user role
    user.role = role;
    await user.save();

    res.json({ 
      success: true, 
      message: 'User role updated successfully',
      data: {
        user: {
          _id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          role: user.role
        }
      }
    });
  } catch (error) {
    console.error('Update user role error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   POST /api/admin/parkings
// @desc    Create a new parking spot
// @access  Private (Admin only)
router.post('/parkings', protect, requireAdmin, async (req, res) => {
  try {
    const parking = new Parking({
      ...req.body,
      owner: req.user._id
    });

    await parking.save();

    res.status(201).json({
      success: true,
      message: 'Parking created successfully',
      data: parking
    });
  } catch (error) {
    console.error('Create parking error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   PUT /api/admin/parkings/:id
// @desc    Update a parking spot
// @access  Private (Admin only)
router.put('/parkings/:id', protect, requireAdmin, async (req, res) => {
  try {
    const parking = await Parking.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!parking) {
      return res.status(404).json({ success: false, message: 'Parking not found' });
    }

    res.json({
      success: true,
      message: 'Parking updated successfully',
      data: parking
    });
  } catch (error) {
    console.error('Update parking error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/admin/parkings/:id
// @desc    Delete a parking spot
// @access  Private (Admin only)
router.delete('/parkings/:id', protect, requireAdmin, async (req, res) => {
  try {
    const parking = await Parking.findByIdAndDelete(req.params.id);

    if (!parking) {
      return res.status(404).json({ success: false, message: 'Parking not found' });
    }

    res.json({ success: true, message: 'Parking deleted successfully' });
  } catch (error) {
    console.error('Delete parking error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   POST /api/admin/admins
// @desc    Create a new admin user
// @access  Private (Super Admin only)
router.post('/admins', protect, requireSuperAdmin, async (req, res) => {
  try {
    const { firstName, lastName, email, phone, password, role } = req.body;

    // Validate role
    if (!['admin', 'parking_operator'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid role. Can only create admin or parking_operator users'
      });
    }

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email'
      });
    }

    const user = new User({
      firstName,
      lastName,
      email,
      phone,
      password,
      role,
      isVerified: true
    });

    await user.save();

    res.status(201).json({
      success: true,
      message: `${role === 'admin' ? 'Admin' : 'Parking Operator'} created successfully`,
      data: {
        id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Create admin error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/admin/admins
// @desc    Get all admin users
// @access  Private (Super Admin only)
router.get('/admins', protect, requireSuperAdmin, async (req, res) => {
  try {
    const admins = await User.find({
      role: { $in: ['admin', 'parking_operator', 'super_admin'] }
    }).select('-password').sort({ createdAt: -1 });

    res.json({
      success: true,
      data: admins
    });
  } catch (error) {
    console.error('Get admins error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/admin/admins/:id
// @desc    Delete an admin user
// @access  Private (Super Admin only)
router.delete('/admins/:id', protect, requireSuperAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Prevent deleting super_admin
    if (user.role === 'super_admin') {
      return res.status(403).json({ success: false, message: 'Cannot delete super admin' });
    }

    // Prevent deleting yourself
    if (user._id.toString() === req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Cannot delete yourself' });
    }

    await User.findByIdAndDelete(req.params.id);

    res.json({ success: true, message: 'Admin user deleted successfully' });
  } catch (error) {
    console.error('Delete admin error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;