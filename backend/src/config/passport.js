const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const FacebookStrategy = require('passport-facebook').Strategy;
const User = require('../models/User');

module.exports = (passport) => {
  // Serialize user for session
  passport.serializeUser((user, done) => {
    done(null, user.id);
  });

  // Deserialize user from session
  passport.deserializeUser(async (id, done) => {
    try {
      const user = await User.findById(id);
      done(null, user);
    } catch (error) {
      done(error, null);
    }
  });

  // Google OAuth Strategy
  passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: '/api/auth/google/callback'
  },
  async (accessToken, refreshToken, profile, done) => {
    try {
      // Check if user already exists with this Google ID
      let user = await User.findOne({ googleId: profile.id });

      if (user) {
        return done(null, user);
      }

      // Check if user exists with same email
      user = await User.findOne({ email: profile.emails[0].value });

      if (user) {
        // Link Google account to existing user
        user.googleId = profile.id;
        await user.save();
        return done(null, user);
      }

      // Create new user
      const newUser = new User({
        firstName: profile.name.givenName,
        lastName: profile.name.familyName,
        email: profile.emails[0].value,
        googleId: profile.id,
        avatar: profile.photos[0].value,
        isVerified: true, // Google accounts are pre-verified
        lastLogin: new Date(),
        loginCount: 1
      });

      await newUser.save();
      done(null, newUser);
    } catch (error) {
      done(error, null);
    }
  }));

  // Facebook OAuth Strategy
  passport.use(new FacebookStrategy({
    clientID: process.env.FACEBOOK_APP_ID,
    clientSecret: process.env.FACEBOOK_APP_SECRET,
    callbackURL: '/api/auth/facebook/callback',
    profileFields: ['id', 'emails', 'name', 'picture']
  },
  async (accessToken, refreshToken, profile, done) => {
    try {
      // Check if user already exists with this Facebook ID
      let user = await User.findOne({ facebookId: profile.id });

      if (user) {
        return done(null, user);
      }

      // Check if user exists with same email
      if (profile.emails && profile.emails[0]) {
        user = await User.findOne({ email: profile.emails[0].value });

        if (user) {
          // Link Facebook account to existing user
          user.facebookId = profile.id;
          await user.save();
          return done(null, user);
        }
      }

      // Create new user
      const newUser = new User({
        firstName: profile.name.givenName || profile.displayName.split(' ')[0],
        lastName: profile.name.familyName || profile.displayName.split(' ').slice(1).join(' '),
        email: profile.emails ? profile.emails[0].value : null,
        facebookId: profile.id,
        avatar: profile.photos ? profile.photos[0].value : null,
        isVerified: true, // Facebook accounts are pre-verified
        lastLogin: new Date(),
        loginCount: 1
      });

      await newUser.save();
      done(null, newUser);
    } catch (error) {
      done(error, null);
    }
  }));
};