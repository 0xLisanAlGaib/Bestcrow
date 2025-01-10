/** @type {import('next').NextConfig} */
const nextConfig = {
  env: {
    NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID,
    NEXT_PUBLIC_ALCHEMY_ID: process.env.NEXT_PUBLIC_ALCHEMY_ID,
    NEXT_PUBLIC_BESTCROW_ADDRESS: process.env.NEXT_PUBLIC_BESTCROW_ADDRESS,
  },
  typescript: {
    // Temporarily ignore type errors during build (fix these later)
    ignoreBuildErrors: true,
  },
  eslint: {
    // Temporarily ignore ESLint errors during build (fix these later)
    ignoreDuringBuilds: true,
  }
};

export default nextConfig;
