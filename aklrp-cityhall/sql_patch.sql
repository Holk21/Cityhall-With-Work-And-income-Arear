-- SQL patch: add deny_reason columns if you already imported original winz.sql
ALTER TABLE winz_food_grants ADD COLUMN IF NOT EXISTS deny_reason TEXT DEFAULT NULL;
ALTER TABLE winz_money_grants ADD COLUMN IF NOT EXISTS deny_reason TEXT DEFAULT NULL;
