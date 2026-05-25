import mongoose from 'mongoose';
import { env } from './env';

export const connectDatabase = async (): Promise<void> => {
  try {
    console.log('[Rakshati][Startup] Connecting to MongoDB Atlas...');
    await mongoose.connect(env.MONGODB_URI, {
      autoIndex: env.NODE_ENV !== 'production',
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 10000,
    });
    console.log('[Rakshati][Startup] MongoDB connected');
  } catch (error) {
    console.error('[Rakshati][Startup] MongoDB connection failed:', error);
    throw error;
  }
};
