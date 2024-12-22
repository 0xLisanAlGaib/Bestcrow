// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "@forge-std/Script.sol";
import {Bestcrow} from "../src/Bestcrow.sol";

contract DeployBestcrow is Script {
    function run() external returns (Bestcrow) {
        // Begin recording transactions for deployment
        vm.startBroadcast();

        // Deploy the Bestcrow contract
        Bestcrow bestcrow = new Bestcrow();

        vm.stopBroadcast();
        return bestcrow;
    }
}
