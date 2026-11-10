import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "TT SPENCE — Your social world", description: "Your people. Your moments. Your world." };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}