'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { FileText, Send, CheckCircle } from 'lucide-react'

interface TimelineItem {
  icon: React.ReactNode
  title: string
  description: string
}

const timelineItems: TimelineItem[] = [
  {
    icon: <FileText className="h-6 w-6 text-blue-400" />,
    title: "Create Contract",
    description: "Connect your wallet and fill out the escrow details, including the title, description, receiver address, asset, amount, and expiry date. The funds will be locked in the smart contract."
  },
  {
    icon: <Send className="h-6 w-6 text-green-400" />,
    title: "Accept Escrow",
    description: "The receiver connects their wallet, reviews the contract in detail, and accepts it by depositing the required collateral."
  },
  {
    icon: <CheckCircle className="h-6 w-6 text-yellow-400" />,
    title: "Release Funds",
    description: "Once the receiver delivers on what is agreed and the depositor is satisfied, the funds are released to the receiver."
  }
]

export function InteractiveTimeline() {
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null)

  return (
    <div className="relative pl-3">
      <div className="absolute left-0 top-4 bottom-4 w-0.5 bg-gray-600" />
      {timelineItems.map((item, index) => (
        <TimelineItem
          key={index}
          item={item}
          isActive={hoveredIndex === index}
          index={index}
          totalItems={timelineItems.length}
          onMouseEnter={() => setHoveredIndex(index)}
          onMouseLeave={() => setHoveredIndex(null)}
        />
      ))}
    </div>
  )
}

function TimelineItem({ 
  item, 
  isActive, 
  index, 
  totalItems, 
  onMouseEnter, 
  onMouseLeave 
}: { 
  item: TimelineItem; 
  isActive: boolean; 
  index: number; 
  totalItems: number;
  onMouseEnter: () => void;
  onMouseLeave: () => void;
}) {
  return (
    <div className="relative" onMouseEnter={onMouseEnter} onMouseLeave={onMouseLeave}>
      <div
        className={`absolute left-0 rounded-full transition-all duration-300 z-10 ${
          isActive ? 'bg-blue-500 w-6 h-6 -ml-3.5' : 'bg-gray-500 w-4 h-4 -ml-2.5'
        }`}
        style={{
          top: index === 0 ? '0' : index === totalItems - 1 ? 'auto' : '50%',
          bottom: index === totalItems - 1 ? '0' : 'auto',
          transform: index === 0 || index === totalItems - 1 ? 'translateX(-50%)' : 'translate(-50%, -50%)',
        }}
      />
      <div
        className="timeline-item ml-6 transition-all duration-300 ease-out"
        style={{
          paddingTop: index === 0 ? '0' : '4rem',
          paddingBottom: index === totalItems - 1 ? '0' : '4rem',
        }}
      >
        <Card
          className={`bg-white/10 backdrop-blur-lg border-none transition-all duration-300 ${
            isActive ? 'shadow-lg shadow-blue-500/20' : ''
          }`}
        >
          <CardHeader>
            <CardTitle className="flex items-center text-xl font-semibold text-white">
              {item.icon}
              <span className="ml-2">{item.title}</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-gray-300">{item.description}</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

