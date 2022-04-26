import * as dotenv from 'dotenv'

import { HardhatUserConfig, task } from 'hardhat/config'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'solidity-coverage'

dotenv.config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners()

    for (const account of accounts) {
        console.log(account.address)
    }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
    solidity: {
        version: '0.8.13',
        settings: {
            viaIR: true,
            optimizer: {
                enabled: true,
                runs: 1000,
            },
        },
    },
    networks: {
        hardhat: {
            forking: {
                enabled: true,
                url: 'https://eth-rinkeby.alchemyapi.io/v2/sK3CQF-j7R_12rrKhMwpA4uBCFgbm-MQ',
                blockNumber: 10572873,
            },
            accounts: {
                count: 1001,
            },
        },
        rinkeby: {
            url: 'https://eth-rinkeby.alchemyapi.io/v2/sK3CQF-j7R_12rrKhMwpA4uBCFgbm-MQ',
            chainId: 4,
            accounts: [process.env.MAINNET_PK as string],
        },
    },
    gasReporter: {
        enabled: true,
        currency: 'USD',
        gasPrice: 60,
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
}

export default config
