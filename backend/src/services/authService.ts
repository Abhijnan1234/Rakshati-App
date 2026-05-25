import bcrypt from 'bcrypt';
import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { UserDocument, UserModel } from '../models/User';
import { AppError } from '../utils/appError';

const googleClient = new OAuth2Client(env.GOOGLE_CLIENT_ID || undefined);

export const sanitizeUser = (user: UserDocument) => ({
  id: user.id,
  username: user.username,
  email: user.email ?? null,
  authType: user.authType,
  createdAt: user.createdAt,
});

export const signJwt = (user: UserDocument): string => {
  console.log('[Rakshati][Auth] JWT generation start userId=%s username=%s', user.id, user.username);
  const token = jwt.sign(
    {
      sub: user.id,
      authType: user.authType,
      username: user.username,
    },
    env.JWT_SECRET,
    {
      expiresIn: '7d',
    },
  );
  console.log('[Rakshati][Auth] JWT generated userId=%s', user.id);
  return token;
};

export const hashPassword = async (password: string): Promise<string> => {
  console.log('[Rakshati][Auth] bcrypt hash start');
  const result = await bcrypt.hash(password, 12);
  console.log('[Rakshati][Auth] bcrypt hash end');
  return result;
};

export const comparePassword = async (
  password: string,
  passwordHash: string,
): Promise<boolean> => {
  console.log('[Rakshati][Auth] bcrypt compare start');
  const result = await bcrypt.compare(password, passwordHash);
  console.log('[Rakshati][Auth] bcrypt compare end result=%s', result);
  return result;
};

export const ensureUniqueUsername = async (username: string): Promise<void> => {
  console.log('[Rakshati][Auth] Checking duplicate username=%s', username);
  const existingUser = await UserModel.exists({ username });
  console.log('[Rakshati][Auth] Duplicate username check complete exists=%s', Boolean(existingUser));
  if (existingUser) {
    throw new AppError('Username is already in use.', 409, 'USERNAME_TAKEN');
  }
};

export const ensureUniqueEmail = async (email: string): Promise<void> => {
  console.log('[Rakshati][Auth] Checking duplicate email=%s', email);
  const existingUser = await UserModel.exists({ email: email.toLowerCase() });
  console.log('[Rakshati][Auth] Duplicate email check complete exists=%s', Boolean(existingUser));
  if (existingUser) {
    throw new AppError('Email is already registered.', 409, 'EMAIL_TAKEN');
  }
};

export const buildUniqueGuestName = async (guestName: string): Promise<string> => {
  const normalizedBase = guestName.trim().replace(/\s+/g, '_');
  console.log('[Rakshati][Auth] Building guest name from %s', normalizedBase);

  for (let attempt = 0; attempt < 10; attempt += 1) {
    const candidate =
      attempt === 0
        ? normalizedBase
        : `${normalizedBase}_${Math.floor(100 + Math.random() * 900)}`;
    const exists = await UserModel.exists({ username: candidate });
    console.log('[Rakshati][Auth] Guest candidate=%s exists=%s', candidate, Boolean(exists));
    if (!exists) {
      return candidate;
    }
  }

  throw new AppError('Unable to generate a unique guest name.', 500, 'GUEST_NAME_UNAVAILABLE');
};

export const verifyGoogleIdentity = async ({
  idToken,
  email,
}: {
  idToken?: string;
  email: string;
}): Promise<void> => {
  if (!idToken) {
    console.warn('[Rakshati][Auth] No Google idToken supplied. Skipping backend token verification.');
    return;
  }

  if (!env.GOOGLE_CLIENT_ID) {
    console.warn('[Rakshati][Auth] GOOGLE_CLIENT_ID is not configured. Skipping Google token verification.');
    return;
  }

  console.log('[Rakshati][Auth] Google token verification start');
  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: env.GOOGLE_CLIENT_ID,
  });
  const payload = ticket.getPayload();

  if (!payload?.email) {
    throw new AppError('Unable to verify Google account email.', 401, 'INVALID_GOOGLE_TOKEN');
  }

  if (payload.email.toLowerCase() != email.toLowerCase()) {
    throw new AppError('Google account email mismatch.', 401, 'GOOGLE_EMAIL_MISMATCH');
  }

  console.log('[Rakshati][Auth] Google token verification end email=%s', payload.email);
};
