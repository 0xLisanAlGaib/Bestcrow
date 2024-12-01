'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Search, Filter, ChevronDown, ExternalLink } from 'lucide-react'
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

// Updated mock data for active escrows
const mockEscrows = [
  { 
    id: 'ESC001',
    contractAddress: '0x1234...5678',
    title: 'Web3 Project Escrow',
    amount: '5 ETH',
    status: 'active',
    type: 'milestone',
    depositor: '0xabcd...ef01',
    receiver: '0x2345...6789',
    expirationDate: '2023-12-31'
  },
  { 
    id: 'ESC002',
    contractAddress: '0x9876...5432',
    title: 'NFT Purchase',
    amount: '2.5 ETH',
    status: 'completed',
    type: 'standard',
    depositor: '0xfedc...ba98',
    receiver: '0x3456...7890',
    expirationDate: '2023-11-15'
  },
  { 
    id: 'ESC003',
    contractAddress: '0xabcd...ef01',
    title: 'DeFi Integration',
    amount: '10000 USDC',
    status: 'pending',
    type: 'milestone',
    depositor: '0x4567...8901',
    receiver: '0xbcde...f012',
    expirationDate: '2024-01-31'
  },
  { 
    id: 'ESC004',
    contractAddress: '0x2345...6789',
    title: 'Smart Contract Audit',
    amount: '3 ETH',
    status: 'active',
    type: 'standard',
    depositor: '0xcdef...0123',
    receiver: '0x5678...9012',
    expirationDate: '2023-12-15'
  },
  { 
    id: 'ESC005',
    contractAddress: '0x3456...7890',
    title: 'Metaverse Land Sale',
    amount: '1.8 ETH',
    status: 'expired',
    type: 'standard',
    depositor: '0xdef0...1234',
    receiver: '0x6789...0123',
    expirationDate: '2023-05-28'
  },
]

export default function EscrowPool() {
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')

  const filteredEscrows = mockEscrows.filter(escrow => 
    (escrow.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
     escrow.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
     escrow.contractAddress.toLowerCase().includes(searchTerm.toLowerCase())) &&
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

  const truncateAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8">
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
                  <TableCell className="font-medium text-white">{escrow.id}</TableCell>
                  <TableCell className="text-white">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger className="underline decoration-dotted">
                          {truncateAddress(escrow.contractAddress)}
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>{escrow.contractAddress}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>
                  <TableCell className="text-white">{escrow.title}</TableCell>
                  <TableCell className="text-white">{escrow.amount}</TableCell>
                  <TableCell>
                    <Badge className={`${getStatusColor(escrow.status)} text-white`}>
                      {escrow.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-white">{escrow.type}</TableCell>
                  <TableCell className="text-white">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger className="underline decoration-dotted">
                          {truncateAddress(escrow.depositor)}
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>{escrow.depositor}</p>
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
                          <p>{escrow.receiver}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>
                  <TableCell className="text-white">{escrow.expirationDate}</TableCell>
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
                <CardTitle className="text-white flex justify-between items-center">
                  <span>{escrow.title}</span>
                  <Badge className={`${getStatusColor(escrow.status)} text-white`}>
                    {escrow.status}
                  </Badge>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <p className="text-gray-400">ID: {escrow.id}</p>
                <p className="text-gray-400">Contract: {truncateAddress(escrow.contractAddress)}</p>
                <p className="text-gray-400">Amount: {escrow.amount}</p>
                <p className="text-gray-400">Type: {escrow.type}</p>
                <p className="text-gray-400">Depositor: {truncateAddress(escrow.depositor)}</p>
                <p className="text-gray-400">Receiver: {truncateAddress(escrow.receiver)}</p>
                <p className="text-gray-400">Expiration: {escrow.expirationDate}</p>
                <Button variant="outline" className="w-full mt-2 bg-gray-700 border-gray-600 text-white">
                  View Details
                  <ExternalLink className="ml-2 h-4 w-4" />
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      </motion.div>
    </div>
  )
}

