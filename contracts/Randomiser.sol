// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRandomiserCallback.sol";

contract Randomiser is Ownable, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    address public linkTokenAddress;
    address public coordinator;
    uint256 public randomResult;
    mapping(bytes32 => address) private requestIdToCallbackMap;
    mapping(address => bool) public authorisedContracts;

    constructor(
        address coordinator_,
        bytes32 keyHash_,
        address linkTokenAddress_
    )
        VRFConsumerBase(
            coordinator_, /** coordinator */
            linkTokenAddress_ /** link address */
        )
    {
        coordinator = coordinator_;
        keyHash = keyHash_;
        linkTokenAddress = linkTokenAddress_;
        fee = 0.0001 * (10**18);
    }

    /**
     * So peeps can't randomly spam the contract and use up our precious LINK
     */
    modifier onlyAuthorised() {
        require(authorisedContracts[msg.sender], "Not authorised");
        _;
    }

    /**
     *  Authorise a contract.
     */
    function authorise(address contractAddress) public onlyOwner {
        authorisedContracts[contractAddress] = true;
    }

    /**
     * Deauthorise a contract.
     */
    function deauthorise(address contractAddress) external onlyOwner {
        authorisedContracts[contractAddress] = false;
    }

    /**
     * In case we need to change the VRF fee for the network.
     */
    function setVrfFee(uint256 fee_) external onlyOwner {
        fee = fee_;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber(address callbackContract)
        public
        onlyAuthorised
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        requestId = requestRandomness(keyHash, fee);
        requestIdToCallbackMap[requestId] = callbackContract;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        address callbackContract = requestIdToCallbackMap[requestId];
        delete requestIdToCallbackMap[requestId];
        IRandomiserCallback(callbackContract).receiveRandomness(randomness);
    }

    /**
     * Withdraw an ERC20 token from the contract.
     */
    function withdraw(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance));
    }

    /**
     * Helper function: withdraw LINK (Polygon) token.
     */
    function withdrawLINK() external onlyOwner {
        withdraw(linkTokenAddress);
    }
}
