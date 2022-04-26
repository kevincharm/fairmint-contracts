// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IRandomiserCallback {
    function receiveRandomness(uint256 randomness) external;
}
