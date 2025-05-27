const mongoose = require('mongoose');

const EmotionRecordSchema = new mongoose.Schema({
  emotions: {
    type: Map,
    of: String,
    required: true
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  userId: {
    type: String,
    default: 'anonymous' // In a real app, this would be linked to user authentication
  },
  audioFilePath: {
    type: String
  }
});

 