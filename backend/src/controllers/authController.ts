import { Request, Response } from 'express';
import { z } from 'zod';
import { UserDocument, UserModel } from '../models/User';
import {
  buildUniqueGuestName,
  comparePassword,
  ensureUniqueEmail,
  ensureUniqueUsername,
  hashPassword,
  sanitizeUser,
  signJwt,
  verifyGoogleIdentity,
} from '../services/authService';
import { AppError } from '../utils/appError';

const usernameSchema = z
  .string()
  .trim()
  .min(3, 'Username must be at least 3 characters long.')
  .max(24, 'Username must be at most 24 characters long.')
  .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores.');

const signupSchema = z.object({
  username: usernameSchema,
  email: z.string().trim().email('Enter a valid email address.').transform((value) => value.toLowerCase()),
  password: z.string().min(6, 'Password must be at least 6 characters long.'),
});

const loginSchema = z.object({
  email: z.string().trim().email('Enter a valid email address.').transform((value) => value.toLowerCase()),
  password: z.string().min(1, 'Password is required.'),
});

const guestSchema = z.object({
  guestName: z.string().trim().min(3, 'Guest name must be at least 3 characters long.'),
});

const googleSchema = z.object({
  email: z.string().trim().email('Enter a valid email address.').transform((value) => value.toLowerCase()),
  googleId: z.string().trim().min(1, 'googleId is required.'),
  username: usernameSchema.optional(),
  idToken: z.string().trim().optional(),
});

const respondWithSession = (res: Response, statusCode: number, user: UserDocument | null) => {
  if (!user) {
    throw new AppError('User account could not be loaded.', 500, 'USER_NOT_FOUND');
  }

  console.log('[Rakshati][AuthController] Sending auth response status=%d userId=%s', statusCode, user.id);
  res.status(statusCode).json({
    token: signJwt(user),
    user: sanitizeUser(user),
  });
};

export const signup = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][AuthController] POST /auth/signup body=%o', {
    ...req.body,
    password: req.body?.password ? '***' : undefined,
  });

  try {
    const payload = signupSchema.parse(req.body);

    await Promise.all([
      ensureUniqueUsername(payload.username),
      ensureUniqueEmail(payload.email),
    ]);

    console.log('[Rakshati][AuthController] Creating email user');
    const user = await UserModel.create({
      username: payload.username,
      email: payload.email,
      passwordHash: await hashPassword(payload.password),
      authType: 'email',
    });

    console.log('[Rakshati][AuthController] Signup created userId=%s', user.id);
    respondWithSession(res, 201, user);
  } catch (error) {
    console.error('[Rakshati][AuthController] Signup failed:', error);
    throw error;
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][AuthController] POST /auth/login body=%o', {
    email: req.body?.email,
    password: req.body?.password ? '***' : undefined,
  });

  try {
    const payload = loginSchema.parse(req.body);

    console.log('[Rakshati][AuthController] Querying user by email');
    const user = await UserModel.findOne({ email: payload.email });
    console.log('[Rakshati][AuthController] User query complete found=%s', Boolean(user));
    if (!user || user.authType !== 'email' || !user.passwordHash) {
      throw new AppError('Invalid email or password.', 401, 'INVALID_CREDENTIALS');
    }

    const passwordMatches = await comparePassword(payload.password, user.passwordHash);
    if (!passwordMatches) {
      throw new AppError('Invalid email or password.', 401, 'INVALID_CREDENTIALS');
    }

    console.log('[Rakshati][AuthController] Login succeeded userId=%s', user.id);
    respondWithSession(res, 200, user);
  } catch (error) {
    console.error('[Rakshati][AuthController] Login failed:', error);
    throw error;
  }
};

export const guestAuth = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][AuthController] POST /auth/guest body=%o', req.body);

  try {
    const payload = guestSchema.parse(req.body);
    const username = await buildUniqueGuestName(payload.guestName);

    console.log('[Rakshati][AuthController] Creating guest user username=%s', username);
    const user = await UserModel.create({
      username,
      authType: 'guest',
    });

    console.log('[Rakshati][AuthController] Guest account created userId=%s username=%s', user.id, username);
    respondWithSession(res, 201, user);
  } catch (error) {
    console.error('[Rakshati][AuthController] Guest login failed:', error);
    throw error;
  }
};

export const googleAuth = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][AuthController] POST /auth/google body=%o', {
    email: req.body?.email,
    googleId: req.body?.googleId,
    username: req.body?.username,
    idToken: req.body?.idToken ? 'present' : 'missing',
  });

  try {
    const payload = googleSchema.parse(req.body);
    await verifyGoogleIdentity({
      idToken: payload.idToken,
      email: payload.email,
    });

    console.log('[Rakshati][AuthController] Looking up user by googleId');
    const existingGoogleUser = await UserModel.findOne({ googleId: payload.googleId });
    if (existingGoogleUser) {
      console.log('[Rakshati][AuthController] Existing Google user found userId=%s', existingGoogleUser.id);
      respondWithSession(res, 200, existingGoogleUser);
      return;
    }

    console.log('[Rakshati][AuthController] Looking up user by email');
    const existingEmailUser = await UserModel.findOne({ email: payload.email });
    if (existingEmailUser) {
      if (existingEmailUser.authType !== 'google') {
        throw new AppError(
          'This email is already registered with a different sign-in method.',
          409,
          'AUTH_TYPE_MISMATCH',
        );
      }

      existingEmailUser.googleId = payload.googleId;
      await existingEmailUser.save();
      console.log('[Rakshati][AuthController] Existing Google email user updated userId=%s', existingEmailUser.id);
      respondWithSession(res, 200, existingEmailUser);
      return;
    }

    if (!payload.username) {
      throw new AppError(
        'Choose a username to finish your first Google sign-in.',
        409,
        'USERNAME_REQUIRED',
      );
    }

    await ensureUniqueUsername(payload.username);
    console.log('[Rakshati][AuthController] Creating Google user username=%s', payload.username);
    const user = await UserModel.create({
      username: payload.username,
      email: payload.email,
      googleId: payload.googleId,
      authType: 'google',
    });

    console.log('[Rakshati][AuthController] Google account created userId=%s', user.id);
    respondWithSession(res, 201, user);
  } catch (error) {
    console.error('[Rakshati][AuthController] Google auth failed:', error);
    throw error;
  }
};

export const me = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][AuthController] GET /auth/me userId=%s', req.user.id);
  try {
    res.status(200).json({
      user: sanitizeUser(req.user),
    });
  } catch (error) {
    console.error('[Rakshati][AuthController] Fetch current user failed:', error);
    throw error;
  }
};
