// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mock/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubcriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();

        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();

        return createSubsciption(vrfCoordinator);
    }

    function createSubsciption(address vrfCoordinator) public returns (uint64) {
        console.log("Creating subsciption on chainId: ", block.chainid);

        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription id is: ", subId);
        return subId;
    }

    function run() external returns (uint64) {
        return createSubcriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubcriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            address link
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, link);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subId,
        address link
    ) public {
        console.log("Funding subscription: ", subId);
        console.log("Using VRF Coordinator: ", vrfCoordinator);
        console.log("On chainId:", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubcriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address raffle,
        address vrfCoordinator,
        uint64 subscriptionId
    ) public {
        console.log("Adding consumer contract:", raffle);
        console.log("Using vrfCoordinator", vrfCoordinator);
        console.log("On chainId", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            raffle
        );
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();

        (, , address vrfCoordinator, , uint64 subscriptionId, , ) = helperConfig
            .activeNetworkConfig();

        addConsumer(raffle, vrfCoordinator, subscriptionId);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );

        addConsumerUsingConfig(raffle);
    }
}
