// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEventTicketContract {
    function getUserTicketCount(address user) external view returns (uint256);
}

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LoyaltyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;
    
    string private baseTokenURI;

    IEventTicketContract private eventTicket;

    address public brandAddress;

    uint256 public numberOfTransactions;

    mapping(address => bool) private hasMintedNFT; // Mapping to track whether a user has minted an NFT

    // Mapping to track redeemed rewards
    mapping(uint256 => bool) private redeemedRewards;

    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI, uint256 _numberOfTransactions, address _eventTicket) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        
        brandAddress = _eventTicket;
        numberOfTransactions = _numberOfTransactions;
        
        eventTicket = IEventTicketContract(_eventTicket);

    }

    // Mint loyalty NFT based on the number of transactions for a specific brand
    function mintNFT() external {
        require(!hasMintedNFT[msg.sender], "You have already minted an NFT");
        require(eventTicket.getUserTicketCount(msg.sender) >= numberOfTransactions, "Insufficient ticket count");

        _mint(msg.sender, tokenIdCounter.current());
        tokenIdCounter.increment();

        hasMintedNFT[msg.sender] = true;
    }

    // Update the number of transactions for a user on another contract
    function updateTransactionCount(uint256 transactionCount) external onlyOwner {
        numberOfTransactions = transactionCount;
    }

    // View function to retrieve the base token URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // Update the base token URI (for metadata)
    function setBaseURI(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    // Implement reward redemption logic here
    function redeemReward(uint256 tokenId) external {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "You do not own this token");
        require(!redeemedRewards[tokenId], "Reward already redeemed");

        redeemedRewards[tokenId] = true;
    }
}
