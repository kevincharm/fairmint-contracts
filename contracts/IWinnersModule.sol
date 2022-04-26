// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @notice Callback interface for the winners module.
 * @dev A contract implementing this interface will be called with the address of every
 *      raffle winner.
 */
interface IWinnersModule {
    function award(address winner) external;
}
