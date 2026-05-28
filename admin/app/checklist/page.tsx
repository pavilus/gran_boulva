import type { Metadata } from "next";
import ChecklistClient from "./ChecklistClient";

export const metadata: Metadata = {
  title: "Beta Test Checklist — Gran Boulva",
  description: "Gid pou testè beta Gran Boulva",
};

export default function ChecklistPage() {
  return <ChecklistClient />;
}
