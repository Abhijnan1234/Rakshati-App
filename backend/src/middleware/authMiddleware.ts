import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { UserModel } from '../models/User';
import { AppError } from '../utils/appError';

type JwtPayload = {
  sub: string;
};

export const authenticate = async (
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const authorizationHeader = req.headers.authorization;
    console.log('[Rakshati][AuthMiddleware] Authorization header present=%s', Boolean(authorizationHeader));

    if (!authorizationHeader?.startsWith('Bearer ')) {
      throw new AppError('Authentication token is missing.', 401, 'AUTH_REQUIRED');
    }

    const token = authorizationHeader.replace('Bearer ', '').trim();
    const decoded = jwt.verify(token, env.JWT_SECRET) as JwtPayload;
    console.log('[Rakshati][AuthMiddleware] JWT verified for userId=%s', decoded.sub);

    const user = await UserModel.findById(decoded.sub);
    if (!user) {
      throw new AppError('User account no longer exists.', 401, 'INVALID_TOKEN');
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('[Rakshati][AuthMiddleware] Authentication failed:', error);
    next(
      error instanceof AppError
        ? error
        : new AppError('Invalid or expired authentication token.', 401, 'INVALID_TOKEN'),
    );
  }
};
