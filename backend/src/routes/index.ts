import { Router } from 'express';
import { authRouter } from './authRoutes';
import { connectionsRouter } from './connectionsRoutes';
import { locationsRouter } from './locationsRoutes';

const router = Router();

router.get('/ping', (_req, res) => {
  res.status(200).json({
    success: true,
  });
});

router.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'rakshati-backend',
    timestamp: new Date().toISOString(),
  });
});

router.use('/auth', authRouter);
router.use('/locations', locationsRouter);
router.use('/connections', connectionsRouter);
console.log('[Rakshati][Startup] Auth routes loaded at /auth');
console.log('[Rakshati][Startup] Ping route loaded at /ping');
console.log('[Rakshati][Startup] Locations routes loaded at /locations');
console.log('[Rakshati][Startup] Connections routes loaded at /connections');

export { router };
