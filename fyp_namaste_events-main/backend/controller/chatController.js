import ChatModel from '../model/Chat.js';
import MessageModel from '../model/Message.js';
import mongoose from 'mongoose'; // <-- Add this line

// Create or get a 1-to-1 chat
export const createChat = async (req, res) => {
  const { participants } = req.body;
  // Ensure both a customer and an artist are present
  const hasCustomer = participants && participants.some(p => p.participantModel === "Customer");
  const hasArtist = participants && participants.some(p => p.participantModel === "Artist");

  if (!hasCustomer || !hasArtist) {
    return res.status(400).json({ message: "Both customer and artist must be participants" });
  }

  let chat;
  if (participants && participants.length === 2) {
    chat = await ChatModel.findOne({
      'participants.participantId': { $all: participants.map(p => p.participantId) },
      'participants.participantModel': { $all: participants.map(p => p.participantModel) }
    });
    if (!chat) {
      chat = await ChatModel.create({
        participants
      });
    }
  } else {
    return res.status(400).json({ message: "Invalid parameters" });
  }
  return res.json({ chat });
};


export const listChats = async (req, res) => {
  // Log the incoming request
  console.log('--- listChats called ---');
  console.log('req.query:', req.query);
  console.log('req.body:', req.body);

  // Extract parameters at the top
  const participantId = req.query.participantId || req.body.participantId;
  const participantModel = req.query.participantModel || req.body.participantModel;

  console.log('Extracted participantId:', participantId);
  console.log('Extracted participantModel:', participantModel);

  // Validate presence
  if (!participantId || !participantModel) {
    console.log('Validation failed: Missing participantId or participantModel');
    return res.status(400).json({ message: "participantId and participantModel are required" });
  }

  // Validate ObjectId
  if (!mongoose.Types.ObjectId.isValid(participantId)) {
    console.log('Validation failed: Invalid ObjectId');
    return res.status(400).json({ error: "Invalid Artist ID" });
  }

  try {
    let participantIdQuery = new mongoose.Types.ObjectId(participantId);

    // Query for chats
    const chats = await ChatModel.find({
      participants: {
        $elemMatch: { participantId: participantIdQuery, participantModel }
      }
    }).populate('participants.participantId');

    console.log('Chats found:', chats.length);
    res.json({ chats });
  } catch (err) {
    console.error('Error in listChats:', err);
    res.status(500).json({ error: err.message });
  }
};

export const getMessages = async (req, res) => {
  const { id } = req.params;
  const messages = await MessageModel.find({ chat: id }).populate('senderId');
  res.json({ messages });
};