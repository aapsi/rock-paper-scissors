// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Rock Paper Scissors Game
 * @dev A secure, feature-rich implementation of Rock Paper Scissors with betting, timeouts, and proper game lifecycle management
 */
contract RockPaperScissors {
    // Custom errors for gas efficiency
    error InvalidGameId();
    error NotAPlayer();
    error InvalidGameState();
    error InsufficientBet();
    error CannotPlayAgainstSelf();
    error BetAmountMismatch();
    error CommitPhaseEnded();
    error MoveAlreadyCommitted();
    error InvalidCommitment();
    error RevealPhaseEnded();
    error NoCommittedMove();
    error MoveAlreadyRevealed();
    error InvalidMove();
    error InvalidMoveOrSecret();
    error NoTimeoutToClaim();
    error OnlyCreatorCanCancel();
    error MustWaitBeforeCanceling();
    
    // Events for better transparency and frontend integration
    event GameCreated(uint256 indexed gameId, address indexed creator, uint256 betAmount);
    event PlayerJoined(uint256 indexed gameId, address indexed player);
    event MoveCommitted(uint256 indexed gameId, address indexed player);
    event MoveRevealed(uint256 indexed gameId, address indexed player, MoveOption move);
    event GameFinished(uint256 indexed gameId, address indexed winner, uint256 prize);
    event GameTimedOut(uint256 indexed gameId, address indexed winner);
    
    enum MoveOption {
        NotRevealedYet,
        Rock,
        Paper,
        Scissors
    }
    
    enum GameState {
        WaitingForPlayer,
        CommitPhase,
        RevealPhase,
        Finished,
        TimedOut
    }
    
    struct GameMove {
        bytes32 commitment;
        MoveOption revealedMove;
        uint256 timestamp;
    }
    
    struct Game {
        address[2] players;
        mapping(address => GameMove) moves;
        uint256 betAmount;
        GameState state;
        address winner;
        uint256 createdAt;
        uint256 commitDeadline;
        uint256 revealDeadline;
        uint8 playersJoined;
        uint8 movesCommitted;
        uint8 movesRevealed;
    }
    
    // Contract state
    mapping(uint256 => Game) public games;
    uint256 public nextGameId = 1;
    uint256 public constant COMMIT_TIMEOUT = 10 minutes;
    uint256 public constant REVEAL_TIMEOUT = 5 minutes;
    uint256 public constant MIN_BET = 0.001 ether;
    
    // Modifiers
    modifier validGame(uint256 gameId) {
        if (gameId == 0 || gameId >= nextGameId) revert InvalidGameId();
        _;
    }
    
    modifier onlyPlayer(uint256 gameId) {
        Game storage game = games[gameId];
        if (msg.sender != game.players[0] && msg.sender != game.players[1]) {
            revert NotAPlayer();
        }
        _;
    }
    
    modifier inState(uint256 gameId, GameState expectedState) {
        if (games[gameId].state != expectedState) revert InvalidGameState();
        _;
    }
    
    /**
     * @dev Create a new game with optional betting
     */
    function createGame() external payable returns (uint256 gameId) {
        if (msg.value < MIN_BET) revert InsufficientBet();
        
        gameId = nextGameId++;
        Game storage game = games[gameId];
        
        game.players[0] = msg.sender;
        game.betAmount = msg.value;
        game.state = GameState.WaitingForPlayer;
        game.createdAt = block.timestamp;
        game.playersJoined = 1;
        
        emit GameCreated(gameId, msg.sender, msg.value);
    }
    
    /**
     * @dev Join an existing game
     */
    function joinGame(uint256 gameId) 
        external 
        payable 
        validGame(gameId) 
        inState(gameId, GameState.WaitingForPlayer) 
    {
        Game storage game = games[gameId];
        if (msg.sender == game.players[0]) revert CannotPlayAgainstSelf();
        if (msg.value != game.betAmount) revert BetAmountMismatch();
        
        game.players[1] = msg.sender;
        game.state = GameState.CommitPhase;
        game.commitDeadline = block.timestamp + COMMIT_TIMEOUT;
        game.playersJoined = 2;
        
        emit PlayerJoined(gameId, msg.sender);
    }
    
    /**
     * @dev Commit a move using commit-reveal scheme
     * @param gameId The game identifier
     * @param commitment Hash of (move + secret + msg.sender) for additional security
     */
    function commitMove(uint256 gameId, bytes32 commitment) 
        external 
        validGame(gameId) 
        onlyPlayer(gameId) 
        inState(gameId, GameState.CommitPhase) 
    {
        Game storage game = games[gameId];
        if (block.timestamp > game.commitDeadline) revert CommitPhaseEnded();
        if (game.moves[msg.sender].commitment != bytes32(0)) revert MoveAlreadyCommitted();
        if (commitment == bytes32(0)) revert InvalidCommitment();
        
        game.moves[msg.sender] = GameMove({
            commitment: commitment,
            revealedMove: MoveOption.NotRevealedYet,
            timestamp: block.timestamp
        });
        
        game.movesCommitted++;
        
        // Transition to reveal phase when both players have committed
        if (game.movesCommitted == 2) {
            game.state = GameState.RevealPhase;
            game.revealDeadline = block.timestamp + REVEAL_TIMEOUT;
        }
        
        emit MoveCommitted(gameId, msg.sender);
    }
    
    /**
     * @dev Reveal your committed move
     * @param gameId The game identifier
     * @param move The original move
     * @param secret The secret used in commitment
     */
    function revealMove(uint256 gameId, MoveOption move, bytes32 secret) 
        external 
        validGame(gameId) 
        onlyPlayer(gameId) 
        inState(gameId, GameState.RevealPhase) 
    {
        Game storage game = games[gameId];
        if (block.timestamp > game.revealDeadline) revert RevealPhaseEnded();
        if (game.moves[msg.sender].commitment == bytes32(0)) revert NoCommittedMove();
        if (game.moves[msg.sender].revealedMove != MoveOption.NotRevealedYet) revert MoveAlreadyRevealed();
        if (move == MoveOption.NotRevealedYet) revert InvalidMove();
        
        // Verify commitment includes sender address to prevent replay attacks
        bytes32 calculatedCommitment = keccak256(abi.encodePacked(move, secret, msg.sender));
        if (calculatedCommitment != game.moves[msg.sender].commitment) revert InvalidMoveOrSecret();
        
        game.moves[msg.sender].revealedMove = move;
        game.movesRevealed++;
        
        emit MoveRevealed(gameId, msg.sender, move);
        
        // Finish game when both moves are revealed
        if (game.movesRevealed == 2) {
            _finishGame(gameId);
        }
    }
    
    /**
     * @dev Handle timeout scenarios - allows honest players to claim victory
     */
    function claimTimeout(uint256 gameId) 
        external 
        validGame(gameId) 
        onlyPlayer(gameId) 
    {
        Game storage game = games[gameId];
        
        if (game.state == GameState.CommitPhase && block.timestamp > game.commitDeadline) {
            // If only one player committed, they win
            if (game.moves[msg.sender].commitment == bytes32(0)) revert NoCommittedMove();
            
            address opponent = (msg.sender == game.players[0]) ? game.players[1] : game.players[0];
            if (game.moves[opponent].commitment != bytes32(0)) revert InvalidGameState();
            
            game.winner = msg.sender;
            game.state = GameState.TimedOut;
            _distributePrize(gameId);
            
            emit GameTimedOut(gameId, msg.sender);
            
        } else if (game.state == GameState.RevealPhase && block.timestamp > game.revealDeadline) {
            // If only one player revealed, they win
            if (game.moves[msg.sender].revealedMove == MoveOption.NotRevealedYet) revert NoCommittedMove();
            
            address opponent = (msg.sender == game.players[0]) ? game.players[1] : game.players[0];
            if (game.moves[opponent].revealedMove != MoveOption.NotRevealedYet) revert InvalidGameState();
            
            game.winner = msg.sender;
            game.state = GameState.TimedOut;
            _distributePrize(gameId);
            
            emit GameTimedOut(gameId, msg.sender);
        } else {
            revert NoTimeoutToClaim();
        }
    }
    
    /**
     * @dev Internal function to determine winner and finish the game
     */
    function _finishGame(uint256 gameId) internal {
        Game storage game = games[gameId];
        
        MoveOption move1 = game.moves[game.players[0]].revealedMove;
        MoveOption move2 = game.moves[game.players[1]].revealedMove;
        
        game.winner = _determineWinner(move1, move2, game.players[0], game.players[1]);
        game.state = GameState.Finished;
        
        _distributePrize(gameId);
        
        emit GameFinished(gameId, game.winner, game.betAmount * 2);
    }
    
    /**
     * @dev Determine the winner based on Rock Paper Scissors rules
     */
    function _determineWinner(
        MoveOption move1, 
        MoveOption move2, 
        address player1, 
        address player2
    ) internal pure returns (address) {
        if (move1 == move2) {
            return address(0); // Tie
        }
        
        bool player1Wins = (move1 == MoveOption.Rock && move2 == MoveOption.Scissors) ||
                          (move1 == MoveOption.Paper && move2 == MoveOption.Rock) ||
                          (move1 == MoveOption.Scissors && move2 == MoveOption.Paper);
        
        return player1Wins ? player1 : player2;
    }
    
    /**
     * @dev Distribute prize money to winner or split on tie
     */
    function _distributePrize(uint256 gameId) internal {
        Game storage game = games[gameId];
        uint256 totalPrize = game.betAmount * 2;
        
        if (game.winner == address(0)) {
            // Tie - refund both players
            payable(game.players[0]).transfer(game.betAmount);
            payable(game.players[1]).transfer(game.betAmount);
        } else {
            // Winner takes all
            payable(game.winner).transfer(totalPrize);
        }
    }
    
    /**
     * @dev Cancel a game if no second player joins within reasonable time
     */
    function cancelGame(uint256 gameId) 
        external 
        validGame(gameId) 
        inState(gameId, GameState.WaitingForPlayer) 
    {
        Game storage game = games[gameId];
        if (msg.sender != game.players[0]) revert OnlyCreatorCanCancel();
        if (block.timestamp <= game.createdAt + 1 hours) revert MustWaitBeforeCanceling();
        
        game.state = GameState.TimedOut;
        payable(game.players[0]).transfer(game.betAmount);
        
        emit GameTimedOut(gameId, address(0));
    }
    
    // View functions
    function getGameInfo(uint256 gameId) 
        external 
        view 
        validGame(gameId) 
        returns (
            address[2] memory players,
            uint256 betAmount,
            GameState state,
            address winner,
            uint256 commitDeadline,
            uint256 revealDeadline
        ) 
    {
        Game storage game = games[gameId];
        return (
            game.players,
            game.betAmount,
            game.state,
            game.winner,
            game.commitDeadline,
            game.revealDeadline
        );
    }
    
    function getPlayerMove(uint256 gameId, address player) 
        external 
        view 
        validGame(gameId) 
        returns (bool hasCommitted, MoveOption revealedMove) 
    {
        Game storage game = games[gameId];
        GameMove storage move = game.moves[player];
        return (
            move.commitment != bytes32(0),
            move.revealedMove
        );
    }
    
    /**
     * @dev Helper function to generate commitment hash
     * Should be called off-chain to generate the commitment
     */
    function generateCommitment(MoveOption move, bytes32 secret, address player) 
        external 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(move, secret, player));
    }
}