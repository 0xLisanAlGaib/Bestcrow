'use client'

import { useState } from 'react'
import Link from 'next/link'
import { motion } from 'framer-motion'
import { Search, Filter, ChevronDown } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip"

const mockEscrows = [
  { 
    id: 'ESC001',
    contractAddress: '0x9876543210987654321098765432109876543219',
    title: 'Standard Web3 Project Escrow',
    amount: '10 ETH',
    status: 'active',
    type: 'standard',
    depositor: '0x8B9469241e0Bd69C3503D73d049b6135cc6013d0',
    receiver: '0x8B9469241e0Bd69C3503D73d049b6135cc6013d0',
    expirationDate: '2023-12-31'
  },
  { 
    id: 'ESC002',
    contractAddress: '0x9876543210987654321098765432109876543210',
    title: 'NFT Marketplace Integration',
    amount: '5 ETH',
    status: 'completed',
    type: 'milestone',
    depositor: '0xfedcba9876543210fedcba9876543210fedcba98',
    receiver: '0x3456789012345678901234567890123456789012',
    expirationDate: '2023-11-15'
  },
  { 
    id: 'ESC003',
    contractAddress: '0xabcdef1234567890abcdef1234567890abcdef12',
    title: 'DeFi Protocol Development',
    amount: '20000 USDC',
    status: 'pending',
    type: 'milestone',
    depositor: '0x4567890123456789012345678901234567890123',
    receiver: '0xbcdef1234567890abcdef1234567890abcdef123',
    expirationDate: '2024-01-31'
  },
  { 
    id: 'ESC004',
    contractAddress: '0x2345678901234567890123456789012345678901',
    title: 'Smart Contract Audit',
    amount: '3 ETH',
    status: 'active',
    type: 'standard',
    depositor: '0xcdef1234567890abcdef1234567890abcdef1234',
    receiver: '0x5678901234567890123456789012345678901234',
    expirationDate: '2023-12-15'
  },
  { 
    id: 'ESC005',
    contractAddress: '0x3456789012345678901234567890123456789012',
    title: 'Metaverse Land Sale',
    amount: '1.8 ETH',
    status: 'expired',
    type: 'standard',
    depositor: '0xdef1234567890abcdef1234567890abcdef12345',
    receiver: '0x6789012345678901234567890123456789012345',
    expirationDate: '2023-05-28'
  },
  { 
    id: 'ESC006',
    contractAddress: '0x7890123456789012345678901234567890123456',
    title: 'DAO Governance Implementation',
    amount: '15 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0x890123456789012345678901234567890123456',
    receiver: '0x9012345678901234567890123456789012345678',
    expirationDate: '2024-03-15'
  },
  { 
    id: 'ESC007',
    contractAddress: '0xa1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
    title: 'Cross-chain Bridge Development',
    amount: '25 ETH',
    status: 'pending',
    type: 'milestone',
    depositor: '0xb2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3',
    receiver: '0xc3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4',
    expirationDate: '2024-06-30'
  },
  { 
    id: 'ESC008',
    contractAddress: '0xd4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5',
    title: 'NFT Collection Launch',
    amount: '2.5 ETH',
    status: 'completed',
    type: 'standard',
    depositor: '0xe5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6',
    receiver: '0xf6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1',
    expirationDate: '2023-09-30'
  },
  { 
    id: 'ESC009',
    contractAddress: '0x123456789abcdef123456789abcdef123456789a',
    title: 'DeFi Yield Farming Protocol',
    amount: '50000 USDC',
    status: 'active',
    type: 'milestone',
    depositor: '0x23456789abcdef123456789abcdef123456789ab',
    receiver: '0x3456789abcdef123456789abcdef123456789abc',
    expirationDate: '2024-08-31'
  },
  { 
    id: 'ESC010',
    contractAddress: '0x456789abcdef123456789abcdef123456789abcd',
    title: 'Blockchain Game Development',
    amount: '20 ETH',
    status: 'pending',
    type: 'milestone',
    depositor: '0x56789abcdef123456789abcdef123456789abcde',
    receiver: '0x6789abcdef123456789abcdef123456789abcdef',
    expirationDate: '2024-12-31'
  },
  { 
    id: 'ESC011',
    contractAddress: '0x789abcdef123456789abcdef123456789abcdef1',
    title: 'Decentralized Exchange Integration',
    amount: '8 ETH',
    status: 'active',
    type: 'standard',
    depositor: '0x89abcdef123456789abcdef123456789abcdef12',
    receiver: '0x9abcdef123456789abcdef123456789abcdef123',
    expirationDate: '2023-11-30'
  },
  { 
    id: 'ESC012',
    contractAddress: '0xabcdef123456789abcdef123456789abcdef1234',
    title: 'Layer 2 Scaling Solution',
    amount: '30 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0xbcdef123456789abcdef123456789abcdef12345',
    receiver: '0xcdef123456789abcdef123456789abcdef123456',
    expirationDate: '2024-09-30'
  },
  { 
    id: 'ESC013',
    contractAddress: '0xdef123456789abcdef123456789abcdef1234567',
    title: 'Tokenization Platform',
    amount: '12 ETH',
    status: 'completed',
    type: 'standard',
    depositor: '0xef123456789abcdef123456789abcdef12345678',
    receiver: '0xf123456789abcdef123456789abcdef123456789',
    expirationDate: '2023-10-15'
  },
  { 
    id: 'ESC014',
    contractAddress: '0x123456789abcdef123456789abcdef123456789a',
    title: 'Crypto Payment Gateway',
    amount: '18 ETH',
    status: 'pending',
    type: 'milestone',
    depositor: '0x23456789abcdef123456789abcdef123456789ab',
    receiver: '0x3456789abcdef123456789abcdef123456789abc',
    expirationDate: '2024-07-31'
  },
  { 
    id: 'ESC015',
    contractAddress: '0x456789abcdef123456789abcdef123456789abcd',
    title: 'Decentralized Identity Solution',
    amount: '7 ETH',
    status: 'active',
    type: 'standard',
    depositor: '0x56789abcdef123456789abcdef123456789abcde',
    receiver: '0x6789abcdef123456789abcdef123456789abcdef',
    expirationDate: '2023-12-31'
  },
  { 
    id: 'ESC016',
    contractAddress: '0x789abcdef123456789abcdef123456789abcdef1',
    title: 'NFT Marketplace Development',
    amount: '22 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0x89abcdef123456789abcdef123456789abcdef12',
    receiver: '0x9abcdef123456789abcdef123456789abcdef123',
    expirationDate: '2024-05-31'
  },
  { 
    id: 'ESC017',
    contractAddress: '0xabcdef123456789abcdef123456789abcdef1234',
    title: 'Decentralized Storage Solution',
    amount: '15000 USDC',
    status: 'pending',
    type: 'milestone',
    depositor: '0xbcdef123456789abcdef123456789abcdef12345',
    receiver: '0xcdef123456789abcdef123456789abcdef123456',
    expirationDate: '2024-04-30'
  },
  { 
    id: 'ESC018',
    contractAddress: '0xdef123456789abcdef123456789abcdef1234567',
    title: 'DeFi Lending Protocol',
    amount: '28 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0xef123456789abcdef123456789abcdef12345678',
    receiver: '0xf123456789abcdef123456789abcdef123456789',
    expirationDate: '2024-10-31'
  },
  { 
    id: 'ESC019',
    contractAddress: '0x123456789abcdef123456789abcdef123456789a',
    title: 'Blockchain Supply Chain Solution',
    amount: '20 ETH',
    status: 'completed',
    type: 'standard',
    depositor: '0x23456789abcdef123456789abcdef123456789ab',
    receiver: '0x3456789abcdef123456789abcdef123456789abc',
    expirationDate: '2023-08-31'
  },
  { 
    id: 'ESC020',
    contractAddress: '0x456789abcdef123456789abcdef123456789abcd',
    title: 'Decentralized Social Media Platform',
    amount: '35 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0x56789abcdef123456789abcdef123456789abcde',
    receiver: '0x6789abcdef123456789abcdef123456789abcdef',
    expirationDate: '2024-11-30'
  },
  { 
    id: 'ESC021',
    contractAddress: '0x789abcdef123456789abcdef123456789abcdef1',
    title: 'Crypto Trading Bot Development',
    amount: '6 ETH',
    status: 'pending',
    type: 'standard',
    depositor: '0x89abcdef123456789abcdef123456789abcdef12',
    receiver: '0x9abcdef123456789abcdef123456789abcdef123',
    expirationDate: '2023-12-15'
  },
  { 
    id: 'ESC022',
    contractAddress: '0xabcdef123456789abcdef123456789abcdef1234',
    title: 'Blockchain Voting System',
    amount: '18 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0xbcdef123456789abcdef123456789abcdef12345',
    receiver: '0xcdef123456789abcdef123456789abcdef123456',
    expirationDate: '2024-02-29'
  },
  { 
    id: 'ESC023',
    contractAddress: '0xdef123456789abcdef123456789abcdef1234567',
    title: 'Decentralized Insurance Platform',
    amount: '25000 USDC',
    status: 'pending',
    type: 'milestone',
    depositor: '0xef123456789abcdef123456789abcdef12345678',
    receiver: '0xf123456789abcdef123456789abcdef123456789',
    expirationDate: '2024-08-15'
  },
  { 
    id: 'ESC024',
    contractAddress: '0x123456789abcdef123456789abcdef123456789a',
    title: 'NFT Ticketing System',
    amount: '9 ETH',
    status: 'active',
    type: 'standard',
    depositor: '0x23456789abcdef123456789abcdef123456789ab',
    receiver: '0x3456789abcdef123456789abcdef123456789abc',
    expirationDate: '2023-11-30'
  },
  { 
    id: 'ESC025',
    contractAddress: '0x456789abcdef123456789abcdef123456789abcd',
    title: 'Decentralized File Storage',
    amount: '14 ETH',
    status: 'completed',
    type: 'milestone',
    depositor: '0x56789abcdef123456789abcdef123456789abcde',
    receiver: '0x6789abcdef123456789abcdef123456789abcdef',
    expirationDate: '2023-09-30'
  },
  { 
    id: 'ESC026',
    contractAddress: '0x789abcdef123456789abcdef123456789abcdef1',
    title: 'Blockchain-based Supply Chain',
    amount: '30 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0x89abcdef123456789abcdef123456789abcdef12',
    receiver: '0x9abcdef123456789abcdef123456789abcdef123',
    expirationDate: '2024-07-31'
  },
  { 
    id: 'ESC027',
    contractAddress: '0xabcdef123456789abcdef123456789abcdef1234',
    title: 'Decentralized Prediction Market',
    amount: '12 ETH',
    status: 'pending',
    type: 'standard',
    depositor: '0xbcdef123456789abcdef123456789abcdef12345',
    receiver: '0xcdef123456789abcdef123456789abcdef123456',
    expirationDate: '2023-12-31'
  },
  { 
    id: 'ESC028',
    contractAddress: '0xdef123456789abcdef123456789abcdef1234567',
    title: 'Crypto Payment Gateway Integration',
    amount: '8 ETH',
    status: 'active',
    type: 'standard',
    depositor: '0xef123456789abcdef123456789abcdef12345678',
    receiver: '0xf123456789abcdef123456789abcdef123456789',
    expirationDate: '2023-11-15'
  },
  { 
    id: 'ESC029',
    contractAddress: '0x123456789abcdef123456789abcdef123456789a',
    title: 'Decentralized Autonomous Organization (DAO) Setup',
    amount: '20 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0x23456789abcdef123456789abcdef123456789ab',
    receiver: '0x3456789abcdef123456789abcdef123456789abc',
    expirationDate: '2024-06-30'
  },
  { 
    id: 'ESC030',
    contractAddress: '0x45678NFT Marketplace Upgrade',
    amount: '15 ETH',
    status: 'pending',
    type: 'milestone',
    depositor: '0x56789abcdef123456789abcdef123456789abcde',
    receiver: '0x6789abcdef123456789abcdef123456789abcdef',
    expirationDate: '2024-03-31'
  },
  { 
    id: 'ESC031',
    contractAddress: '0x789abcdef123456789abcdef123456789abcdef1',
    title: 'DeFi Yield Aggregator Development',
    amount: '25 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0x89abcdef123456789abcdef123456789abcdef12',
    receiver: '0x9abcdef123456789abcdef123456789abcdef123',
    expirationDate: '2024-09-30'
  },
  { 
    id: 'ESC032',
    contractAddress: '0xabcdef123456789abcdef123456789abcdef1234',
    title: 'Blockchain-based Voting System',
    amount: '18 ETH',
    status: 'completed',
    type: 'standard',
    depositor: '0xbcdef123456789abcdef123456789abcdef12345',
    receiver: '0xcdef123456789abcdef123456789abcdef123456',
    expirationDate: '2023-10-31'
  },
  { 
    id: 'ESC033',
    contractAddress: '0xdef123456789abcdef123456789abcdef1234567',
    title: 'Cross-chain DeFi Protocol',
    amount: '40 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0xef123456789abcdef123456789abcdef12345678',
    receiver: '0xf123456789abcdef123456789abcdef123456789',
    expirationDate: '2024-12-15'
  },
  { 
    id: 'ESC034',
    contractAddress: '0x123456789abcdef123456789abcdef123456789a',
    title: 'Decentralized Content Platform',
    amount: '22 ETH',
    status: 'pending',
    type: 'milestone',
    depositor: '0x23456789abcdef123456789abcdef123456789ab',
    receiver: '0x3456789abcdef123456789abcdef123456789abc',
    expirationDate: '2024-05-31'
  },
  { 
    id: 'ESC035',
    contractAddress: '0x45678Smart Contract Security Audit',
    amount: '5 ETH',
    status: 'active',
    type: 'standard',
    depositor: '0x56789abcdef123456789abcdef123456789abcde',
    receiver: '0x6789abcdef123456789abcdef123456789abcdef',
    expirationDate: '2023-12-31'
  }
]

export default function EscrowPool() {
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')

  const filteredEscrows = mockEscrows.filter(escrow => 
    (escrow.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
     escrow.id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
     escrow.contractAddress?.toLowerCase().includes(searchTerm.toLowerCase())) &&
    (filterStatus === 'all' || escrow.status === filterStatus)
  )

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-500'
      case 'completed': return 'bg-blue-500'
      case 'pending': return 'bg-yellow-500'
      case 'expired': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  const truncateAddress = (address: string | undefined) => {
    if (!address) return 'N/A';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8 pt-24">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <h1 className="text-4xl font-bold mb-8 text-center">Escrow Pool</h1>
        
        <div className="flex flex-col md:flex-row justify-between items-center mb-6 space-y-4 md:space-y-0 md:space-x-4">
          <div className="relative w-full md:w-1/3">
            <Input
              type="text"
              placeholder="Search escrows..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10 bg-gray-800 border-gray-700 text-white"
            />
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
          </div>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" className="bg-gray-800 border-gray-700 text-white">
                <Filter className="mr-2 h-4 w-4" />
                Filter by Status
                <ChevronDown className="ml-2 h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent className="bg-gray-800 border-gray-700 text-white">
              <DropdownMenuItem onClick={() => setFilterStatus('all')}>All</DropdownMenuItem>
              <DropdownMenuItem onClick={() => setFilterStatus('active')}>Active</DropdownMenuItem>
              <DropdownMenuItem onClick={() => setFilterStatus('completed')}>Completed</DropdownMenuItem>
              <DropdownMenuItem onClick={() => setFilterStatus('pending')}>Pending</DropdownMenuItem>
              <DropdownMenuItem onClick={() => setFilterStatus('expired')}>Expired</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        {/* Desktop view */}
        <div className="hidden md:block overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-white">Escrow ID</TableHead>
                <TableHead className="text-white">Contract Address</TableHead>
                <TableHead className="text-white">Title</TableHead>
                <TableHead className="text-white">Amount</TableHead>
                <TableHead className="text-white">Status</TableHead>
                <TableHead className="text-white">Type</TableHead>
                <TableHead className="text-white">Depositor</TableHead>
                <TableHead className="text-white">Receiver</TableHead>
                <TableHead className="text-white">Expiration Date</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredEscrows.map((escrow) => (
                <TableRow key={escrow.id} className="border-b border-gray-700">
                  <TableCell className="font-medium text-white">{escrow.id || 'N/A'}</TableCell>
                  <TableCell className="text-white">
                    <Link href={`/escrow/${escrow.id}`} className="hover:text-blue-400 transition-colors">
                      <TooltipProvider>
                        <Tooltip>
                          <TooltipTrigger className="underline decoration-dotted">
                            {truncateAddress(escrow.contractAddress)}
                          </TooltipTrigger>
                          <TooltipContent>
                            <p>{escrow.contractAddress || 'N/A'}</p>
                          </TooltipContent>
                        </Tooltip>
                      </TooltipProvider>
                    </Link>
                  </TableCell>
                  <TableCell className="text-white">
                    <Link href={`/escrow/${escrow.id}`} className="hover:text-blue-400 transition-colors">
                      {escrow.title || 'Untitled'}
                    </Link>
                  </TableCell>
                  <TableCell className="text-white">{escrow.amount || 'N/A'}</TableCell>
                  <TableCell>
                    <Badge className={`${getStatusColor(escrow.status || '')} text-white`}>
                      {escrow.status || 'Unknown'}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-white">{escrow.type || 'N/A'}</TableCell>
                  <TableCell className="text-white">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger className="underline decoration-dotted">
                          {truncateAddress(escrow.depositor)}
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>{escrow.depositor || 'N/A'}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>
                  <TableCell className="text-white">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger className="underline decoration-dotted">
                          {truncateAddress(escrow.receiver)}
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>{escrow.receiver || 'N/A'}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>
                  <TableCell className="text-white">{escrow.expirationDate || 'N/A'}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        {/* Mobile view */}
        <div className="md:hidden space-y-4">
          {filteredEscrows.map((escrow) => (
            <Card key={escrow.id} className="bg-gray-800 border-gray-700">
              <CardHeader>
                <CardTitle className="text-white flex justify
between items-center">
                  <Link href={`/escrow/${escrow.id}`} className="hover:text-blue-400 transition-colors">
                    {escrow.title || 'Untitled'}
                  </Link>
                  <Badge className={`${getStatusColor(escrow.status || '')} text-white`}>
                    {escrow.status || 'Unknown'}
                  </Badge>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-gray-400">ID: {escrow.id || 'N/A'}</p>
                <p className="text-sm text-gray-400">Contract: {truncateAddress(escrow.contractAddress)}</p>
                <p className="text-sm text-gray-400">Amount: {escrow.amount || 'N/A'}</p>
                <p className="text-sm text-gray-400">Type: {escrow.type || 'N/A'}</p>
                <p className="text-sm text-gray-400">Depositor: {truncateAddress(escrow.depositor)}</p>
                <p className="text-sm text-gray-400">Receiver: {truncateAddress(escrow.receiver)}</p>
                <p className="text-sm text-gray-400">Expires: {escrow.expirationDate || 'N/A'}</p>
                <div className="mt-4">
                  <Link href={`/escrow/${escrow.id}`}>
                    <Button variant="outline" className="w-full">
                      View Details
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </motion.div>
    </div>
  )
}

