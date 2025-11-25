// @ts-nocheck
// Supabase Edge Function: create_admin_user
// Creates (or reuses) a Supabase Auth user and upserts a matching admin_profiles row.
// Requires env vars: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.3";

type CreateAdminBody = {
  email: string;
  name: string;
  role: "admin" | "super_admin";
  isActive?: boolean;
  strategy?: "auto" | "invite" | "temp_password"; // default: auto
  redirectTo?: string; // used for invite strategy
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(status: number, data: unknown) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

function randomPassword(len = 24) {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_-+=";
  let out = "";
  const array = new Uint32Array(len);
  crypto.getRandomValues(array);
  for (let i = 0; i < len; i++) out += chars[array[i] % chars.length];
  return out;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY } = Deno.env.toObject();
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY) {
      return json(500, { error: "Missing env vars (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY)" });
    }

    // User client: identify the caller from the Authorization header
    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const { data: authData, error: authErr } = await userClient.auth.getUser();
    if (authErr || !authData?.user) {
      return json(401, { error: "Unauthorized" });
    }
    const caller = authData.user;

    // Service client: admin operations (Auth Admin API, bypass RLS for controlled writes)
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Check caller is super_admin
    {
      const { data: callerProfile, error } = await adminClient
        .from("admin_profiles")
        .select("id, role")
        .eq("id", caller.id)
        .maybeSingle();
      if (error) return json(500, { error: "Failed to read caller profile", details: error.message });
      if (!callerProfile || callerProfile.role !== "super_admin") {
        return json(403, { error: "Forbidden: super_admin only" });
      }
    }

    // Parse and validate payload
      const body = (await req.json()) as any;
    const email = body.email ? normalizeEmail(body.email) : "";
      // Support delete operation via action flag (super_admin only)
      if (body?.action === "delete_admin") {
        const targetId: string | undefined = body?.id?.toString();
        if (!targetId) return json(400, { error: "Missing id" });

        // Delete Auth user
        try {
          await (adminClient.auth.admin as any).deleteUser(targetId);
        } catch (e) {
          // If deleteUser fails because user missing, continue to profile cleanup
        }

        // Delete profile row
        try {
          await adminClient.from("admin_profiles").delete().eq("id", targetId);
        } catch (_) {}

        // Log activity
        try {
          await adminClient.from("admin_activity_logs").insert({
            actor_id: caller.id,
            action: "admin_deleted",
            target_type: "admin",
            target_id: targetId,
            details: {},
          });
        } catch (_) {}

        return json(200, { deleted: true, id: targetId });
      }
    const name = (body.name ?? "").trim();
    const role = (body.role ?? "admin") as "admin" | "super_admin";
    const isActive = body.isActive ?? true;
  const strategy = (body.strategy ?? "auto") as "auto" | "invite" | "temp_password";
    const redirectTo = body.redirectTo?.trim();

    if (!email || !name) return json(400, { error: "Missing required fields: email, name" });
    if (!["admin", "super_admin"].includes(role)) return json(400, { error: "Invalid role" });

    // 1) Get or create Auth user
    let targetUserId: string | null = null;
  let created = false;
  let invited = false;

    // Try to find by email first using listUsers (works across SDK versions)
    try {
      const { data: listData, error: listErr } = await (adminClient.auth.admin as any).listUsers({
        page: 1,
        perPage: 1,
        email,
      });
      if (!listErr) {
        const users = (listData as any)?.users ?? [];
        const match = users.find((u: any) => (u?.email ?? "").toLowerCase() === email);
        if (match?.id) {
          targetUserId = match.id as string;
        }
      }
    } catch (_) {
      // ignore, fallback to create/invite
    }

  let recoveryLink: string | null = null;
  let tempPasswordToReturn: string | null = null;

    if (!targetUserId) {
      if (strategy === "invite") {
        const { data: invite, error: inviteErr } = await adminClient.auth.admin.inviteUserByEmail(email, {
          redirectTo,
        });
        if (inviteErr) return json(500, { error: "Invite failed", details: inviteErr.message });
        targetUserId = invite.user?.id ?? null;
        invited = true;
        created = true;
      } else { // auto or temp_password
        // Auto-confirm: create with a random temp password and email_confirm=true
        const tempPassword = randomPassword();
        const { data: createdUser, error: createErr } = await adminClient.auth.admin.createUser({
          email,
          password: tempPassword,
          email_confirm: true,
          user_metadata: { name },
        });
        if (createErr) return json(500, { error: "Create user failed", details: createErr.message });
        targetUserId = createdUser.user?.id ?? null;
        created = true;
        // Optional: trigger a password reset flow separately if you wish.
        // If strategy is temp_password, try to email the password directly below.
        if (strategy === "temp_password") {
          // Do not email for now; return the temp password in the response so UI can display it
          tempPasswordToReturn = tempPassword;
        } else if (strategy === "auto" && redirectTo) {
          // Optionally, also send a recovery link in auto mode if redirectTo provided
          try {
            const { data: linkRes } = await (adminClient.auth.admin as any).generateLink({
              type: "recovery",
              email,
              options: { redirectTo },
            });
            const props = (linkRes as any)?.properties ?? {};
            recoveryLink = props.action_link ?? (linkRes as any)?.action_link ?? null;
          } catch (_) {}
        }
      }
    } else {
      // User exists already
      if (strategy === "invite") {
        // Send a recovery link so the existing user can set (or reset) password
        try {
          const { data: linkRes, error: linkErr } = await (adminClient.auth.admin as any).generateLink({
            type: "recovery",
            email,
            options: redirectTo ? { redirectTo } : undefined,
          });
          if (!linkErr) {
            const props = (linkRes as any)?.properties ?? {};
            recoveryLink = props.action_link ?? (linkRes as any)?.action_link ?? null;
          }
        } catch (_) {
          // ignore; recovery link optional
        }
      } else if (strategy === "temp_password") {
        // Rotate password to a new temporary one and email it
        const tempPassword = randomPassword();
        const { error: updateErr } = await adminClient.auth.admin.updateUserById(targetUserId, {
          password: tempPassword,
        });
        if (updateErr) return json(500, { error: "Update password failed", details: updateErr.message });
        // Do not email for now; return the temp password in the response so UI can display it
        tempPasswordToReturn = tempPassword;
      }
    }

    if (!targetUserId) return json(500, { error: "No user id returned from Auth Admin API" });

    // 2) Upsert profile row (id must equal auth user id)
    {
      const { error: upsertErr } = await adminClient
        .from("admin_profiles")
        .upsert(
          { id: targetUserId, email, name, role, is_active: isActive },
          { onConflict: "id" },
        );
      if (upsertErr) return json(500, { error: "Profile upsert failed", details: upsertErr.message });
    }

    // 3) Log activity (optional but helpful)
    try {
      await adminClient.from("admin_activity_logs").insert({
        actor_id: caller.id,
        action: created ? "admin_created" : "admin_linked",
        target_type: "admin",
        target_id: targetUserId,
        details: { email, name, role, is_active: isActive, invited },
      });
    } catch (_) {
      // Non-fatal
    }

  return json(200, { userId: targetUserId, created, invited, recoveryLink, tempPassword: tempPasswordToReturn });
  } catch (e) {
    return json(500, { error: "Unexpected error", details: String(e) });
  }
});

// Attempt to email the temporary password via Resend or SendGrid if configured.
async function sendPasswordEmail(args: { email: string; name: string; tempPassword: string }) {
  try {
    const env = Deno.env.toObject();
    const from = env.MAIL_FROM || "no-reply@example.com";
    const appName = env.APP_NAME || "Milpress";
    const loginUrl = env.APP_LOGIN_URL || env.SUPABASE_URL || "";
    const subject = `${appName} admin account`;
    const text = `Hello ${args.name},\n\nYour ${appName} admin account has been created.\n\nEmail: ${args.email}\nTemporary password: ${args.tempPassword}\n\nYou can log in here: ${loginUrl}\nPlease change your password after logging in.\n`;
    const html = `
      <p>Hello ${escapeHtml(args.name)},</p>
      <p>Your ${escapeHtml(appName)} admin account has been created.</p>
      <p><strong>Email:</strong> ${escapeHtml(args.email)}<br/>
         <strong>Temporary password:</strong> ${escapeHtml(args.tempPassword)}</p>
      <p>You can log in here: <a href="${escapeAttr(loginUrl)}">${escapeHtml(loginUrl)}</a></p>
      <p>Please change your password after logging in.</p>
    `;

    const resend = env.RESEND_API_KEY;
    if (resend) {
      await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${resend}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from,
          to: args.email,
          subject,
          text,
          html,
        }),
      });
      return;
    }

    const sendgrid = env.SENDGRID_API_KEY;
    if (sendgrid) {
      await fetch("https://api.sendgrid.com/v3/mail/send", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${sendgrid}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          personalizations: [{ to: [{ email: args.email }] }],
          from: { email: from },
          subject,
          content: [
            { type: "text/plain", value: text },
            { type: "text/html", value: html },
          ],
        }),
      });
      return;
    }
    // If no email provider configured, silently skip.
  } catch (_) {
    // Ignore email errors (don’t fail the whole request)
  }
}

function escapeHtml(s: string) {
  return s.replace(/[&<>"]+/g, (m) => ({"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[m] as string));
}
function escapeAttr(s: string) {
  return escapeHtml(s).replace(/'/g, "&#39;");
}
