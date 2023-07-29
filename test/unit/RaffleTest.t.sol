// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {
    // Events
    event EnteredRaffle(address indexed player);

    Raffle public raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    // enterRaffle
    function testRaffleRevertWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSend.selector);

        raffle.enterRaffle();
    }

    function testRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    // checkUpkeep
    function testUpKeepReturnFalseIfNoBalance() public {
        // Arrange
        vm.warp(block.chainid + interval + 1);
        vm.roll(block.number + 1);

        // Action
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        // Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepIfRaffleNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.chainid + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Action
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        // Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {}

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {}

    // performUpKeep
    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.chainid + interval + 1);
        vm.roll(block.number + 1);

        // Action / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertIfCheckUpkeepFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayer = 0;
        uint256 raffleState = 0;

        // Action / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayer,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    // Nếu cần đầu ra của một output để test thì sao? => thì cho output đó vào event và dùng event để kiểm tra output
    function testPerformUpkeepUpdatesIfRaffleStateAndEmitRequetId()
        public
        RaffleEnterAndTimePassed
    {
        // Action
        vm.recordLogs();
        raffle.performUpkeep(""); // emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
    }

    // Modifier
    modifier RaffleEnterAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.chainid + interval + 1);
        vm.roll(block.number + 1);
        _;
    }
}
