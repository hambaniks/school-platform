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
      <body className="min-h-screen bg-gray-50 text-gray-900 antialiased">
        {children}
        <Footer />
      </body>
    </html>
  );
}