"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { Search, Filter, ChevronDown } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { useAccount, useReadContract, useReadContracts } from "wagmi";
import { type Abi } from "viem";
import { BESTCROW_ADDRESS } from "@/constants/bestcrow";
import { BESTCROW_ABI } from "@/constants/abi";
import { formatUnits } from "viem";

interface Escrow {
  id: string;
  depositor: string;
  receiver: string;
  token: string;
  amount: string;
  expiryDate: number;
  createdAt: number;
  isActive: boolean;
  isCompleted: boolean;
  isEth: boolean;
  releaseRequested: boolean;
  title: string;
  description: string;
}

export default function EscrowPool() {
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");
  const [escrows, setEscrows] = useState<Escrow[]>([]);
  const [loading, setLoading] = useState(true);
  const { address: connectedAddress } = useAccount();

  // Add refresh interval
  useEffect(() => {
    const interval = setInterval(() => {
      // This will trigger a re-fetch of the contracts
      setLoading(true);
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  // Get nextEscrowId from contract
  const { data: nextEscrowId } = useReadContract({
    address: BESTCROW_ADDRESS,
    abi: BESTCROW_ABI,
    functionName: "nextEscrowId",
  });

  // Fetch all escrow details
  const { data: escrowResults } = useReadContracts({
    contracts: Array.from({ length: Number(nextEscrowId || 0) }, (_, i) => ({
      address: BESTCROW_ADDRESS as `0x${string}`,
      abi: BESTCROW_ABI as Abi,
      functionName: "escrowDetails",
      args: [BigInt(i + 1)],
    })),
  });

  useEffect(() => {
    if (!escrowResults) return;

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
        return {
          id: String(index + 1),
          depositor: data[0],
          receiver: data[1],
          token: data[2],
          amount: formatUnits(data[3], 18),
          expiryDate: Number(data[4]),
          createdAt: Number(data[5]),
          isActive: data[6],
          isCompleted: data[7],
          isEth: data[8],
          releaseRequested: data[9],
          title: data[10],
          description: data[11],
        };
      })
      .filter((escrow): escrow is Escrow => escrow !== null);

    setEscrows(formattedEscrows);
    setLoading(false);
  }, [escrowResults]);

  const formatDate = (timestamp: number) => {
    return (
      new Date(timestamp * 1000).toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
        timeZone: "UTC",
      }) + " UTC"
    );
  };

  const getEscrowStatus = (escrow: Escrow) => {
    if (escrow.isCompleted && escrow.releaseRequested) return "completed";
    if (escrow.isCompleted && !escrow.releaseRequested) return "expired";
    if (!escrow.isActive && !escrow.isCompleted) return "pending";
    if (escrow.isActive && !escrow.releaseRequested) return "active";
    if (escrow.releaseRequested) return "release_requested";
    return "unknown";
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "bg-green-500";
      case "completed":
        return "bg-blue-500";
      case "pending":
        return "bg-yellow-500";
      case "expired":
        return "bg-red-500";
      case "release_requested":
        return "bg-purple-500";
      default:
        return "bg-gray-500";
    }
  };

  const truncateAddress = (address: string) => {
    if (!address) return "N/A";
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const isParticipant = (escrow: Escrow) => {
    if (!connectedAddress) return false;
    return (
      connectedAddress.toLowerCase() === escrow.depositor.toLowerCase() ||
      connectedAddress.toLowerCase() === escrow.receiver.toLowerCase()
    );
  };

  const filteredEscrows = escrows.filter((escrow) => {
    // First apply search term filter
    const searchMatch =
      escrow.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      escrow.id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      escrow.depositor?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      escrow.receiver?.toLowerCase().includes(searchTerm.toLowerCase());

    // Then apply status filter
    const status = getEscrowStatus(escrow);
    const statusMatch = filterStatus === "all" || status === filterStatus;

    return searchMatch && statusMatch;
  });

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0a192f] to-[#112240] text-white p-4 pt-24">
      <div className="container mx-auto relative">
        <div className="absolute top-[-50px] left-[-50px] w-64 h-64 bg-blue-500/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob"></div>
        <div className="absolute top-[-50px] right-[-50px] w-64 h-64 bg-blue-600/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000"></div>
        <div className="absolute bottom-[-50px] left-[50%] w-64 h-64 bg-blue-700/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000"></div>

        <h1 className="text-4xl md:text-5xl font-bold text-center mb-8 bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-blue-600">
          Escrow Pool
        </h1>

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
          <div className="flex flex-col md:flex-row justify-between items-center mb-6 space-y-4 md:space-y-0 md:space-x-4">
            <div className="relative w-full md:w-1/3">
              <Input
                type="text"
                placeholder="Search escrows..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="flex-grow bg-[#2c4a7c]/50 border-blue-500/30 text-white placeholder-blue-300/50 focus:border-blue-400 focus:ring-blue-400 rounded-xl pl-10"
              />
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-blue-300/50" />
            </div>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="outline"
                  className="bg-[#2c4a7c]/50 border-blue-500/30 text-white hover:bg-[#2c4a7c]/70 rounded-xl min-w-[160px] justify-between relative z-10"
                >
                  <div className="flex items-center gap-2">
                    <Filter className="h-4 w-4" />
                    <span>
                      {filterStatus === "all"
                        ? "All Status"
                        : filterStatus.charAt(0).toUpperCase() + filterStatus.slice(1).replace("_", " ")}
                    </span>
                  </div>
                  <ChevronDown className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent
                align="end"
                className="w-[200px] bg-[#2c4a7c] border border-blue-500/30 text-white rounded-xl shadow-lg overflow-hidden z-50"
              >
                <DropdownMenuItem
                  onClick={() => {
                    console.log("Clicked All Status");
                    setFilterStatus("all");
                  }}
                  className="hover:bg-[#2c4a7c]/90 cursor-pointer focus:bg-[#2c4a7c]/90 focus:text-white px-4 py-2"
                >
                  All Status
                </DropdownMenuItem>
                <DropdownMenuItem
                  onClick={() => {
                    console.log("Clicked Active");
                    setFilterStatus("active");
                  }}
                  className="hover:bg-[#2c4a7c]/90 cursor-pointer focus:bg-[#2c4a7c]/90 focus:text-white px-4 py-2"
                >
                  Active
                </DropdownMenuItem>
                <DropdownMenuItem
                  onClick={() => {
                    console.log("Clicked Completed");
                    setFilterStatus("completed");
                  }}
                  className="hover:bg-[#2c4a7c]/90 cursor-pointer focus:bg-[#2c4a7c]/90 focus:text-white px-4 py-2"
                >
                  Completed
                </DropdownMenuItem>
                <DropdownMenuItem
                  onClick={() => {
                    console.log("Clicked Pending");
                    setFilterStatus("pending");
                  }}
                  className="hover:bg-[#2c4a7c]/90 cursor-pointer focus:bg-[#2c4a7c]/90 focus:text-white px-4 py-2"
                >
                  Pending
                </DropdownMenuItem>
                <DropdownMenuItem
                  onClick={() => {
                    console.log("Clicked Expired");
                    setFilterStatus("expired");
                  }}
                  className="hover:bg-[#2c4a7c]/90 cursor-pointer focus:bg-[#2c4a7c]/90 focus:text-white px-4 py-2"
                >
                  Expired
                </DropdownMenuItem>
                <DropdownMenuItem
                  onClick={() => {
                    console.log("Clicked Release Requested");
                    setFilterStatus("release_requested");
                  }}
                  className="hover:bg-[#2c4a7c]/90 cursor-pointer focus:bg-[#2c4a7c]/90 focus:text-white px-4 py-2"
                >
                  Release Requested
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          {/* Desktop view */}
          <div className="hidden md:block overflow-x-auto">
            <div className="mt-8 rounded-xl overflow-hidden bg-[#1e2a4a]/50">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent">
                    <TableHead className="text-blue-300">Escrow ID</TableHead>
                    <TableHead className="text-blue-300">Title</TableHead>
                    <TableHead className="text-blue-300">Depositor</TableHead>
                    <TableHead className="text-blue-300">Amount</TableHead>
                    <TableHead className="text-blue-300 text-center">Status</TableHead>
                    <TableHead className="text-blue-300">Type</TableHead>
                    <TableHead className="text-blue-300">Receiver</TableHead>
                    <TableHead className="text-blue-300">Created Date</TableHead>
                    <TableHead className="text-blue-300">Expiration Date</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center text-blue-200/70">
                        Loading escrows...
                      </TableCell>
                    </TableRow>
                  ) : filteredEscrows.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center text-blue-200/70">
                        No escrows found
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredEscrows.map((escrow) => (
                      <TableRow key={escrow.id} className="hover:bg-blue-600/10 transition-colors duration-200">
                        <TableCell className="text-blue-100">
                          {isParticipant(escrow) ? (
                            <Link
                              href={`/escrow/${escrow.id}`}
                              className="text-blue-400 hover:text-blue-300 transition-colors"
                            >
                              {escrow.id}
                            </Link>
                          ) : (
                            <span>{escrow.id}</span>
                          )}
                        </TableCell>
                        <TableCell className="text-blue-100">
                          {isParticipant(escrow) ? (
                            <Link
                              href={`/escrow/${escrow.id}`}
                              className="text-blue-400 hover:text-blue-300 transition-colors"
                            >
                              {escrow.title || "Untitled"}
                            </Link>
                          ) : (
                            <span>{escrow.title || "Untitled"}</span>
                          )}
                        </TableCell>
                        <TableCell className="text-blue-100">
                          <TooltipProvider>
                            <Tooltip>
                              <TooltipTrigger>{truncateAddress(escrow.depositor)}</TooltipTrigger>
                              <TooltipContent>
                                <p>{escrow.depositor}</p>
                              </TooltipContent>
                            </Tooltip>
                          </TooltipProvider>
                        </TableCell>
                        <TableCell className="text-blue-100">
                          {escrow.amount} {escrow.isEth ? "ETH" : "Tokens"}
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge className={`${getStatusColor(getEscrowStatus(escrow))} text-white`}>
                            {getEscrowStatus(escrow).replace("_", " ")}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-blue-100">Standard</TableCell>
                        <TableCell className="text-blue-100">
                          <TooltipProvider>
                            <Tooltip>
                              <TooltipTrigger>{truncateAddress(escrow.receiver)}</TooltipTrigger>
                              <TooltipContent>
                                <p>{escrow.receiver}</p>
                              </TooltipContent>
                            </Tooltip>
                          </TooltipProvider>
                        </TableCell>
                        <TableCell className="text-blue-100">{formatDate(escrow.createdAt)}</TableCell>
                        <TableCell className="text-blue-100">{formatDate(escrow.expiryDate)}</TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>
          </div>

          {/* Mobile view */}
          <div className="md:hidden space-y-4">
            {loading ? (
              <Card className="bg-gray-800 border-gray-700">
                <CardContent className="py-4 text-center">Loading escrows...</CardContent>
              </Card>
            ) : filteredEscrows.length === 0 ? (
              <Card className="bg-gray-800 border-gray-700">
                <CardContent className="py-4 text-center">No escrows found</CardContent>
              </Card>
            ) : (
              filteredEscrows.map((escrow) => (
                <Card key={escrow.id} className="bg-gray-800 border-gray-700">
                  <CardHeader>
                    <CardTitle className="text-white flex justify-between items-center">
                      <div>
                        <div className="text-white">
                          {isParticipant(escrow) ? (
                            <Link href={`/escrow/${escrow.id}`} className="hover:text-blue-400 transition-colors">
                              Escrow #{escrow.id}
                            </Link>
                          ) : (
                            <span>Escrow #{escrow.id}</span>
                          )}
                        </div>
                        <div className="text-sm text-gray-400 mt-1">
                          {isParticipant(escrow) ? (
                            <Link href={`/escrow/${escrow.id}`} className="hover:text-blue-400 transition-colors">
                              {escrow.title || "Untitled"}
                            </Link>
                          ) : (
                            <span>{escrow.title || "Untitled"}</span>
                          )}
                        </div>
                      </div>
                      <Badge className={`${getStatusColor(getEscrowStatus(escrow))} text-white`}>
                        {getEscrowStatus(escrow).replace("_", " ")}
                      </Badge>
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-gray-400">Depositor: {truncateAddress(escrow.depositor)}</p>
                    <p className="text-sm text-gray-400">
                      Amount: {escrow.amount} {escrow.isEth ? "ETH" : "Tokens"}
                    </p>
                    <p className="text-sm text-gray-400">Type: Standard</p>
                    <p className="text-sm text-gray-400">Receiver: {truncateAddress(escrow.receiver)}</p>
                    <p className="text-sm text-gray-400">Created: {formatDate(escrow.createdAt)}</p>
                    <p className="text-sm text-gray-400">Expires: {formatDate(escrow.expiryDate)}</p>
                    <div className="mt-4">
                      <Link href={`/escrow/${escrow.id}`}>
                        <Button variant="outline" className="w-full">
                          View Details
                        </Button>
                      </Link>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </motion.div>
      </div>
    </div>
  );
}
