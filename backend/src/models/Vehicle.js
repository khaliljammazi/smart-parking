const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema({
  // Owner
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Vehicle must have an owner']
  },

  // Vehicle Information
  licensePlate: {
    type: String,
    required: [true, 'License plate is required'],
    uppercase: true,
    trim: true,
    unique: true,
    validate: {
      validator: function(plate) {
        // Tunisian license plate format validation
        return /^[0-9]{1,3}\s?[A-Z]{1,3}\s?[0-9]{1,4}$/.test(plate);
      },
      message: 'Please enter a valid Tunisian license plate format'
    }
  },

  make: {
    type: String,
    required: [true, 'Vehicle make is required'],
    trim: true,
    maxlength: [50, 'Make cannot exceed 50 characters']
  },

  model: {
    type: String,
    required: [true, 'Vehicle model is required'],
    trim: true,
    maxlength: [50, 'Model cannot exceed 50 characters']
  },

  year: {
    type: Number,
    required: [true, 'Vehicle year is required'],
    min: [1900, 'Year must be at least 1900'],
    max: [new Date().getFullYear() + 1, 'Year cannot be in the future']
  },

  color: {
    type: String,
    required: [true, 'Vehicle color is required'],
    trim: true,
    maxlength: [30, 'Color cannot exceed 30 characters']
  },

  // Vehicle Type
  type: {
    type: String,
    enum: ['car', 'motorcycle', 'truck', 'van', 'electric', 'hybrid'],
    default: 'car'
  },

  // Additional Details
  fuelType: {
    type: String,
    enum: ['petrol', 'diesel', 'electric', 'hybrid', 'gas'],
    default: 'petrol'
  },

  // Vehicle Status
  isActive: {
    type: Boolean,
    default: true
  },

  isVerified: {
    type: Boolean,
    default: false
  },

  // Insurance & Documents
  insuranceNumber: {
    type: String,
    trim: true
  },

  insuranceExpiry: {
    type: Date,
    validate: {
      validator: function(date) {
        return date > new Date();
      },
      message: 'Insurance must not be expired'
    }
  },

  // Photos
  photos: [{
    type: String, // URLs to vehicle photos
    validate: {
      validator: function(url) {
        return /^https?:\/\/.+/.test(url);
      },
      message: 'Photo must be a valid URL'
    }
  }],

  // Default vehicle flag
  isDefault: {
    type: Boolean,
    default: false
  },

  // Usage statistics
  totalBookings: {
    type: Number,
    default: 0
  },

  totalSpent: {
    type: Number,
    default: 0,
    min: 0
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
vehicleSchema.index({ owner: 1 });
vehicleSchema.index({ licensePlate: 1 }, { unique: true });
vehicleSchema.index({ isDefault: 1 });

// Virtual for full vehicle name
vehicleSchema.virtual('fullName').get(function() {
  return `${this.year} ${this.make} ${this.model}`;
});

// Virtual for formatted license plate
vehicleSchema.virtual('formattedPlate').get(function() {
  return this.licensePlate.toUpperCase();
});

// Pre-save middleware to ensure only one default vehicle per user
vehicleSchema.pre('save', async function(next) {
  if (this.isDefault && this.isModified('isDefault')) {
    // Remove default flag from other vehicles of this user
    await this.constructor.updateMany(
      { owner: this.owner, _id: { $ne: this._id } },
      { isDefault: false }
    );
  }
  next();
});

// Static method to find default vehicle for a user
vehicleSchema.statics.findDefaultForUser = function(userId) {
  return this.findOne({ owner: userId, isDefault: true, isActive: true });
};

// Instance method to mark as default
vehicleSchema.methods.makeDefault = function() {
  this.isDefault = true;
  return this.save();
};

module.exports = mongoose.model('Vehicle', vehicleSchema);