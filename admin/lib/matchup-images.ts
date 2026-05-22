import { readFile } from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

type MatchupOption = {
  id: string;
  option_label: string;
  option_name: string;
};

export type ImageGeneratorMatchup = {
  id: string;
  title_ht: string;
  description_ht?: string | null;
  options: MatchupOption[];
};

const imageModel = "gpt-image-1.5";
const optionSize = "1024x1536";

function optionPrompt(matchup: ImageGeneratorMatchup, option: MatchupOption) {
  const side = option.option_label === "A" ? "left" : "right";
  const palette =
    side === "left"
      ? "cold purple, electric blue, dark navy, storm highlights"
      : "warm magenta, red, pink, sunset orange highlights";

  return `Create one premium cinematic debate-card image for Gran Boulva.

Matchup question: ${matchup.title_ht}
This image represents option ${option.option_label}: ${option.option_name}
${matchup.description_ht ? `Context: ${matchup.description_ht}` : ""}

Requirements:
- Produce a single ${side}-side option image for a mobile social debate card.
- Use dramatic realistic storytelling and culturally believable Haitian or Caribbean context when relevant.
- Palette and mood: ${palette}; cinematic depth; emotional documentary realism.
- Keep the subject readable when cropped into a vertical option panel.
- No typography, no labels, no buttons, no percentages, no logos, no watermark.
- No distorted anatomy, duplicated faces, fake-looking crowds, or clutter.
- Leave visual breathing room near the outer edges for app overlays.`;
}

function compositeSafeText(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function wrapWords(text: string, maxChars: number) {
  const words = text.trim().split(/\s+/);
  const lines: string[] = [];
  let line = "";

  for (const word of words) {
    const next = line ? `${line} ${word}` : word;
    if (next.length <= maxChars || !line) {
      line = next;
    } else {
      lines.push(line);
      line = word;
    }
  }

  if (line) lines.push(line);
  return lines.slice(0, 3);
}

function titleSvg(title: string, y: number, width: number, size: number) {
  const lines = wrapWords(title, width > 1100 ? 34 : 29);
  return lines
    .map(
      (line, index) =>
        `<text x="50%" y="${y + index * (size + 10)}" text-anchor="middle" font-size="${size}" font-weight="800" fill="#ffffff">${compositeSafeText(line)}</text>`,
    )
    .join("");
}

function shortOption(optionName: string) {
  const trimmed = optionName.trim();
  if (trimmed.length <= 22) return trimmed.toUpperCase();
  return `${trimmed.slice(0, 21).trimEnd()}...`.toUpperCase();
}

async function brandLogoDataUri() {
  const logo = await readFile(
    path.join(process.cwd(), "..", "assets", "images", "logo_email.png"),
  );
  return `data:image/png;base64,${logo.toString("base64")}`;
}

async function generatedImage(prompt: string) {
  const openaiKey = process.env.OPENAI_API_KEY;
  if (!openaiKey) throw new Error("OPENAI_API_KEY is not set");

  const response = await fetch("https://api.openai.com/v1/images/generations", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openaiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: imageModel,
      prompt,
      size: optionSize,
      quality: "high",
      output_format: "png",
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI image generation failed: ${await response.text()}`);
  }

  const json = (await response.json()) as { data?: Array<{ b64_json?: string }> };
  const base64 = json.data?.[0]?.b64_json;
  if (!base64) throw new Error("OpenAI image generation returned no image");
  return Buffer.from(base64, "base64");
}

function cardSvg({
  width,
  height,
  matchup,
  optionA,
  optionB,
  logo,
  shareVersion,
}: {
  width: number;
  height: number;
  matchup: ImageGeneratorMatchup;
  optionA: MatchupOption;
  optionB: MatchupOption;
  logo: string;
  shareVersion: boolean;
}) {
  const landscape = width > height;
  const cardY = landscape ? 350 : 770;
  const cardWidth = landscape ? 285 : 360;
  const cardHeight = landscape ? 210 : 365;
  const leftX = landscape ? 210 : 74;
  const rightX = width - leftX - cardWidth;
  const centerX = width / 2;
  const headerSize = landscape ? 48 : 62;
  const titleY = landscape ? 108 : 168;
  const logoSize = landscape ? 74 : 96;
  const footerY = height - (landscape ? 92 : 132);
  const downloadX = landscape ? width - 160 : width - 210;

  return Buffer.from(`<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="14" stdDeviation="18" flood-color="#05010f" flood-opacity="0.82"/>
    </filter>
    <filter id="glow" x="-80%" y="-80%" width="260%" height="260%">
      <feGaussianBlur stdDeviation="16" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <linearGradient id="leftCard" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#1d0b65" stop-opacity=".96"/>
      <stop offset="1" stop-color="#07031d" stop-opacity=".96"/>
    </linearGradient>
    <linearGradient id="rightCard" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#8f103d" stop-opacity=".96"/>
      <stop offset="1" stop-color="#25020f" stop-opacity=".96"/>
    </linearGradient>
  </defs>
  <style>
    text { font-family: Inter, Arial, sans-serif; letter-spacing: 0; }
  </style>
  <rect width="100%" height="100%" fill="rgba(4,3,13,.24)"/>
  <path d="M ${centerX - 60} 0 L ${centerX + 42} 0 L ${centerX - 55} ${height} L ${centerX - 150} ${height} Z" fill="#080312" fill-opacity=".62"/>
  <path d="M ${centerX + 30} 0 L ${centerX - 54} ${height}" stroke="#ff35c9" stroke-width="${landscape ? 4 : 6}" filter="url(#glow)" opacity=".92"/>
  <g filter="url(#shadow)">
    <rect x="${centerX - 140}" y="${landscape ? 24 : 28}" width="280" height="${landscape ? 48 : 58}" rx="29" fill="#0a0618" fill-opacity=".84" stroke="#5c1b96"/>
    <text x="50%" y="${landscape ? 57 : 68}" text-anchor="middle" font-size="${landscape ? 24 : 28}" font-weight="700" fill="#ffffff">🔥 Matchup Popile</text>
  </g>
  ${titleSvg(matchup.title_ht, titleY, width, headerSize)}
  <text x="50%" y="${landscape ? 258 : 416}" text-anchor="middle" font-size="${landscape ? 28 : 36}" font-weight="800" fill="#b174ff">Vin di saw panse sou Gran Boulva</text>
  <text x="50%" y="${landscape ? 294 : 462}" text-anchor="middle" font-size="${landscape ? 20 : 28}" font-weight="600" fill="#f5ecff">Debat. Vote. Agimante.</text>
  <g filter="url(#shadow)">
    <rect x="${leftX}" y="${cardY}" width="${cardWidth}" height="${cardHeight}" rx="${landscape ? 28 : 34}" fill="url(#leftCard)" stroke="#8d46ff" stroke-width="3"/>
    <circle cx="${leftX + cardWidth / 2}" cy="${cardY + (landscape ? 58 : 92)}" r="${landscape ? 35 : 52}" fill="#4111bc" stroke="#9f78ff" stroke-width="3"/>
    <path d="M ${leftX + cardWidth / 2 - 18} ${cardY + (landscape ? 58 : 92)} l 12 12 l 28 -31" fill="none" stroke="#ffffff" stroke-width="${landscape ? 7 : 10}" stroke-linecap="round" stroke-linejoin="round"/>
    <text x="${leftX + cardWidth / 2}" y="${cardY + (landscape ? 126 : 202)}" text-anchor="middle" font-size="${landscape ? 25 : 33}" font-weight="800" fill="#ffffff">${compositeSafeText(shortOption(optionA.option_name))}</text>
    <rect x="${leftX + 26}" y="${cardY + cardHeight - (landscape ? 62 : 98)}" width="${cardWidth - 52}" height="${landscape ? 40 : 72}" rx="${landscape ? 14 : 20}" fill="#5b15ed"/>
    <text x="${leftX + cardWidth / 2}" y="${cardY + cardHeight - (landscape ? 35 : 51)}" text-anchor="middle" font-size="${landscape ? 22 : 30}" font-weight="700" fill="#ffffff">Wi</text>
  </g>
  <g filter="url(#shadow)">
    <rect x="${rightX}" y="${cardY}" width="${cardWidth}" height="${cardHeight}" rx="${landscape ? 28 : 34}" fill="url(#rightCard)" stroke="#f42b78" stroke-width="3"/>
    <circle cx="${rightX + cardWidth / 2}" cy="${cardY + (landscape ? 58 : 92)}" r="${landscape ? 35 : 52}" fill="#a51249" stroke="#ff70a8" stroke-width="3"/>
    <path d="M ${rightX + cardWidth / 2 - 18} ${cardY + (landscape ? 40 : 74)} l 36 36 M ${rightX + cardWidth / 2 + 18} ${cardY + (landscape ? 40 : 74)} l -36 36" fill="none" stroke="#ffffff" stroke-width="${landscape ? 7 : 10}" stroke-linecap="round"/>
    <text x="${rightX + cardWidth / 2}" y="${cardY + (landscape ? 126 : 202)}" text-anchor="middle" font-size="${landscape ? 25 : 33}" font-weight="800" fill="#ffffff">${compositeSafeText(shortOption(optionB.option_name))}</text>
    <rect x="${rightX + 26}" y="${cardY + cardHeight - (landscape ? 62 : 98)}" width="${cardWidth - 52}" height="${landscape ? 40 : 72}" rx="${landscape ? 14 : 20}" fill="#c91958"/>
    <text x="${rightX + cardWidth / 2}" y="${cardY + cardHeight - (landscape ? 35 : 51)}" text-anchor="middle" font-size="${landscape ? 22 : 30}" font-weight="700" fill="#ffffff">Non</text>
  </g>
  <text x="50%" y="${cardY + (landscape ? 126 : 208)}" text-anchor="middle" font-size="${landscape ? 82 : 110}" font-style="italic" font-weight="900" fill="#ffffff" filter="url(#glow)">VS</text>
  <image href="${logo}" x="${landscape ? 52 : 74}" y="${footerY - logoSize / 2}" width="${logoSize}" height="${logoSize}"/>
  <text x="${landscape ? 142 : 188}" y="${footerY - (landscape ? 8 : 12)}" font-size="${landscape ? 26 : 34}" font-weight="800" fill="#ffffff">Gran Boulva</text>
  <text x="${landscape ? 142 : 188}" y="${footerY + (landscape ? 22 : 28)}" font-size="${landscape ? 18 : 23}" font-weight="600" fill="#d9c8ff">Vwa ou konte</text>
  <text x="${downloadX}" y="${footerY - (landscape ? 8 : 14)}" text-anchor="middle" font-size="${landscape ? 17 : 22}" font-weight="700" fill="#ffffff">Telechaje app la</text>
  <rect x="${downloadX - (landscape ? 74 : 98)}" y="${footerY + (landscape ? 4 : 8)}" width="${landscape ? 148 : 196}" height="${landscape ? 38 : 48}" rx="${landscape ? 12 : 16}" fill="#ffffff"/>
  <text x="${downloadX}" y="${footerY + (landscape ? 30 : 41)}" text-anchor="middle" font-size="${landscape ? 18 : 23}" font-weight="800" fill="#090311">App Store</text>
  ${shareVersion ? "" : `<text x="${width - 42}" y="${height - 26}" text-anchor="end" font-size="16" fill="#a7a0c4">Marketing master</text>`}
</svg>`);
}

async function optionBackdrop(imageA: Buffer, imageB: Buffer, width: number, height: number) {
  const half = Math.ceil(width / 2);
  const [left, right] = await Promise.all([
    sharp(imageA)
      .resize(half, height, { fit: "cover", position: "attention" })
      .modulate({ brightness: 0.82, saturation: 1.12 })
      .toBuffer(),
    sharp(imageB)
      .resize(half, height, { fit: "cover", position: "attention" })
      .modulate({ brightness: 0.82, saturation: 1.14 })
      .toBuffer(),
  ]);

  return sharp({
    create: { width, height, channels: 4, background: "#05020f" },
  })
    .composite([
      { input: left, left: 0, top: 0 },
      { input: right, left: width - half, top: 0 },
    ])
    .toBuffer();
}

export async function generateOptionImages(matchup: ImageGeneratorMatchup) {
  const optionA = matchup.options.find((option) => option.option_label === "A");
  const optionB = matchup.options.find((option) => option.option_label === "B");
  if (!optionA || !optionB) throw new Error("Matchup requires options A and B");

  const prompts = [optionPrompt(matchup, optionA), optionPrompt(matchup, optionB)];
  const [imageA, imageB] = await Promise.all(prompts.map(generatedImage));
  return { imageA, imageB, optionA, optionB, prompts };
}

export async function renderCompositeImages({
  matchup,
  optionA,
  optionB,
  imageA,
  imageB,
}: {
  matchup: ImageGeneratorMatchup;
  optionA: MatchupOption;
  optionB: MatchupOption;
  imageA: Buffer;
  imageB: Buffer;
}) {
  const logo = await brandLogoDataUri();
  const poster = { width: 1080, height: 1350 };
  const share = { width: 1200, height: 630 };
  const [posterBackdrop, shareBackdrop] = await Promise.all([
    optionBackdrop(imageA, imageB, poster.width, poster.height),
    optionBackdrop(imageA, imageB, share.width, share.height),
  ]);

  const [posterImage, shareImage] = await Promise.all([
    sharp(posterBackdrop)
      .composite([
        {
          input: cardSvg({
            ...poster,
            matchup,
            optionA,
            optionB,
            logo,
            shareVersion: false,
          }),
        },
      ])
      .png()
      .toBuffer(),
    sharp(shareBackdrop)
      .composite([
        {
          input: cardSvg({
            ...share,
            matchup,
            optionA,
            optionB,
            logo,
            shareVersion: true,
          }),
        },
      ])
      .png()
      .toBuffer(),
  ]);

  return { posterImage, shareImage };
}

export const matchupImageModel = imageModel;
