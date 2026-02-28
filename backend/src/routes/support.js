const express = require('express');
const router = express.Router();
const passport = require('passport');
const nodemailer = require('nodemailer');
const { body, validationResult } = require('express-validator');

const auth = passport.authenticate('jwt', { session: false });

// Transporter using EMAIL_* env vars
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || process.env.GMAIL_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.EMAIL_PORT || '587', 10),
  secure: false,
  auth: {
    user: process.env.EMAIL_USER || process.env.GMAIL_USER,
    pass: process.env.EMAIL_PASS || process.env.GMAIL_PASS,
  },
});

// POST /api/support/report
router.post('/report', auth, [
  body('category').optional().isString(),
  body('description').isString().isLength({ min: 5 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { category = 'Autre', description } = req.body;
    const user = req.user;

    const toAddress = 'Balssem.Zoghbi@keyrus.com';
    const subject = `Signalement utilisateur — ${category}`;

    // Simple HTML escape to avoid accidental injection
    const escapeHtml = (str = '') => String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');

    const userName = escapeHtml(`${user.firstName || ''} ${user.lastName || ''}`.trim());
    const userEmail = escapeHtml(user.email || '');
    const userPhone = escapeHtml(user.phone || 'N/A');
    const safeCategory = escapeHtml(category);
    const safeDescription = escapeHtml(description).replace(/\n/g, '<br/>');
    const env = escapeHtml(process.env.NODE_ENV || 'unknown');
    const sentAt = new Date().toLocaleString('fr-FR');
    const clientUrl = process.env.CLIENT_URL || '';

    const html = `
      <div style="font-family: Arial, Helvetica, sans-serif; color: #222;">
        <div style="background:#1a237e;color:#fff;padding:16px;border-radius:8px 8px 0 0;">
          <h2 style="margin:0;font-size:18px">Smart Parking — Signalement utilisateur</h2>
          <div style="font-size:12px;opacity:0.9">${escapeHtml(sentAt)} • Environnement: ${env}</div>
        </div>
        <div style="padding:16px;background:#ffffff;border:1px solid #e9ecef;border-top:none;border-radius:0 0 8px 8px;">
          <p style="margin:0 0 12px;">Un nouvel incident a été signalé depuis l'application Smart Parking. Détails ci-dessous :</p>

          <table style="width:100%;border-collapse:collapse;margin-bottom:12px;font-size:14px;">
            <tr><td style="padding:6px 8px;font-weight:600;width:160px;color:#333">Utilisateur</td><td style="padding:6px 8px;color:#555">${userName} &lt;${userEmail}&gt;</td></tr>
            <tr><td style="padding:6px 8px;font-weight:600;color:#333">Téléphone</td><td style="padding:6px 8px;color:#555">${userPhone}</td></tr>
            <tr><td style="padding:6px 8px;font-weight:600;color:#333">Catégorie</td><td style="padding:6px 8px;color:#555">${safeCategory}</td></tr>
            <tr><td style="padding:6px 8px;font-weight:600;color:#333">Environnement</td><td style="padding:6px 8px;color:#555">${env}</td></tr>
          </table>

          <div style="margin-bottom:12px;">
            <div style="font-weight:600;margin-bottom:6px;color:#333">Description</div>
            <div style="padding:12px;background:#f8f9fa;border-radius:8px;color:#222;line-height:1.4">${safeDescription}</div>
          </div>

          ${clientUrl ? `<p style="font-size:13px;color:#333">Voir l'application: <a href="${escapeHtml(clientUrl)}">${escapeHtml(clientUrl)}</a></p>` : ''}

          <hr style="border:none;border-top:1px solid #eee;margin:16px 0"/>
          <div style="font-size:12px;color:#666">Message généré automatiquement — Smart Parking</div>
        </div>
      </div>
    `;

    const text = `Smart Parking - Signalement utilisateur\n\nUtilisateur: ${userName} <${userEmail}>\nTéléphone: ${userPhone}\nCatégorie: ${safeCategory}\nEnvironnement: ${env}\nDate: ${sentAt}\n\nDescription:\n${description}\n\n${clientUrl ? 'Application: ' + clientUrl + '\n' : ''}`;

    // Persist ticket in DB for admin management
    try {
      const SupportTicket = require('../models/SupportTicket');
      const ticket = new SupportTicket({
        user: user._id,
        category,
        description,
        metadata: { clientUrl }
      });
      await ticket.save();
    } catch (dbErr) {
      console.error('Support ticket save error:', dbErr);
    }

    await transporter.sendMail({
      from: process.env.EMAIL_USER || process.env.GMAIL_USER,
      to: toAddress,
      subject,
      text,
      html
    });

    return res.status(200).json({ success: true, message: 'Report sent' });
  } catch (err) {
    console.error('Support report error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
