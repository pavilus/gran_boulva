import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        bg: {
          base: "#07080f",
          card: "#0e0f1e",
          hover: "#13152a",
          border: "#1e2040",
        },
        purple: {
          DEFAULT: "#7c3aed",
          light: "#a78bfa",
          dim: "#2d1b69",
          glow: "rgba(124,58,237,0.25)",
        },
        pink: {
          DEFAULT: "#ec4899",
          light: "#f9a8d4",
          dim: "#4a1942",
        },
        accent: {
          green: "#10b981",
          orange: "#f59e0b",
          red: "#ef4444",
        },
      },
      fontFamily: {
        sans: ["Inter", "sans-serif"],
      },
      boxShadow: {
        card: "0 0 0 1px rgba(124,58,237,0.15), 0 4px 24px rgba(0,0,0,0.4)",
        glow: "0 0 20px rgba(124,58,237,0.3)",
      },
    },
  },
  plugins: [],
};

export default config;
