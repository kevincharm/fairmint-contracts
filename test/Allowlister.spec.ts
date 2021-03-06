import { expect } from 'chai'
import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { Allowlister__factory } from '../typechain'
import { BigNumber } from 'ethers'

const RAFFLE_ID = 1
const RANDOM_SEED = BigNumber.from('69420')

const deployAllowlister = async (deployer: SignerWithAddress, winnersToDraw: number) =>
    new Allowlister__factory(deployer).deploy(
        RAFFLE_ID,
        'Oofbirds',
        winnersToDraw,
        /** Set deployer as randomiser so we can inject a random seed */
        deployer.address,
        ethers.constants.AddressZero,
        ethers.constants.AddressZero
    )

describe('Allowlister', () => {
    let deployer: SignerWithAddress
    beforeEach(async () => {
        ;[deployer] = await ethers.getSigners()
    })

    it('should pick 100 winners from 5000 participants', async function () {
        const allowlister = await deployAllowlister(deployer, 100)
        await allowlister.deployed()

        // Register participants
        const [, ...participants] = await ethers.getSigners()
        for (let i = 0; i < 100; i++) {
            const participant = participants[i]
            await allowlister.connect(participant).register()
        }

        // Inject initial random seed
        await expect(allowlister.receiveRandomness(RANDOM_SEED))
            .to.emit(allowlister, 'RandomSeedInitialised')
            .withArgs(RAFFLE_ID, RANDOM_SEED)

        // Perform raffle
        await allowlister.raffle()

        // Invoke it as a non-read transaction so that gas is reported
        const getWinnersTx = await deployer.sendTransaction(
            await allowlister.populateTransaction.getWinners()
        )
        await getWinnersTx.wait()

        // Verify winners
        const winners = await allowlister.getWinners()
        // Since we are drawing 100 winners from a pool of 100, the set of winners
        // and participants should be equivalent.
        expect(winners.length === participants.length)
    })

    it('should pick 1000 winners from 5000 participants', async function () {
        const allowlister = await deployAllowlister(deployer, 1000)
        await allowlister.deployed()

        // Register participants
        const [, ...participants] = await ethers.getSigners()
        for (let i = 0; i < 1000; i++) {
            const participant = participants[i]
            await allowlister.connect(participant).register()
        }

        // Inject initial random seed
        await expect(allowlister.receiveRandomness(RANDOM_SEED))
            .to.emit(allowlister, 'RandomSeedInitialised')
            .withArgs(RAFFLE_ID, RANDOM_SEED)

        // Perform raffle
        await allowlister.raffle()

        // Invoke it as a non-read transaction so that gas is reported
        const getWinnersTx = await deployer.sendTransaction(
            await allowlister.populateTransaction.getWinners()
        )
        await getWinnersTx.wait()

        // Verify winners
        const winners = await allowlister.getWinners()
        // Since we are drawing 100 winners from a pool of 100, the set of winners
        // and participants should be equivalent.
        expect(winners.length === participants.length)
    }).timeout(60_000)
})
