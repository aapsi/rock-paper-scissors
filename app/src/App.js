import React from 'react';
import { WagmiConfig } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ConnectKitProvider } from 'connectkit';
import { config } from './config/wagmi';
import Header from './components/Header';
import GameBoard from './components/GameBoard';
import './index.css';

// Create a client
const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <WagmiConfig config={config}>
        <ConnectKitProvider>
          <div className="min-h-screen">
            <Header />
            <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
              <div className="space-y-8">
                <div className="text-center">
                  <h2 className="text-3xl font-bold mb-4">
                    Decentralized Rock Paper Scissors
                  </h2>
                  <p className="text-lg text-white/70 max-w-2xl mx-auto">
                    Play Rock Paper Scissors on the blockchain with secure commit-reveal mechanics. 
                    Create games, place bets, and compete for prizes!
                  </p>
                </div>
                
                <GameBoard />
                
                <div className="card">
                  <h3 className="text-lg font-semibold mb-4">How to Play</h3>
                  <div className="space-y-3 text-sm text-white/80">
                    <div className="flex items-start gap-3">
                      <span className="bg-primary-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">1</span>
                      <p>Create a new game with your desired bet amount (minimum 0.001 ETH)</p>
                    </div>
                    <div className="flex items-start gap-3">
                      <span className="bg-primary-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">2</span>
                      <p>Share the Game ID with your opponent so they can join</p>
                    </div>
                    <div className="flex items-start gap-3">
                      <span className="bg-primary-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">3</span>
                      <p>Both players commit their moves with a secret (commit phase)</p>
                    </div>
                    <div className="flex items-start gap-3">
                      <span className="bg-primary-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">4</span>
                      <p>Reveal your moves using the same secret (reveal phase)</p>
                    </div>
                    <div className="flex items-start gap-3">
                      <span className="bg-primary-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">5</span>
                      <p>The winner takes all! Ties result in refunds to both players</p>
                    </div>
                  </div>
                </div>
                
                <div className="card">
                  <h3 className="text-lg font-semibold mb-4">Game Rules</h3>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                    <div className="text-center p-4 bg-white/5 rounded-lg">
                      <div className="text-2xl mb-2">🪨</div>
                      <div className="font-semibold">Rock</div>
                      <div className="text-white/70">Beats Scissors</div>
                    </div>
                    <div className="text-center p-4 bg-white/5 rounded-lg">
                      <div className="text-2xl mb-2">📄</div>
                      <div className="font-semibold">Paper</div>
                      <div className="text-white/70">Beats Rock</div>
                    </div>
                    <div className="text-center p-4 bg-white/5 rounded-lg">
                      <div className="text-2xl mb-2">✂️</div>
                      <div className="font-semibold">Scissors</div>
                      <div className="text-white/70">Beats Paper</div>
                    </div>
                  </div>
                </div>
              </div>
            </main>
          </div>
        </ConnectKitProvider>
      </WagmiConfig>
    </QueryClientProvider>
  );
}

export default App; 