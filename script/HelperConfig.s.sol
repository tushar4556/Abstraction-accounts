//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";

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
    address constant _FOUNDRY_DEFAULT_WALLET = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38; 

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
            return getOrCreateAnvilEthConfig(address(0));
        }
    }

    function getEthSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: _BURNER_WALLET});
    }

    function getZkSyncSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: _BURNER_WALLET});
    }

    function getOrCreateAnvilEthConfig(address deployerKey) public  returns (NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            return localNetworkConfig;
        }

        // If account not set or deployerKey not provided effectively, return config with the default foundry wallet
        // Or use deployerKey if it's valid.
        address accountToUse = deployerKey == address(0) ? _FOUNDRY_DEFAULT_WALLET : deployerKey;
        localNetworkConfig = NetworkConfig({entryPoint: address(0), account: accountToUse});
        return localNetworkConfig;
    }
}
