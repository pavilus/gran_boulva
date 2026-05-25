import { NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  try {
    const body = await req.json() as {
      name?: string;
      email?: string;
      phone_number?: string;
      country?: string;
      profession?: string;
      business_background?: string;
      linkedin_url?: string;
      why_interested?: string;
      strategic_skills?: string;
      interests?: string[];
      investment_range?: string;
      industry_expertise?: string;
      audience_size?: string;
      stripe_session_id?: string;
    };

    // Required field validation
    if (!body.name?.trim())            return NextResponse.json({ error: "Name is required" },    { status: 400 });
    if (!body.email?.trim())           return NextResponse.json({ error: "Email is required" },   { status: 400 });
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email))
                                       return NextResponse.json({ error: "Invalid email" },        { status: 400 });
    if (!body.why_interested?.trim())  return NextResponse.json({ error: "Please explain your interest" }, { status: 400 });
    if (!body.interests?.length)       return NextResponse.json({ error: "Select at least one interest area" }, { status: 400 });

    const supabase = createAdminClient();
    const { error } = await supabase.from("partner_applications").insert({
      name:                body.name.trim(),
      email:               body.email.trim().toLowerCase(),
      phone_number:        body.phone_number?.trim()         || null,
      country:             body.country?.trim()              || null,
      profession:          body.profession?.trim()           || null,
      business_background: body.business_background?.trim()  || null,
      linkedin_url:        body.linkedin_url?.trim()         || null,
      why_interested:      body.why_interested.trim(),
      strategic_skills:    body.strategic_skills?.trim()     || null,
      interests:           body.interests,
      investment_range:    body.investment_range?.trim()     || null,
      industry_expertise:  body.industry_expertise?.trim()   || null,
      audience_size:       body.audience_size?.trim()        || null,
      stripe_session_id:   body.stripe_session_id            || null,
    });

    if (error) {
      // Duplicate session = already submitted
      if (error.code === "23505") return NextResponse.json({ ok: true, already: true });
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
