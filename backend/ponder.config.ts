import { createConfig } from "@ponder/core";
import { http } from "viem";

import { BestcrowAbi } from "./abis/BestcrowAbi";

export default createConfig({
  networks: {
    holesky: {
      chainId: 17000,
      transport: http(process.env.PONDER_RPC_URL_1),
    },
  },
  contracts: {
    Bestcrow: {
      network: "holesky",
      abi: BestcrowAbi,
      address: "0x77C385fD50164Fde71A6c29732F9F7763AAC6753",
      startBlock: 3081000,
    },
  },
});
