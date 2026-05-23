-- Insert default welcome_confirmed email template (idempotent)
insert into public.email_templates (name, subject, body_text, body_html, signature_html)
values (
  'welcome_confirmed',
  'Byenveni sou Gran Boulva! 🎉',
  E'Ou konfime adrès imèl ou. Kounye a ou ka debat, vote, ak monte nan klasman.\n\nTélécharge aplikasyon an epi konekte ak kominote Ayisyen an ki pale, ki vote, ki fè bagay chanje!\n\n— Ekip Gran Boulva',
  '<p style="font-size:15px;line-height:1.6;color:#374151;">
    Ou konfime adrès imèl ou. <strong>Kounye a ou ka debat, vote, ak monte nan klasman.</strong>
  </p>
  <p style="font-size:15px;line-height:1.6;color:#374151;margin-top:14px;">
    Konekte ak kominote Ayisyen an ki pale, ki vote, ki fè bagay chanje!
  </p>
  <div style="margin:24px 0;">
    <a href="https://granboulva.com"
       style="display:inline-block;background:linear-gradient(90deg,#7c3aed,#ec4899);color:#fff;font-weight:700;font-size:14px;padding:12px 28px;border-radius:10px;text-decoration:none;">
      Louvri Gran Boulva
    </a>
  </div>',
  '<p style="font-size:14px;color:#4b5563;">
    Mèsi dèske ou fè pati Gran Boulva.<br/>
    Si ou pa kreye kont sa a, ignore mesaj sa a.
  </p>'
)
on conflict (name) do nothing;
