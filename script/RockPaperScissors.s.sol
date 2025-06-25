// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RockPaperScissors} from "../src/RockPaperScissors.sol";

contract RockPaperScissorsScript is Script {
    RockPaperScissors public rockPaperScissors;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the Rock Paper Scissors contract
        rockPaperScissors = new RockPaperScissors();
        
        console.log("Rock Paper Scissors deployed at:", address(rockPaperScissors));
        console.log("Next Game ID:", rockPaperScissors.nextGameId());
        console.log("Minimum Bet:", rockPaperScissors.MIN_BET());

        vm.stopBroadcast();
    }
}
