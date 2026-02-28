const admin = require('firebase-admin');

// Initialize Firebase Admin if credentials provided
function initFirebase() {
  if (admin.apps.length) return;

  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
      const serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp();
    } else {
      console.warn('Firebase service account not configured; push disabled');
    }
  } catch (err) {
    console.error('Error initializing Firebase Admin:', err);
  }
}

async function sendPushToTokens(tokens = [], payload = {}) {
  if (!tokens || tokens.length === 0) return { success: false, message: 'No tokens' };
  initFirebase();
  if (!admin.apps.length) return { success: false, message: 'Firebase not initialized' };

  try {
    const message = {
      tokens,
      notification: payload.notification || {},
      data: payload.data || {},
      android: payload.android || {},
      apns: payload.apns || {},
      webpush: payload.webpush || {}
    };

    const response = await admin.messaging().sendMulticast(message);
    return { success: true, response };
  } catch (err) {
    console.error('Push send error:', err);
    return { success: false, error: err.message };
  }
}

module.exports = { initFirebase, sendPushToTokens };
