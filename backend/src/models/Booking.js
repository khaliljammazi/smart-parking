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
    ref: 'Vehicle'
    // Made optional for immediate reservations
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
        // Skip validation if booking is being checked in (has checkInTime), checked out (has checkOutTime),
        // or is already active/completed
        if (this.checkInTime || this.checkOutTime || this.status === 'active' || this.status === 'completed') {
          return true;
        }
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

  // Admin validation
  adminValidated: {
    type: Boolean,
    default: false
  },

  adminValidatedAt: {
    type: Date
  },

  adminValidatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
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

bookingSchema.methods.checkOut = async function() {
  this.checkOutTime = new Date();
  this.status = 'completed';

  // Calculate final pricing
  await this.calculatePricing();

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

// Calculate pricing based on actual usage time
bookingSchema.methods.calculatePricing = async function() {
  const parking = await mongoose.model('Parking').findById(this.parking);
  if (!parking) return;

  const checkOutTime = this.checkOutTime || new Date();
  const actualStartTime = this.checkInTime || this.startTime;
  let hoursUsed = Math.ceil((checkOutTime - actualStartTime) / (1000 * 60 * 60));

  // Minimum 1 hour, add 2 extra hours if still parked
  if (this.status === 'active' && !this.checkOutTime) {
    hoursUsed += 2; // Add 2 extra hours for cars still parked
  }

  hoursUsed = Math.max(1, hoursUsed); // Minimum 1 hour

  const hourlyRate = parking.pricing.hourly || 1; // Default 1 DT per hour
  const subtotal = hoursUsed * hourlyRate;
  const tax = subtotal * 0.19; // 19% tax
  const total = subtotal + tax;

  this.pricing = {
    rate: hourlyRate,
    subtotal: Math.round(subtotal * 100) / 100,
    tax: Math.round(tax * 100) / 100,
    total: Math.round(total * 100) / 100
  };

  this.duration = { hours: hoursUsed };

  return this.save();
};

// Add pagination plugin
bookingSchema.plugin(require('mongoose-paginate-v2'));

module.exports = mongoose.model('Booking', bookingSchema);