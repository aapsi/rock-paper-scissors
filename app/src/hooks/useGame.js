import { useState, useEffect, useCallback } from 'react';
import { useReadContract, useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { ROCK_PAPER_SCISSORS_ABI, getContractAddress, GAME_STATES, MOVE_OPTIONS } from '../contracts/rockPaperScissors';
import { generateCommitment, stringToBytes32 } from '../utils/commitment';

export const useGame = () => {
  const { address, isConnected } = useAccount();
  const [gameId, setGameId] = useState(null);
  const [betAmount, setBetAmount] = useState('0.001');
  const [selectedMove, setSelectedMove] = useState(null);
  const [secret, setSecret] = useState('');
  const [gameInfo, setGameInfo] = useState(null);
  const [playerMove, setPlayerMove] = useState(null);
  const [isLoading, setIsLoading] = useState(false);

  // Contract configuration
  const contractAddress = getContractAddress(31337); // Default to localhost

  // Read contract data
  const { data: minBet } = useReadContract({
    address: contractAddress,
    abi: ROCK_PAPER_SCISSORS_ABI,
    functionName: 'MIN_BET',
  });

  const { data: nextGameId } = useReadContract({
    address: contractAddress,
    abi: ROCK_PAPER_SCISSORS_ABI,
    functionName: 'nextGameId',
  });

  // Game info
  const { data: gameData, refetch: refetchGameInfo } = useReadContract({
    address: contractAddress,
    abi: ROCK_PAPER_SCISSORS_ABI,
    functionName: 'getGameInfo',
    args: gameId ? [gameId] : undefined,
    query: {
      enabled: !!gameId,
    },
  });

  // Player move info
  const { data: moveData, refetch: refetchPlayerMove } = useReadContract({
    address: contractAddress,
    abi: ROCK_PAPER_SCISSORS_ABI,
    functionName: 'getPlayerMove',
    args: gameId && address ? [gameId, address] : undefined,
    query: {
      enabled: !!gameId && !!address,
    },
  });

  // Contract write functions
  const { writeContract: createGame, data: createGameData } = useWriteContract();

  const { writeContract: joinGame, data: joinGameData } = useWriteContract();

  const { writeContract: commitMove, data: commitMoveData } = useWriteContract();

  const { writeContract: revealMove, data: revealMoveData } = useWriteContract();

  const { writeContract: claimTimeout, data: claimTimeoutData } = useWriteContract();

  const { writeContract: cancelGame, data: cancelGameData } = useWriteContract();

  // Wait for transactions
  const { isLoading: isCreatingGame } = useWaitForTransactionReceipt({
    hash: createGameData,
  });

  const { isLoading: isJoiningGame } = useWaitForTransactionReceipt({
    hash: joinGameData,
  });

  const { isLoading: isCommittingMove } = useWaitForTransactionReceipt({
    hash: commitMoveData,
  });

  const { isLoading: isRevealingMove } = useWaitForTransactionReceipt({
    hash: revealMoveData,
  });

  const { isLoading: isClaimingTimeout } = useWaitForTransactionReceipt({
    hash: claimTimeoutData,
  });

  const { isLoading: isCancelingGame } = useWaitForTransactionReceipt({
    hash: cancelGameData,
  });

  // Update loading state
  useEffect(() => {
    setIsLoading(
      isCreatingGame ||
      isJoiningGame ||
      isCommittingMove ||
      isRevealingMove ||
      isClaimingTimeout ||
      isCancelingGame
    );
  }, [
    isCreatingGame,
    isJoiningGame,
    isCommittingMove,
    isRevealingMove,
    isClaimingTimeout,
    isCancelingGame,
  ]);

  // Parse game data
  useEffect(() => {
    if (gameData) {
      const [players, betAmount, state, winner, commitDeadline, revealDeadline] = gameData;
      setGameInfo({
        players,
        betAmount: formatEther(betAmount),
        state: Number(state),
        winner,
        commitDeadline: Number(commitDeadline),
        revealDeadline: Number(revealDeadline),
      });
    }
  }, [gameData]);

  // Parse player move data
  useEffect(() => {
    if (moveData) {
      const [hasCommitted, revealedMove] = moveData;
      setPlayerMove({
        hasCommitted,
        revealedMove: Number(revealedMove),
      });
    }
  }, [moveData]);

  // Helper functions
  const handleCreateGame = useCallback(() => {
    if (!isConnected || !betAmount) return;
    
    const value = parseEther(betAmount);
    createGame({
      address: contractAddress,
      abi: ROCK_PAPER_SCISSORS_ABI,
      functionName: 'createGame',
      value,
    });
  }, [isConnected, betAmount, createGame, contractAddress]);

  const handleJoinGame = useCallback((targetGameId) => {
    if (!isConnected || !gameInfo) return;
    
    const value = parseEther(gameInfo.betAmount);
    joinGame({
      address: contractAddress,
      abi: ROCK_PAPER_SCISSORS_ABI,
      functionName: 'joinGame',
      args: [targetGameId],
      value,
    });
  }, [isConnected, gameInfo, joinGame, contractAddress]);

  const handleCommitMove = useCallback(() => {
    if (!isConnected || !gameId || !selectedMove || !secret) return;
    
    // Generate commitment using the utility function
    const commitment = generateCommitment(selectedMove, secret, address);
    
    commitMove({
      address: contractAddress,
      abi: ROCK_PAPER_SCISSORS_ABI,
      functionName: 'commitMove',
      args: [gameId, commitment],
    });
  }, [isConnected, gameId, selectedMove, secret, address, commitMove, contractAddress]);

  const handleRevealMove = useCallback(() => {
    if (!isConnected || !gameId || !selectedMove || !secret) return;
    
    // Convert secret string to bytes32
    const secretBytes32 = stringToBytes32(secret);
    
    revealMove({
      address: contractAddress,
      abi: ROCK_PAPER_SCISSORS_ABI,
      functionName: 'revealMove',
      args: [gameId, selectedMove, secretBytes32],
    });
  }, [isConnected, gameId, selectedMove, secret, revealMove, contractAddress]);

  const handleClaimTimeout = useCallback(() => {
    if (!isConnected || !gameId) return;
    
    claimTimeout({
      address: contractAddress,
      abi: ROCK_PAPER_SCISSORS_ABI,
      functionName: 'claimTimeout',
      args: [gameId],
    });
  }, [isConnected, gameId, claimTimeout, contractAddress]);

  const handleCancelGame = useCallback(() => {
    if (!isConnected || !gameId) return;
    
    cancelGame({
      address: contractAddress,
      abi: ROCK_PAPER_SCISSORS_ABI,
      functionName: 'cancelGame',
      args: [gameId],
    });
  }, [isConnected, gameId, cancelGame, contractAddress]);

  const refreshGameData = useCallback(() => {
    refetchGameInfo();
    refetchPlayerMove();
  }, [refetchGameInfo, refetchPlayerMove]);

  const isPlayerInGame = useCallback(() => {
    if (!gameInfo || !address) return false;
    return gameInfo.players.includes(address);
  }, [gameInfo, address]);

  const isGameCreator = useCallback(() => {
    if (!gameInfo || !address) return false;
    return gameInfo.players[0] === address;
  }, [gameInfo, address]);

  const getGameStateText = useCallback((state) => {
    switch (state) {
      case GAME_STATES.WAITING_FOR_PLAYER:
        return 'Waiting for Player';
      case GAME_STATES.COMMIT_PHASE:
        return 'Commit Phase';
      case GAME_STATES.REVEAL_PHASE:
        return 'Reveal Phase';
      case GAME_STATES.FINISHED:
        return 'Finished';
      case GAME_STATES.TIMED_OUT:
        return 'Timed Out';
      default:
        return 'Unknown';
    }
  }, []);

  const getMoveText = useCallback((move) => {
    switch (move) {
      case MOVE_OPTIONS.ROCK:
        return 'Rock';
      case MOVE_OPTIONS.PAPER:
        return 'Paper';
      case MOVE_OPTIONS.SCISSORS:
        return 'Scissors';
      case MOVE_OPTIONS.NOT_REVEALED_YET:
        return 'Not Revealed';
      default:
        return 'Unknown';
    }
  }, []);

  return {
    // State
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
    
    // Contract data
    minBet: minBet ? formatEther(minBet) : '0',
    nextGameId: nextGameId ? Number(nextGameId) : 0,
    
    // Actions
    handleCreateGame,
    handleJoinGame,
    handleCommitMove,
    handleRevealMove,
    handleClaimTimeout,
    handleCancelGame,
    refreshGameData,
    
    // Helpers
    isPlayerInGame: isPlayerInGame(),
    isGameCreator: isGameCreator(),
    getGameStateText,
    getMoveText,
  };
}; 