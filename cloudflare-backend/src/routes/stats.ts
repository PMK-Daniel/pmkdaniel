import { Hono } from "hono";
import { Env, User, ApiResponse } from "../types";
import { authMiddleware } from "../utils/auth";

export const statsRouter = new Hono<{ Bindings: Env; Variables: { user: User } }>();

statsRouter.get("/", authMiddleware, async (c) => {
  try {
    const pengumumanCount = await c.env.DB.prepare("SELECT COUNT(*) as count FROM pengumuman").first<{ count: number }>();
    const viewsSum = await c.env.DB.prepare("SELECT COALESCE(SUM(views), 0) as total FROM pengumuman").first<{ total: number }>();
    const pengurusCount = await c.env.DB.prepare("SELECT COUNT(*) as count FROM pengurus").first<{ count: number }>();
    const divisiCount = await c.env.DB.prepare("SELECT COUNT(*) as count FROM divisi").first<{ count: number }>();

    const { results: latest } = await c.env.DB.prepare(
      "SELECT id, title, category, date_published, views FROM pengumuman ORDER BY created_at DESC LIMIT 5"
    ).all();

    return c.json<ApiResponse>({
      success: true,
      data: {
        totalPengumuman: pengumumanCount ? pengumumanCount.count : 0,
        totalViews: viewsSum ? Number(viewsSum.total) : 0,
        totalPengurus: pengurusCount ? pengurusCount.count : 0,
        totalDivisi: divisiCount ? divisiCount.count : 0,
        latestPengumuman: latest || [],
      },
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memuat statistik" }, 500);
  }
});
