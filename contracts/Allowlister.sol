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
 * @title Allowlister
 * @notice Contract that allows users to register for an allowlist, then draws
 *      n random winners for the allowlist.
 */
contract Allowlister is IRandomiserCallback, Ownable {
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
    event RaffleDrawn(uint256 indexed raffleId);

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
     * @notice Executes the raffle, picking random winners from the `ids` array.
     */
    function raffle() external onlyOwner {
        require(!s_isRaffleFinished, "Raffle already finished");
        require(
            s_registeredAddresses.length >= winnersToDraw,
            "Not enough registered for raffle"
        );

        // Load temporary copy of registered participant addresses into memory as
        // array with static length.
        address[] memory registeredAddresses = s_registeredAddresses;
        // `nParticipants` will be decremented every time an address is popped.
        // This should be used as the dynamic length of `registeredAddresses`
        uint256 nParticipants = registeredAddresses.length;

        // TODO: Optimise math. Get number of required "buckets" of uint256 to s.t.
        // there is 1 bit available for each registered address.
        uint256 nBuckets = (nParticipants / 256) +
            ((nParticipants * (nParticipants / 256)) < nParticipants ? 1 : 0);
        uint256[] memory winnersBitmap = new uint256[](nBuckets);

        for (uint256 i = 0; i < winnersToDraw; i++) {
            // Pick a winner by calculating the next random number, then modulo
            // with the current cardinality of eligible participants.
            uint256 randomIndex = getNthRandomNumber(i) % nParticipants;

            // Recover the real index from the original registrations array in storage
            address winner = registeredAddresses[randomIndex];
            uint256 winnerIndex = uint256(s_registrations[winner].index);

            // Record winner index by setting it in the bitmap
            uint256 bucketIndex = winnerIndex / 256;
            require(bucketIndex < nBuckets, "Bitmap overflow");
            uint8 bit = uint8(winnerIndex % 256);
            winnersBitmap[bucketIndex] |= (1 << bit);

            // Remove address from raffle entrants (so they can't be drawn again)
            // by swapping the picked winner element with the last element, then
            // contracting the domain of eligible participants.
            registeredAddresses[randomIndex] = registeredAddresses[
                nParticipants - 1
            ];
            nParticipants -= 1;
        }

        s_winnersBitmap = winnersBitmap;
        s_isRaffleFinished = true;
        emit RaffleDrawn(raffleId);

        // Call the winners module, if defined. The winners module is any external contract
        // that defines the `award` function and is called for every winner.
        // if (address(winnersModule) != address(0)) {
        //     for (uint256 i = 0; i < winnersToDraw; i++) {
        //         address winner = winners[i];
        //         require(winner != address(0), "Mint to zero address");
        //         winnersModule.award(winner);
        //     }
        // }
    }

    // This is currently ~214303 gas
    function getWinners() external view returns (address[] memory) {
        require(s_isRaffleFinished, "Raffle not finished");

        address[] memory winners = new address[](winnersToDraw);
        uint256 winnerCount = 0;
        for (uint256 i = 0; i < s_winnersBitmap.length; i++) {
            uint256 bucket = s_winnersBitmap[i];
            if (bucket == 0) {
                continue;
            }

            // Bitscan: check every bit to see if set
            // TODO: Can we do better? Binary search?
            for (uint256 j = 0; j < 256; j++) {
                bool isSet = ((bucket >> j) & 1) == 1;
                if (!isSet) {
                    continue;
                }

                uint256 index = i * 256 + j;
                address winner = s_registeredAddresses[index];
                winners[winnerCount++] = winner;

                // Optimisation: exit early if all winners drawn
                if (winnerCount == winnersToDraw) {
                    break;
                }
            }

            // Optimisation: exit early if all winners drawn
            if (winnerCount == winnersToDraw) {
                break;
            }
        }

        return winners;
    }

    /**
     * @notice Register for a raffle with current EOA.
     */
    function register() external {
        require(s_randomSeed == 0, "Already drawn");
        require(!s_isRaffleFinished, "Already over");
        require(
            !s_registrations[msg.sender].isRegistered,
            "Already registered"
        );

        // Ensure user registering for raffle passes validation
        // This is where the validation module would check for this profile's
        // follower count, publication count, or timestamp of follow.
        if (address(validateModule) != address(0)) {
            require(
                validateModule.validate(msg.sender),
                "Profile validation failed"
            );
        }

        // require(
        //     s_registeredAddresses.length < 2**248 - 1,
        //     "Too many registrations" // Unrealistic anyway
        // );
        uint248 n = uint248(s_registeredAddresses.length);
        s_registeredAddresses.push(msg.sender);
        Registration storage registration = s_registrations[msg.sender];
        registration.isRegistered = true;
        registration.index = n;

        emit Registered(raffleId, msg.sender, n);
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
