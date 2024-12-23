"use client";

import { useRouter } from "next/navigation";
import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Loader2, ArrowRight, Shield } from "lucide-react";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { ESCROW_CONTRACT_ADDRESS } from "@/constants/bestcrow";
import { ESCROW_CONTRACT_ABI } from "@/constants/abi";
import { parseUnits, parseEther } from "viem";
import { ESCROW_FEE, DENOMINATOR, ESCROW_FEE_BASIS_POINTS } from "@/constants/fees";
import { hexToString, hexToBigInt, formatUnits } from "viem";
import dynamic from "next/dynamic";
import "react-datepicker/dist/react-datepicker.css";

// @ts-ignore
const ReactDatePicker = dynamic(() => import("react-datepicker"), { ssr: false });

// Add CSS to remove spinner buttons
const styles = `
  input[type=number]::-webkit-inner-spin-button,
  input[type=number]::-webkit-outer-spin-button {
    -webkit-appearance: none;
    margin: 0;
  }
  input[type=number] {
    -moz-appearance: textfield;
  }
`;

interface CustomDatePickerProps {
  selected: Date;
  onChange: (date: Date | null) => void;
}

const CustomDatePicker = ({ selected, onChange }: CustomDatePickerProps) => (
  // @ts-ignore
  <ReactDatePicker
    selected={selected}
    onChange={onChange}
    showTimeSelect
    timeFormat="HH:mm"
    timeIntervals={15}
    dateFormat="MMMM d, yyyy h:mm aa"
    minDate={new Date()}
    className="w-full bg-gray-700 border-gray-600 text-white placeholder-gray-400 rounded-md px-3 py-2"
    wrapperClassName="w-full"
  />
);

export default function CreateEscrow() {
  const router = useRouter();
  const { data: hash, isPending, writeContract } = useWriteContract();

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [escrowAsset, setEscrowAsset] = useState("ETH");
  const [formState, setFormState] = useState({
    title: "",
    description: "",
    receiver: "",
    tokenAddress: "",
    amount: "",
    expiryDate: new Date(),
  });
  const [escrowType, setEscrowType] = useState("standard");

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormState((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setIsSubmitting(true);

    // Params
    const token = "0x0000000000000000000000000000000000000000";
    const amount = parseUnits(formState.amount, 18);
    const expiryDate = parseUnits(Math.floor(formState.expiryDate.getTime() / 1000).toString(), 0);
    const receiver = formState.receiver;
    const msgValue = amount + (amount * ESCROW_FEE) / DENOMINATOR;

    console.log(token, amount, expiryDate, receiver, msgValue);

    // Simulating form submission
    writeContract({
      abi: ESCROW_CONTRACT_ABI,
      address: ESCROW_CONTRACT_ADDRESS,
      functionName: "createEscrow",
      args: [token, amount, expiryDate, receiver],
      value: msgValue,
    });

    setIsSubmitting(false);
  };

  // Helper hooks to wait for the transaction to be confirmed
  const {
    data: logs,
    isLoading: isConfirming,
    isSuccess: isConfirmed,
  } = useWaitForTransactionReceipt({
    hash,
  });

  // This useEffect is triggered when the transaction is confirmed, to redirect to the escrow page
  useEffect(() => {
    if (logs && logs !== undefined) {
      console.log(logs);
      if (logs && logs.logs && logs.logs[0] && logs.logs[0].topics && logs.logs[0].topics[1]) {
        console.log(logs.logs[0].topics[1]);
        console.log(formatUnits(hexToBigInt(logs.logs[0].topics[1]), 0));
        router.push(`/escrow/${formatUnits(hexToBigInt(logs.logs[0].topics[1]), 0)}`);
      }
    }
  }, [logs]);

  const getLabelColor = (fieldName: string) => {
    return formState[fieldName as keyof typeof formState] ? "text-orange-300" : "text-white";
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 flex items-center justify-center p-4">
      <style jsx global>
        {styles}
      </style>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="w-full max-w-2xl"
      >
        <Card className="bg-gray-800/50 backdrop-blur-lg border-gray-700 shadow-xl">
          <CardHeader className="text-center">
            <CardTitle className="text-3xl font-bold text-white">Create New Escrow</CardTitle>
            <CardDescription className="text-gray-400">Set up a secure escrow for your transaction</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="title" className={`${getLabelColor("title")} transition-colors duration-300`}>
                  Escrow Title
                </Label>
                <Input
                  id="title"
                  name="title"
                  value={formState.title}
                  onChange={handleInputChange}
                  placeholder="Enter a title for your escrow"
                  className="bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                />
              </div>
              <div className="space-y-2">
                <Label
                  htmlFor="description"
                  className={`${getLabelColor("description")} transition-colors duration-300`}
                >
                  Description
                </Label>
                <Textarea
                  id="description"
                  name="description"
                  value={formState.description}
                  onChange={handleInputChange}
                  placeholder="Describe the terms of your escrow"
                  className="bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="receiver" className={`${getLabelColor("receiver")} transition-colors duration-300`}>
                  Receiver Address
                </Label>
                <Input
                  id="receiver"
                  name="receiver"
                  value={formState.receiver}
                  onChange={handleInputChange}
                  placeholder="0x..."
                  className="bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="asset" className="text-white">
                  Escrow Asset
                </Label>
                <Select onValueChange={setEscrowAsset} defaultValue={escrowAsset}>
                  <SelectTrigger className="bg-gray-700 border-gray-600 text-white">
                    <SelectValue placeholder="Select asset" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-700 border-gray-600 text-white">
                    <SelectItem value="ETH">ETH</SelectItem>
                    {/* <SelectItem value="ERC20">ERC20</SelectItem> */}
                  </SelectContent>
                </Select>
              </div>
              {escrowAsset === "ERC20" && (
                <div className="space-y-2">
                  <Label
                    htmlFor="tokenAddress"
                    className={`${getLabelColor("tokenAddress")} transition-colors duration-300`}
                  >
                    Token Address
                  </Label>
                  <Input
                    id="tokenAddress"
                    name="tokenAddress"
                    value={formState.tokenAddress}
                    onChange={handleInputChange}
                    placeholder="0x..."
                    className="bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                  />
                </div>
              )}
              <div className="space-y-2">
                <Label htmlFor="amount" className={`${getLabelColor("amount")} transition-colors duration-300`}>
                  Amount
                </Label>
                <Input
                  id="amount"
                  name="amount"
                  value={formState.amount}
                  onChange={handleInputChange}
                  type="number"
                  min="0"
                  step="0.000001"
                  placeholder="0.00"
                  className="bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="expiryDate" className="text-white">
                  Expiry Date
                </Label>
                <div className="relative">
                  <CustomDatePicker
                    selected={formState.expiryDate}
                    onChange={(date: Date | null) =>
                      setFormState((prev) => ({ ...prev, expiryDate: date || new Date() }))
                    }
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label className="text-white">Escrow Type</Label>
                <RadioGroup value={escrowType} onValueChange={setEscrowType} className="flex space-x-4">
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="standard" id="standard" className="border-gray-600 text-blue-500" />
                    <Label htmlFor="standard" className="text-white">
                      Standard
                    </Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="milestone" id="milestone" className="border-gray-600 text-blue-500" />
                    <Label htmlFor="milestone" className="text-white">
                      Milestone-based
                    </Label>
                  </div>
                </RadioGroup>
                {escrowType === "milestone" && (
                  <p className="text-red-500 text-sm mt-2">
                    Milestone-based escrows are not available yet. Please choose the standard option.
                  </p>
                )}
              </div>
            </form>
          </CardContent>
          <CardFooter>
            <Button
              onClick={handleSubmit}
              disabled={isSubmitting || escrowType === "milestone"}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded transition duration-300 flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Creating Escrow...
                </>
              ) : (
                <>
                  Create Escrow
                  <ArrowRight className="ml-2 h-4 w-4" />
                </>
              )}
            </Button>
          </CardFooter>
        </Card>
      </motion.div>
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.3, duration: 0.5 }}
        className="fixed bottom-4 right-4"
      >
        <div className="bg-blue-600 text-white p-3 rounded-full shadow-lg flex items-center space-x-2">
          <Shield className="h-6 w-6" />
          <span className="text-sm font-medium">Secure Escrow</span>
        </div>
      </motion.div>
    </div>
  );
}
