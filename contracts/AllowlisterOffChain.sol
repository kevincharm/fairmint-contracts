// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
// Using viaIR: true

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRandomiserCallback} from "./IRandomiserCallback.sol";
import {Randomiser} from "./Randomiser.sol";
import {IValidateModule} from "./IValidateModule.sol";
import {IWinnersModule} from "./IWinnersModule.sol";

/**
 * @title AllowlisterOffChain
 * @notice Allowlister contract where participants register off-chain. The `raffle` function is called
 *      to begin the raffle draw with the IPFS CID containing the list of participants. An array of
 *      verifiably random indices will be emitted in the `RaffleDrawn` event. Each index corresponds to
 *      an element in the original participant list contained in the file described by the IPFS CID.
 */
contract AllowlisterOffChain is IRandomiserCallback, Ownable {
    struct Registration {
        bool isRegistered;
        uint248 index;
    }

    /// @notice Raffle ID, determined by parent factory
    uint256 public immutable raffleId;

    /// @notice The display name of the raffle
    string public displayName;

    /// @notice The `Randomiser` contract implementing the randomisation logic.
    Randomiser public immutable randomiser;

    /// @notice Number of winners left to draw from the raffle.
    uint256 public immutable winnersToDraw;

    /// @notice The contract implementing `IWinnersModule` that determines the logic
    ///     for handling what happens with the winner addresses.
    IWinnersModule public immutable winnersModule;

    /// @notice The contract implementing `IValidateMOdule` that determines that logic
    ///     for handling validation of each follower after they are drawn during the raffle.
    IValidateModule public immutable validateModule;

    /// @dev Profile IDs registered for raffle. This is the array from which random winners are picked.
    address[] public s_registeredAddresses;

    /// @dev Determines whether address has already registered for raffle
    mapping(address => Registration) public s_registrations;

    /// @notice A bitmap of the drawn winners. The nth bit in this map determines whether the nth
    ///     entry in the `s_registeredAddresses` has won.
    uint256[] public s_winnersBitmap;

    /// @dev The first random number as provided by VRF (can't be changed after it's set)
    uint256 public s_randomSeed;

    /// @notice Flag determining if raffle is already completed
    bool public s_isRaffleFinished = false;

    /// @notice Event emitted when all winners have been drawn from the raffle.
    event RaffleDrawn(
        uint256 indexed raffleId,
        bytes ipfsCid,
        uint32[] winners
    );

    /// @notice Event emitted when VRF calls back with a verifiable random number
    event RandomSeedInitialised(uint256 indexed raffleId, uint256 randomSeed);

    /// @notice Event emitted when a user registers themselves as a raffle participant
    event Registered(
        uint256 indexed raffleId,
        address indexed participant,
        uint256 n
    );

    constructor(
        uint256 raffleId_,
        string memory displayName_,
        uint256 winnersToDraw_,
        address randomiser_,
        address winnersModule_,
        address validateModule_
    ) Ownable() {
        raffleId = raffleId_;
        displayName = displayName_;
        require(winnersToDraw_ > 0, "Gotta have some weeners brah");
        winnersToDraw = winnersToDraw_;
        // TODO: ERC-165 guard these aux contracts
        randomiser = Randomiser(randomiser_);
        winnersModule = IWinnersModule(winnersModule_);
        validateModule = IValidateModule(validateModule_);
    }

    /**
     * @notice Optimistically executes a raffle given an IPFS CID that contains a
     *      JSON payload containing the list of participants.
     * @param ipfsCid raw IPFS CID (36B)
     * @param nParticipants the total number of addresses participating in the raffle
     */
    function raffle(bytes calldata ipfsCid, uint32 nParticipants)
        external
        onlyOwner
    {
        require(!s_isRaffleFinished, "Raffle already finished");
        require(
            nParticipants >= winnersToDraw,
            "Not enough registered for raffle"
        );

        // Populate an array of indices to pick from. Each element from this
        // array is an index to the original list of participants.
        uint32[] memory participants = new uint32[](nParticipants);
        for (uint32 i = 0; i < nParticipants; i++) {
            participants[i] = i;
        }

        uint32[] memory winners = new uint32[](winnersToDraw);
        uint256 participantsLength = nParticipants;
        for (uint256 i = 0; i < winnersToDraw; i++) {
            uint256 randomIndex = getNthRandomNumber(i) % participantsLength;
            uint32 winningIndex = uint32(participants[randomIndex]);
            winners[i] = winningIndex;

            // Remove winning index from raffle entrants (so they can't be drawn again)
            // by swapping the picked winner element with the last element, then
            // contracting the domain of eligible participants.
            participants[randomIndex] = participants[participantsLength - 1];
            participantsLength -= 1;
        }

        s_isRaffleFinished = true;
        emit RaffleDrawn(raffleId, ipfsCid, winners);
    }

    function getRegisteredAddressesLength() external view returns (uint256) {
        return s_registeredAddresses.length;
    }

    /**
     * @notice Get the nth random number using current seed.
     */
    function getNthRandomNumber(uint256 n) private view returns (uint256) {
        uint256 randomSeed = s_randomSeed;
        require(randomSeed != 0, "Blz init random seed");
        return uint256(keccak256(abi.encodePacked(randomSeed, n)));
    }

    /**
     * @notice Request a random number from the Randomiser contract.
     */
    function requestRandomNumber() external onlyOwner {
        require(s_randomSeed == 0, "Randomness has already been set");
        randomiser.getRandomNumber(address(this));
    }

    /**
     * @dev Callback implementing `IRandomiserCallback`, sets the random seed.
     *      Reverts if seed has already been set.
     */
    function receiveRandomness(uint256 randomness) external {
        require(msg.sender == address(randomiser), "Only randomiser may call");
        require(s_randomSeed == 0, "Randomness has already been set");
        s_randomSeed = randomness;
        emit RandomSeedInitialised(raffleId, randomness);
    }
}
