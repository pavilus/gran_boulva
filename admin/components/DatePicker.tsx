"use client";

import { forwardRef } from "react";
import ReactDatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { parse, isValid, format } from "date-fns";
import { CalendarDays } from "lucide-react";

// ─── Dark-theme overrides ─────────────────────────────────────────────────────
const CSS = `
.dp-wrap { position: relative; width: 100%; }
.dp-wrap .dp-input {
  width: 100%;
  background: #0e0f1e;
  border: 1px solid #2e3060;
  color: #e2e8f0;
  border-radius: 12px;
  padding: 8px 12px 8px 34px;
  font-size: 13px;
  outline: none;
  min-height: 38px;
  box-sizing: border-box;
}
.dp-wrap .dp-input::placeholder { color: #475569; }
.dp-wrap .dp-input:focus { border-color: #7c3aed; }
.dp-wrap .dp-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #64748b;
  pointer-events: none;
}
.dp-dark .react-datepicker {
  background: #0e0f1e;
  border: 1px solid #2e3060;
  border-radius: 14px;
  font-family: inherit;
  font-size: 13px;
  color: #e2e8f0;
  box-shadow: 0 8px 32px rgba(0,0,0,0.5);
  overflow: hidden;
}
.dp-dark .react-datepicker__triangle { display: none; }
.dp-dark .react-datepicker__header {
  background: #13152a;
  border-bottom: 1px solid #2e3060;
  padding: 12px 0 8px;
  border-radius: 14px 14px 0 0;
}
.dp-dark .react-datepicker__current-month {
  color: #fff;
  font-weight: 600;
  font-size: 13px;
  margin-bottom: 6px;
}
.dp-dark .react-datepicker__navigation-icon::before {
  border-color: #64748b;
}
.dp-dark .react-datepicker__navigation:hover .react-datepicker__navigation-icon::before {
  border-color: #a855f7;
}
.dp-dark .react-datepicker__day-name {
  color: #64748b;
  font-size: 11px;
  width: 34px;
  line-height: 28px;
  text-transform: uppercase;
}
.dp-dark .react-datepicker__day {
  color: #cbd5e1;
  width: 34px;
  line-height: 34px;
  border-radius: 8px;
  margin: 1px;
}
.dp-dark .react-datepicker__day:hover {
  background: rgba(168,85,247,0.15);
  color: #e2e8f0;
  border-radius: 8px;
}
.dp-dark .react-datepicker__day--selected,
.dp-dark .react-datepicker__day--keyboard-selected {
  background: #a855f7 !important;
  color: #fff !important;
  font-weight: 600;
  border-radius: 8px;
}
.dp-dark .react-datepicker__day--today {
  color: #a855f7;
  font-weight: 700;
}
.dp-dark .react-datepicker__day--today.react-datepicker__day--selected {
  color: #fff;
}
.dp-dark .react-datepicker__day--outside-month { color: #334155; }
.dp-dark .react-datepicker__close-icon::after {
  background-color: #475569;
  font-size: 11px;
}
.dp-dark .react-datepicker__close-icon:hover::after { background-color: #ef4444; }
.dp-dark .react-datepicker__month { margin: 6px; }
.dp-dark .react-datepicker__month-container { float: none; }
`;

// ─── Props ────────────────────────────────────────────────────────────────────
interface DatePickerProps {
  value: string | null | undefined;
  onChange: (val: string) => void;
  placeholder?: string;
}

// ─── Typed custom input (allows keyboard entry + calendar toggle) ──────────────
const TypeableInput = forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(
  (props, ref) => (
    <div className="dp-wrap">
      <CalendarDays size={14} className="dp-icon" />
      <input ref={ref} {...props} className="dp-input" />
    </div>
  )
);
TypeableInput.displayName = "TypeableInput";

// ─── Component ────────────────────────────────────────────────────────────────
export default function DatePicker({ value, onChange, placeholder = "Chwazi dat…" }: DatePickerProps) {
  const selected: Date | null = (() => {
    if (!value) return null;
    const d = parse(value.slice(0, 10), "yyyy-MM-dd", new Date());
    return isValid(d) ? d : null;
  })();

  const handleChange = (date: Date | null) => {
    onChange(date ? format(date, "yyyy-MM-dd") : "");
  };

  return (
    <>
      <style>{CSS}</style>
      <div className="dp-dark">
        <ReactDatePicker
          selected={selected}
          onChange={handleChange}
          dateFormat="yyyy-MM-dd"
          placeholderText={placeholder}
          isClearable
          showPopperArrow={false}
          popperPlacement="bottom-start"
          customInput={<TypeableInput placeholder={placeholder} />}
        />
      </div>
    </>
  );
}
