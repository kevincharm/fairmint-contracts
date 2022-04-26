// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Allowlister} from "./Allowlister.sol";
import {Randomiser} from "./Randomiser.sol";

contract AllowlisterFactory is Ownable {
    Randomiser public immutable randomiser;

    uint256 public s_raffleId = 0;
    mapping(uint256 => Allowlister) public raffles;

    event RaffleCreated(uint256 indexed raffleId, address indexed creator);

    constructor(
        uint256 startingRaffleId,
        address coordinator_,
        bytes32 keyHash_,
        address linkTokenAddress_
    ) Ownable() {
        s_raffleId = startingRaffleId;
        randomiser = new Randomiser(coordinator_, keyHash_, linkTokenAddress_);
    }

    function transferRandomiserOwnership(address to) external onlyOwner {
        randomiser.transferOwnership(to);
    }

    function createRaffle(
        string calldata raffleDisplayName,
        uint256 winnersToDraw,
        address winnersModule,
        address validateModule
    ) external returns (address, uint256) {
        uint256 raffleId = s_raffleId++;
        Allowlister raffle = new Allowlister(
            raffleId,
            raffleDisplayName,
            winnersToDraw,
            address(randomiser),
            winnersModule,
            validateModule
        );
        emit RaffleCreated(raffleId, msg.sender);

        // Transfer ownership of raffle to account that created raffle
        raffle.transferOwnership(msg.sender);
        raffles[raffleId] = raffle;

        // Authorise newly-deployed raffle contract on the randomiser
        randomiser.authorise(address(raffle));

        return (address(raffle), raffleId);
    }
}
