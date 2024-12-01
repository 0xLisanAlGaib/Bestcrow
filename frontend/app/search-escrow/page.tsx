'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'

interface Escrow {
  id: string
  title: string
  depositorAddress: string
  receiverAddress: string
  amount: string
  asset: string
  contractAddress: string
}

export default function SearchEscrow() {
  const [searchTerm, setSearchTerm] = useState('')
  const [searchResults, setSearchResults] = useState<Escrow[]>([])

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault()
    // Here you would typically make an API call to search for escrows
    // For now, we'll use dummy data
    const dummyResults: Escrow[] = [
      {
        id: '1',
        title: 'Test Escrow',
        depositorAddress: '0x1234...5678',
        receiverAddress: '0xabcd...efgh',
        amount: '1.5',
        asset: 'ETH',
        contractAddress: '0x9876...5432',
      },
    ]
    setSearchResults(dummyResults)
  }

  return (
    <div className="min-h-screen bg-[#0a192f] text-white p-4">
      <div className="container mx-auto">
        <Card className="w-full max-w-2xl mx-auto bg-[#112240] text-white">
          <CardHeader>
            <CardTitle className="text-2xl font-bold">Search Escrow</CardTitle>
            <CardDescription className="text-gray-400">Enter an escrow title or contract address to search</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSearch} className="space-y-4">
              <div className="flex space-x-2">
                <Input
                  type="text"
                  placeholder="Escrow title or contract address"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="flex-grow bg-[#1e2a4a] border-gray-600 text-white"
                />
                <Button type="submit" className="bg-blue-500 hover:bg-blue-600">Search</Button>
              </div>
            </form>

            {searchResults.length > 0 && (
              <Table className="mt-8">
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-white">Title</TableHead>
                    <TableHead className="text-white">Depositor</TableHead>
                    <TableHead className="text-white">Receiver</TableHead>
                    <TableHead className="text-white">Amount</TableHead>
                    <TableHead className="text-white">Asset</TableHead>
                    <TableHead className="text-white">Contract Address</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {searchResults.map((escrow) => (
                    <TableRow key={escrow.id}>
                      <TableCell className="text-white">{escrow.title}</TableCell>
                      <TableCell className="text-white">{escrow.depositorAddress}</TableCell>
                      <TableCell className="text-white">{escrow.receiverAddress}</TableCell>
                      <TableCell className="text-white">{escrow.amount}</TableCell>
                      <TableCell className="text-white">{escrow.asset}</TableCell>
                      <TableCell className="text-white">{escrow.contractAddress}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

