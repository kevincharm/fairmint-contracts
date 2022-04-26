// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TradeableAllowlistNFTWinnersModule} from "./TradeableAllowlistNFTWinnersModule.sol";

/**
 * @title SoulboundAllowlistNFTWinnersModule
 * @notice A WinnersModule for Allowlister that distributes an Allowlist NFT to any address
 *      that wins the allowlist raffle. This NFT is soulbound i.e., it cannot be traded.
 */
contract SoulboundAllowlistNFTWinnersModule is
    TradeableAllowlistNFTWinnersModule
{
    constructor(string memory name, string memory symbol)
        TradeableAllowlistNFTWinnersModule(name, symbol)
    {}

    function _transfer(
        address,
        address,
        uint256
    ) internal virtual override {
        revert("Soulbound");
    }
}
