//SPDX-License-Identifier: MIT
//nww7sm, Prabhath Tangella

pragma solidity ^0.8.33;

import "./IDAO.sol";
import "./INFTManager.sol";
import "./NFTManager.sol";
import "./Strings.sol";

contract DAO is IDAO{
    uint public numberOfProposals;
    mapping(uint => Proposal) public proposals;
    uint constant public minProposalDebatePeriod = 600;
    address public tokens;
    INFTManager private nftManager;
    string public purpose; 
    string public howToJoin;
    address public curator;
    uint public reservedEther;
    mapping(address => mapping(uint => bool)) public votedYes;
    mapping(address => mapping(uint => bool)) public votedNo;

    constructor(){
        nftManager = new NFTManager();
        tokens = address(nftManager);
        curator = msg.sender;
        nftManager.mintWithURI(curator, generateURI(curator));
        purpose = "To Decide whats the greatest sci-fi movie of all time.";
        howToJoin = "Be a sci-fi movie enthusiast";
    }

    receive() external payable{
        return;
    }

    function newProposal(address recipient, uint amount, 
                        string memory description, uint debatingPeriod) external payable returns (uint){
        require(checkMembership(msg.sender), "Only members can start a new proposal.");
        require(debatingPeriod >= minProposalDebatePeriod, "Debate period not long enough.");
        require(address(this).balance >= reservedEther + amount, "Not enough eth in reserve");
        reservedEther += amount;

        proposals[numberOfProposals] = Proposal(
            {
                recipient: recipient, 
                amount: amount,
                description: description,
                votingDeadline: block.timestamp + debatingPeriod,
                open: true, 
                proposalPassed: false,
                yea: 0, 
                nay: 0, 
                creator: msg.sender
            }
        );
        emit NewProposal(numberOfProposals, recipient, amount, description);
        numberOfProposals += 1;
        return numberOfProposals - 1;
    }

    function vote(uint proposalID, bool supportsProposal) external {
        require(proposalID < numberOfProposals, "Invalid Proposal ID");
        require(checkMembership(msg.sender), "To vote you must be a member");
        require(block.timestamp < proposals[proposalID].votingDeadline, "Voting Deadling has passed.");
        require(votedYes[msg.sender][proposalID] == false && votedNo[msg.sender][proposalID] == false, "You have already voted for this proposal.");

        if (supportsProposal){
            votedYes[msg.sender][proposalID] = true;
            votedNo[msg.sender][proposalID] = false;
            proposals[proposalID].yea += 1;
        }else{
            votedYes[msg.sender][proposalID] = false;
            votedNo[msg.sender][proposalID] = true;
            proposals[proposalID].nay += 1;
        }
        emit Voted(proposalID, supportsProposal, msg.sender);
    }

    function closeProposal(uint proposalID) external{
        require(block.timestamp >= proposals[proposalID].votingDeadline, "Voting Deadline hasn't ended yet.");
        require(checkMembership(msg.sender), "Only DAO members can close a proposal.");
        
        if (proposals[proposalID].yea > proposals[proposalID].nay){
            (bool success, ) = payable(proposals[proposalID].recipient).call{value: proposals[proposalID].amount}("");
            require(success, "Payment to recipient failed");
            proposals[proposalID].proposalPassed = true;
        }
        proposals[proposalID].open = false;
        reservedEther -= proposals[proposalID].amount;
        emit ProposalClosed(proposalID, proposals[proposalID].proposalPassed);
    }

    function checkMembership(address who) internal view returns (bool){
        require(who != address(0), "Please provide a valid address.");
        return nftManager.balanceOf(who) > 0; 
    }

    function isMember(address who) external view returns (bool){
        require(who != address(0), "Please provide a valid address.");
        return nftManager.balanceOf(who) > 0; 
    }

    function addMember(address who) external{
        require(who != address(0));
        require(checkMembership(msg.sender), "Only members can add other members.");
        nftManager.mintWithURI(who, generateURI(who));
    }

    function requestMembership() external{
        require(nftManager.balanceOf(msg.sender) == 0, "You are already a member of the DAO");
        nftManager.mintWithURI(msg.sender, generateURI(msg.sender));
    }

    function generateURI(address addr) internal pure returns (string memory){
        return substring(Strings.toHexString(addr), 2, 34);
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++)
            result[i-startIndex] = strBytes[i];
        return string(result);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IDAO).interfaceId;
    }
}
