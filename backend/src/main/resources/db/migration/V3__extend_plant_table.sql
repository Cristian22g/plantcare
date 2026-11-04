ALTER TABLE plant
        ADD COLUMN garden_id    BIGINT NOT NULL REFERENCES garden (id) ON DELETE CASCADE,
        ADD COLUMN exposure     VARCHAR(10) NOT NULL CHECK (exposure IN ('INDOOR', 'OUTDOOR')),
        ADD COLUMN planted_on   DATE,
        ADD COLUMN last_watered_on  DATE    NOT NULL,
        ADD COLUMN interval_days    INTEGER NOT NULL CHECK (interval_days > 0),
        ADD COLUMN next_watering_on DATE    NOT NULL,
        ADD COLUMN created_at   TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE INDEX idx_plant_garden_id ON plant (garden_id);