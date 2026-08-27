import { Hono } from "hono";
import { Env, User, DynamicForm, FormSubmission, ApiResponse } from "../types";
import { authMiddleware } from "../utils/auth";
import { generateRandomId, slugify } from "../utils/crypto";

export const dynamicFormsRouter = new Hono<{ Bindings: Env; Variables: { user: User } }>();

function parseFormOut(form: DynamicForm, submissionCount: number = 0) {
  let fields: any[] = [];
  try {
    fields = form.fields_schema ? JSON.parse(form.fields_schema) : [];
  } catch (e) {
    fields = [];
  }

  return {
    id: form.id,
    title: form.title,
    slug: form.slug,
    description: form.description,
    fields_schema: fields,
    is_active: form.is_active,
    submission_count: submissionCount,
    created_at: form.created_at,
    updated_at: form.updated_at,
  };
}

// ----------------- PUBLIC ENDPOINTS -----------------

// GET /api/dynamic-forms
dynamicFormsRouter.get("/", async (c) => {
  try {
    const activeOnly = c.req.query("active_only") === "true";
    const query = activeOnly
      ? "SELECT * FROM dynamic_forms WHERE is_active = 1 ORDER BY created_at DESC"
      : "SELECT * FROM dynamic_forms ORDER BY created_at DESC";

    const { results: forms } = await c.env.DB.prepare(query).all<DynamicForm>();

    const { results: counts } = await c.env.DB.prepare(
      "SELECT form_id, COUNT(*) as count FROM form_submissions GROUP BY form_id"
    ).all<{ form_id: string; count: number }>();

    const countMap: Record<string, number> = {};
    for (const row of counts || []) {
      countMap[row.form_id] = row.count;
    }

    const results = (forms || []).map((f) => parseFormOut(f, countMap[f.id] || 0));

    return c.json<ApiResponse>({
      success: true,
      data: results,
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memuat formulir" }, 500);
  }
});

// GET /api/dynamic-forms/:id_or_slug
dynamicFormsRouter.get("/:id_or_slug", async (c) => {
  try {
    const idOrSlug = c.req.param("id_or_slug");

    const form = await c.env.DB.prepare(
      "SELECT * FROM dynamic_forms WHERE id = ? OR slug = ?"
    )
      .bind(idOrSlug, idOrSlug)
      .first<DynamicForm>();

    if (!form) {
      return c.json<ApiResponse>({ success: false, detail: "Formulir tidak ditemukan" }, 404);
    }

    const countResult = await c.env.DB.prepare(
      "SELECT COUNT(*) as count FROM form_submissions WHERE form_id = ?"
    )
      .bind(form.id)
      .first<{ count: number }>();

    return c.json<ApiResponse>({
      success: true,
      data: parseFormOut(form, countResult ? countResult.count : 0),
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memuat formulir" }, 500);
  }
});

// POST /api/dynamic-forms/:id_or_slug/submit
dynamicFormsRouter.post("/:id_or_slug/submit", async (c) => {
  try {
    const idOrSlug = c.req.param("id_or_slug");
    const body = await c.req.json<{ answers?: Record<string, any> }>();

    const form = await c.env.DB.prepare(
      "SELECT * FROM dynamic_forms WHERE id = ? OR slug = ?"
    )
      .bind(idOrSlug, idOrSlug)
      .first<DynamicForm>();

    if (!form) {
      return c.json<ApiResponse>({ success: false, detail: "Formulir tidak ditemukan" }, 404);
    }

    if (form.is_active === 0) {
      return c.json<ApiResponse>(
        { success: false, detail: "Formulir ini sudah ditutup dan tidak menerima tanggapan baru." },
        400
      );
    }

    let fields: any[] = [];
    try {
      fields = form.fields_schema ? JSON.parse(form.fields_schema) : [];
    } catch {
      fields = [];
    }

    const answers = body.answers || {};

    // ─── Helper: run a single validation rule ────────────────────────────────
    function runValidation(rule: any, val: any): string | null {
      if (!rule || val === undefined || val === null || val === "") return null;

      const strVal = typeof val === "string" ? val : String(val);
      const numVal = parseFloat(strVal);
      const customMsg = rule.errorMessage;
      const err = (msg: string) => customMsg || msg;

      switch (rule.type) {
        case "number":
          if (!/^-?\d+([.,]\d+)?$/.test(strVal.trim()))
            return err("Jawaban harus berupa angka");
          break;
        case "email":
          if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(strVal.trim()))
            return err("Format email tidak valid");
          break;
        case "url":
          try { new URL(strVal.trim()); } catch { return err("Format URL tidak valid"); }
          break;
        case "phone":
          if (!/^(\+62|62|0)[0-9]{8,13}$/.test(strVal.trim().replace(/\s|-/g, "")))
            return err("Format nomor telepon tidak valid");
          break;
        case "min_length": {
          const min = parseInt(rule.value || "0", 10);
          if (strVal.length < min) return err(`Minimal ${min} karakter`);
          break;
        }
        case "max_length": {
          const max = parseInt(rule.value || "9999", 10);
          if (strVal.length > max) return err(`Maksimal ${max} karakter`);
          break;
        }
        case "min_value": {
          const min = parseFloat(rule.value || "0");
          if (isNaN(numVal) || numVal < min) return err(`Nilai harus ≥ ${min}`);
          break;
        }
        case "max_value": {
          const max = parseFloat(rule.value || "0");
          if (isNaN(numVal) || numVal > max) return err(`Nilai harus ≤ ${max}`);
          break;
        }
        case "regex": {
          try {
            const pattern = new RegExp(rule.value || "");
            if (!pattern.test(strVal)) return err("Format jawaban tidak sesuai");
          } catch { /* invalid regex — skip */ }
          break;
        }
        case "min_checked": {
          const arr = Array.isArray(val) ? val : [];
          const min = parseInt(rule.value || "1", 10);
          if (arr.length < min) return err(`Pilih minimal ${min} opsi`);
          break;
        }
        case "max_checked": {
          const arr = Array.isArray(val) ? val : [];
          const max = parseInt(rule.value || "9999", 10);
          if (arr.length > max) return err(`Maksimal pilih ${max} opsi`);
          break;
        }
        case "min_date": {
          if (rule.value && strVal < rule.value) return err(`Tanggal harus setelah ${rule.value}`);
          break;
        }
        case "max_date": {
          if (rule.value && strVal > rule.value) return err(`Tanggal harus sebelum ${rule.value}`);
          break;
        }
      }
      return null;
    }
    // ─────────────────────────────────────────────────────────────────────────

    for (const f of fields) {
      const fId = f.id;
      const fLabel = f.label || "Pertanyaan";
      const val = answers[fId];

      // 1. Required check
      if (f.required === true) {
        if (
          val === undefined ||
          val === null ||
          (typeof val === "string" && !val.trim()) ||
          (Array.isArray(val) && val.length === 0)
        ) {
          return c.json<ApiResponse>({ success: false, detail: `'${fLabel}' wajib diisi.` }, 400);
        }
      }

      // 2. Custom validation rule check (skip if value is empty/not provided)
      if (f.validation && val !== undefined && val !== null && val !== "") {
        const ruleError = runValidation(f.validation, val);
        if (ruleError) {
          return c.json<ApiResponse>(
            { success: false, detail: `'${fLabel}': ${ruleError}` },
            422
          );
        }
      }
    }

    const subId = generateRandomId("sub", 5);
    await c.env.DB.prepare(
      "INSERT INTO form_submissions (id, form_id, answers_json, submitted_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)"
    )
      .bind(subId, form.id, JSON.stringify(answers))
      .run();

    return c.json<ApiResponse>({
      success: true,
      data: { submissionId: subId },
      message: "Terima kasih, tanggapan Anda berhasil disimpan!",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal menyimpan tanggapan" }, 500);
  }
});

// POST /api/dynamic-forms/upload-attachment (Public upload for form attachments)
dynamicFormsRouter.post("/upload-attachment", async (c) => {
  try {
    const formData = await c.req.parseBody();
    const file = formData["file"] as File;

    if (!file || typeof file === "string") {
      return c.json<ApiResponse>({ success: false, detail: "Berkas tidak ditemukan" }, 400);
    }

    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      return c.json<ApiResponse>({ success: false, detail: "Ukuran berkas maksimal 10MB" }, 400);
    }

    const ext = file.name.includes(".") ? file.name.split(".").pop() : "dat";
    const uniqueFilename = `form_att_${Math.floor(Date.now() / 1000)}_${Math.random().toString(36).substring(2, 8)}.${ext}`;
    const contentType = file.type || "application/octet-stream";

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
        fileName: file.name,
        url,
        size: file.size,
        contentType,
      },
      message: "Berkas berhasil diunggah",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal mengunggah berkas" }, 500);
  }
});

// ----------------- ADMIN ENDPOINTS -----------------

// POST /api/dynamic-forms (Admin only)
dynamicFormsRouter.post("/", authMiddleware, async (c) => {
  try {
    const body = await c.req.json<{
      title: string;
      slug?: string;
      description?: string;
      fields_schema: any[];
      is_active?: number;
    }>();

    if (!body.title) {
      return c.json<ApiResponse>({ success: false, detail: "Judul formulir wajib diisi" }, 400);
    }

    const formId = generateRandomId("form", 4);
    const baseSlug = slugify(body.slug || body.title);

    let slug = baseSlug;
    let counter = 1;
    while (
      await c.env.DB.prepare("SELECT id FROM dynamic_forms WHERE slug = ?").bind(slug).first()
    ) {
      slug = `${baseSlug}-${counter}`;
      counter++;
    }

    const fieldsJson = JSON.stringify(body.fields_schema || []);
    const isActive = body.is_active !== undefined ? body.is_active : 1;
    const description = body.description || null;

    await c.env.DB.prepare(
      `INSERT INTO dynamic_forms (id, title, slug, description, fields_schema, is_active)
       VALUES (?, ?, ?, ?, ?, ?)`
    )
      .bind(formId, body.title, slug, description, fieldsJson, isActive)
      .run();

    const created = await c.env.DB.prepare("SELECT * FROM dynamic_forms WHERE id = ?").bind(formId).first<DynamicForm>();

    return c.json<ApiResponse>(
      {
        success: true,
        data: created ? parseFormOut(created, 0) : null,
        message: "Formulir berhasil dibuat",
      },
      201
    );
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal membuat formulir" }, 500);
  }
});

// PUT /api/dynamic-forms/:id (Admin only)
dynamicFormsRouter.put("/:id", authMiddleware, async (c) => {
  try {
    const id = c.req.param("id");
    const body = await c.req.json<{
      title?: string;
      slug?: string;
      description?: string;
      fields_schema?: any[];
      is_active?: number;
    }>();

    const existing = await c.env.DB.prepare("SELECT * FROM dynamic_forms WHERE id = ?").bind(id).first<DynamicForm>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Formulir tidak ditemukan" }, 404);
    }

    let slug = existing.slug;
    if (body.slug && body.slug !== existing.slug) {
      const baseSlug = slugify(body.slug);
      slug = baseSlug;
      let counter = 1;
      while (
        await c.env.DB.prepare("SELECT id FROM dynamic_forms WHERE slug = ? AND id != ?")
          .bind(slug, id)
          .first()
      ) {
        slug = `${baseSlug}-${counter}`;
        counter++;
      }
    }

    const title = body.title !== undefined ? body.title : existing.title;
    const description = body.description !== undefined ? body.description : existing.description;
    const fieldsJson = body.fields_schema !== undefined ? JSON.stringify(body.fields_schema) : existing.fields_schema;
    const isActive = body.is_active !== undefined ? body.is_active : existing.is_active;

    await c.env.DB.prepare(
      `UPDATE dynamic_forms
       SET title = ?, slug = ?, description = ?, fields_schema = ?, is_active = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`
    )
      .bind(title, slug, description, fieldsJson, isActive, id)
      .run();

    const updated = await c.env.DB.prepare("SELECT * FROM dynamic_forms WHERE id = ?").bind(id).first<DynamicForm>();
    const countResult = await c.env.DB.prepare("SELECT COUNT(*) as count FROM form_submissions WHERE form_id = ?")
      .bind(id)
      .first<{ count: number }>();

    return c.json<ApiResponse>({
      success: true,
      data: updated ? parseFormOut(updated, countResult ? countResult.count : 0) : null,
      message: "Formulir berhasil diperbarui",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memperbarui formulir" }, 500);
  }
});

// DELETE /api/dynamic-forms/:id (Admin only)
dynamicFormsRouter.delete("/:id", authMiddleware, async (c) => {
  try {
    const id = c.req.param("id");
    const existing = await c.env.DB.prepare("SELECT * FROM dynamic_forms WHERE id = ?").bind(id).first<DynamicForm>();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Formulir tidak ditemukan" }, 404);
    }

    await c.env.DB.prepare("DELETE FROM form_submissions WHERE form_id = ?").bind(id).run();
    await c.env.DB.prepare("DELETE FROM dynamic_forms WHERE id = ?").bind(id).run();

    return c.json<ApiResponse>({
      success: true,
      message: "Formulir berhasil dihapus",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal menghapus formulir" }, 500);
  }
});

// GET /api/dynamic-forms/:id/submissions (Admin only)
dynamicFormsRouter.get("/:id/submissions", authMiddleware, async (c) => {
  try {
    const id = c.req.param("id");
    const form = await c.env.DB.prepare("SELECT * FROM dynamic_forms WHERE id = ?").bind(id).first<DynamicForm>();
    if (!form) {
      return c.json<ApiResponse>({ success: false, detail: "Formulir tidak ditemukan" }, 404);
    }

    const { results: subs } = await c.env.DB.prepare(
      "SELECT * FROM form_submissions WHERE form_id = ? ORDER BY submitted_at DESC"
    )
      .bind(id)
      .all<FormSubmission>();

    const results = (subs || []).map((s) => {
      let answers = {};
      try {
        answers = s.answers_json ? JSON.parse(s.answers_json) : {};
      } catch {}
      return {
        id: s.id,
        form_id: s.form_id,
        answers,
        submitted_at: s.submitted_at,
      };
    });

    return c.json<ApiResponse>({
      success: true,
      data: results,
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal memuat tanggapan" }, 500);
  }
});

// DELETE /api/dynamic-forms/submissions/:submission_id (Admin only)
dynamicFormsRouter.delete("/submissions/:submission_id", authMiddleware, async (c) => {
  try {
    const subId = c.req.param("submission_id");
    const existing = await c.env.DB.prepare("SELECT id FROM form_submissions WHERE id = ?").bind(subId).first();
    if (!existing) {
      return c.json<ApiResponse>({ success: false, detail: "Tanggapan tidak ditemukan" }, 404);
    }

    await c.env.DB.prepare("DELETE FROM form_submissions WHERE id = ?").bind(subId).run();

    return c.json<ApiResponse>({
      success: true,
      message: "Tanggapan berhasil dihapus",
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal menghapus tanggapan" }, 500);
  }
});

// GET /api/dynamic-forms/:id_or_slug/export-csv
dynamicFormsRouter.get("/:id_or_slug/export-csv", async (c) => {
  try {
    const idOrSlug = c.req.param("id_or_slug");
    const form = await c.env.DB.prepare("SELECT * FROM dynamic_forms WHERE id = ? OR slug = ?")
      .bind(idOrSlug, idOrSlug)
      .first<DynamicForm>();

    if (!form) {
      return c.json<ApiResponse>({ success: false, detail: "Formulir tidak ditemukan" }, 404);
    }

    let fields: any[] = [];
    try {
      fields = form.fields_schema ? JSON.parse(form.fields_schema) : [];
    } catch {}

    const { results: subs } = await c.env.DB.prepare(
      "SELECT * FROM form_submissions WHERE form_id = ? ORDER BY submitted_at ASC"
    )
      .bind(form.id)
      .all<FormSubmission>();

    const escapeCsv = (str: string) => {
      if (str.includes(",") || str.includes('"') || str.includes("\n") || str.includes("\r")) {
        return `"${str.replace(/"/g, '""')}"`;
      }
      return str;
    };

    // Header row
    const headers = ["No", "ID Respon", "Waktu Pengisian (WIB)"];
    for (const f of fields) {
      headers.push(f.label || f.id || "Pertanyaan");
    }

    let csvContent = "\ufeff"; // UTF-8 BOM
    csvContent += headers.map(escapeCsv).join(",") + "\r\n";

    // Data rows
    (subs || []).forEach((s, idx) => {
      let answers: Record<string, any> = {};
      try {
        answers = s.answers_json ? JSON.parse(s.answers_json) : {};
      } catch {}

      const row = [String(idx + 1), s.id, s.submitted_at || "-"];
      for (const f of fields) {
        const val = answers[f.id];
        let valStr = "";
        if (Array.isArray(val)) {
          valStr = val.join(", ");
        } else if (typeof val === "object" && val !== null) {
          valStr = JSON.stringify(val);
        } else {
          valStr = val !== undefined && val !== null ? String(val) : "";
        }
        row.push(valStr);
      }
      csvContent += row.map(escapeCsv).join(",") + "\r\n";
    });

    const cleanTitle = form.title.replace(/[^\w\s-]/g, "").trim().replace(/\s+/g, "_");
    const filename = `Respon_${cleanTitle}_${Date.now()}.csv`;

    return new Response(csvContent, {
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="${filename}"`,
      },
    });
  } catch (err: any) {
    return c.json<ApiResponse>({ success: false, error: err.message || "Gagal export CSV" }, 500);
  }
});
