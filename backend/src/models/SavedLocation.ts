import { HydratedDocument, Model, Schema, Types, model } from 'mongoose';

export type SavedLocationCategory =
  | 'Home'
  | 'College'
  | 'Work'
  | 'Hospital'
  | 'Custom';

export interface SavedLocation {
  userId: Types.ObjectId;
  name: string;
  category: SavedLocationCategory;
  latitude: number;
  longitude: number;
  createdAt: Date;
}

const savedLocationSchema = new Schema<SavedLocation>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 60,
    },
    category: {
      type: String,
      enum: ['Home', 'College', 'Work', 'Hospital', 'Custom'],
      required: true,
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
  },
  {
    timestamps: {
      createdAt: true,
      updatedAt: false,
    },
  },
);

savedLocationSchema.index({ userId: 1, name: 1, category: 1 });

export type SavedLocationDocument = HydratedDocument<SavedLocation>;
export type SavedLocationModel = Model<SavedLocation>;

export const SavedLocationModel = model<SavedLocation>(
  'SavedLocation',
  savedLocationSchema,
);
