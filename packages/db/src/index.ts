import { Pool } from "pg";

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://eventflow:eventflow_password@127.0.0.1:5433/eventflow"
});

export const query = (text: string, params?: any[]) => pool.query(text, params);