const express = require('express');
const router = express.Router();
const passport = require('passport');
const User = require('../models/User');

const auth = passport.authenticate('jwt', { session: false });

// Register device token
router.post('/register', auth, async (req, res) => {
  try {
    const { token, platform } = req.body;
    if (!token) return res.status(400).json({ success: false, message: 'Token required' });

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    // Prevent duplicates
    const exists = (user.deviceTokens || []).some(t => t.token === token);
    if (!exists) {
      user.deviceTokens = user.deviceTokens || [];
      user.deviceTokens.push({ token, platform: platform || 'unknown' });
      await user.save();
    }

    res.json({ success: true, message: 'Token registered' });
  } catch (err) {
    console.error('Register device token error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Unregister device token
router.post('/unregister', auth, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ success: false, message: 'Token required' });

    await User.updateOne({ _id: req.user._id }, { $pull: { deviceTokens: { token } } });
    res.json({ success: true, message: 'Token unregistered' });
  } catch (err) {
    console.error('Unregister device token error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
