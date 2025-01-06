import { createConfig } from "ponder";
import { http } from "viem";

import { BestcrowAbi } from "./abis/BestcrowAbi";

export default createConfig({
  networks: {
    holesky: {
      chainId: 17000,
      transport: http(process.env.HOLESKY_RPC_URL_17000),
    },
  },
  contracts: {
    Bestcrow: {
      network: "holesky",
      abi: BestcrowAbi,
      address: "0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6",
      startBlock: 3090600,
    },
  },
});
