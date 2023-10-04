// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Airdrop is Ownable {
    IERC721 public nftContract;
    uint256 public airdropAmount;

    mapping(uint256 => bool) public hasClaimed;

    event AirdropClaimed(address indexed user, uint256 indexed tokenId);

    constructor(address _nftContractAddress, uint256 _airdropAmount) {
        nftContract = IERC721(_nftContractAddress);
        airdropAmount = _airdropAmount * 1 ether;
    }

    function setAirdropAmount(uint256 _amount) external onlyOwner {
        airdropAmount = _amount;
    }

    function claimAirdrop(uint256 _tokenId) external {
        require(!hasClaimed[_tokenId], "Already claimed");
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You do not own this token");
        
        hasClaimed[_tokenId] = true;

        (bool success, ) = msg.sender.call{value: airdropAmount}("");
        require(success, "Transfer failed");

        emit AirdropClaimed(msg.sender, _tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {}
}
