import MessageModel from '../model/Message.js';

export const sendMessage = async (req, res) => {
  const { id } = req.params; // chat id
  const { content, type, senderId, senderModel } = req.body;

  // Require senderId and senderModel in the body
  if (!senderId || !senderModel) {
    return res.status(400).json({ message: "Sender (Customer or Artist) information missing" });
  }

  let fileUrl = null;
  // Handle file upload if needed

  const message = await MessageModel.create({
    chat: id,
    senderId,
    senderModel,
    content: type === 'text' ? content : undefined,
    type,
    fileUrl
  });

  // Emit via socket.io if needed
  const io = req.app.get('io');
  if (io) {
    io.to(id).emit('newMessage', {
      ...message.toObject(),
      senderId,
      senderModel
    });
  }

  res.json({ message });
};