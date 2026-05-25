import { connectDatabase } from './config/database';
import { env } from './config/env';
import { createApp } from './app';

const startServer = async (): Promise<void> => {
  console.log('[Rakshati][Startup] Booting backend...');
  await connectDatabase();

  const app = createApp();
  const host = '0.0.0.0';
  app.listen(env.PORT, host, () => {
    console.log('[Rakshati][Startup] Server running on http://%s:%d', host, env.PORT);
  });
};

startServer().catch((error) => {
  console.error('[Rakshati][Startup] Failed to start backend:', error);
  process.exit(1);
});
