import { CheckCircle2, Clock } from 'lucide-react'

type Step = {
  title: string;
  description: string;
  completed: boolean;
  transactionAddress?: string;
}

type TimelineProps = {
  steps: Step[];
}

export function Timeline({ steps }: TimelineProps) {
  return (
    <div className="relative">
      <div className="absolute left-4 top-4 bottom-4 w-0.5 bg-gray-600" />
      {steps.map((step, index) => (
        <div 
          key={index} 
          className="mb-8 flex items-center"
          style={{
            marginTop: index === 0 ? '0' : '',
            marginBottom: index === steps.length - 1 ? '0' : '',
          }}
        >
          <div 
            className={`relative z-10 flex items-center justify-center w-8 h-8 rounded-full border-2 ${
              step.completed ? 'bg-green-500 border-green-500' : 'bg-gray-700 border-gray-600'
            }`}
            style={{
              marginTop: index === 0 ? '0' : '',
              marginBottom: index === steps.length - 1 ? '0' : '',
            }}
          >
            {step.completed ? (
              <CheckCircle2 className="w-5 h-5 text-white" />
            ) : (
              <Clock className="w-5 h-5 text-gray-400" />
            )}
          </div>
          <div className="ml-4 flex-grow">
            <h3 className={`text-lg font-semibold ${step.completed ? 'text-green-400' : 'text-white'}`}>
              {step.title}
            </h3>
            <p className="text-gray-400">{step.description}</p>
            {step.transactionAddress && (
              <p className="text-sm text-blue-400 mt-1">
                Tx: {step.transactionAddress}
              </p>
            )}
          </div>
        </div>
      ))}
    </div>
  )
}

