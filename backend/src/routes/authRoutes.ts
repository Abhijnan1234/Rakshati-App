import { Router } from 'express';
import { googleAuth, guestAuth, login, me, signup } from '../controllers/authController';
import { authenticate } from '../middleware/authMiddleware';
import { asyncHandler } from '../utils/asyncHandler';

const authRouter = Router();

authRouter.post('/signup', asyncHandler(signup));
authRouter.post('/login', asyncHandler(login));
authRouter.post('/guest', asyncHandler(guestAuth));
authRouter.post('/google', asyncHandler(googleAuth));
authRouter.get('/me', authenticate, asyncHandler(me));

export { authRouter };
