import { Router } from 'express';
import { deleteLocation, getLocations, saveLocation } from '../controllers/locationsController';
import { authenticate } from '../middleware/authMiddleware';
import { asyncHandler } from '../utils/asyncHandler';

export const locationsRouter = Router();

locationsRouter.use(authenticate);
locationsRouter.post('/save', asyncHandler(saveLocation));
locationsRouter.get('/', asyncHandler(getLocations));
locationsRouter.delete('/:id', asyncHandler(deleteLocation));
