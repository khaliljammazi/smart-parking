const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  // References
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Booking must have a user']
  },

  parking: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Parking',
    required: [true, 'Booking must have a parking spot']
  },

  vehicle: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle',
    required: [true, 'Booking must have a vehicle']
  },

  // Booking Details
  bookingType: {
    type: String,
    enum: ['hourly', 'daily', 'monthly'],
    default: 'hourly'
  },

  startTime: {
    type: Date,
    required: [true, 'Start time is required'],
    validate: {
      validator: function(value) {
        return value > new Date();
      },
      message: 'Start time must be in the future'
    }
  },

  endTime: {
    type: Date,
    required: [true, 'End time is required'],
    validate: {
      validator: function(value) {
        return value > this.startTime;
      },
      message: 'End time must be after start time'
    }
  },

  duration: {
    hours: Number,
    days: Number,
    months: Number
  },

  // Pricing
  pricing: {
    rate: {
      type: Number,
      required: true,
      min: 0
    },
    subtotal: {
      type: Number,
      required: true,
      min: 0
    },
    tax: {
      type: Number,
      default: 0,
      min: 0
    },
    total: {
      type: Number,
      required: true,
      min: 0
    }
  },

  // Booking Status
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'active', 'completed', 'cancelled', 'no_show'],
    default: 'pending'
  },

  // Check-in/Check-out
  checkInTime: Date,
  checkOutTime: Date,

  // QR Code for this booking
  qrCode: {
    type: String,
    unique: true,
    sparse: true
  },

  qrCodeGenerated: {
    type: Date
  },

  qrCodeExpires: {
    type: Date
  },

  // Payment (happens at exit)
  payment: {
    status: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded'],
      default: 'pending'
    },
    method: {
      type: String,
      enum: ['card', 'cash', 'wallet'],
      default: 'card'
    },
    transactionId: String,
    paidAt: Date,
    amount: Number
  },

  // Additional Services
  services: [{
    name: String,
    price: Number,
    quantity: {
      type: Number,
      default: 1
    }
  }],

  // Notes
  specialRequests: {
    type: String,
    maxlength: [200, 'Special requests cannot exceed 200 characters']
  },

  // Cancellation
  cancelledAt: Date,
  cancellationReason: {
    type: String,
    enum: ['user_cancelled', 'no_show', 'system_cancelled', 'parking_unavailable']
  },

  // Ratings & Feedback (after completion)
  rating: {
    parking: {
      type: Number,
      min: 1,
      max: 5
    },
    service: {
      type: Number,
      min: 1,
      max: 5
    },
    overall: {
      type: Number,
      min: 1,
      max: 5
    }
  },

  feedback: {
    type: String,
    maxlength: [500, 'Feedback cannot exceed 500 characters']
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
bookingSchema.index({ user: 1, status: 1 });
bookingSchema.index({ parking: 1, startTime: 1, endTime: 1 });
bookingSchema.index({ qrCode: 1 }, { sparse: true });
bookingSchema.index({ startTime: 1, endTime: 1 });
bookingSchema.index({ status: 1, startTime: 1 });

// Virtual for booking duration in hours
bookingSchema.virtual('durationHours').get(function() {
  return Math.ceil((this.endTime - this.startTime) / (1000 * 60 * 60));
});

// Virtual for is active booking
bookingSchema.virtual('isActive').get(function() {
  const now = new Date();
  return this.status === 'active' ||
         (this.status === 'confirmed' && this.startTime <= now && this.endTime >= now);
});

// Pre-save middleware
bookingSchema.pre('save', async function(next) {
  // Calculate duration
  if (this.startTime && this.endTime) {
    const durationMs = this.endTime - this.startTime;
    this.duration = {
      hours: Math.ceil(durationMs / (1000 * 60 * 60)),
      days: Math.ceil(durationMs / (1000 * 60 * 60 * 24)),
      months: Math.ceil(durationMs / (1000 * 60 * 60 * 24 * 30))
    };
  }

  // Generate QR code if not exists
  if (!this.qrCode) {
    const crypto = require('crypto');
    this.qrCode = crypto.randomBytes(16).toString('hex');

    // Set QR code expiry (15 minutes after start time)
    const qrValidityMinutes = parseInt(process.env.QR_VALIDITY_MINUTES) || 15;
    this.qrCodeExpires = new Date(this.startTime.getTime() + (qrValidityMinutes * 60 * 1000));
    this.qrCodeGenerated = new Date();
  }

  next();
});

// Static methods
bookingSchema.statics.findActiveBookings = function() {
  const now = new Date();
  return this.find({
    status: { $in: ['confirmed', 'active'] },
    startTime: { $lte: now },
    endTime: { $gte: now }
  });
};

bookingSchema.statics.findByQRCode = function(qrCode) {
  return this.findOne({
    qrCode,
    qrCodeExpires: { $gt: new Date() },
    status: { $in: ['confirmed', 'active'] }
  }).populate('user parking vehicle');
};

bookingSchema.statics.findUserBookings = function(userId, status = null) {
  const query = { user: userId };
  if (status) query.status = status;
  return this.find(query)
    .populate('parking', 'name address coordinates pricing')
    .populate('vehicle', 'make model licensePlate')
    .sort({ createdAt: -1 });
};

// Instance methods
bookingSchema.methods.checkIn = function() {
  this.checkInTime = new Date();
  this.status = 'active';
  return this.save();
};

bookingSchema.methods.checkOut = function() {
  this.checkOutTime = new Date();
  this.status = 'completed';
  return this.save();
};

bookingSchema.methods.cancel = function(reason = 'user_cancelled') {
  this.cancelledAt = new Date();
  this.cancellationReason = reason;
  this.status = 'cancelled';
  return this.save();
};

bookingSchema.methods.addRating = function(rating) {
  this.rating = { ...this.rating, ...rating };
  return this.save();
};

module.exports = mongoose.model('Booking', bookingSchema);