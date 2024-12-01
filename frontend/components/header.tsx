'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Search } from 'lucide-react'
import { Button } from '@/components/ui/button'

export function Header() {
  const [isConnected, setIsConnected] = useState(false)
  const [address, setAddress] = useState('')

  const connectWallet = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
        setIsConnected(true)
        setAddress(accounts[0])
      } catch (error) {
        console.error('Failed to connect to MetaMask', error)
      }
    } else {
      alert('Please install MetaMask to use this feature')
    }
  }

  return (
    <header className="bg-gray-800 py-4 absolute top-0 left-0 right-0 z-50">
      <div className="container mx-auto px-4 flex justify-between items-center">
        <Link href="/" className="text-2xl font-bold text-white">
          Bestcrow
        </Link>
        <nav className="flex items-center space-x-4">
          <Link 
            href="/create-escrow" 
            className="text-white hover:text-orange-300 transition-colors"
          >
            Create Escrow
          </Link>
          <Link 
            href="/escrow-pool" 
            className="text-white hover:text-orange-300 transition-colors"
          >
            Escrow Pool
          </Link>
          <Link 
            href="/search-escrow" 
            className="text-white hover:text-orange-300 transition-colors"
          >
            <Search className="w-5 h-5" />
            <span className="sr-only">Search Escrow</span>
          </Link>
          {isConnected ? (
            <span className="text-white">{`${address.slice(0, 6)}...${address.slice(-4)}`}</span>
          ) : (
            <Button 
              onClick={connectWallet} 
              variant="outline" 
              className="bg-blue-500 hover:bg-blue-600 text-white hover:text-orange-300 transition-colors"
            >
              Connect Wallet
            </Button>
          )}
        </nav>
      </div>
    </header>
  )
}

