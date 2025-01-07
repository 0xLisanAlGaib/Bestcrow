"use client";

import Link from "next/link";
import { Search } from "lucide-react";
import { ConnectKitButton } from "connectkit";

export function Header() {
  return (
    <header className="bg-gray-800 py-4 absolute top-0 left-0 right-0 z-50">
      <div className="container mx-auto px-4 flex justify-between items-center">
        <Link href="/" className="text-2xl font-bold text-white">
          Bestcrow
        </Link>
        <nav className="flex items-center space-x-4">
          <Link href="/create-escrow" className="text-white hover:text-orange-300 transition-colors">
            Create Escrow
          </Link>
          <Link href="/escrow-pool" className="text-white hover:text-orange-300 transition-colors">
            Escrow Pool
          </Link>
          <Link href="/search-escrow" className="text-white hover:text-orange-300 transition-colors">
            <Search className="w-5 h-5" />
            <span className="sr-only">Search Escrow</span>
          </Link>
          <ConnectKitButton showBalance={true} showAvatar={true} />
        </nav>
      </div>
    </header>
  );
}
