import { HydratedDocument, Model, Schema, Types, model } from 'mongoose';

interface RoutePoint {
  latitude: number;
  longitude: number;
  timestamp: Date;
}

export interface SafeWalkSession {
  safeWalkerId: Types.ObjectId;
  destination: string;
  startedAt: Date;
  endedAt?: Date;
  status: 'Active' | 'Completed' | 'Cancelled' | 'SOS';
  routePoints: RoutePoint[];
}

const routePointSchema = new Schema<RoutePoint>(
  {
    latitude: Number,
    longitude: Number,
    timestamp: Date,
  },
  { _id: false },
);

const safeWalkSessionSchema = new Schema<SafeWalkSession>(
  {
    safeWalkerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    destination: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    startedAt: {
      type: Date,
      required: true,
      default: Date.now,
    },
    endedAt: Date,
    status: {
      type: String,
      enum: ['Active', 'Completed', 'Cancelled', 'SOS'],
      required: true,
      default: 'Active',
    },
    routePoints: {
      type: [routePointSchema],
      default: [],
    },
  },
  {
    timestamps: false,
  },
);

export type SafeWalkSessionDocument = HydratedDocument<SafeWalkSession>;
export type SafeWalkSessionModel = Model<SafeWalkSession>;

export const SafeWalkSessionModel = model<SafeWalkSession>(
  'SafeWalkSession',
  safeWalkSessionSchema,
);
