-- Migration 003: Allow CUSTOMER_CONFIRMED in appointments.status check constraint
-- Drops the existing check constraint and recreates it to include CUSTOMER_CONFIRMED status
-- This aligns the database with the AppointmentStatus enum that includes CUSTOMER_CONFIRMED

-- Run this against the techtorque_appointments database

ALTER TABLE IF EXISTS appointments DROP CONSTRAINT IF EXISTS appointments_status_check;

ALTER TABLE appointments
  ADD CONSTRAINT appointments_status_check
  CHECK (status IN (
    'PENDING',
    'CONFIRMED',
    'IN_PROGRESS',
    'COMPLETED',
    'CUSTOMER_CONFIRMED',
    'CANCELLED',
    'NO_SHOW'
  ));

