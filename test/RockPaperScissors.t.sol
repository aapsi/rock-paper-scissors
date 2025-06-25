// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {RockPaperScissors} from "../src/RockPaperScissors.sol";

contract RockPaperScissorsTest is Test {
    RockPaperScissors public game;
    
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    
    uint256 public constant MIN_BET = 0.001 ether;
    uint256 public constant COMMIT_TIMEOUT = 10 minutes;
    uint256 public constant REVEAL_TIMEOUT = 5 minutes;
    
    event GameCreated(uint256 indexed gameId, address indexed creator, uint256 betAmount);
    event PlayerJoined(uint256 indexed gameId, address indexed player);
    event MoveCommitted(uint256 indexed gameId, address indexed player);
    event MoveRevealed(uint256 indexed gameId, address indexed player, RockPaperScissors.MoveOption move);
    event GameFinished(uint256 indexed gameId, address indexed winner, uint256 prize);
    event GameTimedOut(uint256 indexed gameId, address indexed winner);
    
    function setUp() public {
        game = new RockPaperScissors();
        
        // Fund test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
    }
    
    // Helper function to generate commitment
    function generateCommitment(
        RockPaperScissors.MoveOption move, 
        bytes32 secret, 
        address player
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(move, secret, player));
    }
    
    // Helper function to create and join a game
    function createAndJoinGame(uint256 betAmount) internal returns (uint256 gameId) {
        vm.prank(alice);
        gameId = game.createGame{value: betAmount}();
        
        vm.prank(bob);
        game.joinGame{value: betAmount}(gameId);
    }
    
    // Helper function to commit moves for both players
    function commitMoves(
        uint256 gameId,
        RockPaperScissors.MoveOption move1,
        bytes32 secret1,
        RockPaperScissors.MoveOption move2,
        bytes32 secret2
    ) internal {
        bytes32 commitment1 = generateCommitment(move1, secret1, alice);
        bytes32 commitment2 = generateCommitment(move2, secret2, bob);
        
        vm.prank(alice);
        game.commitMove(gameId, commitment1);
        
        vm.prank(bob);
        game.commitMove(gameId, commitment2);
    }
    
    // Test game creation
    function test_CreateGame() public {
        vm.prank(alice);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        assertEq(gameId, 1);
        assertEq(game.nextGameId(), 2);
        
        (
            address[2] memory players,
            uint256 betAmount,
            RockPaperScissors.GameState state,
            address winner,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(players[0], alice);
        assertEq(players[1], address(0));
        assertEq(betAmount, MIN_BET);
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.WaitingForPlayer));
        assertEq(winner, address(0));
    }
    
    function test_CreateGame_InsufficientBet() public {
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.InsufficientBet.selector);
        game.createGame{value: MIN_BET - 1}();
    }
    
    // Test joining games
    function test_JoinGame() public {
        vm.prank(alice);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        vm.prank(bob);
        game.joinGame{value: MIN_BET}(gameId);
        
        (
            address[2] memory players,
            uint256 betAmount,
            RockPaperScissors.GameState state,
            ,
            uint256 commitDeadline,
        ) = game.getGameInfo(gameId);
        
        assertEq(players[1], bob);
        assertEq(betAmount, MIN_BET);
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.CommitPhase));
        assertEq(commitDeadline, block.timestamp + COMMIT_TIMEOUT);
    }
    
    function test_JoinGame_InvalidGameId() public {
        vm.prank(bob);
        vm.expectRevert(RockPaperScissors.InvalidGameId.selector);
        game.joinGame{value: MIN_BET}(999);
    }
    
    function test_JoinGame_WrongState() public {
        vm.prank(alice);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        vm.prank(bob);
        game.joinGame{value: MIN_BET}(gameId);
        
        vm.prank(charlie);
        vm.expectRevert(RockPaperScissors.InvalidGameState.selector);
        game.joinGame{value: MIN_BET}(gameId);
    }
    
    function test_JoinGame_CannotPlayAgainstSelf() public {
        vm.prank(alice);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.CannotPlayAgainstSelf.selector);
        game.joinGame{value: MIN_BET}(gameId);
    }
    
    function test_JoinGame_BetAmountMismatch() public {
        vm.prank(alice);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        vm.prank(bob);
        vm.expectRevert(RockPaperScissors.BetAmountMismatch.selector);
        game.joinGame{value: MIN_BET + 0.001 ether}(gameId);
    }
    
    // Test move commitment
    function test_CommitMove() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, alice);
        
        vm.prank(alice);
        game.commitMove(gameId, commitment);
        
        (bool hasCommitted, ) = game.getPlayerMove(gameId, alice);
        assertTrue(hasCommitted);
    }
    
    function test_CommitMove_NotPlayer() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, charlie);
        
        vm.prank(charlie);
        vm.expectRevert(RockPaperScissors.NotAPlayer.selector);
        game.commitMove(gameId, commitment);
    }
    
    function test_CommitMove_AlreadyCommitted() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, alice);
        
        vm.prank(alice);
        game.commitMove(gameId, commitment);
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.MoveAlreadyCommitted.selector);
        game.commitMove(gameId, commitment);
    }
    
    function test_CommitMove_InvalidCommitment() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.InvalidCommitment.selector);
        game.commitMove(gameId, bytes32(0));
    }
    
    // Test move revelation
    function test_RevealMove() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret1 = keccak256("secret1");
        bytes32 secret2 = keccak256("secret2");
        RockPaperScissors.MoveOption move1 = RockPaperScissors.MoveOption.Rock;
        RockPaperScissors.MoveOption move2 = RockPaperScissors.MoveOption.Scissors;
        
        commitMoves(gameId, move1, secret1, move2, secret2);
        
        vm.prank(alice);
        game.revealMove(gameId, move1, secret1);
        
        vm.prank(bob);
        game.revealMove(gameId, move2, secret2);
        
        (
            ,
            ,
            RockPaperScissors.GameState state,
            address winner,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.Finished));
        assertEq(winner, alice); // Rock beats Scissors
    }
    
    function test_RevealMove_InvalidMoveOrSecret() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, alice);
        
        vm.prank(alice);
        game.commitMove(gameId, commitment);
        
        vm.prank(bob);
        bytes32 commitment2 = generateCommitment(RockPaperScissors.MoveOption.Paper, keccak256("secret2"), bob);
        game.commitMove(gameId, commitment2);
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.InvalidMoveOrSecret.selector);
        game.revealMove(gameId, move, keccak256("wrong_secret"));
    }
    
    function test_RevealMove_NoCommittedMove() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.NoCommittedMove.selector);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Rock, keccak256("secret"));
    }
    
    function test_RevealMove_AlreadyRevealed() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, alice);
        
        vm.prank(alice);
        game.commitMove(gameId, commitment);
        
        vm.prank(bob);
        bytes32 commitment2 = generateCommitment(RockPaperScissors.MoveOption.Paper, keccak256("secret2"), bob);
        game.commitMove(gameId, commitment2);
        
        vm.prank(alice);
        game.revealMove(gameId, move, secret);
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.MoveAlreadyRevealed.selector);
        game.revealMove(gameId, move, secret);
    }
    
    // Test game outcomes
    function test_GameOutcome_RockBeatsScissors() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret1 = keccak256("secret1");
        bytes32 secret2 = keccak256("secret2");
        
        commitMoves(gameId, RockPaperScissors.MoveOption.Rock, secret1, RockPaperScissors.MoveOption.Scissors, secret2);
        
        vm.prank(alice);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Rock, secret1);
        
        vm.prank(bob);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Scissors, secret2);
        
        (
            ,
            ,
            RockPaperScissors.GameState state,
            address winner,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.Finished));
        assertEq(winner, alice);
        
        uint256 aliceBalance = alice.balance;
        assertEq(aliceBalance, 10 ether + MIN_BET * 2); // Original + both bets
    }
    
    function test_GameOutcome_PaperBeatsRock() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret1 = keccak256("secret1");
        bytes32 secret2 = keccak256("secret2");
        
        commitMoves(gameId, RockPaperScissors.MoveOption.Paper, secret1, RockPaperScissors.MoveOption.Rock, secret2);
        
        vm.prank(alice);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Paper, secret1);
        
        vm.prank(bob);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Rock, secret2);
        
        (
            ,
            ,
            RockPaperScissors.GameState state,
            address winner,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.Finished));
        assertEq(winner, alice);
    }
    
    function test_GameOutcome_ScissorsBeatsPaper() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret1 = keccak256("secret1");
        bytes32 secret2 = keccak256("secret2");
        
        commitMoves(gameId, RockPaperScissors.MoveOption.Scissors, secret1, RockPaperScissors.MoveOption.Paper, secret2);
        
        vm.prank(alice);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Scissors, secret1);
        
        vm.prank(bob);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Paper, secret2);
        
        (
            ,
            ,
            RockPaperScissors.GameState state,
            address winner,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.Finished));
        assertEq(winner, alice);
    }
    
    function test_GameOutcome_Tie() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret1 = keccak256("secret1");
        bytes32 secret2 = keccak256("secret2");
        
        commitMoves(gameId, RockPaperScissors.MoveOption.Rock, secret1, RockPaperScissors.MoveOption.Rock, secret2);
        
        vm.prank(alice);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Rock, secret1);
        
        vm.prank(bob);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Rock, secret2);
        
        (
            ,
            ,
            RockPaperScissors.GameState state,
            address winner,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.Finished));
        assertEq(winner, address(0)); // Tie
        
        uint256 aliceBalance = alice.balance;
        uint256 bobBalance = bob.balance;
        assertEq(aliceBalance, 10 ether); // Refunded original bet
        assertEq(bobBalance, 10 ether); // Refunded original bet
    }
    
    // Test timeout scenarios
    function test_ClaimTimeout_CommitPhase() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, alice);
        
        vm.prank(alice);
        game.commitMove(gameId, commitment);
        
        // Fast forward past commit deadline
        vm.warp(block.timestamp + COMMIT_TIMEOUT + 1);
        
        vm.prank(alice);
        game.claimTimeout(gameId);
        
        (
            ,
            ,
            RockPaperScissors.GameState state,
            address winner,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.TimedOut));
        assertEq(winner, alice);
    }
    
    function test_ClaimTimeout_RevealPhase() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret1 = keccak256("secret1");
        bytes32 secret2 = keccak256("secret2");
        
        commitMoves(gameId, RockPaperScissors.MoveOption.Rock, secret1, RockPaperScissors.MoveOption.Paper, secret2);
        
        vm.prank(alice);
        game.revealMove(gameId, RockPaperScissors.MoveOption.Rock, secret1);
        
        // Fast forward past reveal deadline
        vm.warp(block.timestamp + REVEAL_TIMEOUT + 1);
        
        vm.prank(alice);
        game.claimTimeout(gameId);
        
        (
            ,
            ,
            RockPaperScissors.GameState state,
            address winner,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.TimedOut));
        assertEq(winner, alice);
    }
    
    function test_ClaimTimeout_NoTimeoutToClaim() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.NoTimeoutToClaim.selector);
        game.claimTimeout(gameId);
    }
    
    // Test game cancellation
    function test_CancelGame() public {
        vm.prank(alice);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        // Fast forward past 1 hour
        vm.warp(block.timestamp + 1 hours + 1);
        
        vm.prank(alice);
        game.cancelGame(gameId);
        
        (
            ,
            ,
            RockPaperScissors.GameState state,
            ,
            ,
        ) = game.getGameInfo(gameId);
        
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.TimedOut));
        
        uint256 aliceBalance = alice.balance;
        assertEq(aliceBalance, 10 ether); // Refunded original bet
    }
    
    function test_CancelGame_OnlyCreatorCanCancel() public {
        vm.prank(alice);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        vm.warp(block.timestamp + 1 hours + 1);
        
        vm.prank(bob);
        vm.expectRevert(RockPaperScissors.OnlyCreatorCanCancel.selector);
        game.cancelGame(gameId);
    }
    
    function test_CancelGame_MustWaitBeforeCanceling() public {
        vm.prank(alice);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.MustWaitBeforeCanceling.selector);
        game.cancelGame(gameId);
    }
    
    // Test view functions
    function test_GetGameInfo() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        (
            address[2] memory players,
            uint256 betAmount,
            RockPaperScissors.GameState state,
            address winner,
            uint256 commitDeadline,
            uint256 revealDeadline
        ) = game.getGameInfo(gameId);
        
        assertEq(players[0], alice);
        assertEq(players[1], bob);
        assertEq(betAmount, MIN_BET);
        assertEq(uint256(state), uint256(RockPaperScissors.GameState.CommitPhase));
        assertEq(winner, address(0));
        assertEq(commitDeadline, block.timestamp + COMMIT_TIMEOUT);
        assertEq(revealDeadline, 0);
    }
    
    function test_GetPlayerMove() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, alice);
        
        vm.prank(alice);
        game.commitMove(gameId, commitment);
        
        (bool hasCommitted, RockPaperScissors.MoveOption revealedMove) = game.getPlayerMove(gameId, alice);
        assertTrue(hasCommitted);
        assertEq(uint256(revealedMove), uint256(RockPaperScissors.MoveOption.NotRevealedYet));
        
        vm.prank(alice);
        game.revealMove(gameId, move, secret);
        
        (hasCommitted, revealedMove) = game.getPlayerMove(gameId, alice);
        assertTrue(hasCommitted);
        assertEq(uint256(revealedMove), uint256(RockPaperScissors.MoveOption.Rock));
    }
    
    function test_GenerateCommitment() public {
        bytes32 secret = keccak256("test_secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Paper;
        
        bytes32 expectedCommitment = keccak256(abi.encodePacked(move, secret, alice));
        bytes32 actualCommitment = game.generateCommitment(move, secret, alice);
        
        assertEq(actualCommitment, expectedCommitment);
    }
    
    // Test events
    function test_Events() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit GameCreated(1, alice, MIN_BET);
        uint256 gameId = game.createGame{value: MIN_BET}();
        
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit PlayerJoined(gameId, bob);
        game.joinGame{value: MIN_BET}(gameId);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, alice);
        
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit MoveCommitted(gameId, alice);
        game.commitMove(gameId, commitment);
        
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit MoveRevealed(gameId, alice, move);
        game.revealMove(gameId, move, secret);
    }
    
    // Test edge cases
    function test_MultipleGames() public {
        // Create multiple games
        vm.prank(alice);
        uint256 gameId1 = game.createGame{value: MIN_BET}();
        
        vm.prank(bob);
        uint256 gameId2 = game.createGame{value: MIN_BET * 2}();
        
        assertEq(gameId1, 1);
        assertEq(gameId2, 2);
        assertEq(game.nextGameId(), 3);
        
        // Join both games
        vm.prank(charlie);
        game.joinGame{value: MIN_BET}(gameId1);
        
        vm.prank(alice);
        game.joinGame{value: MIN_BET * 2}(gameId2);
        
        // Verify games are independent
        (
            ,
            uint256 betAmount1,
            ,
            ,
            ,
        ) = game.getGameInfo(gameId1);
        
        (
            ,
            uint256 betAmount2,
            ,
            ,
            ,
        ) = game.getGameInfo(gameId2);
        
        assertEq(betAmount1, MIN_BET);
        assertEq(betAmount2, MIN_BET * 2);
    }
    
    function test_InvalidGameId() public {
        vm.expectRevert(RockPaperScissors.InvalidGameId.selector);
        game.getGameInfo(0);
        
        vm.expectRevert(RockPaperScissors.InvalidGameId.selector);
        game.getGameInfo(999);
    }
    
    function test_InvalidMove() public {
        uint256 gameId = createAndJoinGame(MIN_BET);
        
        bytes32 secret = keccak256("secret");
        RockPaperScissors.MoveOption move = RockPaperScissors.MoveOption.Rock;
        bytes32 commitment = generateCommitment(move, secret, alice);
        
        vm.prank(alice);
        game.commitMove(gameId, commitment);
        
        vm.prank(bob);
        bytes32 commitment2 = generateCommitment(RockPaperScissors.MoveOption.Paper, keccak256("secret2"), bob);
        game.commitMove(gameId, commitment2);
        
        vm.prank(alice);
        vm.expectRevert(RockPaperScissors.InvalidMove.selector);
        game.revealMove(gameId, RockPaperScissors.MoveOption.NotRevealedYet, secret);
    }
}
