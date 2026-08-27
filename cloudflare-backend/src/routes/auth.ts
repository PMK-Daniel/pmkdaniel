import { Hono } from "hono";
import { Env, User, ApiResponse } from "../types";
import { verifyPassword, sha256 } from "../utils/crypto";
import { createAccessToken, authMiddleware } from "../utils/auth";

export const authRouter = new Hono<{ Bindings: Env; Variables: { user: User } }>();

authRouter.post("/login", async (c) => {
  try {
    const body = await c.req.json<{ username?: string; password?: string }>();
    const { username, password } = body;

    if (!username || !password) {
      return c.json<ApiResponse>(
        { success: false, detail: "Username dan password wajib diisi", message: "Username dan password wajib diisi" },
        400
      );
    }

    const user = await c.env.DB.prepare("SELECT id, username, password_hash, role FROM users WHERE username = ?")
      .bind(username.trim())
      .first<User>();

    if (!user) {
      return c.json<ApiResponse>(
        { success: false, detail: "Username atau password salah", message: "Username atau password salah" },
        401
      );
    }

    const isMatch = await verifyPassword(password, user.password_hash);
    if (!isMatch) {
      return c.json<ApiResponse>(
        { success: false, detail: "Username atau password salah", message: "Username atau password salah" },
        401
      );
    }

    const token = await createAccessToken(
      { id: user.id, username: user.username, role: user.role },
      c.env.JWT_SECRET
    );

    return c.json<ApiResponse>({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          username: user.username,
          role: user.role,
        },
      },
      message: "Login berhasil",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memproses login" }, 500);
  }
});

authRouter.get("/me", authMiddleware, async (c) => {
  const user = c.get("user");
  return c.json<ApiResponse>({
    success: true,
    data: {
      id: user.id,
      username: user.username,
      role: user.role,
    },
    message: "Token valid",
  });
});

authRouter.put("/change-password", authMiddleware, async (c) => {
  try {
    const user = c.get("user");
    const body = await c.req.json<{ oldPassword?: string; newPassword?: string }>();
    const { oldPassword, newPassword } = body;

    if (!oldPassword || !newPassword) {
      return c.json<ApiResponse>({ success: false, detail: "Password lama dan baru wajib diisi" }, 400);
    }

    const isMatch = await verifyPassword(oldPassword, user.password_hash);
    if (!isMatch) {
      return c.json<ApiResponse>({ success: false, detail: "Password lama tidak sesuai" }, 400);
    }

    if (newPassword.length < 6) {
      return c.json<ApiResponse>({ success: false, detail: "Password baru minimal 6 karakter" }, 400);
    }

    const newHash = await sha256(newPassword);
    await c.env.DB.prepare("UPDATE users SET password_hash = ? WHERE id = ?")
      .bind(newHash, user.id)
      .run();

    return c.json<ApiResponse>({
      success: true,
      message: "Password berhasil diperbarui",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal mengubah password" }, 500);
  }
});
