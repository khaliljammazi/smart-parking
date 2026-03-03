const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema({
  parking: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Parking',
    required: [true, 'Parking is required']
  },

  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User is required']
  },

  rating: {
    type: Number,
    required: [true, 'Rating is required'],
    min: [1, 'Rating must be at least 1'],
    max: [5, 'Rating cannot exceed 5']
  },

  review: {
    type: String,
    trim: true,
    maxlength: [500, 'Review cannot exceed 500 characters']
  },

  tags: [{
    type: String,
    trim: true
  }],

  // Owner/Admin public reply
  adminReply: {
    text: { type: String, trim: true, maxlength: 500 },
    repliedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    repliedAt: { type: Date }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// One rating per user per parking
ratingSchema.index({ parking: 1, user: 1 }, { unique: true });
ratingSchema.index({ parking: 1, createdAt: -1 });

// After saving a rating, update the parking's average rating
ratingSchema.post('save', async function () {
  await this.constructor.updateParkingRating(this.parking);
});

ratingSchema.post('findOneAndDelete', async function (doc) {
  if (doc) {
    await doc.constructor.updateParkingRating(doc.parking);
  }
});

// Static method to recalculate parking average rating
ratingSchema.statics.updateParkingRating = async function (parkingId) {
  const Parking = mongoose.model('Parking');

  const result = await this.aggregate([
    { $match: { parking: parkingId } },
    {
      $group: {
        _id: '$parking',
        average: { $avg: '$rating' },
        count: { $sum: 1 }
      }
    }
  ]);

  if (result.length > 0) {
    await Parking.findByIdAndUpdate(parkingId, {
      'rating.average': Math.round(result[0].average * 10) / 10,
      'rating.count': result[0].count
    });
  } else {
    await Parking.findByIdAndUpdate(parkingId, {
      'rating.average': 0,
      'rating.count': 0
    });
  }
};

module.exports = mongoose.model('Rating', ratingSchema);
