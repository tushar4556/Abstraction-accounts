//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {DeployMinimal} from "script/DeployMinimal.s.sol";
import {ERC20Mock} from "lib/openzepplin-contracts/contracts/mocks/ERC20Mock.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {SendPackedUserOp, PackedUserOperation} from "script/SendPackedUserOp.s.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    HelperConfig public helperConfig;
    MinimalAccount public minimalAccount;
    ERC20Mock public usdc;
    uint256 public constant AMOUNT = 1e18;
    SendPackedUserOp sendPackedUserOp;
    address user = makeAddr("User");

    function setUp() external {
        DeployMinimal deployM = new DeployMinimal();
        (helperConfig, minimalAccount) = deployM.deployMinimalAccount();
        usdc = new ERC20Mock("USDC", "USDC", address(this), 1000e18);
        sendPackedUserOp = new SendPackedUserOp();
    }

    function testOwnerCanExecuteCommands() external {
        //Arrange
        address user = makeAddr(("User"));
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //Act
        vm.startPrank(minimalAccount.owner());
        minimalAccount.execute(dest, value, data);

        //Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testRecoverSignedOp() public {
        //Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, data);

        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.genratedSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount));

        //Act
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        address actualSigner = ECDSA.recover(userOpHash.toEthSignedMessageHash(), packedUserOp.signature);

        //Assert
        assertEq(actualSigner, minimalAccount.owner(), "The signer should be the owner of the MinimalAccount");
    }

    function testValidatorOfUserOps() external {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, data);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.genratedSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount));
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 actualvalidationData = minimalAccount.validateUserOp(packedUserOp, userOpHash, 0);

        uint256 expectedValidationData = SIG_VALIDATION_SUCCESS;

        //Assert
        assertEq(actualvalidationData, expectedValidationData, "The validation data should be success");
    }

    function testEntryPointCanExecuteCommands() external {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, data);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.genratedSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount));
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        vm.deal(address(minimalAccount), 1e18);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;


        //Act
        vm.prank(user);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(user));

        //Assert

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
