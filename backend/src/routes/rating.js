const express = require('express');
const Rating = require('../models/Rating');
const Parking = require('../models/Parking');
const { protect } = require('../middleware/auth');

const router = express.Router();

// @route   POST /api/ratings
// @desc    Submit or update a rating for a parking
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { parkingId, rating, review, tags } = req.body;

    if (!parkingId || !rating) {
      return res.status(400).json({
        success: false,
        message: 'parkingId and rating are required'
      });
    }

    if (rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    // Check parking exists
    const parking = await Parking.findById(parkingId);
    if (!parking) {
      return res.status(404).json({
        success: false,
        message: 'Parking not found'
      });
    }

    // Upsert: update if user already rated this parking, create otherwise
    const existingRating = await Rating.findOne({
      parking: parkingId,
      user: req.user._id
    });

    let savedRating;
    if (existingRating) {
      existingRating.rating = rating;
      existingRating.review = review || existingRating.review;
      existingRating.tags = tags || existingRating.tags;
      savedRating = await existingRating.save();
    } else {
      savedRating = await Rating.create({
        parking: parkingId,
        user: req.user._id,
        rating,
        review: review || undefined,
        tags: tags || undefined
      });
    }

    // Fetch updated parking rating to return it
    const updatedParking = await Parking.findById(parkingId).select('rating');

    res.status(201).json({
      success: true,
      message: existingRating ? 'Rating updated successfully' : 'Rating submitted successfully',
      data: { 
        rating: savedRating,
        parkingRating: updatedParking?.rating
      }
    });
  } catch (error) {
    console.error('Submit rating error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/ratings/my-ratings
// @desc    Get current user's ratings
// @access  Private
router.get('/my-ratings', protect, async (req, res) => {
  try {
    const ratings = await Rating.find({ user: req.user._id })
      .populate('parking', 'name address images')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: { ratings }
    });
  } catch (error) {
    console.error('Get my ratings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/ratings/:parkingId
// @desc    Get ratings for a parking
// @access  Public
router.get('/:parkingId', async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    const total = await Rating.countDocuments({ parking: req.params.parkingId });

    const ratings = await Rating.find({ parking: req.params.parkingId })
      .populate('user', 'firstName lastName avatar')
      .populate('adminReply.repliedBy', 'firstName lastName')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    // Get rating distribution
    const distribution = await Rating.aggregate([
      { $match: { parking: require('mongoose').Types.ObjectId.createFromHexString(req.params.parkingId) } },
      { $group: { _id: '$rating', count: { $sum: 1 } } },
      { $sort: { _id: -1 } }
    ]);

    res.json({
      success: true,
      data: {
        ratings,
        distribution,
        pagination: {
          page: pageNum,
          pages: Math.ceil(total / limitNum),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get ratings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/ratings/:id
// @desc    Delete a rating
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    const rating = await Rating.findOne({
      _id: req.params.id,
      user: req.user._id
    });

    if (!rating) {
      return res.status(404).json({
        success: false,
        message: 'Rating not found'
      });
    }

    await Rating.findOneAndDelete({ _id: req.params.id });

    res.json({
      success: true,
      message: 'Rating deleted successfully'
    });
  } catch (error) {
    console.error('Delete rating error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
