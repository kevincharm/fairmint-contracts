/* eslint-disable */
import { ethers } from "hardhat";
import {
  MinFollowersValidateModule__factory,
  MinFollowTimeValidateModule__factory,
  SoulboundAllowlistNFTWinnersModule__factory,
  TradeableAllowlistNFTWinnersModule__factory,
} from "../typechain";

const LENS_HUB_PROXY_ADDRESS = "0x4BF0c7AD32Fd2d32089790a54485e23f5C7736C0";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deployer: ${deployer.address}`);

  // Deploy minimum 1 followers module
  const minFollowersValidateModule =
    await new MinFollowersValidateModule__factory(deployer).deploy(
      LENS_HUB_PROXY_ADDRESS,
      1
    );
  await minFollowersValidateModule.deployed();
  console.log(
    `MinFollowersValidateModule: ${minFollowersValidateModule.address}`
  );

  // Deploy minimum 1 followers module
  const minFollowTimeValidateModule =
    await new MinFollowTimeValidateModule__factory(deployer).deploy(
      LENS_HUB_PROXY_ADDRESS,
      "zethamsterdam",
      1
    );
  await minFollowTimeValidateModule.deployed();
  console.log(
    `MinFollowTimeValidateModule: ${minFollowTimeValidateModule.address}`
  );

  const tradeableAllowlistNFTWinnersModule =
    await new TradeableAllowlistNFTWinnersModule__factory(deployer).deploy(
      "Example Allowlist NFT",
      "ALLOW"
    );
  await tradeableAllowlistNFTWinnersModule.deployed();
  console.log(
    `TradeableAllowlistNFTWinnersModule: ${tradeableAllowlistNFTWinnersModule.address}`
  );

  const soulboundAllowlistNFTWinnersModule =
    await new SoulboundAllowlistNFTWinnersModule__factory(deployer).deploy(
      "Example Soulbound Allowlist NFT",
      "ALLOW"
    );
  await soulboundAllowlistNFTWinnersModule.deployed();
  console.log(
    `SoulboundAllowlistNFTWinnersModule: ${soulboundAllowlistNFTWinnersModule.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
