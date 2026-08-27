import { Hono } from "hono";
import { cors } from "hono/cors";
import { Env, User } from "./types";
import { authRouter } from "./routes/auth";
import { pengumumanRouter } from "./routes/pengumuman";
import { pengurusRouter } from "./routes/pengurus";
import { formsRouter } from "./routes/forms";
import { dynamicFormsRouter } from "./routes/dynamicForms";
import { uploadRouter } from "./routes/upload";
import { statsRouter } from "./routes/stats";

const app = new Hono<{ Bindings: Env; Variables: { user: User } }>();

// Enable CORS for all routes
app.use(
  "*",
  cors({
    origin: "*",
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allowHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
    maxAge: 86400,
  })
);

// Health check endpoint
app.get("/", (c) => {
  return c.json({
    name: "Backend API PMK Daniel FILKOM UB (Cloudflare Edge)",
    status: "online",
    version: "2.0.0",
    runtime: "Cloudflare Workers + D1 + R2",
  });
});

// Mount API subrouters
app.route("/api/auth", authRouter);
app.route("/api/pengumuman", pengumumanRouter);
app.route("/api/pengurus", pengurusRouter);
app.route("/api/forms", formsRouter);
app.route("/api/dynamic-forms", dynamicFormsRouter);
app.route("/api/upload", uploadRouter);
app.route("/api/stats", statsRouter);

// 404 handler
app.notFound((c) => {
  return c.json({ success: false, error: "Endpoint tidak ditemukan" }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error("Worker Error:", err);
  return c.json(
    {
      success: false,
      error: err.message || "Internal Server Error",
    },
    500
  );
});

export default app;
