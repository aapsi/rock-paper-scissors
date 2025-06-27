import { keccak256, toBytes } from 'viem';

/**
 * Generate a commitment hash for a move
 * @param {number} move - The move (1=Rock, 2=Paper, 3=Scissors)
 * @param {string} secret - The secret string
 * @param {string} address - The player's address
 * @returns {string} The commitment hash
 */
export const generateCommitment = (move, secret, address) => {
  // Convert move to uint8
  const moveBytes = toBytes(move);
  
  // Convert secret string to bytes
  const secretBytes = toBytes(secret);
  
  // Convert address to bytes
  const addressBytes = toBytes(address);
  
  // Concatenate all bytes
  const combined = new Uint8Array([...moveBytes, ...secretBytes, ...addressBytes]);
  
  // Generate keccak256 hash
  return keccak256(combined);
};

/**
 * Convert a string to bytes32 format
 * @param {string} str - The string to convert
 * @returns {string} The bytes32 representation
 */
export const stringToBytes32 = (str) => {
  const encoder = new TextEncoder();
  const bytes = encoder.encode(str);
  return '0x' + Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}; 