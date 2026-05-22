"use client";

import { useState, useRef, useEffect } from "react";
import { DayPicker } from "react-day-picker";
import { format, parse, isValid } from "date-fns";
import { CalendarDays, X } from "lucide-react";

// ─── Inline styles for react-day-picker dark theme ────────────────────────────
// We don't import the CSS file because it conflicts with our dark theme.
// Instead we pass classNames-based inline CSS via a <style> tag.

const PICKER_CSS = `
.rdp-root {
  --rdp-accent-color: #a855f7;
  --rdp-accent-background-color: rgba(168,85,247,0.18);
  --rdp-day-height: 36px;
  --rdp-day-width: 36px;
  --rdp-day_button-height: 34px;
  --rdp-day_button-width: 34px;
  --rdp-day_button-border-radius: 8px;
  --rdp-selected-border: none;
  --rdp-outside-opacity: 0.3;
  --rdp-weekday-opacity: 0.5;
  --rdp-range_middle-background-color: rgba(168,85,247,0.10);
  --rdp-today-color: #a855f7;
  color: #e2e8f0;
  font-size: 13px;
}
.rdp-root button {
  color: #e2e8f0;
  background: transparent;
  border: none;
  cursor: pointer;
}
.rdp-root button:hover:not([disabled]) {
  background: rgba(168,85,247,0.15);
  border-radius: 8px;
}
.rdp-selected .rdp-day_button {
  background: #a855f7 !important;
  color: #fff !important;
  border-radius: 8px;
}
.rdp-today:not(.rdp-selected) .rdp-day_button {
  color: #a855f7;
  font-weight: 700;
}
.rdp-month_caption {
  color: #fff;
  font-weight: 600;
  padding: 4px 0 8px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.rdp-nav {
  display: flex;
  gap: 4px;
}
.rdp-nav button {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #94a3b8;
}
.rdp-weekday {
  color: #64748b;
  font-size: 11px;
  font-weight: 500;
  text-transform: uppercase;
}
.rdp-outside {
  opacity: 0.3;
}
`;

// ─── Props ────────────────────────────────────────────────────────────────────
interface DatePickerProps {
  /** YYYY-MM-DD string (or empty string / undefined for no date) */
  value: string | null | undefined;
  /** Called with a YYYY-MM-DD string when a date is chosen, or "" to clear */
  onChange: (val: string) => void;
  placeholder?: string;
}

// ─── Component ────────────────────────────────────────────────────────────────
export default function DatePicker({ value, onChange, placeholder = "Chwazi dat…" }: DatePickerProps) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  // Parse the YYYY-MM-DD string into a JS Date for DayPicker
  const selected: Date | undefined = (() => {
    if (!value) return undefined;
    const d = parse(value.slice(0, 10), "yyyy-MM-dd", new Date());
    return isValid(d) ? d : undefined;
  })();

  // Close popover when clicking outside
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleSelect = (date: Date | undefined) => {
    if (!date) { onChange(""); setOpen(false); return; }
    onChange(format(date, "yyyy-MM-dd"));
    setOpen(false);
  };

  const clear = (e: React.MouseEvent) => {
    e.stopPropagation();
    onChange("");
  };

  const displayLabel = selected ? format(selected, "dd MMM yyyy") : "";

  return (
    <div ref={ref} className="relative w-full">
      {/* Inject picker CSS once */}
      <style>{PICKER_CSS}</style>

      {/* Trigger button */}
      <button
        type="button"
        onClick={() => setOpen(v => !v)}
        className="w-full flex items-center gap-2 text-sm rounded-xl px-3 py-2 text-left"
        style={{
          background: "#0e0f1e",
          border: "1px solid #1e2040",
          color: displayLabel ? "#e2e8f0" : "#475569",
          minHeight: 38,
        }}
      >
        <CalendarDays size={14} style={{ color: "#64748b", flexShrink: 0 }} />
        <span className="flex-1 truncate">{displayLabel || placeholder}</span>
        {displayLabel && (
          <span onClick={clear} className="ml-1 hover:text-red-400" style={{ color: "#64748b" }}>
            <X size={13} />
          </span>
        )}
      </button>

      {/* Calendar popover */}
      {open && (
        <div
          className="absolute z-50 mt-1 rounded-2xl p-4 shadow-2xl"
          style={{
            background: "#0e0f1e",
            border: "1px solid #1e2040",
            minWidth: 280,
          }}
        >
          <DayPicker
            mode="single"
            selected={selected}
            onSelect={handleSelect}
            defaultMonth={selected ?? new Date()}
            showOutsideDays
          />
        </div>
      )}
    </div>
  );
}
