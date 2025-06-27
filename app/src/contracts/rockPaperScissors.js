// Rock Paper Scissors Contract ABI
export const ROCK_PAPER_SCISSORS_ABI = [
  {
    "inputs": [],
    "name": "MIN_BET",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "COMMIT_TIMEOUT",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "REVEAL_TIMEOUT",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "nextGameId",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "uint256"}],
    "name": "games",
    "outputs": [
      {"type": "address[2]"},
      {"type": "uint256"},
      {"type": "uint8"},
      {"type": "address"},
      {"type": "uint256"},
      {"type": "uint256"},
      {"type": "uint256"},
      {"type": "uint8"},
      {"type": "uint8"},
      {"type": "uint8"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "createGame",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [{"type": "uint256"}],
    "name": "joinGame",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "uint256"},
      {"type": "bytes32"}
    ],
    "name": "commitMove",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "uint256"},
      {"type": "uint8"},
      {"type": "bytes32"}
    ],
    "name": "revealMove",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "uint256"}],
    "name": "claimTimeout",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "uint256"}],
    "name": "cancelGame",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "uint256"}],
    "name": "getGameInfo",
    "outputs": [
      {"type": "address[2]"},
      {"type": "uint256"},
      {"type": "uint8"},
      {"type": "address"},
      {"type": "uint256"},
      {"type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "uint256"},
      {"type": "address"}
    ],
    "name": "getPlayerMove",
    "outputs": [
      {"type": "bool"},
      {"type": "uint8"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "uint8"},
      {"type": "bytes32"},
      {"type": "address"}
    ],
    "name": "generateCommitment",
    "outputs": [{"type": "bytes32"}],
    "stateMutability": "pure",
    "type": "function"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "type": "uint256"},
      {"indexed": true, "type": "address"},
      {"indexed": false, "type": "uint256"}
    ],
    "name": "GameCreated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "type": "uint256"},
      {"indexed": true, "type": "address"}
    ],
    "name": "PlayerJoined",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "type": "uint256"},
      {"indexed": true, "type": "address"}
    ],
    "name": "MoveCommitted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "type": "uint256"},
      {"indexed": true, "type": "address"},
      {"indexed": false, "type": "uint8"}
    ],
    "name": "MoveRevealed",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "type": "uint256"},
      {"indexed": true, "type": "address"},
      {"indexed": false, "type": "uint256"}
    ],
    "name": "GameFinished",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "type": "uint256"},
      {"indexed": true, "type": "address"}
    ],
    "name": "GameTimedOut",
    "type": "event"
  }
];

// Contract addresses (update these based on your deployment)
export const CONTRACT_ADDRESSES = {
  mainnet: "0x0000000000000000000000000000000000000000", // Update with actual address
  sepolia: "0x0000000000000000000000000000000000000000", // Update with actual address
  localhost: "0x5FbDB2315678afecb367f032d93F642f64180aa3", // Default localhost address
};

// Game states enum
export const GAME_STATES = {
  WAITING_FOR_PLAYER: 0,
  COMMIT_PHASE: 1,
  REVEAL_PHASE: 2,
  FINISHED: 3,
  TIMED_OUT: 4,
};

// Move options enum
export const MOVE_OPTIONS = {
  NOT_REVEALED_YET: 0,
  ROCK: 1,
  PAPER: 2,
  SCISSORS: 3,
};

// Helper function to get contract address based on chain
export const getContractAddress = (chainId) => {
  switch (chainId) {
    case 1: // mainnet
      return CONTRACT_ADDRESSES.mainnet;
    case 11155111: // sepolia
      return CONTRACT_ADDRESSES.sepolia;
    case 31337: // localhost
      return CONTRACT_ADDRESSES.localhost;
    default:
      return CONTRACT_ADDRESSES.localhost;
  }
}; 