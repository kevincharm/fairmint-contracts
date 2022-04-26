// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IWinnersModule.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TradeableAllowlistNFTWinnersModule
 * @notice A WinnersModule for Allowlister that distributes an Allowlist NFT to any address
 *      that wins the allowlist raffle.
 */
contract TradeableAllowlistNFTWinnersModule is
    ERC721Enumerable,
    Ownable,
    IWinnersModule
{
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable()
    {}

    function award(address winner) external onlyOwner {
        _safeMint(winner, totalSupply() + 1);
    }
}
