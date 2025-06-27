import React from 'react';
import { Gamepad2 } from 'lucide-react';
import { ConnectKitButton } from 'connectkit';

const Header = () => {
  return (
    <header className="bg-retroPanel border-b-4 border-retroYellow shadow-2xl">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          <div className="flex items-center gap-3">
            <Gamepad2 className="w-10 h-10 text-retroBlue animate-bounce drop-shadow-[0_0_6px_#00eaff]" />
            <h1
              className="text-3xl font-retro font-bold bg-gradient-to-r from-retroPink to-retroYellow bg-clip-text text-transparent transition-transform duration-500 hover:scale-110 hover:animate-wiggle drop-shadow-[2px_2px_0_#fff200,4px_4px_0_#00eaff]"
              style={{ animation: 'bounce 1s' }}
            >
              Rock Paper Scissors
            </h1>
          </div>
          <ConnectKitButton />
        </div>
      </div>
    </header>
  );
};

export default Header; 