const express = require('express');
const passport = require('passport');
const { body, validationResult } = require('express-validator');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const User = require('../models/User');
const Session = require('../models/Session');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Helper: create a DB session and return the sessionId
async function createSession(userId, req) {
  const expiresMs = parseInt(process.env.SESSION_EXPIRE_DAYS || '30') * 24 * 60 * 60 * 1000;
  const session = await Session.create({
    userId,
    expiresAt: new Date(Date.now() + expiresMs),
    userAgent: req.headers['user-agent'] || null,
    ipAddress: req.ip || null,
  });
  return session.sessionId;
}

// In-memory OTP store (for demo; use Redis or DB in production)
const otpStore = new Map(); // key: email, value: { otp: string, expires: Date }

// Configure nodemailer with Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASS,
  },
});

// Helper to generate OTP
function generateOTP() {
  return crypto.randomInt(100000, 999999).toString();
}

// Build a professional OTP email template
function buildOtpEmail(name, otp, title, description, expiresMinutes) {
  return `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <style>
      body { font-family: 'Segoe UI', Tahoma, Geneva, sans-serif; background: #f4f6f9; margin: 0; padding: 0; }
      .container { max-width: 520px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
      .header { background: linear-gradient(135deg, #1a237e, #283593); padding: 30px; text-align: center; }
      .header h1 { color: #ffffff; margin: 0; font-size: 22px; }
      .header p { color: #b3c0ff; margin: 8px 0 0; font-size: 13px; }
      .body { padding: 30px; text-align: center; }
      .title { font-size: 20px; font-weight: bold; color: #1a237e; margin-bottom: 8px; }
      .desc { font-size: 14px; color: #666; margin-bottom: 24px; }
      .otp-box { display: inline-block; padding: 18px 36px; background: linear-gradient(135deg, #e8eaf6, #f3f4ff); border: 2px dashed #1a237e; border-radius: 12px; margin: 16px 0; }
      .otp-code { font-family: 'Courier New', monospace; font-size: 36px; letter-spacing: 10px; color: #1a237e; font-weight: bold; }
      .expires { font-size: 13px; color: #f57c00; margin-top: 16px; }
      .warning { background: #fff3e0; border-radius: 8px; padding: 12px; margin-top: 20px; font-size: 12px; color: #e65100; }
      .footer { text-align: center; padding: 20px; color: #999; font-size: 11px; border-top: 1px solid #eee; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <div style="font-size:40px; margin-bottom:8px;">🅿️</div>
        <h1>Smart Parking</h1>
        <p>Stationnement intelligent en Tunisie</p>
      </div>
      <div class="body">
        <p style="color:#333; font-size:15px;">Bonjour <strong>${name}</strong>,</p>
        <p class="title">${title}</p>
        <p class="desc">${description}</p>
        <div class="otp-box">
          <div class="otp-code">${otp}</div>
        </div>
        <p class="expires">⏰ Ce code expire dans <strong>${expiresMinutes} minutes</strong></p>
        <div class="warning">
          🔒 Ne partagez jamais ce code avec personne. L'équipe Smart Parking ne vous demandera jamais votre code.
        </div>
      </div>
      <div class="footer">
        <p>© ${new Date().getFullYear()} Smart Parking — Tous droits réservés</p>
        <p>Si vous n'avez pas effectué cette demande, ignorez cet email.</p>
      </div>
    </div>
  </body>
  </html>`;
}

// Validation rules
const registerValidation = [
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters'),
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('phone')
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please provide a valid phone number'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long')
];

const loginValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty()
];

// @route   POST /api/auth/register
// @desc    Register user
// @access  Public
router.post('/register', registerValidation, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { firstName, lastName, email, phone, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findByEmailOrOAuth(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email'
      });
    }

    // Create user
    const user = new User({
      firstName,
      lastName,
      email,
      phone,
      password
    });

    await user.save();

    // Generate OTP for email verification
    const emailOtp = generateOTP();
    user.emailVerificationToken = crypto.createHash('sha256').update(emailOtp).digest('hex');
    user.emailVerificationExpires = Date.now() + 10 * 60 * 1000; // 10 minutes

    await user.save();

    // Generate token with session
    const sessionId = await createSession(user._id, req);
    const token = user.generateAuthToken(sessionId);

    // Update login info
    user.lastLogin = new Date();
    user.loginCount += 1;
    await user.save();

    // Send verification email
    try {
      if (process.env.GMAIL_USER && process.env.GMAIL_PASS) {
        await transporter.sendMail({
          from: process.env.GMAIL_USER,
          to: user.email,
          subject: '🔐 Vérifiez votre email — Smart Parking',
          html: buildOtpEmail(user.firstName || 'Utilisateur', emailOtp, 'Vérification de votre email', 'Utilisez ce code pour vérifier votre adresse email et accéder à Smart Parking.', 10)
        });
      }
    } catch (emailError) {
      console.error('Email sending failed:', emailError);
    }

    res.status(201).json({
      success: true,
      message: 'User registered successfully. Please check your email for verification code.',
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone,
          avatar: user.avatar,
          isVerified: user.isVerified
        },
        token
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration'
    });
  }
});

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', loginValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { email, password } = req.body;

    // Check if user exists and get password
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Generate token with session
    const sessionId = await createSession(user._id, req);
    const token = user.generateAuthToken(sessionId);

    // Update login info
    user.lastLogin = new Date();
    user.loginCount += 1;
    await user.save();

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone,
          avatar: user.avatar,
          isVerified: user.isVerified
        },
        token
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  }
});

// @route   POST /api/auth/add-phone-and-send-otp
// @desc    Add phone and send OTP for Google users
// @access  Public
router.post('/add-phone-and-send-otp', async (req, res) => {
  const { userId, phone } = req.body;
  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    user.phone = phone;
    await user.save();

    // Generate and store OTP
    const otp = generateOTP();
    const expires = new Date(Date.now() + 5 * 60 * 1000);
    otpStore.set(user.email, { otp, expires });

    // Send OTP to email
    await transporter.sendMail({
      from: process.env.GMAIL_USER,
      to: user.email,
      subject: '📱 Vérification de votre numéro — Smart Parking',
      html: buildOtpEmail(user.firstName || 'Utilisateur', otp, 'Vérification de votre numéro de téléphone', 'Utilisez ce code pour confirmer votre numéro de téléphone.', 5)
    });

    res.json({ success: true, message: 'OTP sent to your email' });
  } catch (error) {
    console.error('Add phone and send OTP error:', error);
    res.status(500).json({ success: false, message: 'Error adding phone or sending OTP' });
  }
});

// @route   POST /api/auth/verify-phone-otp
// @desc    Verify phone OTP
// @access  Public
router.post('/verify-phone-otp', async (req, res) => {
  const { userId, otp } = req.body;
  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const stored = otpStore.get(user.email);
    if (!stored || stored.otp !== otp || new Date() > stored.expires) {
      return res.status(401).json({ success: false, message: 'Invalid or expired OTP' });
    }

    otpStore.delete(user.email);
    res.json({ success: true, message: 'Phone verified successfully' });
  } catch (error) {
    console.error('Verify phone OTP error:', error);
    res.status(500).json({ success: false, message: 'OTP verification failed' });
  }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('vehicles');

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone,
          avatar: user.avatar,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          language: user.language,
          notifications: user.notifications,
          preferredPaymentMethod: user.preferredPaymentMethod,
          vehicles: user.vehicles,
          isVerified: user.isVerified,
          role: user.role,
          lastLogin: user.lastLogin,
          loginCount: user.loginCount
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Google OAuth routes
router.get('/google',
  passport.authenticate('google', { scope: ['profile', 'email'], session: false })
);

router.get('/google/callback',
  passport.authenticate('google', { failureRedirect: '/login', session: false }),
  async (req, res) => {
    try {
      const sessionId = await createSession(req.user._id, req);
      const token = req.user.generateAuthToken(sessionId);

      // Update login info
      req.user.lastLogin = new Date();
      req.user.loginCount += 1;
      await req.user.save();

      // Redirect to frontend with token
      const redirectUrl = `${process.env.CLIENT_URL}/auth/callback?token=${token}&provider=google`;
      res.redirect(redirectUrl);
    } catch (error) {
      console.error('Google OAuth callback error:', error);
      res.redirect(`${process.env.CLIENT_URL}/login?error=oauth_failed`);
    }
  }
);

// @route   POST /api/auth/logout
// @desc    Logout user — invalidates the DB session
// @access  Private
router.post('/logout', protect, async (req, res) => {
  try {
    // Extract sessionId from the JWT (if present) and deactivate the session
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const jwt = require('jsonwebtoken');
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (decoded.sessionId) {
          await Session.findOneAndUpdate(
            { sessionId: decoded.sessionId },
            { isActive: false }
          );
        }
      } catch (_) { /* ignore decode errors on logout */ }
    }
    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ success: false, message: 'Server error during logout' });
  }
});

// @route   POST /api/auth/send-verify-email
// @desc    Send verification email
// @access  Private
router.post('/send-verify-email', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (user.isVerified) {
      return res.status(400).json({ success: false, message: 'Email already verified' });
    }

    const otp = generateOTP();
    user.emailVerificationToken = crypto.createHash('sha256').update(otp).digest('hex');
    user.emailVerificationExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
    await user.save();

    if (process.env.GMAIL_USER && process.env.GMAIL_PASS) {
      await transporter.sendMail({
        from: process.env.GMAIL_USER,
        to: user.email,
        subject: '🔐 Vérifiez votre email — Smart Parking',
        html: buildOtpEmail(user.firstName || 'Utilisateur', otp, 'Vérification de votre email', 'Utilisez ce code pour vérifier votre adresse email.', 10)
      });
    }

    res.json({ success: true, message: 'Verification email sent' });
  } catch (error) {
    console.error('Send verify email error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   POST /api/auth/verify-email
// @desc    Verify email with OTP
// @access  Public
router.post('/verify-email', [
  body('email').isEmail().normalizeEmail(),
  body('otp').notEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  const { email, otp } = req.body;

  try {
    // Hash the OTP to compare with stored hash
    const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');

    const user = await User.findOne({
      email,
      emailVerificationToken: hashedOtp,
      emailVerificationExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    user.isVerified = true;
    user.emailVerificationToken = undefined;
    user.emailVerificationExpires = undefined;
    await user.save();

    const sessionId = await createSession(user._id, req);
    const token = user.generateAuthToken(sessionId);

    res.json({
      success: true,
      message: 'Email verified successfully',
      data: { token, user: { id: user._id, email: user.email, isVerified: true } }
    });
  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   POST /api/auth/forgot-password
// @desc    Forgot password (send OTP)
// @access  Public
router.post('/forgot-password', [
  body('email').isEmail().normalizeEmail()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const user = await User.findOne({ email: req.body.email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const otp = generateOTP();
    user.passwordResetToken = crypto.createHash('sha256').update(otp).digest('hex');
    user.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
    await user.save();

    if (process.env.GMAIL_USER && process.env.GMAIL_PASS) {
      await transporter.sendMail({
        from: process.env.GMAIL_USER,
        to: user.email,
        subject: '🔑 Réinitialisation du mot de passe — Smart Parking',
        html: buildOtpEmail(user.firstName || 'Utilisateur', otp, 'Réinitialisation du mot de passe', 'Vous avez demandé la réinitialisation de votre mot de passe. Utilisez ce code pour continuer.', 10)
      });
    }

    res.json({ success: true, message: 'Password reset code sent to email' });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   POST /api/auth/reset-password
// @desc    Reset password
// @access  Public
router.post('/reset-password', [
  body('email').isEmail().normalizeEmail(),
  body('otp').notEmpty(),
  body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  const { email, otp, newPassword } = req.body;

  try {
    const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');

    const user = await User.findOne({
      email,
      passwordResetToken: hashedOtp,
      passwordResetExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    user.password = newPassword;
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await user.save();

    res.json({ success: true, message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;