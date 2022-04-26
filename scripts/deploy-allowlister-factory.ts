import { BigNumber } from "ethers";
import { ethers } from "hardhat";
// eslint-disable-next-line
import { AllowlisterFactory__factory, Randomiser__factory } from "../typechain";

const LENS_HUB_PROXY_ADDRESS = "0x4BF0c7AD32Fd2d32089790a54485e23f5C7736C0";
const MUMBAI_VRF_COORDINATOR = "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255";
const MUMBAI_VRF_KEYHASH =
  "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4";
const MUMBAI_LINK_TOKEN_ADDRESS = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
// const RANDOMISER_ADDRESS = "0xdbb039ea7485adbc223d211fbb64e1ee9e39eb4a";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deployer: ${deployer.address}`);

  // Deploy randomiser contract
  // const randomiser = await new Randomiser__factory(deployer).deploy(
  //   MUMBAI_VRF_COORDINATOR,
  //   MUMBAI_VRF_KEYHASH,
  //   MUMBAI_LINK_TOKEN_ADDRESS
  // );
  // await randomiser.deployed();
  // console.log(`Randomiser deployed to: ${randomiser.address}`);

  // Replace tx
  // const replaceTx = await deployer.sendTransaction(
  //   await deployer.populateTransaction({
  //     to: deployer.address,
  //     value: 0,
  //     nonce: 256,
  //     gasLimit: 21_000,
  //     gasPrice: BigNumber.from(500).mul(BigNumber.from(10).pow(9)),
  //   })
  // );
  // console.log(`Replace tx: ${replaceTx.hash}`);
  // const replaceTxReceipt = await replaceTx.wait();
  // console.log(`Replace tx receipt: ${replaceTxReceipt.transactionHash}`);

  // Deploy allowlister
  const allowlisterFactory = await new AllowlisterFactory__factory(
    deployer
  ).deploy(
    LENS_HUB_PROXY_ADDRESS,
    MUMBAI_VRF_COORDINATOR,
    MUMBAI_VRF_KEYHASH,
    MUMBAI_LINK_TOKEN_ADDRESS,
    {
      gasLimit: 3_000_000,
      gasPrice: BigNumber.from("600000000000"), // 600 gwei
    }
  );
  const deployTx = allowlisterFactory.deployTransaction;
  console.log(deployTx);
  console.log(await deployTx.wait());
  await allowlisterFactory.deployed();
  console.log(`AllowlisterFactory deployed to: ${allowlisterFactory.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
