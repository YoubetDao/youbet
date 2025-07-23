// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from 'forge-std/Script.sol';
import {Distributor} from '../src/Distributor.sol';
import {Upgrades, Options} from 'openzeppelin-foundry-upgrades/Upgrades.sol';

contract DistributorScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        address ownerAddress = vm.addr(deployerPrivateKey);
        address signerAddress = vm.envAddress('SIGNER_ADDRESS');
        address tokenAddress = vm.envAddress('TOKEN_ADDRESS');
        vm.startBroadcast(deployerPrivateKey);

        Options memory opts;
        opts.unsafeSkipStorageCheck = true;

        address proxy = Upgrades.deployUUPSProxy(
            'Distributor.sol:Distributor',
            abi.encodeCall(
                Distributor.initialize,
                (signerAddress, ownerAddress, tokenAddress)
            ),
            opts
        );

        console.log('Distributor proxy deployed at:', proxy);

        vm.stopBroadcast();
    }
}
