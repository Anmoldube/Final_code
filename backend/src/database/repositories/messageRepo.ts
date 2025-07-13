import { Aggregate, Mongoose, PipelineStage, Types } from "mongoose";
import Chat, { ChatModel } from "../model/Chat";
import {
  NotFoundError,
  AuthFailureError,
  BadRequestError,
  InternalError,
} from "../../core/ApiError";
// import { getLocalFilePath, getStaticFilePath } from "helpers/utils";
// import { emitSocketEvent } from "socket";
// import { ProtectedRequest } from "types/app-request";
// import { ChatEventEnum } from "../../constants/index";
import Message, { MessageModel, MessageStatus } from "../model/Message";
import { createValidatedTimestamp, logTimeInfo } from "../../helpers/timeUtils";

const chatMessageCommonAggregator = (): PipelineStage[] => {
  return [
    {
      $lookup: {
        from: "users",
        foreignField: "_id",
        localField: "sender",
        as: "sender",
        pipeline: [
          {
            $project: {
              username: 1,
              avatarUrl: 1,
              email: 1,
            },
          },
        ],
      },
    },
    {
      $lookup: {
        from: "users",
        foreignField: "_id",
        localField: "readBy",
        as: "readByUsers",
        pipeline: [
          {
            $project: {
              username: 1,
              avatarUrl: 1,
              email: 1,
            },
          },
        ],
      },
    },
    {
      $addFields: {
        sender: { $first: "$sender" },
        isRead: { $gt: [{ $size: "$readBy" }, 0] },
        readCount: { $size: "$readBy" },
      },
    },
  ];
};

// find message by Id
const getMessageById = (id: Types.ObjectId): Promise<Message | null> => {
  return MessageModel.findById(id);
};

// get all messages of a particular Id
const getMessagesOfChatId = (
  chatId: Types.ObjectId
): Promise<Array<Message>> => {
  return MessageModel.find({ chatId });
};

const deleteMessageById = (id: Types.ObjectId): Promise<Message | null> => {
  return MessageModel.findByIdAndDelete(id);
};

const deleteAllMessagesOfChatId = (chatId: Types.ObjectId): Promise<any> => {
  return MessageModel.deleteMany({ chat: chatId });
};

// get all messages aggregated
const getAllMessagesAggregated = (chatId: Types.ObjectId): Aggregate<any> => {
  return MessageModel.aggregate([
    {
      $match: {
        chat: chatId,
      },
    },
    {
      $sort: {
        createdAt: 1,
      },
    },
    ...chatMessageCommonAggregator(),
  ]);
};

const getLastMessage = (chatId: Types.ObjectId): Promise<any> => {
  return MessageModel.findOne({ chat: chatId }).sort({ createdAt: -1 }).exec();
};

// create a new message
const createMessage = (
  userId: Types.ObjectId,
  chatId: Types.ObjectId,
  content: string,
  attachemntFiles: { url: string; localPath: string }[]
): Promise<any> => {
  // Log time info for debugging
  logTimeInfo('createMessage');
  
  const timestamp = createValidatedTimestamp();
  
  const messageData: any = {
    sender: userId,
    content: content,
    chat: chatId,
    attachments: attachemntFiles,
    status: MessageStatus.PENDING, // Start with pending status
    readBy: [],
    deliveredTo: [],
    retryCount: 0,
    createdAt: timestamp,
    updatedAt: timestamp,
  };


  
  return MessageModel.create(messageData);
};

// structure the messages
const getStructuredMessages = (messageId: Types.ObjectId) => {
  return MessageModel.aggregate([
    {
      $match: {
        _id: messageId,
      },
    },
    ...chatMessageCommonAggregator(),
  ]);
};

// Mark a message as read by a user
const markMessageAsRead = (messageId: Types.ObjectId, userId: Types.ObjectId): Promise<Message | null> => {
  return MessageModel.findByIdAndUpdate(
    messageId,
    {
      $addToSet: { readBy: userId },
      $set: { 
        readAt: new Date(),
        updatedAt: new Date()
      }
    },
    { new: true }
  );
};

// Mark a message as delivered to a user
const markMessageAsDelivered = (messageId: Types.ObjectId, userId: Types.ObjectId): Promise<Message | null> => {
  return MessageModel.findByIdAndUpdate(
    messageId,
    {
      $addToSet: { deliveredTo: userId },
      $set: { 
        deliveredAt: new Date(),
        updatedAt: new Date()
      }
    },
    { new: true }
  );
};

// Update message status
const updateMessageStatus = (
  messageId: Types.ObjectId, 
  status: MessageStatus,
  additionalData?: any
): Promise<Message | null> => {
  const updateData: any = {
    status,
    updatedAt: new Date(),
    ...additionalData
  };

  // Set specific timestamps based on status
  switch (status) {
    case MessageStatus.SENT:
      updateData.sentAt = new Date();
      break;
    case MessageStatus.DELIVERED:
      updateData.deliveredAt = updateData.deliveredAt || new Date();
      break;
    case MessageStatus.READ:
      updateData.readAt = updateData.readAt || new Date();
      break;
    case MessageStatus.FAILED:
      updateData.retryCount = (additionalData?.retryCount || 0) + 1;
      break;
  }

  return MessageModel.findByIdAndUpdate(
    messageId,
    { $set: updateData },
    { new: true }
  );
};

// Get messages by status
const getMessagesByStatus = (chatId: Types.ObjectId, status: MessageStatus): Promise<Message[]> => {
  return MessageModel.find({ chat: chatId, status }).sort({ createdAt: -1 });
};

// Get failed messages for retry
const getFailedMessages = (userId: Types.ObjectId): Promise<Message[]> => {
  return MessageModel.find({ 
    sender: userId, 
    status: MessageStatus.FAILED 
  }).sort({ createdAt: -1 });
};

// Increment retry count
const incrementRetryCount = (messageId: Types.ObjectId): Promise<Message | null> => {
  return MessageModel.findByIdAndUpdate(
    messageId,
    { 
      $inc: { retryCount: 1 },
      $set: { updatedAt: new Date() }
    },
    { new: true }
  );
};

// Mark all messages in a chat as read by a user
const markAllMessagesAsRead = (chatId: Types.ObjectId, userId: Types.ObjectId): Promise<any> => {
  return MessageModel.updateMany(
    { 
      chat: chatId,
      sender: { $ne: userId },
      readBy: { $ne: userId }
    },
    {
      $addToSet: { readBy: userId }
    }
  );
};

// Get unread messages count for a user in a specific chat
const getUnreadMessagesCount = async (chatId: Types.ObjectId, userId: Types.ObjectId): Promise<number> => {
  const count = await MessageModel.countDocuments({
    chat: chatId,
    sender: { $ne: userId },  // Only count messages where sender is not the current user
    readBy: { $ne: userId }   // And the current user hasn't read them
  });
  return count;
};

// Get all unread messages for a user across all chats
const getAllUnreadMessages = (userId: Types.ObjectId): Aggregate<any> => {
  return MessageModel.aggregate([
    {
      $match: {
        sender: { $ne: userId },  // Only count messages where sender is not the current user
        readBy: { $ne: userId }   // And the current user hasn't read them
      }
    },
    {
      $lookup: {
        from: "chats",
        localField: "chat",
        foreignField: "_id",
        as: "chatInfo"
      }
    },
    {
      $match: {
        "chatInfo.participants": userId
      }
    },
    ...chatMessageCommonAggregator(),
    {
      $group: {
        _id: "$chat",
        unreadCount: { $sum: 1 },
        lastMessage: { $last: "$$ROOT" }
      }
    }
  ]);
};

export default {
  getAllMessagesAggregated,
  createMessage,
  getStructuredMessages,
  getMessageById,
  getMessagesOfChatId,
  deleteMessageById,
  deleteAllMessagesOfChatId,
  getLastMessage,
  markMessageAsRead,
  markMessageAsDelivered,
  updateMessageStatus,
  getMessagesByStatus,
  getFailedMessages,
  incrementRetryCount,
  markAllMessagesAsRead,
  getUnreadMessagesCount,
  getAllUnreadMessages,
};
