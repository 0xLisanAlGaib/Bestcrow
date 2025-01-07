"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useAccount, useReadContract, useReadContracts } from "wagmi";
import { WalletIcon, Loader2 } from "lucide-react";
import { BESTCROW_ADDRESS } from "@/constants/bestcrow";
import { BESTCROW_ABI } from "@/constants/abi";
import { formatEther } from "viem";
import { type Address, type Abi } from "viem";
import Link from "next/link";

interface Escrow {
  id: string;
  title: string;
  depositor: string;
  receiver: string;
  amount: string;
  isEth: boolean;
  token: string;
  isActive: boolean;
  isCompleted: boolean;
  expiryDate: number;
  createdAt: number;
}

export default function SearchEscrow() {
  const [searchTerm, setSearchTerm] = useState("");
  const [searchResults, setSearchResults] = useState<Escrow[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const { address: walletAddress, isConnected } = useAccount();

  // Add refresh interval
  useEffect(() => {
    const interval = setInterval(() => {
      if (searchTerm) {
        handleSearch(new Event("refresh") as any);
      }
    }, 5000);

    return () => clearInterval(interval);
  }, [searchTerm]);

  // Get nextEscrowId from contract
  const { data: nextEscrowId } = useReadContract({
    address: BESTCROW_ADDRESS,
    abi: BESTCROW_ABI,
    functionName: "nextEscrowId",
  });

  // Fetch all escrow details
  const { data: escrowResults } = useReadContracts({
    contracts: Array.from({ length: Number(nextEscrowId || 0) }, (_, i) => ({
      address: BESTCROW_ADDRESS as Address,
      abi: BESTCROW_ABI as Abi,
      functionName: "escrowDetails",
      args: [BigInt(i + 1)],
    })),
  });

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isConnected) {
      alert("Please connect your wallet first");
      return;
    }

    setIsLoading(true);
    try {
      if (!escrowResults) {
        setSearchResults([]);
        return;
      }

      const formattedEscrows = escrowResults
        .map((result, index) => {
          if (!result || !result.result) return null;
          const data = result.result as [
            string,
            string,
            string,
            bigint,
            bigint,
            bigint,
            boolean,
            boolean,
            boolean,
            boolean,
            string,
            string
          ];

          // Only include escrows where the connected wallet is involved
          if (
            data[0].toLowerCase() !== walletAddress?.toLowerCase() && // depositor
            data[1].toLowerCase() !== walletAddress?.toLowerCase() // receiver
          ) {
            return null;
          }

          return {
            id: String(index + 1),
            title: data[10],
            depositor: data[0],
            receiver: data[1],
            amount: formatEther(data[3]),
            isEth: data[8],
            token: data[2],
            isActive: data[6],
            isCompleted: data[7],
            expiryDate: Number(data[4]),
            createdAt: Number(data[5]),
          };
        })
        .filter((escrow): escrow is Escrow => escrow !== null);

      // Filter escrows based on search term
      const filteredResults = formattedEscrows.filter((escrow) => {
        const searchLower = searchTerm.toLowerCase();
        return escrow.id.toLowerCase().includes(searchLower) || escrow.title.toLowerCase().includes(searchLower);
      });

      setSearchResults(filteredResults);
    } catch (error) {
      console.error("Error searching escrows:", error);
      alert("Error searching escrows. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0a192f] to-[#112240] text-white p-4 pt-24">
      <div className="container mx-auto relative">
        <div className="absolute top-[-50px] left-[-50px] w-64 h-64 bg-blue-500/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob"></div>
        <div className="absolute top-[-50px] right-[-50px] w-64 h-64 bg-blue-600/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000"></div>
        <div className="absolute bottom-[-50px] left-[50%] w-64 h-64 bg-blue-700/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000"></div>

        <h1 className="text-4xl md:text-5xl font-bold text-center mb-8 bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-blue-600">
          Search Escrow
        </h1>

        <Card className="w-full max-w-2xl mx-auto bg-[#1a365d]/50 backdrop-blur-lg border-0 shadow-xl rounded-2xl overflow-hidden">
          <CardHeader className="rounded-t-2xl">
            <CardTitle className="text-2xl font-bold text-center text-blue-300">Find Your Escrow</CardTitle>
            <CardDescription className="text-center text-blue-200/70">
              {isConnected ? (
                <div className="flex items-center justify-center gap-2">
                  <WalletIcon className="w-4 h-4 text-green-400" />
                  <span>
                    Connected: {walletAddress?.slice(0, 6)}...{walletAddress?.slice(-4)}
                  </span>
                </div>
              ) : (
                <div className="flex items-center justify-center gap-2">
                  <WalletIcon className="w-4 h-4 text-yellow-400" />
                  <span>Please connect your wallet to search for escrows</span>
                </div>
              )}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSearch} className="space-y-4">
              <div className="flex space-x-2">
                <Input
                  type="text"
                  placeholder={isConnected ? "Search by escrow ID or title" : "Connect wallet to search"}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="flex-grow bg-[#2c4a7c]/50 border-blue-500/30 text-white placeholder-blue-300/50 focus:border-blue-400 focus:ring-blue-400 rounded-xl"
                  disabled={!isConnected}
                />
                <Button
                  type="submit"
                  className="bg-blue-500 hover:bg-blue-600 transition-colors duration-200 disabled:opacity-50 rounded-xl"
                  disabled={!isConnected || isLoading}
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Searching...
                    </>
                  ) : (
                    "Search"
                  )}
                </Button>
              </div>
            </form>

            {searchResults.length > 0 && (
              <div className="mt-8 rounded-xl overflow-hidden bg-[#1e2a4a]/50">
                <Table>
                  <TableHeader>
                    <TableRow className="hover:bg-transparent">
                      <TableHead className="text-blue-300">ID</TableHead>
                      <TableHead className="text-blue-300">Title</TableHead>
                      <TableHead className="text-blue-300">Depositor</TableHead>
                      <TableHead className="text-blue-300">Receiver</TableHead>
                      <TableHead className="text-blue-300">Amount</TableHead>
                      <TableHead className="text-blue-300">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {searchResults.map((escrow) => (
                      <TableRow key={escrow.id} className="hover:bg-blue-600/10 transition-colors duration-200">
                        <TableCell className="text-blue-100">{escrow.id}</TableCell>
                        <TableCell className="text-blue-100">{escrow.title}</TableCell>
                        <TableCell className="text-blue-100">
                          {escrow.depositor.slice(0, 6)}...{escrow.depositor.slice(-4)}
                        </TableCell>
                        <TableCell className="text-blue-100">
                          {escrow.receiver.slice(0, 6)}...{escrow.receiver.slice(-4)}
                        </TableCell>
                        <TableCell className="text-blue-100">
                          {escrow.amount} {escrow.isEth ? "ETH" : "Tokens"}
                        </TableCell>
                        <TableCell className="text-blue-100">
                          <Link
                            href={`/escrow/${escrow.id}`}
                            className="text-blue-400 hover:text-blue-300 transition-colors"
                          >
                            View Details
                          </Link>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}

            {searchResults.length === 0 && searchTerm && !isLoading && (
              <div className="mt-4 text-center text-blue-200/70">No escrows found matching your search criteria</div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
