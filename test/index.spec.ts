import { expect } from 'chai'
import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { Allowlister, Allowlister__factory } from '../typechain'
import { BigNumber } from 'ethers'
import assert from 'assert'

const RAFFLE_ID = 1
const RANDOM_SEED = BigNumber.from('69420')

describe('Allowlister', () => {
    let deployer: SignerWithAddress
    let allowlister: Allowlister
    before(async () => {
        ;[deployer] = await ethers.getSigners()
        // Deploy allowlister
        allowlister = await new Allowlister__factory(deployer).deploy(
            RAFFLE_ID,
            'Oofbirds',
            100,
            /** Set deployer as randomiser so we can inject a random seed */
            deployer.address,
            ethers.constants.AddressZero,
            ethers.constants.AddressZero
        )
        await allowlister.deployed()
    })

    it('should perform raffle for 100 participants', async function () {
        // Register 100 participants
        const [, ...participants] = await ethers.getSigners()
        assert(participants.length >= 100)

        for (let i = 0; i < 100; i++) {
            const participant = participants[i]
            await allowlister.connect(participant).register()
            // await expect()
            //     .to.emit(allowlister, 'Registered')
            //     .withArgs(RAFFLE_ID, participant.address, i)
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
})
