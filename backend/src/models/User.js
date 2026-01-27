const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  // Basic Information
  firstName: {
    type: String,
    required: [true, 'First name is required'],
    trim: true,
    maxlength: [50, 'First name cannot exceed 50 characters']
  },
  lastName: {
    type: String,
    required: [true, 'Last name is required'],
    trim: true,
    maxlength: [50, 'Last name cannot exceed 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    validate: {
      validator: function(email) {
        return /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/.test(email);
      },
      message: 'Please enter a valid email'
    }
  },
  phone: {
    type: String,
    required: function() {
      return !this.googleId && !this.facebookId; // Phone required for email signup only
    },
    validate: {
      validator: function(phone) {
        return /^\+?[\d\s\-\(\)]+$/.test(phone);
      },
      message: 'Please enter a valid phone number'
    }
  },

  // Authentication
  password: {
    type: String,
    required: function() {
      return !this.googleId && !this.facebookId; // Password required for email signup
    },
    minlength: [6, 'Password must be at least 6 characters'],
    select: false // Don't include password in queries by default
  },

  // OAuth 2.0
  googleId: {
    type: String,
    sparse: true
  },
  facebookId: {
    type: String,
    sparse: true
  },
  githubId: {
    type: String,
    sparse: true
  },
  twitterId: {
    type: String,
    sparse: true
  },

  // Profile
  avatar: {
    type: String, // URL to avatar image
    default: null
  },
  dateOfBirth: {
    type: Date,
    validate: {
      validator: function(dob) {
        return dob <= new Date();
      },
      message: 'Date of birth cannot be in the future'
    }
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer_not_to_say'],
    default: 'prefer_not_to_say'
  },

  // Preferences
  language: {
    type: String,
    enum: ['fr', 'en', 'ar'],
    default: 'fr'
  },
  notifications: {
    email: { type: Boolean, default: true },
    push: { type: Boolean, default: true },
    sms: { type: Boolean, default: false }
  },
  preferredPaymentMethod: {
    type: String,
    enum: ['card', 'cash', 'wallet'],
    default: 'card'
  },

  // Vehicles (references to Vehicle model)
  vehicles: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle'
  }],

  // Account Status
  isActive: {
    type: Boolean,
    default: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  passwordResetToken: String,
  passwordResetExpires: Date,

  // Activity
  lastLogin: Date,
  loginCount: {
    type: Number,
    default: 0
  },

  // Location (for personalized parking suggestions)
  defaultLocation: {
    latitude: Number,
    longitude: Number,
    address: String
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
userSchema.index({ phone: 1 });

// Virtual for full name
userSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`;
});

// Pre-save middleware to hash password
userSchema.pre('save', async function(next) {
  // Only hash the password if it has been modified (or is new)
  if (!this.isModified('password') || !this.password) return next();

  try {
    // Hash password with cost of 12
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Instance method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
  if (!this.password) return false;
  return bcrypt.compare(candidatePassword, this.password);
};

// Instance method to generate auth token
userSchema.methods.generateAuthToken = function() {
  const jwt = require('jsonwebtoken');
  return jwt.sign(
    { userId: this._id, email: this.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

// Static method to find user by email or OAuth ID
userSchema.statics.findByEmailOrOAuth = function(email, googleId = null, facebookId = null) {
  const query = { $or: [{ email }] };
  if (googleId) query.$or.push({ googleId });
  if (facebookId) query.$or.push({ facebookId });
  return this.findOne(query);
};

module.exports = mongoose.model('User', userSchema);