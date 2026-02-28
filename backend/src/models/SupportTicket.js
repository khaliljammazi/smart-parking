const mongoose = require('mongoose');

const supportTicketSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  category: { type: String, default: 'Autre' },
  description: { type: String, required: true },
  status: { type: String, enum: ['open', 'in_progress', 'resolved', 'closed'], default: 'open' },
  handledBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  metadata: { type: mongoose.Schema.Types.Mixed },
}, { timestamps: true });

module.exports = mongoose.model('SupportTicket', supportTicketSchema);
