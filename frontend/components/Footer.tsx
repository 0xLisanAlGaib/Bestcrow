import Link from 'next/link'
import { Github, Twitter, Mail } from 'lucide-react'

export function Footer() {
  return (
    <footer className="bg-[#0d2238] text-white py-6 relative z-10">
      <div className="container mx-auto px-4">
        <div className="flex justify-center items-center space-x-6">
          <Link href="https://github.com/0xLisanAlGaib/Bestcrow" target="_blank" rel="noopener noreferrer" className="hover:text-blue-400 transition-colors">
            <Github className="w-6 h-6" />
            <span className="sr-only">GitHub</span>
          </Link>
          <Link href="https://x.com/0xLisanAlGaib" target="_blank" rel="noopener noreferrer" className="hover:text-blue-400 transition-colors">
            <Twitter className="w-6 h-6" />
            <span className="sr-only">X (Twitter)</span>
          </Link>
          <Link href="https://medium.com/@0xlisanalgaib" target="_blank" rel="noopener noreferrer" className="hover:text-blue-400 transition-colors">
            <svg viewBox="0 0 1043.63 592.71" className="w-6 h-6 fill-current">
              <g>
                <path d="M588.67 296.36c0 163.67-131.78 296.35-294.33 296.35S0 460 0 296.36 131.78 0 294.34 0s294.33 132.69 294.33 296.36M911.56 296.36c0 154.06-65.89 279-147.17 279s-147.17-124.94-147.17-279 65.88-279 147.16-279 147.17 124.9 147.17 279M1043.63 296.36c0 138-23.17 249.94-51.76 249.94s-51.75-111.91-51.75-249.94 23.17-249.94 51.75-249.94 51.76 111.9 51.76 249.94"></path>
              </g>
            </svg>
            <span className="sr-only">Medium</span>
          </Link>
          <Link href="mailto:0xlisanalgaib@gmail.com" className="hover:text-blue-400 transition-colors">
            <Mail className="w-6 h-6" />
            <span className="sr-only">Email</span>
          </Link>
        </div>
        <div className="text-center mt-4 text-sm text-gray-400">
          © {new Date().getFullYear()} Bestcrow. All rights reserved.
        </div>
      </div>
    </footer>
  )
}

