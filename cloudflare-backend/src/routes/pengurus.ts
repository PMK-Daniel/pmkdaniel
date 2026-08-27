import { Hono } from "hono";
import { Env, User, Divisi, Pengurus, ApiResponse } from "../types";
import { authMiddleware } from "../utils/auth";
import { generateRandomId } from "../utils/crypto";

export const pengurusRouter = new Hono<{ Bindings: Env; Variables: { user: User } }>();

// GET /api/pengurus (Get all divisions with nested members)
pengurusRouter.get("/", async (c) => {
  try {
    const { results: divisions } = await c.env.DB.prepare(
      "SELECT * FROM divisi ORDER BY order_priority ASC"
    ).all<Divisi>();

    const { results: allMembers } = await c.env.DB.prepare(
      "SELECT * FROM pengurus ORDER BY order_priority ASC"
    ).all<Pengurus>();

    const membersByDivisi: Record<string, Pengurus[]> = {};
    for (const m of allMembers || []) {
      if (!membersByDivisi[m.divisi_id]) {
        membersByDivisi[m.divisi_id] = [];
      }
      membersByDivisi[m.divisi_id].push(m);
    }

    const data = (divisions || []).map((div) => ({
      ...div,
      members: membersByDivisi[div.id] || [],
    }));

    return c.json<ApiResponse>({
      success: true,
      data,
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memuat data pengurus" }, 500);
  }
});

// POST /api/pengurus/divisi (Create division - Admin only)
pengurusRouter.post("/divisi", authMiddleware, async (c) => {
  try {
    const body = await c.req.json<{
      id?: string;
      name: string;
      komisi?: string;
      icon_name?: string;
      description?: string;
      group_photo_url?: string;
      order_priority?: number;
    }>();

    if (!body.name) {
      return c.json<ApiResponse>({ success: false, detail: "Nama divisi wajib diisi" }, 400);
    }

    const divId = body.id || generateRandomId("div", 4);
    const komisi = body.komisi || null;
    const iconName = body.icon_name || null;
    const description = body.description || null;
    const groupPhotoUrl = body.group_photo_url || null;
    const orderPriority = body.order_priority !== undefined ? body.order_priority : 0;

    await c.env.DB.prepare(
      `INSERT INTO divisi (id, name, komisi, icon_name, description, group_photo_url, order_priority)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(divId, body.name, komisi, iconName, description, groupPhotoUrl, orderPriority)
      .run();

    const created = await c.env.DB.prepare("SELECT * FROM divisi WHERE id = ?").bind(divId).first<Divisi>();

    return c.json<ApiResponse>(
      {
        success: true,
        data: { ...created, members: [] },
        message: "Divisi berhasil dibuat",
      },
      201
    );
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal membuat divisi" }, 500);
  }
});

// PUT /api/pengurus/divisi/:id (Update division - Admin only)
pengurusRouter.put("/divisi/:id", authMiddleware, async (c) => {
  try {
    const divId = c.req.param("id");
    const body = await c.req.json<{
      name?: string;
      komisi?: string;
      icon_name?: string;
      description?: string;
      group_photo_url?: string;
      order_priority?: number;
    }>();

    const existing = await c.env.DB.prepare("SELECT * FROM divisi WHERE id = ?").bind(divId).first<Divisi>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Divisi tidak ditemukan" }, 404);
    }

    const name = body.name !== undefined ? body.name : existing.name;
    const komisi = body.komisi !== undefined ? body.komisi : existing.komisi;
    const iconName = body.icon_name !== undefined ? body.icon_name : existing.icon_name;
    const description = body.description !== undefined ? body.description : existing.description;
    const groupPhotoUrl = body.group_photo_url !== undefined ? body.group_photo_url : existing.group_photo_url;
    const orderPriority = body.order_priority !== undefined ? body.order_priority : existing.order_priority;

    await c.env.DB.prepare(
      `UPDATE divisi
       SET name = ?, komisi = ?, icon_name = ?, description = ?, group_photo_url = ?, order_priority = ?
       WHERE id = ?`
    )
      .bind(name, komisi, iconName, description, groupPhotoUrl, orderPriority, divId)
      .run();

    const updated = await c.env.DB.prepare("SELECT * FROM divisi WHERE id = ?").bind(divId).first<Divisi>();
    const { results: members } = await c.env.DB.prepare(
      "SELECT * FROM pengurus WHERE divisi_id = ? ORDER BY order_priority ASC"
    )
      .bind(divId)
      .all<Pengurus>();

    return c.json<ApiResponse>({
      success: true,
      data: { ...updated, members: members || [] },
      message: "Divisi berhasil diperbarui",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memperbarui divisi" }, 500);
  }
});

// DELETE /api/pengurus/divisi/:id (Delete division - Admin only)
pengurusRouter.delete("/divisi/:id", authMiddleware, async (c) => {
  try {
    const divId = c.req.param("id");
    const existing = await c.env.DB.prepare("SELECT * FROM divisi WHERE id = ?").bind(divId).first<Divisi>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Divisi tidak ditemukan" }, 404);
    }

    await c.env.DB.prepare("DELETE FROM pengurus WHERE divisi_id = ?").bind(divId).run();
    await c.env.DB.prepare("DELETE FROM divisi WHERE id = ?").bind(divId).run();

    return c.json<ApiResponse>({
      success: true,
      message: "Divisi berhasil dihapus",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal menghapus divisi" }, 500);
  }
});

// POST /api/pengurus/member (Create member - Admin only)
pengurusRouter.post("/member", authMiddleware, async (c) => {
  try {
    const body = await c.req.json<{
      divisi_id: string;
      name: string;
      role: string;
      photo_url?: string;
      period?: string;
      order_priority?: number;
    }>();

    if (!body.divisi_id || !body.name || !body.role) {
      return c.json<ApiResponse>({ success: false, detail: "Divisi, nama, dan peran wajib diisi" }, 400);
    }

    const divisi = await c.env.DB.prepare("SELECT id FROM divisi WHERE id = ?").bind(body.divisi_id).first();
    if (!divisi) {
      return c.json<ApiResponse>({ success: false, detail: "Divisi tidak ditemukan" }, 404);
    }

    const memberId = generateRandomId("png", 4);
    const photoUrl = body.photo_url || null;
    const period = body.period || "2025/2026";
    const orderPriority = body.order_priority !== undefined ? body.order_priority : 0;

    await c.env.DB.prepare(
      `INSERT INTO pengurus (id, divisi_id, name, role, photo_url, period, order_priority)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(memberId, body.divisi_id, body.name, body.role, photoUrl, period, orderPriority)
      .run();

    const created = await c.env.DB.prepare("SELECT * FROM pengurus WHERE id = ?").bind(memberId).first<Pengurus>();

    return c.json<ApiResponse>(
      {
        success: true,
        data: created,
        message: "Pengurus berhasil ditambahkan",
      },
      201
    );
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal menambahkan pengurus" }, 500);
  }
});

// PUT /api/pengurus/member/:id (Update member - Admin only)
pengurusRouter.put("/member/:id", authMiddleware, async (c) => {
  try {
    const memberId = c.req.param("id");
    const body = await c.req.json<{
      divisi_id?: string;
      name?: string;
      role?: string;
      photo_url?: string;
      period?: string;
      order_priority?: number;
    }>();

    const existing = await c.env.DB.prepare("SELECT * FROM pengurus WHERE id = ?").bind(memberId).first<Pengurus>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Pengurus tidak ditemukan" }, 404);
    }

    const divisiId = body.divisi_id !== undefined ? body.divisi_id : existing.divisi_id;
    const name = body.name !== undefined ? body.name : existing.name;
    const role = body.role !== undefined ? body.role : existing.role;
    const photoUrl = body.photo_url !== undefined ? body.photo_url : existing.photo_url;
    const period = body.period !== undefined ? body.period : existing.period;
    const orderPriority = body.order_priority !== undefined ? body.order_priority : existing.order_priority;

    await c.env.DB.prepare(
      `UPDATE pengurus
       SET divisi_id = ?, name = ?, role = ?, photo_url = ?, period = ?, order_priority = ?
       WHERE id = ?`
    )
      .bind(divisiId, name, role, photoUrl, period, orderPriority, memberId)
      .run();

    const updated = await c.env.DB.prepare("SELECT * FROM pengurus WHERE id = ?").bind(memberId).first<Pengurus>();

    return c.json<ApiResponse>({
      success: true,
      data: updated,
      message: "Data pengurus berhasil diperbarui",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memperbarui pengurus" }, 500);
  }
});

// DELETE /api/pengurus/member/:id (Delete member - Admin only)
pengurusRouter.delete("/member/:id", authMiddleware, async (c) => {
  try {
    const memberId = c.req.param("id");
    const existing = await c.env.DB.prepare("SELECT * FROM pengurus WHERE id = ?").bind(memberId).first<Pengurus>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Pengurus tidak ditemukan" }, 404);
    }

    await c.env.DB.prepare("DELETE FROM pengurus WHERE id = ?").bind(memberId).run();

    return c.json<ApiResponse>({
      success: true,
      message: "Pengurus berhasil dihapus",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal menghapus pengurus" }, 500);
  }
});
