import { createConfig } from "ponder";
import { http } from "viem";

import { BestcrowAbi } from "./abis/BestcrowAbi";

export default createConfig({
  networks: {
    arbitrum: {
      chainId: 42161,
      transport: http(process.env.ARBITRUM_RPC_URL_42161),
    },
  },
  contracts: {
    Bestcrow: {
      network: "arbitrum",
      abi: BestcrowAbi,
      address: "0x718D184786561e6D12a7fe66aD71504Ce90aEee3",
      startBlock: 3090600,
    },
  },
});
