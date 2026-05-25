import { Request, Response } from 'express';
import { z } from 'zod';
import {
  SavedLocationCategory,
  SavedLocationDocument,
  SavedLocationModel,
} from '../models/SavedLocation';
import { AppError } from '../utils/appError';

const categoryValues = [
  'Home',
  'College',
  'Work',
  'Hospital',
  'Custom',
] as const satisfies readonly SavedLocationCategory[];

const saveLocationSchema = z.object({
  name: z.string().trim().min(2, 'Location name must be at least 2 characters long.').max(60),
  category: z.enum(categoryValues),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
});

const serializeLocation = (location: SavedLocationDocument) => ({
  id: location.id,
  userId: location.userId.toString(),
  name: location.name,
  category: location.category,
  latitude: location.latitude,
  longitude: location.longitude,
  createdAt: location.createdAt,
});

export const saveLocation = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][Locations] POST /locations/save userId=%s body=%o', req.user.id, req.body);
  try {
    const payload = saveLocationSchema.parse(req.body);
    const location = await SavedLocationModel.create({
      userId: req.user._id,
      ...payload,
    });

    console.log('[Rakshati][Locations] Saved location id=%s', location.id);
    res.status(201).json({
      location: serializeLocation(location),
    });
  } catch (error) {
    console.error('[Rakshati][Locations] Save failed:', error);
    throw error;
  }
};

export const getLocations = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][Locations] GET /locations userId=%s', req.user.id);
  try {
    const locations = await SavedLocationModel.find({
      userId: req.user._id,
    }).sort({ createdAt: -1 });

    res.status(200).json({
      locations: locations.map(serializeLocation),
    });
  } catch (error) {
    console.error('[Rakshati][Locations] Fetch failed:', error);
    throw error;
  }
};

export const deleteLocation = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][Locations] DELETE /locations/%s userId=%s', req.params.id, req.user.id);
  try {
    const location = await SavedLocationModel.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!location) {
      throw new AppError('Saved location not found.', 404, 'LOCATION_NOT_FOUND');
    }

    res.status(200).json({
      success: true,
    });
  } catch (error) {
    console.error('[Rakshati][Locations] Delete failed:', error);
    throw error;
  }
};
