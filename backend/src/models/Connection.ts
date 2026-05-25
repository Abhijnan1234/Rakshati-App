import { HydratedDocument, Model, Schema, Types, model } from 'mongoose';

export type RelationshipType = 'guardian' | 'safeWalker';

export interface Connection {
  ownerId: Types.ObjectId;
  peerId: Types.ObjectId;
  pairKey: string;
  relationshipType: RelationshipType;
  status: 'active';
  createdAt: Date;
  updatedAt: Date;
}

const connectionSchema = new Schema<Connection>(
  {
    ownerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    peerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    pairKey: {
      type: String,
      required: true,
      index: true,
    },
    relationshipType: {
      type: String,
      enum: ['guardian', 'safeWalker'],
      required: true,
    },
    status: {
      type: String,
      enum: ['active'],
      default: 'active',
      required: true,
    },
  },
  {
    timestamps: true,
  },
);

connectionSchema.index(
  {
    ownerId: 1,
    peerId: 1,
    relationshipType: 1,
  },
  { unique: true },
);

export type ConnectionDocument = HydratedDocument<Connection>;
export type ConnectionModel = Model<Connection>;

export const ConnectionModel = model<Connection>('Connection', connectionSchema);
