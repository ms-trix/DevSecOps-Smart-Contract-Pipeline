import type { HardhatUserConfig } from "hardhat/types/config";
import hardhatMocha from "@nomicfoundation/hardhat-mocha";
import hardhatEthersChai from "@nomicfoundation/hardhat-ethers-chai-matchers";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  plugins: [hardhatEthersChai, hardhatMocha],
  solidity: {
    version: "0.8.28",
  },
  networks: {
    ...(process.env.SEPOLIA_RPC_URL ? {
      sepolia: {
        type: "http",
        url: process.env.SEPOLIA_RPC_URL,
        accounts: process.env.METAMASK_API ? [process.env.METAMASK_API] : [],
      },
    } : {}),
  },
};

export default config;