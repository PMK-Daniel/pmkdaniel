import { Hono } from "hono";
import { Env, User, ApiResponse } from "../types";
import { authMiddleware } from "../utils/auth";

export const uploadRouter = new Hono<{ Bindings: Env; Variables: { user: User } }>();

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif", "image/svg+xml"];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

uploadRouter.post("/", authMiddleware, async (c) => {
  try {
    const formData = await c.req.parseBody();
    const file = formData["file"] as File;

    if (!file || typeof file === "string") {
      return c.json<ApiResponse>({ success: false, detail: "File tidak ditemukan" }, 400);
    }

    if (!ALLOWED_TYPES.includes(file.type)) {
      return c.json<ApiResponse>(
        {
          success: false,
          detail: "Hanya file gambar (JPEG, PNG, WebP, GIF, SVG) yang diperbolehkan",
        },
        400
      );
    }

    if (file.size > MAX_SIZE) {
      return c.json<ApiResponse>({ success: false, detail: "Ukuran file maksimal 5MB" }, 400);
    }

    const ext = file.name.includes(".") ? file.name.split(".").pop() : "webp";
    const uniqueFilename = `pmk_${Math.floor(Date.now() / 1000)}_${Math.random().toString(36).substring(2, 8)}.${ext}`;
    const contentType = file.type;

    const arrayBuffer = await file.arrayBuffer();

    if (c.env.R2_BUCKET) {
      await c.env.R2_BUCKET.put(uniqueFilename, arrayBuffer, {
        httpMetadata: { contentType },
      });
    }

    const publicDomain = c.env.R2_PUBLIC_DOMAIN || "https://pub-317e9a74788b4b17a1deee01aa307c7c.r2.dev";
    const url = `${publicDomain}/${uniqueFilename}`;

    return c.json<ApiResponse>({
      success: true,
      data: {
        fileName: uniqueFilename,
        url,
        size: file.size,
        contentType,
      },
      message: "Upload berhasil",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal mengunggah gambar" }, 500);
  }
});
