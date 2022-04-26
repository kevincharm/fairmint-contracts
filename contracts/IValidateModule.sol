// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @notice Callback interface for the validate module.
 * @dev A contract implementing this interface will be called with address of entrant.
 */
interface IValidateModule {
    function validate(address entrant) external returns (bool);
}
