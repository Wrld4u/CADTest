CREATE EXTENSION IF NOT EXISTS "pgcrypto";

ALTER TABLE "reservations"
ALTER COLUMN "id" TYPE uuid
USING "id"::uuid;

ALTER TABLE "reservations"
ALTER COLUMN "id" SET DEFAULT gen_random_uuid();
