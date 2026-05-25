import { NextFunction, Request, Response } from 'express';
import mongoose, { Error as MongooseError } from 'mongoose';
import { ZodError } from 'zod';
import { AppError } from '../utils/appError';

export const notFoundHandler = (req: Request, _res: Response, next: NextFunction): void => {
  console.error('[Rakshati][Error] Route not found %s %s', req.method, req.originalUrl);
  next(new AppError('Route not found.', 404, 'ROUTE_NOT_FOUND'));
};

export const errorHandler = (
  error: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  console.error('[Rakshati][Error] %s %s failed:', req.method, req.originalUrl, error);

  if (error instanceof ZodError) {
    res.status(400).json({
      message: 'Validation failed.',
      code: 'VALIDATION_ERROR',
      errors: error.issues.map((issue) => ({
        field: issue.path.join('.'),
        message: issue.message,
      })),
    });
    return;
  }

  if (error instanceof MongooseError.ValidationError) {
    res.status(400).json({
      message: 'Validation failed.',
      code: 'VALIDATION_ERROR',
      errors: Object.values(error.errors).map((item) => ({
        field: item.path,
        message: item.message,
      })),
    });
    return;
  }

  if (
    error instanceof mongoose.Error &&
    'code' in error &&
    (error as mongoose.Error & { code?: number }).code === 11000
  ) {
    const duplicateField = Object.keys(
      ((error as mongoose.Error & { keyPattern?: Record<string, number> }).keyPattern) ?? {},
    )[0];

    res.status(409).json({
      message: duplicateField
          ? `${duplicateField} is already in use.`
          : 'A unique field already exists.',
      code: 'DUPLICATE_VALUE',
    });
    return;
  }

  if (error instanceof AppError) {
    res.status(error.statusCode).json({
      message: error.message,
      code: error.code,
    });
    return;
  }

  res.status(500).json({
    message: 'Something went wrong.',
    code: 'INTERNAL_SERVER_ERROR',
  });
};
