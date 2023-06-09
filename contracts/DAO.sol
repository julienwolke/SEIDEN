// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAO is Ownable {
    // Variables
    ERC20 public token;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    // Structs
    struct Proposal {
        uint256 id;
        string description;
        uint256 amount;
        address payable recipient;
        uint256 votes;
        bool executed;
    }

    // Events
    event ProposalCreated(
        uint256 id,
        string description,
        uint256 amount,
        address recipient
    );
    event ProposalExecuted(uint256 id);
    event Voted(uint256 proposalId, address voter);

    // Constructor
    constructor(address _token) {
        token = ERC20(_token);
    }

    // Functions
    function createProposal(
        string memory _description,
        uint256 _amount,
        address payable _recipient
    ) public onlyOwner {
        proposalCount++;
        proposals[proposalCount] = Proposal(
            proposalCount,
            _description,
            _amount,
            _recipient,
            0,
            false
        );
        emit ProposalCreated(proposalCount, _description, _amount, _recipient);
    }

    function vote(uint256 _proposalId) public {
        require(token.balanceOf(msg.sender) > 0, "Must hold tokens to vote.");
        require(
            _proposalId > 0 && _proposalId <= proposalCount,
            "Invalid proposal ID."
        );

        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");

        proposal.votes += token.balanceOf(msg.sender);
        emit Voted(_proposalId, msg.sender);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(proposal.votes > token.totalSupply() / 2, "Not enough votes.");

        proposal.recipient.transfer(proposal.amount);
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
