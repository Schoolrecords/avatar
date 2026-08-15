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

    // 1) Lấy token đăng nhập từ header và xác thực (truyền token TRỰC TIẾP cho getUser)
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) return json(401, { error: "Thiếu token đăng nhập." });
    const anonClient = createClient(URL, ANON);
    const { data: ures, error: uerr } = await anonClient.auth.getUser(token);
    const uid = ures?.user?.id;
    if (uerr || !uid) return json(401, { error: "Phiên đăng nhập không hợp lệ. Hãy đăng nhập lại." });

    // 2) Client quyền cao (service_role) — đọc quyền (bỏ RLS) + tạo/sửa/xóa user
    const admin = createClient(URL, SERVICE, { auth: { autoRefreshToken: false, persistSession: false } });
    const { data: prof } = await admin.from("profiles").select("role").eq("id", uid).maybeSingle();
    if (!prof || prof.role !== "admin") return json(403, { error: "Chỉ quản trị mới được thao tác tài khoản." });

    // Chỉ cho phép thao tác lên tài khoản GIÁO VIÊN (tạo / khóa / xóa).
    const assertTeacher = async (id: string) => {
      if (!id) return false;
      const { data } = await admin.from("profiles").select("role").eq("id", id).maybeSingle();
      return data?.role === "teacher";
    };

    // ĐẶT LẠI MẬT KHẨU được phép rộng hơn: giáo viên VÀ lễ tân.
    // Lý do: địa chỉ @avatar.vn không phải hòm thư thật nên không ai tự khôi phục
    // được bằng email, và màn hình đăng nhập cũng không có "Quên mật khẩu" —
    // mọi trường hợp quên đều phải qua quản trị. Trước đây lễ tân quên thì quản trị
    // phải mở Supabase Dashboard, trong khi lễ tân lại là nhóm dùng app nhiều nhất.
    // VẪN CHẶN vai trò 'admin': không ai đặt lại được mật khẩu quản trị qua đường này,
    // kể cả chính quản trị — muốn đổi thì tự đổi trong app hoặc vào Dashboard.
    const assertResetPwDuoc = async (id: string) => {
      if (!id) return { ok: false, msg: "Thiếu tài khoản." };
      const { data } = await admin.from("profiles").select("role").eq("id", id).maybeSingle();
      if (!data) return { ok: false, msg: "Không tìm thấy tài khoản." };
      if (data.role === "admin")
        return { ok: false, msg: "Không đặt lại được mật khẩu tài khoản quản trị qua đây. Hãy tự đổi trong app hoặc dùng Supabase Dashboard." };
      if (data.role !== "teacher" && data.role !== "owner")
        return { ok: false, msg: "Chỉ đặt lại được mật khẩu giáo viên và lễ tân." };
      return { ok: true, msg: "" };
    };

    const body = await req.json().catch(() => ({} as any));
    const action = body.action;

    if (action === "list") {
      // Trả về CẢ giáo viên và lễ tân (kèm cột role để app xếp thành 2 nhóm).
      // Không trả tài khoản admin — app không có việc gì phải đụng tới nó.
      const { data: profs } = await admin.from("profiles")
        .select("id, ho_ten, role, coso_id, gv_id").in("role", ["teacher", "owner"]);
      const { data: list } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
      const byId = new Map((list?.users || []).map((u: any) => [u.id, u]));
      const out = (profs || []).map((p: any) => {
        const u: any = byId.get(p.id);
        const banned = !!(u?.banned_until && new Date(u.banned_until) > new Date());
        return { id: p.id, ho_ten: p.ho_ten, role: p.role, coso_id: p.coso_id, gv_id: p.gv_id, email: u?.email || "", banned };
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
      // Quy tắc phải khớp thiết lập trên Supabase: ≥ 8 ký tự, có chữ thường + HOA + số.
      if (!id) return json(400, { error: "Thiếu tài khoản." });
      if (password.length < 8) return json(400, { error: "Mật khẩu phải từ 8 ký tự trở lên." });
      if (!/[a-z]/.test(password) || !/[A-Z]/.test(password) || !/[0-9]/.test(password))
        return json(400, { error: "Mật khẩu phải có đủ chữ thường, chữ HOA và chữ số." });
      const kt = await assertResetPwDuoc(id);
      if (!kt.ok) return json(403, { error: kt.msg });
      const { error } = await admin.auth.admin.updateUserById(id, { password });
      if (error) return json(400, { error: error.message });
      return json(200, { data: { ok: true } });
    }

    if (action === "ban") {
      const id = body.id; const banned = !!body.banned;
      if (!(await assertTeacher(id))) return json(403, { error: "Chỉ được thao tác trên tài khoản giáo viên." });
      const { error } = await admin.auth.admin.updateUserById(id, { ban_duration: banned ? "876000h" : "none" });
      if (error) return json(400, { error: error.message });
      return json(200, { data: { ok: true } });
    }

    if (action === "delete") {
      const id = body.id;
      if (!(await assertTeacher(id))) return json(403, { error: "Chỉ được thao tác trên tài khoản giáo viên." });
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
