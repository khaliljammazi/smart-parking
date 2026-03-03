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

// ── Admin Vehicle Management ──
const Vehicle = require('../models/Vehicle');

// @route   GET /api/admin/vehicles
// @desc    List all vehicles across all users with search/filter
// @access  Private (Admin only)
router.get('/vehicles', protect, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, search, type, verified } = req.query;
    const query = {};

    if (search) {
      query.$or = [
        { licensePlate: { $regex: search, $options: 'i' } },
        { make: { $regex: search, $options: 'i' } },
        { model: { $regex: search, $options: 'i' } }
      ];
    }
    if (type) query.type = type;
    if (verified !== undefined) query.isVerified = verified === 'true';

    const vehicles = await Vehicle.find(query)
      .populate('owner', 'firstName lastName email')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Vehicle.countDocuments(query);

    // Counts by type
    const typeCounts = await Vehicle.aggregate([
      { $group: { _id: '$type', count: { $sum: 1 } } }
    ]);

    res.json({
      success: true,
      data: {
        vehicles,
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        typeCounts: typeCounts.reduce((acc, t) => { acc[t._id] = t.count; return acc; }, {})
      }
    });
  } catch (error) {
    console.error('Admin get vehicles error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   PUT /api/admin/vehicles/:id/verify
// @desc    Verify or reject a vehicle
// @access  Private (Admin only)
router.put('/vehicles/:id/verify', protect, requireAdmin, async (req, res) => {
  try {
    const { verified } = req.body; // true or false
    const vehicle = await Vehicle.findById(req.params.id).populate('owner', 'firstName lastName email');
    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    vehicle.isVerified = !!verified;

    let cancelledCount = 0;

    if (!verified) {
      // REJECT: disable vehicle + cancel all pending/confirmed bookings
      vehicle.isActive = false;

      // Find bookings tied to this vehicle that are pending or confirmed
      const bookingsToCancel = await Booking.find({
        vehicle: vehicle._id,
        status: { $in: ['pending', 'confirmed'] }
      });
      cancelledCount = bookingsToCancel.length;

      if (cancelledCount > 0) {
        const bookingIds = bookingsToCancel.map(b => b._id);

        // Cancel them all at once (bypass validators)
        await Booking.updateMany(
          { _id: { $in: bookingIds } },
          { $set: { status: 'cancelled', cancellationReason: 'vehicle_rejected', cancelledAt: new Date() } }
        );

        // Release parking spots
        const parkingUpdates = {};
        for (const b of bookingsToCancel) {
          const pid = b.parking.toString();
          parkingUpdates[pid] = (parkingUpdates[pid] || 0) + 1;
        }
        for (const [parkingId, count] of Object.entries(parkingUpdates)) {
          await Parking.findByIdAndUpdate(parkingId, { $inc: { availableSpots: count } });
        }
      }
    } else {
      // APPROVE: make sure vehicle is active
      vehicle.isActive = true;
    }

    await vehicle.save();

    res.json({
      success: true,
      data: vehicle,
      cancelledBookings: cancelledCount,
      message: verified
        ? 'Véhicule vérifié avec succès'
        : `Véhicule rejeté — ${cancelledCount} réservation(s) annulée(s)`
    });
  } catch (error) {
    console.error('Admin verify vehicle error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/admin/vehicles/stats
// @desc    Vehicle statistics for admin dashboard
// @access  Private (Admin only)
router.get('/vehicles/stats', protect, requireAdmin, async (req, res) => {
  try {
    const totalVehicles = await Vehicle.countDocuments();
    const verifiedVehicles = await Vehicle.countDocuments({ isVerified: true });
    const typeCounts = await Vehicle.aggregate([
      { $group: { _id: '$type', count: { $sum: 1 } } }
    ]);
    const fuelCounts = await Vehicle.aggregate([
      { $group: { _id: '$fuelType', count: { $sum: 1 } } }
    ]);

    // Top vehicles by bookings
    const topVehicles = await Booking.aggregate([
      { $match: { vehicle: { $ne: null } } },
      { $group: { _id: '$vehicle', totalBookings: { $sum: 1 }, totalSpent: { $sum: '$pricing.total' } } },
      { $lookup: { from: 'vehicles', localField: '_id', foreignField: '_id', as: 'vehicle' } },
      { $unwind: '$vehicle' },
      { $lookup: { from: 'users', localField: 'vehicle.owner', foreignField: '_id', as: 'owner' } },
      { $unwind: { path: '$owner', preserveNullAndEmptyArrays: true } },
      { $project: {
        licensePlate: '$vehicle.licensePlate',
        make: '$vehicle.make',
        model: '$vehicle.model',
        ownerName: { $concat: ['$owner.firstName', ' ', '$owner.lastName'] },
        totalBookings: 1,
        totalSpent: 1
      }},
      { $sort: { totalBookings: -1 } },
      { $limit: 10 }
    ]);

    // Vehicles with expiring insurance (next 30 days)
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
    const expiringInsurance = await Vehicle.find({
      insuranceExpiry: { $lte: thirtyDaysFromNow, $gte: new Date() }
    }).populate('owner', 'firstName lastName email').limit(20);

    res.json({
      success: true,
      data: {
        totalVehicles,
        verifiedVehicles,
        typeCounts: typeCounts.reduce((acc, t) => { acc[t._id] = t.count; return acc; }, {}),
        fuelCounts: fuelCounts.reduce((acc, t) => { acc[t._id] = t.count; return acc; }, {}),
        topVehicles,
        expiringInsurance
      }
    });
  } catch (error) {
    console.error('Admin vehicle stats error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Support tickets management for admins
const SupportTicket = require('../models/SupportTicket');

// @route   GET /api/admin/support/tickets
// @desc    List support tickets (admin)
// @access  Private (Admin only)
router.get('/support/tickets', protect, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const query = {};
    if (status) query.status = status;

    const tickets = await SupportTicket.find(query)
      .populate('user', 'firstName lastName email')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((page - 1) * parseInt(limit));

    const total = await SupportTicket.countDocuments(query);

    res.json({ success: true, data: { tickets, total, page: parseInt(page), limit: parseInt(limit) } });
  } catch (err) {
    console.error('Get support tickets error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/admin/support/tickets/:id
// @desc    Get support ticket details
// @access  Private (Admin only)
router.get('/support/tickets/:id', protect, requireAdmin, async (req, res) => {
  try {
    const ticket = await SupportTicket.findById(req.params.id).populate('user', 'firstName lastName email');
    if (!ticket) return res.status(404).json({ success: false, message: 'Ticket not found' });
    res.json({ success: true, data: ticket });
  } catch (err) {
    console.error('Get support ticket error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   PUT /api/admin/support/tickets/:id/status
// @desc    Update support ticket status
// @access  Private (Admin only)
router.put('/support/tickets/:id/status', protect, requireAdmin, async (req, res) => {
  try {
    const { status } = req.body;
    if (!['open', 'in_progress', 'resolved', 'closed'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const ticket = await SupportTicket.findById(req.params.id).populate('user', 'firstName lastName email');
    if (!ticket) return res.status(404).json({ success: false, message: 'Ticket not found' });

    const previousStatus = ticket.status;
    ticket.status = status;
    ticket.handledBy = req.user._id;
    await ticket.save();

    // Send resolution email when ticket is resolved or closed
    if ((status === 'resolved' || status === 'closed') && previousStatus !== status) {
      if (ticket.user && ticket.user.email) {
        const nodemailer = require('nodemailer');
        const transporter = nodemailer.createTransport({
          host: process.env.EMAIL_HOST || process.env.GMAIL_HOST || 'smtp.gmail.com',
          port: parseInt(process.env.EMAIL_PORT || '587', 10),
          secure: false,
          auth: {
            user: process.env.EMAIL_USER || process.env.GMAIL_USER,
            pass: process.env.EMAIL_PASS || process.env.GMAIL_PASS,
          },
        });
        const userName = `${ticket.user.firstName || ''} ${ticket.user.lastName || ''}`.trim();
        const statusLabel = status === 'resolved' ? 'Résolu' : 'Fermé';
        const statusColor = status === 'resolved' ? '#2e7d32' : '#616161';
        const statusIcon = status === 'resolved' ? '✅' : '📋';
        const html = `
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:'Segoe UI',Arial,sans-serif;">
  <div style="max-width:600px;margin:20px auto;">
    <!-- Header -->
    <div style="background:linear-gradient(135deg,#1a237e 0%,#283593 100%);border-radius:16px 16px 0 0;padding:32px 24px;text-align:center;">
      <div style="font-size:40px;margin-bottom:8px;">${statusIcon}</div>
      <h1 style="color:#fff;margin:0;font-size:22px;font-weight:600;">Réclamation ${statusLabel}</h1>
      <p style="color:rgba(255,255,255,0.8);margin:6px 0 0;font-size:14px;">Smart Parking — Service Support</p>
    </div>

    <!-- Body -->
    <div style="background:#fff;padding:28px 24px;border:1px solid #e3e8ee;border-top:none;">
      <p style="color:#333;font-size:16px;margin:0 0 20px;">Bonjour <strong>${userName}</strong>,</p>
      <p style="color:#555;font-size:15px;line-height:1.6;margin:0 0 20px;">
        Nous vous informons que votre réclamation a été traitée et marquée comme <strong style="color:${statusColor};">${statusLabel}</strong>.
      </p>

      <!-- Ticket details card -->
      <div style="background:#f8f9fb;border-radius:12px;padding:20px;margin:0 0 20px;border-left:4px solid #1a237e;">
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="color:#888;font-size:13px;padding:4px 0;width:120px;">Catégorie</td>
            <td style="color:#333;font-size:14px;font-weight:500;padding:4px 0;">${ticket.category}</td>
          </tr>
          <tr>
            <td style="color:#888;font-size:13px;padding:4px 0;">Référence</td>
            <td style="color:#333;font-size:14px;font-weight:500;padding:4px 0;">#${ticket._id.toString().slice(-8).toUpperCase()}</td>
          </tr>
          <tr>
            <td style="color:#888;font-size:13px;padding:4px 0;">Statut</td>
            <td style="padding:4px 0;"><span style="background:${statusColor};color:#fff;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:600;">${statusLabel}</span></td>
          </tr>
        </table>
      </div>

      <!-- Description -->
      <div style="background:#fafafa;border-radius:10px;padding:16px;margin:0 0 16px;">
        <div style="color:#888;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px;">Votre description</div>
        <div style="color:#444;font-size:14px;line-height:1.5;">${ticket.description}</div>
      </div>

      ${ticket.adminResponse ? `
      <!-- Admin Response -->
      <div style="background:#e8f5e9;border-radius:10px;padding:16px;margin:0 0 16px;border-left:4px solid #2e7d32;">
        <div style="color:#2e7d32;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px;">💬 Réponse de l'équipe</div>
        <div style="color:#2e7d32;font-size:14px;line-height:1.5;">${ticket.adminResponse}</div>
      </div>` : ''}

      <div style="background:#e3f2fd;border-radius:10px;padding:16px;margin:20px 0 0;text-align:center;">
        <p style="margin:0;color:#1565c0;font-size:14px;">Si le problème persiste, n'hésitez pas à ouvrir une nouvelle réclamation depuis l'application.</p>
      </div>
    </div>

    <!-- Footer -->
    <div style="background:#f8f9fb;border-radius:0 0 16px 16px;padding:20px 24px;text-align:center;border:1px solid #e3e8ee;border-top:none;">
      <p style="margin:0 0 4px;color:#999;font-size:12px;">© ${new Date().getFullYear()} Smart Parking — Tous droits réservés</p>
      <p style="margin:0;color:#bbb;font-size:11px;">Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
    </div>
  </div>
</body>
</html>`;

        try {
          await transporter.sendMail({
            from: process.env.EMAIL_USER || process.env.GMAIL_USER,
            to: ticket.user.email,
            subject: `${statusIcon} Smart Parking — Votre réclamation est ${statusLabel.toLowerCase()} (#${ticket._id.toString().slice(-8).toUpperCase()})`,
            html,
          });
        } catch (emailErr) {
          console.error('Resolution email error:', emailErr);
        }
      }
    }

    res.json({ success: true, message: 'Ticket updated', data: ticket });
  } catch (err) {
    console.error('Update ticket status error:', err);
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


// ═══════════════════════════════════════════════
//  ADMIN REPLY TO SUPPORT TICKET (email to user)
// ═══════════════════════════════════════════════

const nodemailer = require('nodemailer');
const adminTransporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || process.env.GMAIL_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.EMAIL_PORT || '587', 10),
  secure: false,
  auth: {
    user: process.env.EMAIL_USER || process.env.GMAIL_USER,
    pass: process.env.EMAIL_PASS || process.env.GMAIL_PASS,
  },
});

// @route   PUT /api/admin/support/tickets/:id/respond
// @desc    Admin responds to a support ticket and sends email to user
// @access  Private (Admin only)
router.put('/support/tickets/:id/respond', protect, requireAdmin, async (req, res) => {
  try {
    const { response, newStatus } = req.body;
    if (!response || response.trim().length < 3) {
      return res.status(400).json({ success: false, message: 'La réponse est requise (min 3 caractères)' });
    }

    const ticket = await SupportTicket.findById(req.params.id).populate('user', 'firstName lastName email');
    if (!ticket) return res.status(404).json({ success: false, message: 'Ticket non trouvé' });

    ticket.adminResponse = response;
    ticket.respondedAt = new Date();
    ticket.handledBy = req.user._id;
    ticket.status = newStatus || 'resolved';
    await ticket.save();

    // Send email to user
    if (ticket.user && ticket.user.email) {
      const userName = `${ticket.user.firstName || ''} ${ticket.user.lastName || ''}`.trim();
      const statusLabel = ticket.status === 'resolved' ? 'Résolu' : ticket.status === 'closed' ? 'Fermé' : ticket.status;
      const statusColor = ticket.status === 'resolved' ? '#2e7d32' : '#1565c0';
      const statusIcon = ticket.status === 'resolved' ? '✅' : '💬';
      const ticketRef = `#${ticket._id.toString().slice(-8).toUpperCase()}`;

      const html = `
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:'Segoe UI',Arial,sans-serif;">
  <div style="max-width:600px;margin:20px auto;">
    <!-- Header -->
    <div style="background:linear-gradient(135deg,#1a237e 0%,#283593 100%);border-radius:16px 16px 0 0;padding:32px 24px;text-align:center;">
      <div style="font-size:40px;margin-bottom:8px;">${statusIcon}</div>
      <h1 style="color:#fff;margin:0;font-size:22px;font-weight:600;">Réponse à votre réclamation</h1>
      <p style="color:rgba(255,255,255,0.8);margin:6px 0 0;font-size:14px;">Smart Parking — Service Support</p>
    </div>

    <!-- Body -->
    <div style="background:#fff;padding:28px 24px;border:1px solid #e3e8ee;border-top:none;">
      <p style="color:#333;font-size:16px;margin:0 0 20px;">Bonjour <strong>${userName}</strong>,</p>
      <p style="color:#555;font-size:15px;line-height:1.6;margin:0 0 20px;">
        Nous avons traité votre réclamation concernant <strong>${ticket.category}</strong> et souhaitons vous communiquer notre réponse.
      </p>

      <!-- Ticket Info Card -->
      <div style="background:#f8f9fb;border-radius:12px;padding:20px;margin:0 0 20px;border-left:4px solid #1a237e;">
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="color:#888;font-size:13px;padding:4px 0;width:120px;">Référence</td>
            <td style="color:#333;font-size:14px;font-weight:500;padding:4px 0;">${ticketRef}</td>
          </tr>
          <tr>
            <td style="color:#888;font-size:13px;padding:4px 0;">Catégorie</td>
            <td style="color:#333;font-size:14px;font-weight:500;padding:4px 0;">${ticket.category}</td>
          </tr>
          <tr>
            <td style="color:#888;font-size:13px;padding:4px 0;">Statut</td>
            <td style="padding:4px 0;"><span style="background:${statusColor};color:#fff;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:600;">${statusLabel}</span></td>
          </tr>
        </table>
      </div>

      <!-- User's original description -->
      <div style="background:#fafafa;border-radius:10px;padding:16px;margin:0 0 16px;">
        <div style="color:#888;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px;">📋 Votre description</div>
        <div style="color:#444;font-size:14px;line-height:1.5;">${ticket.description}</div>
      </div>

      <!-- Admin Response -->
      <div style="background:#e8f5e9;border-radius:10px;padding:16px;margin:0 0 16px;border-left:4px solid #2e7d32;">
        <div style="color:#2e7d32;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px;">💬 Réponse de l'équipe Smart Parking</div>
        <div style="color:#2e7d32;font-size:15px;line-height:1.6;font-weight:500;">${response}</div>
      </div>

      <!-- Call to action -->
      <div style="background:#e3f2fd;border-radius:10px;padding:16px;margin:20px 0 0;text-align:center;">
        <p style="margin:0;color:#1565c0;font-size:14px;">Si le problème persiste, n'hésitez pas à ouvrir une nouvelle réclamation depuis l'application.</p>
      </div>
    </div>

    <!-- Footer -->
    <div style="background:#f8f9fb;border-radius:0 0 16px 16px;padding:20px 24px;text-align:center;border:1px solid #e3e8ee;border-top:none;">
      <p style="margin:0 0 4px;color:#999;font-size:12px;">© ${new Date().getFullYear()} Smart Parking — Tous droits réservés</p>
      <p style="margin:0;color:#bbb;font-size:11px;">Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
    </div>
  </div>
</body>
</html>`;

      try {
        await adminTransporter.sendMail({
          from: process.env.EMAIL_USER || process.env.GMAIL_USER,
          to: ticket.user.email,
          subject: `${statusIcon} Smart Parking — Réponse à votre réclamation ${ticket.category} (${ticketRef})`,
          html,
        });
      } catch (emailErr) {
        console.error('Reply email error:', emailErr);
      }
    }

    res.json({ success: true, message: 'Réponse envoyée avec succès', data: ticket });
  } catch (error) {
    console.error('Admin respond ticket error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});


// ═══════════════════════════════════════════════
//  ADMIN: VIEW ALL BOOKINGS + DELETE BOOKING
// ═══════════════════════════════════════════════

// @route   GET /api/admin/bookings
// @desc    List all bookings (admin view) with filters
// @access  Private (Admin only)
router.get('/bookings', protect, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, status, search } = req.query;
    const query = {};

    if (status && status !== 'all') {
      query.status = status;
    }

    const bookings = await Booking.find(query)
      .populate('user', 'firstName lastName email')
      .populate('parking', 'name address')
      .populate('vehicle', 'make model licensePlate')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Booking.countDocuments(query);

    // Summary counts
    const [pending, confirmed, active, completed, cancelled] = await Promise.all([
      Booking.countDocuments({ status: 'pending' }),
      Booking.countDocuments({ status: 'confirmed' }),
      Booking.countDocuments({ status: 'active' }),
      Booking.countDocuments({ status: 'completed' }),
      Booking.countDocuments({ status: 'cancelled' }),
    ]);

    res.json({
      success: true,
      data: {
        bookings,
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        summary: { pending, confirmed, active, completed, cancelled }
      }
    });
  } catch (error) {
    console.error('Admin get bookings error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/admin/bookings/:id
// @desc    Delete a booking (admin)
// @access  Private (Admin only)
router.delete('/bookings/:id', protect, requireAdmin, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Réservation non trouvée' });
    }

    // If booking was active/confirmed, release the parking spot
    if (['confirmed', 'active'].includes(booking.status)) {
      await Parking.findByIdAndUpdate(booking.parking, {
        $inc: { availableSpots: 1 }
      });
    }

    await Booking.findByIdAndDelete(req.params.id);

    res.json({ success: true, message: 'Réservation supprimée' });
  } catch (error) {
    console.error('Admin delete booking error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});


// ═══════════════════════════════════════════════
//  REVIEW ANALYTICS DASHBOARD
// ═══════════════════════════════════════════════

const Rating = require('../models/Rating');

// @route   GET /api/admin/reviews/analytics
// @desc    Review analytics: sentiment trends, top-rated parkings, complaint patterns
// @access  Private (Admin only)
router.get('/reviews/analytics', protect, requireAdmin, async (req, res) => {
  try {
    // Overall stats
    const [totalReviews, avgRating] = await Promise.all([
      Rating.countDocuments(),
      Rating.aggregate([{ $group: { _id: null, avg: { $avg: '$rating' } } }]),
    ]);

    // Rating distribution (1-5 stars)
    const ratingDistribution = await Rating.aggregate([
      { $group: { _id: '$rating', count: { $sum: 1 } } },
      { $sort: { _id: 1 } }
    ]);

    // Top 10 highest-rated parkings (min 3 reviews)
    const topRatedParkings = await Rating.aggregate([
      { $group: { _id: '$parking', avg: { $avg: '$rating' }, count: { $sum: 1 } } },
      { $match: { count: { $gte: 3 } } },
      { $sort: { avg: -1 } },
      { $limit: 10 },
      { $lookup: { from: 'parkings', localField: '_id', foreignField: '_id', as: 'parking' } },
      { $unwind: '$parking' },
      { $project: { name: '$parking.name', address: '$parking.address', avg: 1, count: 1 } }
    ]);

    // Worst 10 parkings (min 2 reviews)
    const worstParkings = await Rating.aggregate([
      { $group: { _id: '$parking', avg: { $avg: '$rating' }, count: { $sum: 1 } } },
      { $match: { count: { $gte: 2 } } },
      { $sort: { avg: 1 } },
      { $limit: 10 },
      { $lookup: { from: 'parkings', localField: '_id', foreignField: '_id', as: 'parking' } },
      { $unwind: '$parking' },
      { $project: { name: '$parking.name', address: '$parking.address', avg: 1, count: 1 } }
    ]);

    // Monthly trend (last 12 months)
    const twelveMonthsAgo = new Date();
    twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 12);
    const monthlyTrend = await Rating.aggregate([
      { $match: { createdAt: { $gte: twelveMonthsAgo } } },
      { $group: {
        _id: { year: { $year: '$createdAt' }, month: { $month: '$createdAt' } },
        avgRating: { $avg: '$rating' },
        count: { $sum: 1 },
        lowCount: { $sum: { $cond: [{ $lte: ['$rating', 2] }, 1, 0] } },
        highCount: { $sum: { $cond: [{ $gte: ['$rating', 4] }, 1, 0] } }
      }},
      { $sort: { '_id.year': 1, '_id.month': 1 } }
    ]);

    // Most used tags (complaint patterns)
    const tagStats = await Rating.aggregate([
      { $unwind: '$tags' },
      { $group: { _id: '$tags', count: { $sum: 1 }, avgRating: { $avg: '$rating' } } },
      { $sort: { count: -1 } },
      { $limit: 20 }
    ]);

    // Recent negative reviews (rating <= 2)
    const recentComplaints = await Rating.find({ rating: { $lte: 2 } })
      .populate('user', 'firstName lastName')
      .populate('parking', 'name address')
      .sort({ createdAt: -1 })
      .limit(15)
      .select('rating review tags createdAt');

    // Reviews awaiting admin reply
    const unrepliedCount = await Rating.countDocuments({
      review: { $exists: true, $ne: '' },
      'adminReply.text': { $exists: false }
    });

    res.json({
      success: true,
      data: {
        overview: {
          totalReviews,
          averageRating: avgRating[0]?.avg ? Math.round(avgRating[0].avg * 100) / 100 : 0,
          unrepliedCount
        },
        ratingDistribution,
        topRatedParkings,
        worstParkings,
        monthlyTrend,
        tagStats,
        recentComplaints
      }
    });
  } catch (error) {
    console.error('Review analytics error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/admin/reviews
// @desc    Get all reviews (admin view) with pagination
// @access  Private (Admin only)
router.get('/reviews', protect, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, minRating, maxRating, hasReply } = req.query;
    const query = {};

    if (minRating) query.rating = { ...query.rating, $gte: parseInt(minRating) };
    if (maxRating) query.rating = { ...query.rating, $lte: parseInt(maxRating) };
    if (hasReply === 'true') query['adminReply.text'] = { $exists: true };
    if (hasReply === 'false') query['adminReply.text'] = { $exists: false };

    const reviews = await Rating.find(query)
      .populate('user', 'firstName lastName email')
      .populate('parking', 'name address')
      .populate('adminReply.repliedBy', 'firstName lastName')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Rating.countDocuments(query);

    res.json({
      success: true,
      data: { reviews, total, page: parseInt(page), limit: parseInt(limit) }
    });
  } catch (error) {
    console.error('Admin get reviews error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   PUT /api/admin/reviews/:id/reply
// @desc    Admin/owner public reply to a review
// @access  Private (Admin only)
router.put('/reviews/:id/reply', protect, requireAdmin, async (req, res) => {
  try {
    const { reply } = req.body;
    if (!reply || reply.trim().length < 2) {
      return res.status(400).json({ success: false, message: 'La réponse est requise' });
    }

    const rating = await Rating.findById(req.params.id);
    if (!rating) return res.status(404).json({ success: false, message: 'Avis non trouvé' });

    rating.adminReply = {
      text: reply,
      repliedBy: req.user._id,
      repliedAt: new Date()
    };
    await rating.save();

    const updated = await Rating.findById(req.params.id)
      .populate('adminReply.repliedBy', 'firstName lastName');

    res.json({ success: true, message: 'Réponse publiée', data: updated });
  } catch (error) {
    console.error('Admin reply to review error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/admin/reviews/:id
// @desc    Delete a review (moderation)
// @access  Private (Admin only)
router.delete('/reviews/:id', protect, requireAdmin, async (req, res) => {
  try {
    const rating = await Rating.findById(req.params.id);
    if (!rating) return res.status(404).json({ success: false, message: 'Avis non trouvé' });

    const parkingId = rating.parking;
    await Rating.findByIdAndDelete(req.params.id);

    // Recalculate parking average
    await Rating.updateParkingRating(parkingId);

    res.json({ success: true, message: 'Avis supprimé' });
  } catch (error) {
    console.error('Admin delete review error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;