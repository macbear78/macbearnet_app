import cors from "cors";
import express from "express";
import "dotenv/config";
import { pingDb, pool } from "./db.js";

const app = express();
const port = Number(process.env.PORT ?? 3000);
const corsOrigin = process.env.CORS_ORIGIN ?? "http://127.0.0.1:5173";

app.use(
  cors({
    origin: corsOrigin,
    credentials: true,
  })
);
app.use(express.json());

app.get("/api/health", async (_req, res) => {
  let dbOk = false;
  try {
    dbOk = await pingDb();
  } catch {
    dbOk = false;
  }
  res.json({ ok: true, db: dbOk, env: process.env.NODE_ENV ?? "development" });
});

/** Example: read from DB — run sql/schema.sql first */
app.get("/api/hello", async (_req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT message FROM site_greeting WHERE id = 1 LIMIT 1"
    );
    const message = rows?.[0]?.message ?? "Macbear";
    res.json({ message });
  } catch (err) {
    res.status(500).json({
      error: "db_error",
      detail: err.message,
    });
  }
});

app.listen(port, () => {
  console.log(`API listening on http://127.0.0.1:${port}`);
});
