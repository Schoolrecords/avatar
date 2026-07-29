// ============================================================
// AVATAR — Edge Function: quan-ly-tk
// Quản trị TẠO / ĐỔI MẬT KHẨU / KHÓA / MỞ KHÓA / XÓA / LIỆT KÊ
// tài khoản giáo viên. Chỉ tài khoản 'admin' mới gọi được.
// (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY được
//  Supabase tự cấp — KHÔNG cần khai báo khóa bí mật thủ công.)
// ============================================================
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const URL = Deno.env.get("SUPABASE_URL")!;
    const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
    const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 1) Người gọi phải là admin
    const authHeader = req.headers.get("Authorization") || "";
    const caller = createClient(URL, ANON, { global: { headers: { Authorization: authHeader } } });
    const { data: ures } = await caller.auth.getUser();
    const uid = ures?.user?.id;
    if (!uid) return json(401, { error: "Chưa đăng nhập." });
    const { data: prof } = await caller.from("profiles").select("role").eq("id", uid).maybeSingle();
    if (!prof || prof.role !== "admin") return json(403, { error: "Chỉ quản trị mới được thao tác tài khoản." });

    // 2) Client quyền cao (service_role) để tạo/sửa/xóa user
    const admin = createClient(URL, SERVICE, { auth: { autoRefreshToken: false, persistSession: false } });
    const body = await req.json().catch(() => ({} as any));
    const action = body.action;

    if (action === "list") {
      const { data: profs } = await admin.from("profiles").select("id, ho_ten, role, coso_id, gv_id").eq("role", "teacher");
      const { data: list } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
      const byId = new Map((list?.users || []).map((u: any) => [u.id, u]));
      const out = (profs || []).map((p: any) => {
        const u: any = byId.get(p.id);
        const banned = !!(u?.banned_until && new Date(u.banned_until) > new Date());
        return { id: p.id, ho_ten: p.ho_ten, coso_id: p.coso_id, gv_id: p.gv_id, email: u?.email || "", banned };
      });
      return json(200, { data: out });
    }

    if (action === "create") {
      const email = String(body.email || "").toLowerCase().trim();
      const password = String(body.password || "");
      const ho_ten = String(body.ho_ten || "").trim();
      const coso_id = body.coso_id ?? null;
      const gv_id = body.gv_id ?? null;
      if (!email || password.length < 6) return json(400, { error: "Email/mật khẩu không hợp lệ (mật khẩu ≥ 6 ký tự)." });
      const { data: created, error: cerr } = await admin.auth.admin.createUser({
        email, password, email_confirm: true, user_metadata: { ho_ten },
      });
      if (cerr) return json(400, { error: cerr.message });
      const id = created.user!.id;
      const { error: perr } = await admin.from("profiles").upsert({ id, ho_ten, role: "teacher", coso_id, gv_id });
      if (perr) return json(400, { error: "Tạo tài khoản OK nhưng gán quyền lỗi: " + perr.message });
      return json(200, { data: { id, email } });
    }

    if (action === "resetpw") {
      const id = body.id; const password = String(body.password || "");
      if (!id || password.length < 6) return json(400, { error: "Thiếu tài khoản hoặc mật khẩu quá ngắn (≥ 6 ký tự)." });
      const { error } = await admin.auth.admin.updateUserById(id, { password });
      if (error) return json(400, { error: error.message });
      return json(200, { data: { ok: true } });
    }

    if (action === "ban") {
      const id = body.id; const banned = !!body.banned;
      const { error } = await admin.auth.admin.updateUserById(id, { ban_duration: banned ? "876000h" : "none" });
      if (error) return json(400, { error: error.message });
      return json(200, { data: { ok: true } });
    }

    if (action === "delete") {
      const id = body.id;
      // Xóa hồ sơ trước (phòng khi khóa ngoại), rồi xóa tài khoản đăng nhập
      await admin.from("profiles").delete().eq("id", id);
      const { error } = await admin.auth.admin.deleteUser(id);
      if (error) return json(400, { error: error.message });
      return json(200, { data: { ok: true } });
    }

    return json(400, { error: "Hành động không hợp lệ." });
  } catch (e: any) {
    return json(500, { error: String(e?.message || e) });
  }
});
