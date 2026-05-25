import { HydratedDocument, Model, Schema, Types, model } from 'mongoose';

export interface LocationHistory {
  userId: Types.ObjectId;
  latitude: number;
  longitude: number;
  timestamp: Date;
}

const locationHistorySchema = new Schema<LocationHistory>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    latitude: {
      type: Number,
      required: true,
      min: -90,
      max: 90,
    },
    longitude: {
      type: Number,
      required: true,
      min: -180,
      max: 180,
    },
    timestamp: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: false,
  },
);

locationHistorySchema.index({ userId: 1, timestamp: -1 });

export type LocationHistoryDocument = HydratedDocument<LocationHistory>;
export type LocationHistoryModel = Model<LocationHistory>;

export const LocationHistoryModel = model<LocationHistory>(
  'LocationHistory',
  locationHistorySchema,
);
