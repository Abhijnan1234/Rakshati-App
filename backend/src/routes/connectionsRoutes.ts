import { Router } from 'express';
import {
  acceptInvite,
  createInvite,
  deleteConnection,
  getConnections,
} from '../controllers/connectionsController';
import { authenticate } from '../middleware/authMiddleware';
import { asyncHandler } from '../utils/asyncHandler';

export const connectionsRouter = Router();

connectionsRouter.use(authenticate);
connectionsRouter.post('/invite', asyncHandler(createInvite));
connectionsRouter.post('/accept', asyncHandler(acceptInvite));
connectionsRouter.get('/', asyncHandler(getConnections));
connectionsRouter.delete('/:id', asyncHandler(deleteConnection));
