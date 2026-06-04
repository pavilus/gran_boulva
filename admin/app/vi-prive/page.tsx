import LegalPage from "@/components/LegalPage";

export const metadata = { title: "Règleman Konfidansyalite — Gran Boulva" };

export default function ViPrivePage() {
  return (
    <LegalPage
      title="Règleman Konfidansyalite"
      subtitle="Politik Vi Prive Gran Boulva"
      effectiveDate="27 Me 2026"
      sections={[
        {
          title: "Enfòmasyon Nou Kolekte",
          content: [
            "Enfòmasyon kont: non prenon, non itilizatè, adrès imel, ak modpas (chiffre — pa janm estoke an tèks klè).",
            "Enfòmasyon pwofil: byografi, foto pwofil, ak preferans lang (Kreyòl ayisyen oswa Anglè).",
            "Done aktivite: vòt, agiman, repons, reyaksyon, prediksyon, sovgad, ak abònman.",
            "Done finansye: istwa achte coins ak dosye tranzaksyon. Detay kat pèman yo trete ekskizivman pa Stripe — Gran Boulva pa janm wè oswa estoke nimewo kat yo.",
            "Done teknik: adrès IP, tip aparèy, vèsyon sistèm operasyon, ak vèsyon aplikasyon.",
            "Kontni itilizatè kreye: tèks agiman, repons, ak deklarasyon prediksyon ou soumèt yo.",
            "Anrejistreman vwa ak videyo: anrejistreman odyo ak klip videyo ou anrejistre epi soumèt kòm agiman oswa prediksyon. Yo telechaje nan estokaj cloud sekirize epi asosye ak kont ou.",
          ],
        },
        {
          title: "Kijan Nou Itilize Enfòmasyon Ou",
          content: [
            "Pou bay, opere, ak amelyore platfòm Gran Boulva a.",
            "Pou trete achte coins, transfè, ak ogmantasyon agiman.",
            "Pou voye notifikasyon nan aplikasyon sou aktivite platfòm (vòt, repons, mansyon).",
            "Pou aplike Kondisyon Sèvis ak Politik Itilizasyon Akseptab nou yo.",
            "Pou estoke ak bay aksè nan anrejistreman vwa ak videyo itilizatè yo soumèt.",
            "Pou detekte fwòd, abi, ak kenbe sekirite platfòm lan.",
            "Pou jenere estatistik agrege ak anonim sou itilizasyon platfòm lan.",
            "Pou konfòme ak lwa ak obligasyon legal ki aplikab yo.",
          ],
        },
        {
          title: "Enfòmasyon Nou Pataje",
          content: `Nou pa vann enfòmasyon pèsonèl ou. Nou pataje done sèlman ak founisè sèvis sa yo ki travay pou kont nou:

• Supabase (baz done ak otantifikasyon) — done yo estoke sou sèvè Amazon Web Services nan rejyon us-east-1 (Nò Vijinya). Supabase aji kòm pwosesè done anba yon Akò Trete Done.

• Stripe (trete pèman) — nou pataje done tranzaksyon ki nesesè pou trete achte coins. Stripe sètifye PCI-DSS Nivo 1.

• OpenAI (jenerasyon kontni AI) — nou itilize API OpenAI pou jenere esbo matchups via fonksyon Scout. Pa gen done pèsonèl itilizatè (non, imel, kontni) ki voye bay OpenAI.

• Supabase Storage / AWS S3 (estokaj medya) — anrejistreman vwa ak videyo yo estoke nan bokit cloud sekirize. Fichye yo aksesib sèlman via URL siyen oswa piblik platfòm nou an jenere.

Nou ka divige enfòmasyon si lwa, lòd tribinal, oswa pou pwoteje dwa ak sekirite Gran Boulva ak itilizatè li yo egzije li.`,
        },
        {
          title: "Konsèvasyon Done",
          content: `Nou konsève done pèsonèl ou pandan kont ou aktif. Si ou efase kont ou, nou pral efase enfòmasyon pèsonèl ou nan 90 jou, eksepte kote konsèvasyon egzije pa lwa (pa egzanp, dosye tranzaksyon pèman ki egzije pou konfòmite finansye ka konsève pou jiska 7 ane).

Kontni ou te poste (agiman, repons) ka rete vizib nan fòm anonim oswa efase apre efasman kont, depan de kontèks platfòm lan.

Anrejistreman vwa ak videyo ou te soumèt kòm agiman yo efase nan sèvè estokaj nou lè agiman ki asosye a efase oswa lè kont ou efase, nan 90 jou.`,
        },
        {
          title: "Dwa Ou",
          content: [
            "Aksè: mande yon kopi done pèsonèl nou genyen sou ou.",
            "Kòreksyon: mande nou korije done ki pa egzak oswa ki pa konplè.",
            "Efasman: mande efasman kont ou ak done pèsonèl ki asosye yo.",
            "Pòtabilite: mande done ou nan yon fòma pòtab, ki lisib pa machin.",
            "Objeksyon: objekte kèk tip trete (tankou pwofil).",
            "Restriksyon: mande nou limite trete done ou nan sèten sikonstans.",
            "Pou egzèse nenpòt dwa, kontakte nou nan: support@granboulva.com. Nou pral reponn nan 30 jou.",
          ],
        },
        {
          title: "Vi Prive Timoun",
          content: `Gran Boulva pa dirije bay timoun ki poko gen 13 an. Nou pa konnyans kolekte enfòmasyon pèsonèl timoun ki poko gen 13 an. Si ou nan Inyon Ewopeyen, ou dwe gen omwen 16 an, oswa gen konsantman paran verifye, pou itilize Gran Boulva.

Si nou reyalize nou te kolekte enfòmasyon timoun ki poko gen laj aplikab la san vle, nou pral efase li rapidman. Kontakte nou nan support@granboulva.com si ou kwè nou gen done konsa.`,
        },
        {
          title: "Transfè Done Entènasyonal",
          content: `Gran Boulva opere depi Etazini. Done yo estoke sou sèvè Supabase/AWS nan Etazini (us-east-1). Lè ou kreye yon kont, ou konsanti pou transfè enfòmasyon pèsonèl ou ale Etazini, ki ka gen lwa pwoteksyon done diferan ak peyi rezidans ou.

Pou itilizatè UE/EEE, transfè yo kouvri pa kloz kontraktyèl estanda (SCC) jan Akò Trete Done Supabase a prevwa.`,
        },
        {
          title: "CCPA — Rezidan Kalifòni",
          content: `Si ou se yon rezidan Kalifòni, ou gen dwa adisyonèl anba California Consumer Privacy Act (CCPA):

• Dwa pou Konnen: mande divulgasyon kategori ak enfòmasyon pèsonèl espesifik nou kolekte, sous yo, rezon biznis yo, ak twazyèm pati nou pataje yo.
• Dwa pou Efase: mande efasman enfòmasyon pèsonèl ou (sijè a sèten eksepsyon).
• Dwa pou Refize Lavant: Gran Boulva pa vann enfòmasyon pèsonèl. Ou pa bezwen refize.
• Dwa a Non-Diskriminasyon: nou pap diskrete kont ou pou egzèse dwa CCPA ou yo.

Pou soumèt yon demann, imel support@granboulva.com ak "CCPA Request" nan sijè a.`,
        },
        {
          title: "RGPD — Itilizatè UE / EEE",
          content: `Baz legal nou pou trete done pèsonèl anba Règleman Jeneral sou Pwoteksyon Done (RGPD) yo se:

• Egzekisyon kontra: trete ki nesesè pou bay sèvis Gran Boulva ou enskri pou li a.
• Enterè lejitim: siveyans sekirite, prevansyon fwòd, ak amelyorasyon platfòm lan.
• Konsantman: kominikasyon maketing (ou ka retire konsantman an nenpòt ki lè).

Kontak Pwoteksyon Done nou an: support@granboulva.com. Ou gen dwa tou pou depoze yon plent bay otorite sipèvizyon lokal ou.`,
        },
        {
          title: "Sekirite",
          content: `Nou aplike mezi sekirite estanda endistriyèl ki enkli:
• Tout done transmèt sou HTTPS / chiffraj TLS.
• Modpas chiffre itilize bcrypt via Supabase Auth — pa janm estoke an tèks klè.
• Politik sekirite nivo ranje (RLS) sou tout tab baz done yo.
• Anrejistreman vwa ak videyo estoke nan estokaj cloud kontwole aksè ak pèmisyon chemen ki mare ak kont itilizatè ki telechaje a.
• Aksè nan sistèm pwodiksyon yo restreint bay pèsonèl otorize sèlman.

Pa gen sistèm ki 100% sekirize. Nan ka yon vyolasyon done ki afekte dwa ou, nou pral avèti ou jan lwa ki aplikab egzije li.`,
        },
        {
          title: "Chanjman nan Règleman Sa",
          content: `Nou ka mete ajou Règleman Konfidansyalite sa de tan an tan. Nou pral avèti ou sou chanjman enpòtan yo lè nou voye yon notifikasyon nan aplikasyon oswa pa imel omwen 14 jou anvan chanjman yo antre an vigè. Kontinye itilize Gran Boulva apre dat sa konstitye akseptasyon règleman mete ajou a.

Kontak: support@granboulva.com`,
        },
      ]}
    />
  );
}
