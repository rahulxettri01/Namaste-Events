import mongoose from 'mongoose';

const MessageSchema = new mongoose.Schema({
  chat: { type: mongoose.Schema.Types.ObjectId, ref: 'Chat', required: true },
  senderId: { type: mongoose.Schema.Types.ObjectId, required: true }, // Can be Customer or Artist
  senderModel: { type: String, required: true, enum: ['Customer', 'Artist'] },
  content: { type: String },
  type: { type: String, default: 'text' }, // text, image, etc.
  fileUrl: { type: String },
  createdAt: { type: Date, default: Date.now },
  readBy: [{ type: mongoose.Schema.Types.ObjectId }] // Add this for read/unread tracking
});

const MessageModel = mongoose.model('Message', MessageSchema);
export default MessageModel;