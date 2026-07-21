import type { Metadata } from "next";
import "@/styles/globals.css";
import { Footer } from "@/components/layout/Footer";

export const metadata: Metadata = {
  title: "SchoolNet v3.0 — School Health & LMS Platform",
  description: "Multi-tenant school management platform",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-cyber-black text-gray-100 antialiased flex min-h-screen flex-col">
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}