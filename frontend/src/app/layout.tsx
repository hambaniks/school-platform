import type { Metadata } from "next";
import "@/styles/globals.css";

export const metadata: Metadata = {
  title: "SchoolNet v3.0 — School Health & LMS Platform",
  description: "Multi-tenant school management with health oversight, truancy detection, and cyberpunk UI",
  viewport: "width=device-width, initial-scale=1",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-cyber-black text-gray-100 antialiased">{children}</body>
    </html>
  );
}