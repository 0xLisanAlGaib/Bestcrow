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
      address: "0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A",
      startBlock: 2865350,
    },
  },
});
