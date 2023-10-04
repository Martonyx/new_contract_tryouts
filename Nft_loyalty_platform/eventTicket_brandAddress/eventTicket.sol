// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EventTicketContract is ERC721Enumerable, Ownable {
    enum TicketStatus { Open, Bought, Closed }

    uint256 public ticketIdCounter;
    uint256 public constant MAX_TICKETS = 1000;

    mapping(uint256 => Ticket) public tickets;
    mapping(address => uint256) public userTicketCounts; // Mapping to track the number of tickets purchased by each user

    struct Ticket {
        string ticketTitle;
        string eventDetails;
        uint256 ticketQuantity;
        uint256 price;
        uint256 date;
        TicketStatus status; // Enum to track the ticket status
    }

    event TicketCreated(uint256 indexed ticketId);
    event TicketPurchased(uint256 indexed ticketId, address indexed buyer);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        ticketIdCounter = 1;
    }

    modifier ticketExists(uint256 _ticketId) {
        require(_ticketId > 0 && _ticketId < ticketIdCounter, "Invalid ticket ID");
        _;
    }

    function createTickets(
        string memory _ticketTitle,
        string memory _eventDetails,
        uint256 _ticketQuantity,
        uint256 _price,
        uint256 _date
    ) public onlyOwner {
        require(_ticketQuantity > 0 && ticketIdCounter + _ticketQuantity <= MAX_TICKETS, "Invalid ticket quantity");

        for (uint256 i = 0; i < _ticketQuantity; i++) {
            Ticket memory newTicket = Ticket({
                ticketTitle: _ticketTitle,
                eventDetails: _eventDetails,
                ticketQuantity: _ticketQuantity,
                price: _price,
                date: _date,
                status: TicketStatus.Open
            });

            tickets[ticketIdCounter] = newTicket;
            _mint(address(this), ticketIdCounter); // Mint to the contract
            ticketIdCounter++;

            emit TicketCreated(ticketIdCounter - 1);
        }
    }

    function purchaseTicket(uint256 _ticketId) public payable ticketExists(_ticketId) {
        Ticket storage ticket = tickets[_ticketId];
        require(ticket.status == TicketStatus.Open, "Ticket not available for purchase");
        require(msg.value >= ticket.price * 1 ether, "Insufficient funds");

        _transfer(address(this), msg.sender, _ticketId); // Transfer from contract to buyer
        ticket.status = TicketStatus.Bought;
        emit TicketPurchased(_ticketId, msg.sender);

        // Increment the user's ticket count
        userTicketCounts[msg.sender]++;
    }

    function closeBatchTicketSale(uint256 _startTicketId, uint256 _endTicketId) public onlyOwner {
        require(_startTicketId > 0 && _endTicketId < ticketIdCounter && _endTicketId >= _startTicketId, "Invalid ticket range");

        for (uint256 i = _startTicketId; i <= _endTicketId; i++) {
            Ticket storage ticket = tickets[i];
            if (!_isTicketSoldOut(ticket) || _isEventDateReached(ticket)) {
                ticket.status = TicketStatus.Closed;
            }
        }
    }

     // Function to get the number of tickets purchased by a user
    function getUserTicketCount(address user) public view returns (uint256) {
        return userTicketCounts[user];
    }

    function getUnsoldTicketIds() public view returns (uint256[] memory) {
        uint256[] memory unsoldTicketIds = new uint256[](ticketIdCounter - 1); 
        uint256 unsoldCount = 0;

        for (uint256 i = 1; i < ticketIdCounter; i++) {
            if (tickets[i].status == TicketStatus.Open && !_isEventDateReached(tickets[i])) {
                unsoldTicketIds[unsoldCount] = i; 
                unsoldCount++;
            }
        }

        uint256[] memory unsoldIds = new uint256[](unsoldCount);
        for (uint256 i = 0; i < unsoldCount; i++) {
            unsoldIds[i] = unsoldTicketIds[i];
        }

        return unsoldIds;
    }

    function _isTicketSoldOut(Ticket memory _ticket) private pure returns (bool) {
        return _ticket.ticketQuantity == 0;
    }

    function _isEventDateReached(Ticket memory _ticket) private view returns (bool) {
        return (_ticket.date <= block.timestamp);
    }

    function getTicketsOwnedByUser(address user) public view returns (uint256[] memory) {
        uint256 userTicketCount = balanceOf(user); 
        uint256[] memory ownedTicketIds = new uint256[](userTicketCount); 

        for (uint256 i = 0; i < userTicketCount; i++) {
            ownedTicketIds[i] = tokenOfOwnerByIndex(user, i); 
        }

        return ownedTicketIds;
    }

    function contractsBalance () public view returns(uint256) {
        uint256 contractBalance = address(this).balance;
        return contractBalance;
    }

    function withdrawBalance() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");
        
        (bool success, ) = owner().call{value: contractBalance}("");
        require(success, "Withdrawal failed");
    }
}
