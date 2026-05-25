CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'session_status') THEN
    CREATE TYPE session_status AS ENUM ('active', 'escalated', 'completed', 'cancelled', 'expired');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'session_severity') THEN
    CREATE TYPE session_severity AS ENUM ('normal', 'warning', 'critical');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'deviation_state') THEN
    CREATE TYPE deviation_state AS ENUM ('none', 'minor', 'major');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'eta_state') THEN
    CREATE TYPE eta_state AS ENUM ('on_time', 'grace', 'exceeded');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'safety_sentiment') THEN
    CREATE TYPE safety_sentiment AS ENUM ('safe', 'neutral', 'unsafe');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'incident_category') THEN
    CREATE TYPE incident_category AS ENUM (
      'harassment',
      'stalking',
      'poor_lighting',
      'suspicious_activity',
      'road_hazard',
      'medical',
      'other'
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20) UNIQUE,
  "passwordHash" VARCHAR(255) NOT NULL,
  "fullName" VARCHAR(120) NOT NULL,
  "isPhoneVerified" BOOLEAN NOT NULL DEFAULT FALSE,
  "fcmTokens" TEXT[] NOT NULL DEFAULT '{}',
  "lastKnownLocation" geometry(Point, 4326),
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "tokenHash" VARCHAR(255) NOT NULL,
  "deviceName" VARCHAR(120),
  "expiresAt" TIMESTAMPTZ NOT NULL,
  "revokedAt" TIMESTAMPTZ,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(120) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(120),
  relationship VARCHAR(60),
  "isPrimary" BOOLEAN NOT NULL DEFAULT FALSE,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS safewalk_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status session_status NOT NULL DEFAULT 'active',
  severity session_severity NOT NULL DEFAULT 'normal',
  "deviationState" deviation_state NOT NULL DEFAULT 'none',
  "etaState" eta_state NOT NULL DEFAULT 'on_time',
  origin geometry(Point, 4326) NOT NULL,
  destination geometry(Point, 4326) NOT NULL,
  "destinationLabel" VARCHAR(255) NOT NULL,
  "routePolyline" TEXT,
  "plannedRoute" geometry(LineString, 4326),
  "lastLocation" geometry(Point, 4326),
  "expectedDistanceMeters" DOUBLE PRECISION NOT NULL,
  "expectedDurationSeconds" INTEGER NOT NULL,
  "latestEtaSeconds" INTEGER,
  "startedAt" TIMESTAMPTZ,
  "endedAt" TIMESTAMPTZ,
  "lastPingAt" TIMESTAMPTZ,
  "stopStartedAt" TIMESTAMPTZ,
  "noResponseDeadlineAt" TIMESTAMPTZ,
  "trackingShareToken" VARCHAR(64) NOT NULL UNIQUE,
  "emergencyContactIds" JSONB NOT NULL DEFAULT '[]'::jsonb,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gps_points (
  id BIGSERIAL PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES safewalk_sessions(id) ON DELETE CASCADE,
  point geometry(Point, 4326) NOT NULL,
  "speedKph" DOUBLE PRECISION,
  "accuracyMeters" DOUBLE PRECISION,
  "batteryLevel" SMALLINT,
  "isBackground" BOOLEAN NOT NULL DEFAULT FALSE,
  "clientTimestamp" TIMESTAMPTZ NOT NULL,
  "recordedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS safety_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location geometry(Point, 4326) NOT NULL,
  rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  sentiment safety_sentiment NOT NULL,
  tags VARCHAR[] NOT NULL DEFAULT '{}',
  comment TEXT,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  location geometry(Point, 4326) NOT NULL,
  category incident_category NOT NULL,
  severity SMALLINT NOT NULL DEFAULT 3 CHECK (severity BETWEEN 1 AND 5),
  description TEXT,
  "occurredAt" TIMESTAMPTZ NOT NULL,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS heatmap_cells (
  cell_id VARCHAR(80) PRIMARY KEY,
  centroid geometry(Point, 4326) NOT NULL,
  bounds geometry(Polygon, 4326) NOT NULL,
  "reviewCount" INTEGER NOT NULL DEFAULT 0,
  "incidentCount" INTEGER NOT NULL DEFAULT 0,
  "routeDensity" INTEGER NOT NULL DEFAULT 0,
  "avgSafetyRating" DOUBLE PRECISION NOT NULL DEFAULT 3,
  "safetyScore" DOUBLE PRECISION NOT NULL DEFAULT 50,
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_last_known_location ON users USING GIST ("lastKnownLocation");
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_safewalk_sessions_user_id ON safewalk_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_safewalk_sessions_status ON safewalk_sessions(status);
CREATE INDEX IF NOT EXISTS idx_safewalk_sessions_origin ON safewalk_sessions USING GIST (origin);
CREATE INDEX IF NOT EXISTS idx_safewalk_sessions_destination ON safewalk_sessions USING GIST (destination);
CREATE INDEX IF NOT EXISTS idx_safewalk_sessions_last_location ON safewalk_sessions USING GIST ("lastLocation");
CREATE INDEX IF NOT EXISTS idx_safewalk_sessions_planned_route ON safewalk_sessions USING GIST ("plannedRoute");
CREATE INDEX IF NOT EXISTS idx_gps_points_session_id ON gps_points(session_id);
CREATE INDEX IF NOT EXISTS idx_gps_points_point ON gps_points USING GIST (point);
CREATE INDEX IF NOT EXISTS idx_gps_points_recorded_at ON gps_points("recordedAt");
CREATE INDEX IF NOT EXISTS idx_safety_reviews_user_id ON safety_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_safety_reviews_location ON safety_reviews USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_incidents_user_id ON incidents(user_id);
CREATE INDEX IF NOT EXISTS idx_incidents_location ON incidents USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_heatmap_cells_centroid ON heatmap_cells USING GIST (centroid);
CREATE INDEX IF NOT EXISTS idx_heatmap_cells_bounds ON heatmap_cells USING GIST (bounds);
