import Link from 'next/link'
import AnimatedBackground from '../components/AnimatedBackground'
import AnimatedWaveBackground from '../components/AnimatedWaveBackground'
import { InteractiveTimeline } from '../components/InteractiveTimeline'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowRight, MessageSquare, ShieldCheck, Clock } from 'lucide-react'
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"

export default function Home() {
  return (
    <div className="flex flex-col relative">
      <div className="fixed inset-0 z-0">
        <AnimatedBackground />
      </div>
      <div className="relative z-10">
        {/* Hero Section */}
        <section className="flex flex-col items-center justify-center min-h-screen p-4 text-center">
          <h1 className="text-5xl md:text-6xl font-bold mb-8 animate-title text-white">
            Welcome to Bestcrow
          </h1>
          <p className="text-xl md:text-2xl mb-12 animate-fade-in text-white max-w-2xl">
            Secure, transparent, and effortless Web3 escrows
          </p>
          <div className="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4 justify-center">
            <Link 
              href="/create-escrow" 
              className="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded transition duration-300 animate-fade-in"
            >
              Create Escrow
            </Link>
            <Link 
              href="/escrow-pool" 
              className="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded transition duration-300 animate-fade-in"
            >
              View Escrow Pool
            </Link>
          </div>
        </section>

        {/* How Bestcrow Works Section */}
        <section className="py-16 px-4 min-h-screen flex flex-col justify-center">
          <div className="container mx-auto">
            <h2 className="text-4xl font-bold mb-12 text-center text-white">How Bestcrow Works</h2>
            <InteractiveTimeline />
            <div className="mt-12 text-center">
              <Link 
                href="/create-escrow" 
                className="inline-flex items-center bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded transition duration-300"
              >
                Get Started
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </div>
          </div>
        </section>

        {/* FAQ Section */}
        <section className="py-16 px-4 bg-[#0d2238]">
          <div className="container mx-auto">
            <h2 className="text-4xl font-bold mb-12 text-center text-white">Frequently Asked Questions</h2>
            <Accordion type="single" collapsible className="w-full max-w-2xl mx-auto space-y-4">
              <AccordionItem value="item-1" className="border-b-0">
                <AccordionTrigger className="text-left text-lg font-semibold text-white bg-[#1a365d] p-4 rounded-lg hover:bg-[#2c4a7c] transition-all duration-300 ease-in-out">
                  What is Bestcrow?
                </AccordionTrigger>
                <AccordionContent className="text-gray-300 mt-2 p-4 bg-[#15304f] rounded-lg">
                  Bestcrow is a decentralized escrow platform built on blockchain technology. It allows users to create secure, transparent, and automated escrow contracts for various transactions, providing a trustless environment for both parties involved.
                </AccordionContent>
              </AccordionItem>
              <AccordionItem value="item-2" className="border-b-0">
                <AccordionTrigger className="text-left text-lg font-semibold text-white bg-[#1a365d] p-4 rounded-lg hover:bg-[#2c4a7c] transition-all duration-300 ease-in-out">
                  How does a crypto escrow work?
                </AccordionTrigger>
                <AccordionContent className="text-gray-300 mt-2 p-4 bg-[#15304f] rounded-lg">
                  A crypto escrow works by holding funds in a smart contract until certain conditions are met. The depositor sends funds to the contract, which are then locked. Once the receiver fulfills the agreed-upon conditions and both parties confirm, the funds are automatically released to the receiver.
                </AccordionContent>
              </AccordionItem>
              <AccordionItem value="item-3" className="border-b-0">
                <AccordionTrigger className="text-left text-lg font-semibold text-white bg-[#1a365d] p-4 rounded-lg hover:bg-[#2c4a7c] transition-all duration-300 ease-in-out">
                  How much does it cost to escrow?
                </AccordionTrigger>
                <AccordionContent className="text-gray-300 mt-2 p-4 bg-[#15304f] rounded-lg">
                  The cost of using Bestcrow includes a small platform fee (0.5% of the escrow amount) and the necessary gas fees for blockchain transactions. The exact amount can vary depending on network congestion and the complexity of the escrow contract. We strive to keep our fees competitive and transparent.
                </AccordionContent>
              </AccordionItem>
              <AccordionItem value="item-4" className="border-b-0">
                <AccordionTrigger className="text-left text-lg font-semibold text-white bg-[#1a365d] p-4 rounded-lg hover:bg-[#2c4a7c] transition-all duration-300 ease-in-out">
                  What happens if either the depositor or receiver is trying to rug the other?
                </AccordionTrigger>
                <AccordionContent className="text-gray-300 mt-2 p-4 bg-[#15304f] rounded-lg">
                  Bestcrow's smart contracts are designed to prevent rug pulls. Funds are locked in the contract and can only be released when both parties agree. Failure to achieve this agreement will keep the escrowed amount and collateral in the contract.
                </AccordionContent>
              </AccordionItem>
            </Accordion>
          </div>
        </section>

        {/* Best Practices Section */}
        <section className="py-16 px-4 bg-gradient-to-br from-[#0a192f] to-[#112240] relative overflow-hidden">
          <AnimatedWaveBackground />
          <div className="container mx-auto relative z-10">
            <h2 className="text-5xl font-bold mb-16 text-center text-white bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-600">
              Best Practices for Successful Escrows
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              <Card className="bg-white/10 backdrop-blur-lg border-none group hover:shadow-xl transition-all duration-300 overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 to-purple-600/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-semibold text-white group-hover:text-blue-300 transition-colors duration-300">
                    <MessageSquare className="mr-2 h-6 w-6 text-blue-400 transition-all duration-300 ease-in-out group-hover:rotate-12 group-hover:scale-110" />
                    Clear Communication
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-gray-300 group-hover:text-white transition-colors duration-300">
                    Be as clear and detailed as possible with the receiver about the terms and conditions of the escrow. The clearer the communication, the less likely it is for either party to be dissatisfied with the outcome. The receiver should only accept the escrow if they are confident in the terms and conditions.
                  </p>
                </CardContent>
              </Card>

              <Card className="bg-white/10 backdrop-blur-lg border-none group hover:shadow-xl transition-all duration-300 overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-green-500/20 to-blue-600/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-semibold text-white group-hover:text-green-300 transition-colors duration-300">
                    <ShieldCheck className="mr-2 h-6 w-6 text-green-400 transition-all duration-300 ease-in-out group-hover:rotate-12 group-hover:scale-110" />
                    Verify Identities
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-gray-300 group-hover:text-white transition-colors duration-300">
                    Always verify the identity and reputation of the other party before entering into an escrow agreement. Try to have a grasp of what the receiver has been able to deliver in the past, or on the other hand, if the depositor has been able to fulfill their part on previous agreements.
                  </p>
                </CardContent>
              </Card>

              <Card className="bg-white/10 backdrop-blur-lg border-none group hover:shadow-xl transition-all duration-300 overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-yellow-500/20 to-red-600/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-semibold text-white group-hover:text-yellow-300 transition-colors duration-300">
                    <Clock className="mr-2 h-6 w-6 text-yellow-400 transition-all duration-300 ease-in-out group-hover:rotate-12 group-hover:scale-110" />
                    Set Realistic Timeframes
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-gray-300 group-hover:text-white transition-colors duration-300">
                    Establish realistic timeframes for the completion of the transaction. Consider potential delays and set the expiry date accordingly to avoid unnecessary disputes. The receiver should only accept the escrow if they are confident in the timeframes.
                  </p>
                </CardContent>
              </Card>
            </div>
          </div>
        </section>
      </div>
    </div>
  )
}

