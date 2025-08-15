//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant _ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant _ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant _LOCAL_CHAIN_ID = 31337;
    address constant _BURNER_WALLET = 0x5EF1EEb98Ff418a205832656c254c509d8374495;
    // address constant _FOUNDRY_DEFAULT_WALLET = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address constant _FOUNDRY_DEFAULT_WALLET = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[_ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[_ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chaidId) public returns (NetworkConfig memory) {
        if (chaidId == _ETH_SEPOLIA_CHAIN_ID) {
            return getEthSepoliaConfig();
        } else if (chaidId == _ZKSYNC_SEPOLIA_CHAIN_ID) {
            return getZkSyncSepoliaConfig();
        } else {
            return getOrCreateAnvilEthConfig();
        }
    }

    function getEthSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: _BURNER_WALLET});
    }

    function getZkSyncSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: _BURNER_WALLET});
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            return localNetworkConfig;
        }

        //deploy mocks..
        console2.log("Deploying mocks");
        vm.startBroadcast(_FOUNDRY_DEFAULT_WALLET);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({entryPoint: address(entryPoint), account: _FOUNDRY_DEFAULT_WALLET});

        return (localNetworkConfig);
    }
}
