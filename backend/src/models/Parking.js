const mongoose = require('mongoose');

const parkingSchema = new mongoose.Schema({
  // Basic Information
  name: {
    type: String,
    required: [true, 'Parking name is required'],
    trim: true,
    maxlength: [100, 'Name cannot exceed 100 characters']
  },

  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot exceed 500 characters']
  },

  // Location
  address: {
    street: { type: String, required: true },
    city: { type: String, required: true, default: 'Tunis' },
    postalCode: { type: String },
    country: { type: String, default: 'Tunisia' }
  },

  coordinates: {
    latitude: {
      type: Number,
      required: [true, 'Latitude is required'],
      min: -90,
      max: 90
    },
    longitude: {
      type: Number,
      required: [true, 'Longitude is required'],
      min: -180,
      max: 180
    }
  },

  // Capacity & Availability
  totalSpots: {
    type: Number,
    required: [true, 'Total spots is required'],
    min: [1, 'Must have at least 1 spot']
  },

  availableSpots: {
    type: Number,
    default: function() {
      return this.totalSpots;
    },
    min: 0,
    validate: {
      validator: function(value) {
        return value <= this.totalSpots;
      },
      message: 'Available spots cannot exceed total spots'
    }
  },

  // Pricing
  pricing: {
    hourly: {
      type: Number,
      required: [true, 'Hourly rate is required'],
      min: [0, 'Price cannot be negative']
    },
    daily: {
      type: Number,
      min: [0, 'Price cannot be negative']
    },
    monthly: {
      type: Number,
      min: [0, 'Price cannot be negative']
    }
  },

  // Features & Amenities
  features: [{
    type: String,
    enum: [
      'covered', 'security', 'cctv', 'lighting', 'ev_charging',
      'car_wash', 'valet', 'disabled_access', '24_7', 'payment_terminal'
    ]
  }],

  // Operating Hours
  operatingHours: {
    monday: { open: String, close: String },
    tuesday: { open: String, close: String },
    wednesday: { open: String, close: String },
    thursday: { open: String, close: String },
    friday: { open: String, close: String },
    saturday: { open: String, close: String },
    sunday: { open: String, close: String }
  },

  // Contact Information
  contact: {
    phone: String,
    email: String,
    website: String
  },

  // Images
  images: [{
    type: String, // URLs to parking images
    validate: {
      validator: function(url) {
        return /^https?:\/\/.+/.test(url);
      },
      message: 'Image must be a valid URL'
    }
  }],

  // Owner/Manager
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Parking must have an owner']
  },

  // Status
  isActive: {
    type: Boolean,
    default: true
  },

  isVerified: {
    type: Boolean,
    default: false
  },

  // Ratings & Reviews
  rating: {
    average: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    count: {
      type: Number,
      default: 0,
      min: 0
    }
  },

  // Statistics
  totalBookings: {
    type: Number,
    default: 0
  },

  totalRevenue: {
    type: Number,
    default: 0,
    min: 0
  },

  // QR Code for entry
  qrCode: {
    type: String,
    unique: true,
    sparse: true
  },

  qrCodeGenerated: {
    type: Date
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
parkingSchema.index({ 'coordinates': '2dsphere' });
parkingSchema.index({ 'address.city': 1 });
parkingSchema.index({ isActive: 1 });
parkingSchema.index({ owner: 1 });

// Virtual for full address
parkingSchema.virtual('fullAddress').get(function() {
  return `${this.address.street}, ${this.address.city}, ${this.address.country}`;
});

// Virtual for availability percentage
parkingSchema.virtual('availabilityPercentage').get(function() {
  return this.totalSpots > 0 ? (this.availableSpots / this.totalSpots) * 100 : 0;
});

// Virtual for price per hour in DT
parkingSchema.virtual('pricePerHour').get(function() {
  return this.pricing.hourly;
});

// Pre-save middleware to generate QR code
parkingSchema.pre('save', async function(next) {
  if (this.isNew && !this.qrCode) {
    // Generate unique QR code
    const crypto = require('crypto');
    this.qrCode = crypto.randomBytes(16).toString('hex');
    this.qrCodeGenerated = new Date();
  }
  next();
});

// Static method to find nearby parking
parkingSchema.statics.findNearby = function(longitude, latitude, maxDistance = 5000) {
  return this.find({
    'coordinates': {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [longitude, latitude]
        },
        $maxDistance: maxDistance // in meters
      }
    },
    isActive: true
  });
};

// Instance method to update availability
parkingSchema.methods.updateAvailability = function(change) {
  this.availableSpots = Math.max(0, Math.min(this.totalSpots, this.availableSpots + change));
  return this.save();
};

// Instance method to check if spot is available
parkingSchema.methods.isSpotAvailable = function() {
  return this.availableSpots > 0 && this.isActive;
};

module.exports = mongoose.model('Parking', parkingSchema);