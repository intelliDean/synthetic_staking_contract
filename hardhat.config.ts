import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const {URL, KEY} = process.env;

const config: HardhatUserConfig = {
   solidity: "0.8.20",
  networks: {
    sepolia: {
      url: URL,
      accounts: [`0x${KEY}`]
    }
  }
};

export default config;
