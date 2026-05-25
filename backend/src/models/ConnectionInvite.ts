import { randomBytes } from 'crypto';
import { HydratedDocument, Model, Schema, Types, model } from 'mongoose';
import { RelationshipType } from './Connection';

export interface ConnectionInvite {
  inviterId: Types.ObjectId;
  acceptedBy?: Types.ObjectId;
  token: string;
  relationshipType: RelationshipType;
  status: 'pending' | 'accepted' | 'expired' | 'cancelled';
  expiresAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const connectionInviteSchema = new Schema<ConnectionInvite>(
  {
    inviterId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    acceptedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
    token: {
      type: String,
      required: true,
      unique: true,
      default: () => randomBytes(18).toString('hex'),
    },
    relationshipType: {
      type: String,
      enum: ['guardian', 'safeWalker'],
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'expired', 'cancelled'],
      default: 'pending',
      required: true,
    },
    expiresAt: {
      type: Date,
      required: true,
      index: true,
    },
  },
  {
    timestamps: true,
  },
);

export type ConnectionInviteDocument = HydratedDocument<ConnectionInvite>;
export type ConnectionInviteModel = Model<ConnectionInvite>;

export const ConnectionInviteModel = model<ConnectionInvite>(
  'ConnectionInvite',
  connectionInviteSchema,
);
