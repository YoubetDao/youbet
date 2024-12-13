// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

contract DistributorUpgradeScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        console.log(
            "Deploy owner address: %s, proxy address: %s",
            deployerPrivateKey,
            proxyAddress
        );

        vm.startBroadcast(deployerPrivateKey);

        Options memory opts;
        opts.referenceContract = "Distributor.sol:Distributor";

        // Upgrade proxy to new implementation
        Upgrades.upgradeProxy(
            proxyAddress,
            "Distributor.sol:Distributor",
            "",
            opts
        );

        vm.stopBroadcast();
    }
}
