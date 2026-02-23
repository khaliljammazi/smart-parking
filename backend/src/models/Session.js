const mongoose = require('mongoose');
const crypto = require('crypto');

const sessionSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            index: true,
        },
        sessionId: {
            type: String,
            required: true,
            unique: true,
            default: () => crypto.randomBytes(32).toString('hex'),
        },
        isActive: {
            type: Boolean,
            default: true,
        },
        createdAt: {
            type: Date,
            default: Date.now,
        },
        expiresAt: {
            type: Date,
            required: true,
            // MongoDB TTL index: auto-delete document after expiry
            index: { expireAfterSeconds: 0 },
        },
        // Optional: record device/platform info for future multi-device management
        userAgent: {
            type: String,
            default: null,
        },
        ipAddress: {
            type: String,
            default: null,
        },
    },
    { timestamps: false }
);

// Composite index for fast lookup during token validation
sessionSchema.index({ sessionId: 1, isActive: 1 });

module.exports = mongoose.model('Session', sessionSchema);
