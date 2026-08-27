import { Hono } from "hono";
import { Env, User, FormLink, ApiResponse } from "../types";
import { authMiddleware } from "../utils/auth";

export const formsRouter = new Hono<{ Bindings: Env; Variables: { user: User } }>();

// GET /api/forms (Get active Google Form links)
formsRouter.get("/", async (c) => {
  try {
    const { results } = await c.env.DB.prepare(
      "SELECT * FROM form_links WHERE is_active = 1"
    ).all<FormLink>();

    return c.json<ApiResponse>({
      success: true,
      data: results || [],
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memuat form links" }, 500);
  }
});

// PUT /api/forms/:key (Update Google Form link - Admin only)
formsRouter.put("/:key", authMiddleware, async (c) => {
  try {
    const key = c.req.param("key");
    const body = await c.req.json<{
      title?: string;
      google_form_url?: string;
      is_active?: number;
    }>();

    const existing = await c.env.DB.prepare("SELECT * FROM form_links WHERE key = ?").bind(key).first<FormLink>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Form link tidak ditemukan" }, 404);
    }

    const title = body.title !== undefined ? body.title : existing.title;
    const googleFormUrl = body.google_form_url !== undefined ? body.google_form_url : existing.google_form_url;
    const isActive = body.is_active !== undefined ? body.is_active : existing.is_active;

    await c.env.DB.prepare(
      `UPDATE form_links
       SET title = ?, google_form_url = ?, is_active = ?, updated_at = CURRENT_TIMESTAMP
       WHERE key = ?`
    )
      .bind(title, googleFormUrl, isActive, key)
      .run();

    const updated = await c.env.DB.prepare("SELECT * FROM form_links WHERE key = ?").bind(key).first<FormLink>();

    return c.json<ApiResponse>({
      success: true,
      data: updated,
      message: "Form link berhasil diperbarui",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memperbarui form link" }, 500);
  }
});
