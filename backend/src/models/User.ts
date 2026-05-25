import { HydratedDocument, Model, Schema, model } from 'mongoose';

export type AuthType = 'email' | 'guest' | 'google';

export interface User {
  username: string;
  email?: string;
  passwordHash?: string;
  googleId?: string;
  authType: AuthType;
  createdAt: Date;
}

const userSchema = new Schema<User>(
  {
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      minlength: 3,
      maxlength: 24,
    },
    email: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
      lowercase: true,
    },
    passwordHash: {
      type: String,
    },
    googleId: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
    authType: {
      type: String,
      enum: ['email', 'guest', 'google'],
      required: true,
    },
  },
  {
    timestamps: {
      createdAt: true,
      updatedAt: false,
    },
  },
);

export type UserDocument = HydratedDocument<User>;
export type UserModel = Model<User>;

export const UserModel = model<User>('User', userSchema);
