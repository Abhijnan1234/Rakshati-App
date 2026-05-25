import cors from 'cors';
import express from 'express';
import morgan from 'morgan';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { router } from './routes';

export const createApp = () => {
  const app = express();

  app.use(
    cors({
      origin: '*',
      methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
    }),
  );
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(
    morgan('[Rakshati][HTTP] :method :url status=:status response-time=:response-time ms'),
  );

  app.use((req, _res, next) => {
    console.log('[Rakshati][HTTP] Incoming %s %s body=%o', req.method, req.originalUrl, {
      ...req.body,
      password: req.body?.password ? '***' : undefined,
    });
    next();
  });

  app.get('/', (_req, res) => {
    res.status(200).json({
      message: 'Rakshati API is running.',
    });
  });

  app.use(router);
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
