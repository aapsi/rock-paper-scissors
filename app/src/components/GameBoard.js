import React, { useEffect, useRef } from 'react';
import { useGame } from '../hooks/useGame';
import { MOVE_OPTIONS, GAME_STATES } from '../contracts/rockPaperScissors';
import { RefreshCw, Clock, Trophy, Users, Coins } from 'lucide-react';
import confetti from 'canvas-confetti';

const GameBoard = () => {
  const {
    gameId,
    setGameId,
    betAmount,
    setBetAmount,
    selectedMove,
    setSelectedMove,
    secret,
    setSecret,
    gameInfo,
    playerMove,
    isLoading,
    minBet,
    nextGameId,
    handleCreateGame,
    handleJoinGame,
    handleCommitMove,
    handleRevealMove,
    handleClaimTimeout,
    handleCancelGame,
    refreshGameData,
    isPlayerInGame,
    isGameCreator,
    getGameStateText,
    getMoveText,
  } = useGame();

  // Confetti effect when winner is declared
  const prevWinner = useRef(null);
  useEffect(() => {
    if (
      gameInfo &&
      gameInfo.winner &&
      gameInfo.winner !== '0x0000000000000000000000000000000000000000' &&
      prevWinner.current !== gameInfo.winner
    ) {
      confetti({
        particleCount: 120,
        spread: 80,
        origin: { y: 0.6 },
      });
      prevWinner.current = gameInfo.winner;
    }
  }, [gameInfo]);

  const renderMoveButton = (move, icon, label) => (
    <button
      onClick={() => setSelectedMove(move)}
      className={`flex flex-col items-center gap-2 p-4 rounded-lg border-2 transition-all duration-200 transform
        ${selectedMove === move ? 'border-primary-500 bg-primary-500/20 scale-110 animate-wiggle' : 'border-white/20 hover:border-primary-400 hover:bg-white/5 hover:scale-105 hover:animate-bounce'}
      `}
      style={{ minWidth: 100 }}
    >
      <div className="text-4xl transition-transform duration-300">{icon}</div>
      <span className="font-medium">{label}</span>
    </button>
  );

  const renderGameInfo = () => {
    if (!gameInfo) return null;

    return (
      <div className="card animate-fade-in space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-xl font-bold">Game #{gameId}</h3>
          <div className="flex items-center gap-2">
            <Clock className="w-4 h-4" />
            <span className="text-sm">{getGameStateText(gameInfo.state)}</span>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="flex items-center gap-2">
            <Users className="w-4 h-4 text-primary-400" />
            <span className="text-sm">Players:</span>
            <span className="font-medium">
              {gameInfo.players[0] ? '1' : '0'}/{gameInfo.players[1] ? '2' : '1'}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <Coins className="w-4 h-4 text-primary-400" />
            <span className="text-sm">Bet:</span>
            <span className="font-medium">{gameInfo.betAmount} ETH</span>
          </div>
        </div>

        {gameInfo.winner && gameInfo.winner !== '0x0000000000000000000000000000000000000000' && (
          <div className="flex items-center gap-2 text-green-400">
            <Trophy className="w-4 h-4" />
            <span>Winner: {gameInfo.winner.slice(0, 6)}...{gameInfo.winner.slice(-4)}</span>
          </div>
        )}

        {gameInfo.players[0] && (
          <div className="text-sm text-white/70">
            <div>Player 1: {gameInfo.players[0].slice(0, 6)}...{gameInfo.players[0].slice(-4)}</div>
            {gameInfo.players[1] && (
              <div>Player 2: {gameInfo.players[1].slice(0, 6)}...{gameInfo.players[1].slice(-4)}</div>
            )}
          </div>
        )}
      </div>
    );
  };

  const renderPlayerMove = () => {
    if (!playerMove) return null;

    return (
      <div className="card animate-fade-in">
        <h4 className="text-lg font-semibold mb-3">Your Move</h4>
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span>Committed:</span>
            <span className={playerMove.hasCommitted ? 'text-green-400' : 'text-red-400'}>
              {playerMove.hasCommitted ? 'Yes' : 'No'}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span>Revealed:</span>
            <span className="font-medium">
              {playerMove.revealedMove !== MOVE_OPTIONS.NOT_REVEALED_YET
                ? getMoveText(playerMove.revealedMove)
                : 'Not Revealed'}
            </span>
          </div>
        </div>
      </div>
    );
  };

  const renderGameActions = () => {
    if (!gameInfo) return null;

    switch (gameInfo.state) {
      case GAME_STATES.WAITING_FOR_PLAYER:
        return (
          <div className="card animate-fade-in space-y-4">
            <h4 className="text-lg font-semibold">Game Actions</h4>
            {!isPlayerInGame ? (
              <button
                onClick={() => handleJoinGame(gameId)}
                disabled={isLoading}
                className="btn-primary transition-transform duration-200 hover:scale-105 w-full"
              >
                {isLoading ? 'Joining...' : 'Join Game'}
              </button>
            ) : isGameCreator ? (
              <button
                onClick={() => handleCancelGame()}
                disabled={isLoading}
                className="btn-secondary transition-transform duration-200 hover:scale-105 w-full"
              >
                {isLoading ? 'Canceling...' : 'Cancel Game'}
              </button>
            ) : null}
          </div>
        );

      case GAME_STATES.COMMIT_PHASE:
        return (
          <div className="card animate-fade-in space-y-4">
            <h4 className="text-lg font-semibold">Commit Your Move</h4>
            <div className="grid grid-cols-3 gap-4">
              {renderMoveButton(MOVE_OPTIONS.ROCK, '🪨', 'Rock')}
              {renderMoveButton(MOVE_OPTIONS.PAPER, '📄', 'Paper')}
              {renderMoveButton(MOVE_OPTIONS.SCISSORS, '✂️', 'Scissors')}
            </div>
            <input
              type="text"
              placeholder="Enter a secret (any text)"
              value={secret}
              onChange={(e) => setSecret(e.target.value)}
              className="input-field w-full"
            />
            <button
              onClick={handleCommitMove}
              disabled={!selectedMove || !secret || isLoading}
              className="btn-primary transition-transform duration-200 hover:scale-105 w-full"
            >
              {isLoading ? 'Committing...' : 'Commit Move'}
            </button>
          </div>
        );

      case GAME_STATES.REVEAL_PHASE:
        return (
          <div className="card animate-fade-in space-y-4">
            <h4 className="text-lg font-semibold">Reveal Your Move</h4>
            <div className="grid grid-cols-3 gap-4">
              {renderMoveButton(MOVE_OPTIONS.ROCK, '🪨', 'Rock')}
              {renderMoveButton(MOVE_OPTIONS.PAPER, '📄', 'Paper')}
              {renderMoveButton(MOVE_OPTIONS.SCISSORS, '✂️', 'Scissors')}
            </div>
            <input
              type="text"
              placeholder="Enter your secret"
              value={secret}
              onChange={(e) => setSecret(e.target.value)}
              className="input-field w-full"
            />
            <button
              onClick={handleRevealMove}
              disabled={!selectedMove || !secret || isLoading}
              className="btn-primary transition-transform duration-200 hover:scale-105 w-full"
            >
              {isLoading ? 'Revealing...' : 'Reveal Move'}
            </button>
            <button
              onClick={handleClaimTimeout}
              disabled={isLoading}
              className="btn-secondary transition-transform duration-200 hover:scale-105 w-full"
            >
              {isLoading ? 'Claiming...' : 'Claim Timeout'}
            </button>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* Game ID Input */}
      <div className="card animate-fade-in">
        <h3 className="text-lg font-semibold mb-4">Game Management</h3>
        <div className="flex gap-4">
          <input
            type="number"
            placeholder="Enter Game ID"
            value={gameId || ''}
            onChange={(e) => setGameId(e.target.value ? Number(e.target.value) : null)}
            className="input-field flex-1"
          />
          <button
            onClick={refreshGameData}
            disabled={!gameId || isLoading}
            className="btn-secondary"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Create Game */}
      <div className="card animate-fade-in">
        <h3 className="text-lg font-semibold mb-4">Create New Game</h3>
        <div className="flex gap-4">
          <input
            type="number"
            step="0.001"
            placeholder={`Min bet: ${minBet} ETH`}
            value={betAmount}
            onChange={(e) => setBetAmount(e.target.value)}
            className="input-field flex-1"
          />
          <button
            onClick={handleCreateGame}
            disabled={!betAmount || isLoading}
            className="btn-primary"
          >
            {isLoading ? 'Creating...' : 'Create Game'}
          </button>
        </div>
        <p className="text-sm text-white/70 mt-2">
          Next Game ID: {nextGameId}
        </p>
      </div>

      {/* Game Info */}
      {gameId && renderGameInfo()}

      {/* Player Move Info */}
      {gameId && isPlayerInGame && renderPlayerMove()}

      {/* Game Actions */}
      {gameId && isPlayerInGame && renderGameActions()}
    </div>
  );
};

export default GameBoard; 