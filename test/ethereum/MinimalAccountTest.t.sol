//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {DeployMinimal} from "script/DeployMinimal.s.sol";
import {ERC20Mock} from "lib/openzepplin-contracts/contracts/mocks/ERC20Mock.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract MinimalAccountTest is Test {
    HelperConfig public helperConfig;
    MinimalAccount public minimalAccount;
    ERC20Mock public usdc;
    uint256 constant public  AMOUNT = 1e18;

    function setUp() external {
        DeployMinimal deployM = new DeployMinimal();
        (helperConfig, minimalAccount) = deployM.deployMinimalAccount();
        usdc = new ERC20Mock("USDC", "USDC", address(this), 1000e18);
    }

    function testOwnerCanExecuteCommands() external {
        //Arrange
        address user = makeAddr(("User"));
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount),AMOUNT );

        //Act
        vm.startPrank(minimalAccount.owner());
        minimalAccount.execute(dest, value, data);

        //Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}