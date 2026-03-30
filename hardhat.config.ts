import type { HardhatUserConfig } from "hardhat/types/config";
import "@nomicfoundation/hardhat-ethers";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
  },
  networks: {
    sepolia: {
      type: "http",
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.METAMASK_API ? [process.env.METAMASK_API] : [],
    },
  },
};

export default config;