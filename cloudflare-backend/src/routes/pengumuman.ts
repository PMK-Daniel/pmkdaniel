import { Hono } from "hono";
import { Env, User, Pengumuman, ApiResponse } from "../types";
import { authMiddleware } from "../utils/auth";
import { generateRandomId, slugify } from "../utils/crypto";

export const pengumumanRouter = new Hono<{ Bindings: Env; Variables: { user: User } }>();

// GET /api/pengumuman (Public list)
pengumumanRouter.get("/", async (c) => {
  try {
    const kategori = c.req.query("kategori");
    const search = c.req.query("search");
    const page = Math.max(1, parseInt(c.req.query("page") || "1", 10));
    const limit = Math.min(50, Math.max(1, parseInt(c.req.query("limit") || "10", 10)));
    const offset = (page - 1) * limit;

    let whereClauses: string[] = [];
    let params: any[] = [];

    if (kategori && kategori !== "all") {
      whereClauses.push("category = ?");
      params.push(kategori);
    }

    if (search && search.trim()) {
      whereClauses.push("(title LIKE ? OR content LIKE ?)");
      const term = `%${search.trim()}%`;
      params.push(term, term);
    }

    const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(" AND ")}` : "";

    // Count total
    const countQuery = `SELECT COUNT(*) as total FROM pengumuman ${whereSql}`;
    const countStmt = c.env.DB.prepare(countQuery);
    const countResult = await (params.length > 0 ? countStmt.bind(...params) : countStmt).first<{ total: number }>();
    const total = countResult ? countResult.total : 0;
    const totalPages = limit > 0 ? Math.ceil(total / limit) : 0;

    // Fetch items
    const selectQuery = `SELECT * FROM pengumuman ${whereSql} ORDER BY date_published DESC, created_at DESC LIMIT ? OFFSET ?`;
    const selectParams = [...params, limit, offset];
    const { results } = await c.env.DB.prepare(selectQuery).bind(...selectParams).all<Pengumuman>();

    return c.json<ApiResponse>({
      success: true,
      data: {
        items: results || [],
        pagination: {
          page,
          limit,
          total,
          totalPages,
        },
      },
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memuat pengumuman" }, 500);
  }
});

// GET /api/pengumuman/:id_or_slug (Public detail + increment views)
pengumumanRouter.get("/:id_or_slug", async (c) => {
  try {
    const idOrSlug = c.req.param("id_or_slug");

    const item = await c.env.DB.prepare("SELECT * FROM pengumuman WHERE id = ? OR slug = ?")
      .bind(idOrSlug, idOrSlug)
      .first<Pengumuman>();

    if (!item) {
      return c.json<ApiResponse>({ success: false, detail: "Pengumuman tidak ditemukan" }, 404);
    }

    // Increment views in background
    c.executionCtx?.waitUntil(
      c.env.DB.prepare("UPDATE pengumuman SET views = views + 1 WHERE id = ?").bind(item.id).run()
    );

    return c.json<ApiResponse>({
      success: true,
      data: item,
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memuat detail pengumuman" }, 500);
  }
});

// POST /api/pengumuman (Admin only)
pengumumanRouter.post("/", authMiddleware, async (c) => {
  try {
    const body = await c.req.json<{
      title: string;
      category: string;
      content: string;
      image_url?: string;
      date_published: string;
      author?: string;
    }>();

    if (!body.title || !body.category || !body.content || !body.date_published) {
      return c.json<ApiResponse>({ success: false, detail: "Semua kolom wajib diisi" }, 400);
    }

    const randomSuffix = Math.random().toString(36).substring(2, 6);
    const itemId = `ann_${Math.floor(Date.now() / 1000)}_${randomSuffix}`;
    const slug = `${slugify(body.title)}-${randomSuffix}`;
    const author = body.author || "Pengurus PMK";
    const imageUrl = body.image_url || null;

    await c.env.DB.prepare(
      `INSERT INTO pengumuman (id, title, slug, category, content, image_url, date_published, author, views)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)`
    )
      .bind(itemId, body.title, slug, body.category, body.content, imageUrl, body.date_published, author)
      .run();

    const created = await c.env.DB.prepare("SELECT * FROM pengumuman WHERE id = ?").bind(itemId).first<Pengumuman>();

    return c.json<ApiResponse>(
      {
        success: true,
        data: created,
        message: "Pengumuman berhasil dibuat",
      },
      201
    );
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal membuat pengumuman" }, 500);
  }
});

// PUT /api/pengumuman/:id (Admin only)
pengumumanRouter.put("/:id", authMiddleware, async (c) => {
  try {
    const itemId = c.req.param("id");
    const body = await c.req.json<{
      title?: string;
      category?: string;
      content?: string;
      image_url?: string;
      date_published?: string;
      author?: string;
    }>();

    const existing = await c.env.DB.prepare("SELECT * FROM pengumuman WHERE id = ?").bind(itemId).first<Pengumuman>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Pengumuman tidak ditemukan" }, 404);
    }

    const title = body.title !== undefined ? body.title : existing.title;
    const category = body.category !== undefined ? body.category : existing.category;
    const content = body.content !== undefined ? body.content : existing.content;
    const imageUrl = body.image_url !== undefined ? body.image_url : existing.image_url;
    const datePublished = body.date_published !== undefined ? body.date_published : existing.date_published;
    const author = body.author !== undefined ? body.author : existing.author;

    await c.env.DB.prepare(
      `UPDATE pengumuman
       SET title = ?, category = ?, content = ?, image_url = ?, date_published = ?, author = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`
    )
      .bind(title, category, content, imageUrl, datePublished, author, itemId)
      .run();

    const updated = await c.env.DB.prepare("SELECT * FROM pengumuman WHERE id = ?").bind(itemId).first<Pengumuman>();

    return c.json<ApiResponse>({
      success: true,
      data: updated,
      message: "Pengumuman berhasil diperbarui",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memperbarui pengumuman" }, 500);
  }
});

// DELETE /api/pengumuman/:id (Admin only)
pengumumanRouter.delete("/:id", authMiddleware, async (c) => {
  try {
    const itemId = c.req.param("id");
    const existing = await c.env.DB.prepare("SELECT * FROM pengumuman WHERE id = ?").bind(itemId).first<Pengumuman>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Pengumuman tidak ditemukan" }, 404);
    }

    await c.env.DB.prepare("DELETE FROM pengumuman WHERE id = ?").bind(itemId).run();

    return c.json<ApiResponse>({
      success: true,
      message: "Pengumuman berhasil dihapus",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal menghapus pengumuman" }, 500);
  }
});
