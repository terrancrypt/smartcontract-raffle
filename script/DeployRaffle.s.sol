// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

/// @dev Nếu không có subscription thì tạo một cái trong chainlink VRF, sau đó fund LINK token vào subcription đó
/// @dev Sau khi có subscription thì add startBroadcast để deploy contract, có contract thì add Consumer subsctiption đã tạo (consumer là Contract chính / contract tạo random / contact sử dụng chainlink vrf)

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link
        ) = helperConfig.activeNetworkConfig();

        // Nếu không có subscriptionId thì cần tạo một cái
        if (subscriptionId == 0) {
            CreateSubscription createSubcription = new CreateSubscription();
            subscriptionId = createSubcription.createSubsciption(
                vrfCoordinator
            );

            // Fund it!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinator,
            subscriptionId
        );
        return (raffle, helperConfig);
    }
}
