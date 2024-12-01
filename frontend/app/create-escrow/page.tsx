'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Loader2, ArrowRight, Shield } from 'lucide-react'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

export default function CreateEscrow() {
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [escrowAsset, setEscrowAsset] = useState('ETH')
  const [formState, setFormState] = useState({
    title: '',
    description: '',
    receiver: '',
    tokenAddress: '',
    amount: '',
  })
  const [escrowType, setEscrowType] = useState('standard')

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormState(prev => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    setIsSubmitting(true)
    // Simulating form submission
    await new Promise(resolve => setTimeout(resolve, 2000))
    setIsSubmitting(false)
    // Handle the actual form submission logic here
  }

  const getLabelColor = (fieldName: string) => {
    return formState[fieldName as keyof typeof formState] ? 'text-orange-300' : 'text-white'
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 flex items-center justify-center p-4">
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
                <Label htmlFor="title" className={`${getLabelColor('title')} transition-colors duration-300`}>Escrow Title</Label>
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
                <Label htmlFor="description" className={`${getLabelColor('description')} transition-colors duration-300`}>Description</Label>
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
                <Label htmlFor="receiver" className={`${getLabelColor('receiver')} transition-colors duration-300`}>Receiver Address</Label>
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
                <Label htmlFor="asset" className="text-white">Escrow Asset</Label>
                <Select onValueChange={setEscrowAsset} defaultValue={escrowAsset}>
                  <SelectTrigger className="bg-gray-700 border-gray-600 text-white">
                    <SelectValue placeholder="Select asset" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-700 border-gray-600 text-white">
                    <SelectItem value="ETH">ETH</SelectItem>
                    <SelectItem value="ERC20">ERC20</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              {escrowAsset === 'ERC20' && (
                <div className="space-y-2">
                  <Label htmlFor="tokenAddress" className={`${getLabelColor('tokenAddress')} transition-colors duration-300`}>Token Address</Label>
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
                <Label htmlFor="amount" className={`${getLabelColor('amount')} transition-colors duration-300`}>Amount</Label>
                <Input 
                  id="amount" 
                  name="amount"
                  value={formState.amount}
                  onChange={handleInputChange}
                  type="number" 
                  step="0.000001" 
                  placeholder="0.00" 
                  className="bg-gray-700 border-gray-600 text-white placeholder-gray-400" 
                />
              </div>
              <div className="space-y-2">
                <Label className="text-white">Escrow Type</Label>
                <RadioGroup value={escrowType} onValueChange={setEscrowType} className="flex space-x-4">
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="standard" id="standard" className="border-gray-600 text-blue-500" />
                    <Label htmlFor="standard" className="text-white">Standard</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="milestone" id="milestone" className="border-gray-600 text-blue-500" />
                    <Label htmlFor="milestone" className="text-white">Milestone-based</Label>
                  </div>
                </RadioGroup>
                {escrowType === 'milestone' && (
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
              disabled={isSubmitting || escrowType === 'milestone'}
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
  )
}

