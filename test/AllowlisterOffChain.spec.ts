import { expect } from 'chai'
import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { AllowlisterOffChain__factory } from '../typechain'
import { BigNumber } from 'ethers'
import assert from 'assert'

const RAFFLE_ID = 1
const RANDOM_SEED = BigNumber.from('69420')

const deployAllowlister = async (deployer: SignerWithAddress, winnersToDraw: number) =>
    new AllowlisterOffChain__factory(deployer).deploy(
        RAFFLE_ID,
        'Oofbirds',
        winnersToDraw,
        /** Set deployer as randomiser so we can inject a random seed */
        deployer.address,
        ethers.constants.AddressZero,
        ethers.constants.AddressZero
    )

describe('AllowlisterOffChain', () => {
    let deployer: SignerWithAddress
    beforeEach(async () => {
        ;[deployer] = await ethers.getSigners()
    })

    it('should pick 1000 winners from 5000 participants', async function () {
        const winnersToDraw = 1000
        const allowlister = await deployAllowlister(deployer, winnersToDraw)
        await allowlister.deployed()

        // Register 5000 participants
        const [, ...participants] = await ethers.getSigners()
        assert(participants.length >= 5000)
        const nParticipants = participants.length

        // Inject initial random seed
        await expect(allowlister.receiveRandomness(RANDOM_SEED))
            .to.emit(allowlister, 'RandomSeedInitialised')
            .withArgs(RAFFLE_ID, RANDOM_SEED)

        // Perform raffle
        const raffleTx = await allowlister.raffle(
            '0x01701220c3c4733ec8affd06cf9e9ff50ffc6bcd2ec85a6170004bb709669c31de94391a',
            nParticipants
        )
        const raffleReceipt = await raffleTx.wait()
        const event = raffleReceipt.events![0]
        expect(event.event).to.equal('RaffleDrawn')

        const winners = event.args!.winners
        expect(winners.length).to.equal(winnersToDraw)

        // Verify no duplicates in winners set
        const winnersSet = new Set<number>()
        for (const winner of winners) {
            winnersSet.add(winner)
        }
        expect(winners.length).to.equal(winnersSet.size)
    })
})
