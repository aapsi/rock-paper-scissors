import { createConfig } from 'wagmi';
import { mainnet, sepolia, localhost } from 'wagmi/chains';
import { getDefaultConfig } from 'connectkit';

// Set up wagmi config with ConnectKit
export const config = createConfig(
  getDefaultConfig({
    // Your dApps chains
    chains: [mainnet, sepolia, localhost],
    
    // Required API Keys
    walletConnectProjectId: import.meta.env.VITE_WALLET_CONNECT_PROJECT_ID, // Get from https://cloud.walletconnect.com
    
    // Required App Info
    appName: "Rock Paper Scissors",
    appDescription: "Decentralized Rock Paper Scissors Game",
    appUrl: "https://rock-paper-scissors.vercel.app", // your app's url
    appIcon: "https://family.co/logo.png", // your app's icon, no bigger than 1024x1024px (max. 1MB)
    
    // Optional: customize the theme
    theme: {
      mode: 'dark',
      accentColor: '#3b82f6',
      borderRadius: 'medium',
    },
  })
); 