"use client";

import { useReadContract } from "wagmi";
import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { useParams } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Clock,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  User,
  UserCheck,
  Banknote,
  FileText,
  Calendar,
} from "lucide-react";
import { Timeline } from "@/components/Timeline";
import { ESCROW_CONTRACT_ADDRESS } from "@/constants/bestcrow";
import { ESCROW_CONTRACT_ABI } from "@/constants/abi";
import { parseUnits, formatUnits } from "viem";

// Mock function to fetch escrow details
const fetchEscrowDetails = async (id: string) => {
  // Simulating API call
  // await new Promise((resolve) => setTimeout(resolve, 1000));
  return {
    id: id,
    contractAddress: "0x1234567890123456789012345678901234567890",
    title: "Web3 Project Escrow",
    description: "Escrow for a decentralized application development project",
    amount: "5 ETH",
    status: "pending",
    type: "standard",
    depositor: "0xabcdef1234567890abcdef1234567890abcdef12",
    receiver: "0x2345678901234567890123456789012345678901",
    creationDate: "2023-06-01",
    expirationDate: "2023-12-31",
    steps: [
      { title: "Escrow Creation", description: "Depositor created escrow", completed: true },
      { title: "Escrow Accepted", description: "Receiver accepted escrow", completed: true },
      { title: "Payment Requested", description: "Receiver requested payment", completed: false },
      { title: "Payment Approved", description: "Depositor approved release of payment", completed: false },
      {
        title: "Payment Delivered",
        description: "Receiver obtained payment",
        completed: false,
        transactionAddress: "",
      },
    ],
  };
};

export default function EscrowDetails() {
  const params = useParams();
  const [escrow, setEscrow] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [escrowId, setEscrowId] = useState<string>("0");
  const [escrowDetails, setEscrowDetails] = useState<any>(null);

  useEffect(() => {
    const loadEscrowDetails = async () => {
      if (params.id) {
        const details = await fetchEscrowDetails(params.id as string);
        setEscrow(details);
        setLoading(false);
        setEscrowId(params.id as string);
      }
    };
    loadEscrowDetails();
  }, [params.id]);

  const { data: escrowData } = useReadContract({
    address: ESCROW_CONTRACT_ADDRESS,
    abi: ESCROW_CONTRACT_ABI,
    functionName: "escrowDetails",
    args: [escrowId],
  });

  useEffect(() => {
    if (escrowData && escrowData !== undefined) {
      console.log(escrowData);
      setEscrowDetails(escrowData);
    }
  }, [escrowData]);

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
      default:
        return "bg-gray-500";
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "active":
        return <Clock className="w-5 h-5" />;
      case "completed":
        return <CheckCircle2 className="w-5 h-5" />;
      case "pending":
        return <AlertTriangle className="w-5 h-5" />;
      case "expired":
        return <XCircle className="w-5 h-5" />;
      default:
        return null;
    }
  };

  const truncateAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8 pt-24">
        <div className="max-w-4xl mx-auto">
          <Skeleton className="h-12 w-3/4 bg-gray-700 mb-6" />
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Skeleton className="h-40 bg-gray-700" />
            <Skeleton className="h-40 bg-gray-700" />
            <Skeleton className="h-40 bg-gray-700" />
            <Skeleton className="h-40 bg-gray-700" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8 pt-24">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="max-w-4xl mx-auto"
      >
        <h1 className="text-4xl font-bold mb-8 text-center text-white">{escrow.title}</h1>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card className="bg-gray-800/50 backdrop-blur-lg border-gray-700">
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span className="text-white">Escrow Details</span>
                <Badge className={`${getStatusColor(escrow.status)} text-white flex items-center`}>
                  {getStatusIcon(escrow.status)}
                  <span className="ml-1 text-white">{escrow.status}</span>
                </Badge>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <p className="text-white">
                <FileText className="inline mr-2 text-white" />
                ID: {escrow.id}
              </p>
              <p className="text-white">
                <Banknote className="inline mr-2 text-white" />
                Amount: {escrowDetails !== null ? escrowDetails[4] : "NA"}
              </p>
              <p className="text-white">
                <Calendar className="inline mr-2 text-white" />
                Created: {escrow.creationDate}
              </p>
              <p className="text-white">
                <Calendar className="inline mr-2 text-white" />
                Expires: {escrow.expirationDate}
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gray-800/50 backdrop-blur-lg border-gray-700">
            <CardHeader>
              <CardTitle className="text-white">Parties Involved</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <p className="text-white">
                <User className="inline mr-2 text-white" />
                Depositor: {escrowDetails !== null ? truncateAddress(escrowDetails[0]) : "NA"}
              </p>
              <p className="text-white">
                <UserCheck className="inline mr-2 text-white" />
                Receiver: {escrowDetails !== null ? truncateAddress(escrowDetails[1]) : "NA"}
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gray-800/50 backdrop-blur-lg border-gray-700 md:col-span-2">
            <CardHeader>
              <CardTitle className="text-white">Escrow Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <Timeline steps={escrow.steps} />
            </CardContent>
          </Card>

          <Card className="bg-gray-800/50 backdrop-blur-lg border-gray-700 md:col-span-2">
            <CardHeader>
              <CardTitle className="text-white">Description</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-white">{escrow.description}</p>
            </CardContent>
          </Card>
        </div>

        <div className="mt-8 flex justify-center space-x-4">
          <Button variant="default" className="bg-green-600 hover:bg-green-700">
            Approve
          </Button>
          <Button variant="destructive">Dispute</Button>
        </div>
      </motion.div>
    </div>
  );
}
