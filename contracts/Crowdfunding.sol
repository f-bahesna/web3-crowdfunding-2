// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    string public name; 
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;

    enum CampaignState{ Active, Success, Failed }
    CampaignState public state;

    struct Tier {
        string name;
        uint256 amount;
        uint256 backers;
    }

    Tier[] public tiers;

    //its like middleware
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this contract");
        _; // run onlyOwner() if meet the validation requirement
    }

    modifier isCampaignActive() {
        require(state == CampaignState.Active, "Campaign is not active");
        _;
    }

    modifier CampaignShouldSuccess() {
        require(state == CampaignState.Success, "Campaign is not success");
        _;
    }

    constructor (
        string memory _name, 
        string memory _description, 
        uint256 _goal, 
        uint256 _durationInDays
        ) {
            name = _name;
            description = _description;
            goal = _goal;
            deadline =  block.timestamp + (_durationInDays * 86400);
            owner = msg.sender; // this person who deployed this contract
            state = CampaignState.Active;
        }

    function checkAndUpdateCampaignState() internal {
        if(state == CampaignState.Active){
            if(block.timestamp >= deadline){
                state = address(this).balance >= goal ? CampaignState.Success : CampaignState.Failed;
            } else {
                state = address(this).balance >= goal ? CampaignState.Success : CampaignState.Success;
            }
        }
    }

    function fund(uint256 _tierIndex) public payable isCampaignActive{
        // require(block.timestamp < deadline, "Campaign has ended");
        // commented because soon this validation will handle by isCampaignActive modifier
        require(_tierIndex < tiers.length, "Invalid tier");
        require(msg.value == tiers[_tierIndex].amount, "Incorrect amount");

        tiers[_tierIndex].backers++;
        
        checkAndUpdateCampaignState(); // update campaign status or state to be following requirement.
    }

    function addTier(
        string memory _name,
        uint256 _amount
    ) public onlyOwner{
        require(_amount > 0, "Amount must be greater thatn 0");
        tiers.push(Tier(_name, _amount, 0));
    }

    function removeTier(uint256 _index) public onlyOwner{
        require(_index < tiers.length, "Tier doesn't exists");
        tiers[_index] = tiers[tiers.length -1];
        tiers.pop();
    }

    function withdraw() public onlyOwner CampaignShouldSuccess {
        // require(address(this).balance >= goal, "goal has not been reached");
        checkAndUpdateCampaignState();

        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getInfo() public view returns (string memory) {
        return string(abi.encodePacked('Name: ', name, ' Description: ', description));
    }   
}