# Rock Paper Scissors Frontend

A React frontend for the decentralized Rock Paper Scissors game built with Wagmi for wallet interactions.

## Features

- 🔗 Wallet connection (MetaMask, WalletConnect, Coinbase Wallet)
- 🎮 Create and join games
- 🔒 Secure commit-reveal mechanics
- ⏰ Timeout handling
- 💰 Betting system
- 📱 Responsive design
- 🎨 Modern UI with Tailwind CSS

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- A Web3 wallet (MetaMask recommended)
- Local blockchain network (Anvil, Hardhat, etc.)

## Installation

1. Navigate to the app directory:
```bash
cd app
```

2. Install dependencies:
```bash
npm install
```

3. Configure the contract address:
   - Open `src/contracts/rockPaperScissors.js`
   - Update the `CONTRACT_ADDRESSES.localhost` with your deployed contract address

4. Start the development server:
```bash
npm start
```

The app will open at [http://localhost:3000](http://localhost:3000).

## Configuration

### Contract Address
Update the contract address in `src/contracts/rockPaperScissors.js`:

```javascript
export const CONTRACT_ADDRESSES = {
  mainnet: "0x...", // Your mainnet address
  sepolia: "0x...", // Your sepolia address
  localhost: "0x5FbDB2315678afecb367f032d93F642f64180aa3", // Your local address
};
```

### WalletConnect Project ID
For WalletConnect support, get a project ID from [WalletConnect Cloud](https://cloud.walletconnect.com) and update it in `src/config/wagmi.js`.

## Usage

1. **Connect Wallet**: Click "Connect Wallet" and select your preferred wallet
2. **Create Game**: Enter a bet amount and click "Create Game"
3. **Join Game**: Enter a Game ID and click "Join Game"
4. **Commit Move**: Select your move (Rock/Paper/Scissors) and enter a secret
5. **Reveal Move**: Use the same move and secret to reveal your choice
6. **Claim Winnings**: Winners automatically receive their prize

## Game Flow

1. **Game Creation**: Player creates a game with a bet amount
2. **Joining**: Second player joins the game with matching bet
3. **Commit Phase**: Both players commit their moves with secrets
4. **Reveal Phase**: Players reveal their moves using the same secrets
5. **Resolution**: Winner takes all, ties result in refunds

## Development

### Project Structure
```
src/
├── components/          # React components
│   ├── Header.js       # App header with wallet connection
│   ├── GameBoard.js    # Main game interface
│   └── WalletConnect.js # Wallet connection component
├── hooks/              # Custom React hooks
│   └── useGame.js      # Game logic and contract interactions
├── contracts/          # Contract configuration
│   └── rockPaperScissors.js # ABI and contract addresses
├── config/             # App configuration
│   └── wagmi.js        # Wagmi configuration
├── App.js              # Main app component
├── index.js            # App entry point
└── index.css           # Global styles
```

### Available Scripts

- `npm start` - Start development server
- `npm build` - Build for production
- `npm test` - Run tests
- `npm eject` - Eject from Create React App

## Troubleshooting

### Common Issues

1. **Contract not found**: Ensure the contract address is correct and the contract is deployed
2. **Wallet connection fails**: Check if MetaMask is installed and connected to the correct network
3. **Transaction fails**: Verify you have sufficient ETH for gas fees and bet amounts
4. **Move commitment fails**: Ensure you're using the same move and secret for commit and reveal

### Network Configuration

Make sure your wallet is connected to the correct network:
- **Localhost**: http://127.0.0.1:8545 (Chain ID: 31337)
- **Sepolia**: https://sepolia.infura.io (Chain ID: 11155111)
- **Mainnet**: https://mainnet.infura.io (Chain ID: 1)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see the main project LICENSE file for details. 