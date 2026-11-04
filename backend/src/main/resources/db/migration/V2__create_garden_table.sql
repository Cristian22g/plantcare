CREATE TABLE garden(
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    latitude    DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude   DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    timezone    VARCHAR(50) NOT NULL DEFAULT 'Europe/Madrid',
    edit_token  UUID NOT NULL UNIQUE,
    view_token  UUID NOT NULL UNIQUE,
    last_checked_on  DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT (now()) 
);