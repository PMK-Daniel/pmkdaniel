import { Context, Next } from "hono";
import { sign, verify } from "hono/jwt";
import { Env, User } from "../types";

export async function createAccessToken(
  payload: { id: string; username: string; role: string },
  secret: string
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 7 * 24 * 60 * 60; // 7 days
  return await sign({ ...payload, exp }, secret);
}

export async function authMiddleware(c: Context<{ Bindings: Env; Variables: { user: User } }>, next: Next) {
  const authHeader = c.req.header("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return c.json({ success: false, error: "Token tidak ditemukan atau format salah", message: "Unauthorized" }, 401);
  }

  const token = authHeader.substring(7);
  try {
    const payload = (await verify(token, c.env.JWT_SECRET, "HS256")) as { id: string; username: string; role: string };
    if (!payload || !payload.username) {
      return c.json({ success: false, error: "Token tidak valid", message: "Unauthorized" }, 401);
    }

    const user = await c.env.DB.prepare("SELECT id, username, password_hash, role FROM users WHERE username = ?")
      .bind(payload.username)
      .first<User>();

    if (!user) {
      return c.json({ success: false, error: "Pengguna tidak ditemukan", message: "Unauthorized" }, 401);
    }

    c.set("user", user);
    await next();
  } catch (err) {
    return c.json({ success: false, error: "Token kedaluwarsa atau tidak valid", message: "Unauthorized" }, 401);
  }
}
