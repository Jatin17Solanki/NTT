// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1238.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NTTEvent is ERC1238{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct EventInfo{
        address issuer;
        string title;
        string description;
        string[] links;
        string imageHash;
        string associatedCommunity;
        uint256 startDate;
        uint256 endDate;
    }

    struct TokenInfo {
        address owner;
        uint256 tokenId;
    }

    enum Status{
        Revoked,
        Claimed,
        NotClaimed
    }

    mapping(address => Status) internal whitelist;
    mapping(uint256 => address) internal tokenOwners;
    EventInfo public eventInfo;

    constructor(
        address _issuer,
        string memory _title, 
        string memory _description, 
        string[] memory _links, 
        string memory _imageHash,
        string memory _associatedCommunity,
        uint256 _startDate,
        uint256 _endDate
    ) {

        eventInfo.issuer = _issuer;
        eventInfo.title = _title;
        eventInfo.description = _description;
        eventInfo.links = _links;
        eventInfo.imageHash = _imageHash;
        eventInfo.associatedCommunity = _associatedCommunity;
        eventInfo.startDate = _startDate;
        eventInfo.endDate = _endDate;
    }


    function setWhitelist(address[] memory list) public {
        uint size = list.length;
        for(uint i = 0; i < size; i++){
            whitelist[list[i]] = Status.NotClaimed;
        }

        //emit event
    }


    function removeFromWhitelist(address[] memory list) public {
        uint size = list.length;
        for(uint i = 0; i < size; i++){
            delete whitelist[list[i]];
        }

        //emit event
    }

    function _validDate() private view returns (bool) {
        return true;
    }

    function mint() public {
        require(whitelist[msg.sender] == Status.NotClaimed, "Not eligible to claim token!");
        
        //check if time is within date range
        require(_validDate() == true, "Minting period expired");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(msg.sender, tokenId);

        whitelist[msg.sender] = Status.Claimed;
        tokenOwners[tokenId] = msg.sender;

        //emit event
    }

    function burn(uint256 _tokenId) public {
        address _owner = tokenOwners[_tokenId];
        require(msg.sender == _owner || msg.sender == eventInfo.issuer, "only owner/issuer can burn");
        require(whitelist[_owner] == Status.Claimed, "Cannot burn revoked/unclaimed token");

        _burn(_tokenId);

        whitelist[msg.sender] = Status.Revoked;
        delete tokenOwners[_tokenId];

        //emit event
    }

    function getEventDetails() public view returns(EventInfo memory) {
        return eventInfo;
    }


    function fetchTokenOwners() public view returns(TokenInfo[] memory) {
        require(msg.sender == eventInfo.issuer, "Only contract owner can call this function");

        uint256 size = _tokenIds.current();
        TokenInfo[] memory tokenList = new TokenInfo[](size);

        for(uint i = 0; i < size; i++) {
            tokenList[i].tokenId = i+1;
            tokenList[i].owner = tokenOwners[i+1];
        }

        return tokenList; 
    }
}
