"use client";

import { useReadContract, useAccount, useWriteContract } from "wagmi";
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
import { BESTCROW_ADDRESS } from "@/constants/bestcrow";
import { BESTCROW_ABI } from "@/constants/abi";
import { formatUnits } from "viem";

interface EscrowDetails {
  depositor: string;
  receiver: string;
  token: string;
  amount: bigint;
  expiryDate: bigint;
  title: string;
  isActive: boolean;
  isCompleted: boolean;
  isEthEscrow: boolean;
  releaseRequested: boolean;
  description: string;
}

interface TimelineStep {
  title: string;
  description: string;
  completed: boolean;
}

// Mock function to fetch escrow details
const fetchEscrowDetails = async (id: string) => {
  return {
    id: id,
  };
};

export default function EscrowDetails() {
  const params = useParams();
  const { address: walletAddress } = useAccount();
  const { writeContractAsync: writeContract, isPending } = useWriteContract();
  const [escrow, setEscrow] = useState<{ id: string } | null>(null);
  const [loading, setLoading] = useState(true);
  const [escrowId, setEscrowId] = useState<string>("0");
  const [escrowDetails, setEscrowDetails] = useState<EscrowDetails | null>(null);
  const [pendingAction, setPendingAction] = useState<string | null>(null);

  const { data: escrowData, refetch: refetchEscrowData } = useReadContract({
    address: BESTCROW_ADDRESS,
    abi: BESTCROW_ABI,
    functionName: "escrowDetails",
    args: [escrowId],
  });

  // Add refresh interval
  useEffect(() => {
    const interval = setInterval(() => {
      // This will trigger a re-fetch of the contract data
      if (escrowId !== "0") {
        refetchEscrowData();
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [escrowId, refetchEscrowData]);

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

  useEffect(() => {
    if (escrowData) {
      const [
        depositor,
        receiver,
        token,
        amount,
        expiryDate,
        createdAt,
        isActive,
        isCompleted,
        isEthEscrow,
        releaseRequested,
        title,
        description,
      ] = escrowData as [
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

      setEscrowDetails({
        depositor,
        receiver,
        token,
        amount,
        expiryDate,
        title,
        isActive,
        isCompleted,
        isEthEscrow,
        releaseRequested,
        description,
      });
      setLoading(false);
    }
  }, [escrowData]);

  const getEscrowStatus = (details: EscrowDetails | null) => {
    if (!details) return "unknown";

    const { isActive, isCompleted, releaseRequested } = details;

    if (!isActive && !releaseRequested && isCompleted) return "expired";
    if (!isActive && !isCompleted && !releaseRequested) return "pending";
    if (isActive && !isCompleted && !releaseRequested) return "active";
    if (isActive && !isCompleted && releaseRequested) return "release_requested";
    if (isCompleted && releaseRequested) return "completed";

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
      case "release_requested":
        return <Banknote className="w-5 h-5" />;
      default:
        return null;
    }
  };

  const formatDate = (timestamp: number) => {
    return (
      new Date(Number(timestamp) * 1000).toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        timeZone: "UTC",
      }) + " UTC"
    );
  };

  const truncateAddress = (address: string | undefined | null) => {
    if (!address) return "Unknown";
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const getTimelineSteps = (details: EscrowDetails | null): TimelineStep[] => {
    if (!details) return [];

    const { isActive, isCompleted, releaseRequested, depositor, receiver } = details;

    if (!isActive && !releaseRequested && isCompleted) {
      return [
        {
          title: "Escrow Created",
          description: `Escrow created by ${truncateAddress(depositor)}`,
          completed: true,
        },
        {
          title: "Escrow Expired",
          description: `${truncateAddress(receiver)} did not accept the escrow`,
          completed: true,
        },
      ];
    }

    return [
      {
        title: "Escrow Created",
        description: `Escrow created by ${truncateAddress(depositor)}`,
        completed: true,
      },
      {
        title: "Escrow Accepted",
        description: `Waiting for ${truncateAddress(receiver)} to accept and provide collateral`,
        completed: isActive || isCompleted,
      },
      {
        title: "Payment Release Requested",
        description: `${truncateAddress(receiver)} has requested the release of funds`,
        completed: releaseRequested || isCompleted,
      },
      {
        title: "Payment Released",
        description:
          isCompleted && releaseRequested
            ? `Funds have been released to ${truncateAddress(receiver)}`
            : `Awaiting fund release to ${truncateAddress(receiver)}`,
        completed: isCompleted && releaseRequested,
      },
    ];
  };

  const handleRequestRelease = async () => {
    try {
      await writeContract({
        address: BESTCROW_ADDRESS,
        abi: BESTCROW_ABI,
        functionName: "requestRelease",
        args: [escrowId],
      });
    } catch (error) {
      console.error("Error requesting release:", error);
    }
  };

  const handleAcceptEscrow = async () => {
    try {
      if (!escrowDetails) return;
      setPendingAction("accept");
      const collateralAmount = (escrowDetails.amount * BigInt(5000)) / BigInt(10000); // 50% collateral

      await writeContract({
        address: BESTCROW_ADDRESS,
        abi: BESTCROW_ABI,
        functionName: "acceptEscrow",
        args: [escrowId],
        value: escrowDetails.isEthEscrow ? collateralAmount : BigInt(0), // Only send value if it's an ETH escrow
      });
    } catch (error) {
      console.error("Error accepting escrow:", error);
    } finally {
      setPendingAction(null);
    }
  };

  const handleApproveRelease = async () => {
    try {
      await writeContract({
        address: BESTCROW_ADDRESS,
        abi: BESTCROW_ABI,
        functionName: "approveRelease",
        args: [escrowId],
      });
    } catch (error) {
      console.error("Error approving release:", error);
    }
  };

  const handleRejectEscrow = async () => {
    try {
      setPendingAction("reject");
      await writeContract({
        address: BESTCROW_ADDRESS,
        abi: BESTCROW_ABI,
        functionName: "rejectEscrow",
        args: [escrowId],
      });
    } catch (error) {
      console.error("Error rejecting escrow:", error);
    } finally {
      setPendingAction(null);
    }
  };

  const handleRefundEscrow = async () => {
    try {
      setPendingAction("refund");
      await writeContract({
        address: BESTCROW_ADDRESS,
        abi: BESTCROW_ABI,
        functionName: "refundExpiredEscrow",
        args: [escrowId],
      });
    } catch (error) {
      console.error("Error refunding escrow:", error);
    } finally {
      setPendingAction(null);
    }
  };

  const isParticipant = (details: EscrowDetails | null) => {
    if (!walletAddress || !details) return false;
    return (
      walletAddress.toLowerCase() === details.depositor.toLowerCase() ||
      walletAddress.toLowerCase() === details.receiver.toLowerCase()
    );
  };

  const renderBottomButtons = () => {
    if (!escrowDetails) return null;

    const status = getEscrowStatus(escrowDetails);
    const isDepositor = walletAddress?.toLowerCase() === escrowDetails.depositor.toLowerCase();
    const isReceiver = walletAddress?.toLowerCase() === escrowDetails.receiver.toLowerCase();
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const isExpired = currentTimestamp > Number(escrowDetails.expiryDate);

    if (status === "expired") {
      return (
        <div className="mt-8 text-center">
          <div className="bg-red-500/20 text-red-300 py-3 px-4 rounded-lg inline-flex items-center">
            <XCircle className="w-5 h-5 mr-2" />
            The escrow is no longer available
          </div>
        </div>
      );
    }

    if (status === "completed") {
      return (
        <div className="mt-8 text-center">
          <div className="bg-blue-500/20 text-blue-300 py-3 px-4 rounded-lg inline-flex items-center">
            <CheckCircle2 className="w-5 h-5 mr-2" />
            The escrow has been completed!
          </div>
        </div>
      );
    }

    if (isExpired && isDepositor && !status.includes("completed")) {
      return (
        <div className="mt-8 flex justify-center">
          <Button
            variant="default"
            className="bg-orange-600 hover:bg-orange-700 min-w-[100px]"
            onClick={handleRefundEscrow}
            disabled={isPending}
          >
            {isPending ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                Refunding...
              </div>
            ) : (
              "Refund"
            )}
          </Button>
        </div>
      );
    }

    if (status === "pending") {
      if (isDepositor) {
        return <div className="mt-8 text-center text-gray-400">Waiting for the receiver to accept the escrow</div>;
      }

      if (isReceiver) {
        return (
          <div className="mt-8 flex justify-center space-x-4">
            {(!pendingAction || pendingAction === "accept") && (
              <Button
                variant="default"
                className="bg-green-600 hover:bg-green-700 min-w-[100px]"
                onClick={handleAcceptEscrow}
                disabled={isPending}
              >
                {isPending ? (
                  <div className="flex items-center">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                    Accepting...
                  </div>
                ) : (
                  "Accept"
                )}
              </Button>
            )}
            {(!pendingAction || pendingAction === "reject") && (
              <Button
                variant="destructive"
                className="bg-red-600 hover:bg-red-700 min-w-[100px]"
                onClick={handleRejectEscrow}
                disabled={isPending}
              >
                {isPending ? (
                  <div className="flex items-center">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                    Rejecting...
                  </div>
                ) : (
                  "Reject"
                )}
              </Button>
            )}
          </div>
        );
      }
    }

    if (status === "active" && isReceiver) {
      return (
        <div className="mt-8 flex justify-center">
          <Button
            variant="default"
            className="bg-purple-600 hover:bg-purple-700 min-w-[140px]"
            onClick={handleRequestRelease}
            disabled={isPending}
          >
            {isPending ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                Requesting...
              </div>
            ) : (
              "Request Release"
            )}
          </Button>
        </div>
      );
    }

    if (status === "release_requested" && isDepositor) {
      return (
        <div className="mt-8 flex justify-center">
          <Button
            variant="default"
            className="bg-blue-600 hover:bg-blue-700 min-w-[140px]"
            onClick={handleApproveRelease}
            disabled={isPending}
          >
            {isPending ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                Approving...
              </div>
            ) : (
              "Approve Release"
            )}
          </Button>
        </div>
      );
    }

    return null;
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

  if (escrowDetails && !isParticipant(escrowDetails)) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8 pt-24">
        <div className="max-w-4xl mx-auto text-center">
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
            <div className="bg-red-500/20 text-red-300 py-6 px-8 rounded-xl inline-flex items-center">
              <XCircle className="w-6 h-6 mr-3" />
              You are not part of this escrow
            </div>
          </motion.div>
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
        <h1 className="text-4xl font-bold mb-8 text-center text-white">
          {escrowDetails ? escrowDetails.title : "Loading..."}
        </h1>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card className="bg-gray-800/50 backdrop-blur-lg border-gray-700">
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span className="text-white">Escrow Details</span>
                <Badge className={`${getStatusColor(getEscrowStatus(escrowDetails))} text-white flex items-center`}>
                  {getStatusIcon(getEscrowStatus(escrowDetails))}
                  <span className="ml-1 text-white capitalize">{getEscrowStatus(escrowDetails).replace("_", " ")}</span>
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
                Amount:{" "}
                {escrowDetails !== null
                  ? `${formatUnits(escrowDetails.amount, 18)} ${
                      escrowDetails.isEthEscrow
                        ? "ETH"
                        : escrowDetails.token === "0x0000000000000000000000000000000000000000"
                        ? "ETH"
                        : "Tokens"
                    }`
                  : "NA"}
              </p>
              <p className="text-white">
                <Calendar className="inline mr-2 text-white" />
                Created: {escrowDetails !== null ? formatDate(Number(escrowDetails.expiryDate)) : "Loading..."}
              </p>
              <p className="text-white">
                <Calendar className="inline mr-2 text-white" />
                Expires: {escrowDetails !== null ? formatDate(Number(escrowDetails.expiryDate)) : "NA"}
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
                Depositor: {escrowDetails !== null ? truncateAddress(escrowDetails.depositor) : "NA"}
              </p>
              <p className="text-white">
                <UserCheck className="inline mr-2 text-white" />
                Receiver: {escrowDetails !== null ? truncateAddress(escrowDetails.receiver) : "NA"}
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gray-800/50 backdrop-blur-lg border-gray-700 md:col-span-2">
            <CardHeader>
              <CardTitle className="text-white">Escrow Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <Timeline steps={escrowDetails ? getTimelineSteps(escrowDetails) : []} />
            </CardContent>
          </Card>

          <Card className="bg-gray-800/50 backdrop-blur-lg border-gray-700 md:col-span-2">
            <CardHeader>
              <CardTitle className="text-white">Description</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-white">{escrowDetails ? escrowDetails.description : "Loading..."}</p>
            </CardContent>
          </Card>
        </div>

        {renderBottomButtons()}
      </motion.div>
    </div>
  );
}
