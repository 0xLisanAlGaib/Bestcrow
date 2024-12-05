import './globals.css'
import { Inter } from 'next/font/google'
import { Header } from '../components/header'
import { Footer } from '../components/Footer'
import { Web3Provider } from '../providers/Web3Provider'

const inter = Inter({ subsets: ['latin'] })

export const metadata = {
  title: 'Bestcrow - Web3 Escrow Service',
  description: 'Create and manage escrows using MetaMask',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    
    <html lang="en" className="h-full">
      <Web3Provider><body className={`${inter.className} flex flex-col min-h-screen bg-[#0a192f]`}>
        <Header />
        <main className="flex-grow flex flex-col">
          {children}
        </main>
        <Footer />
        </body>
      </Web3Provider>
    </html>
  );
};

