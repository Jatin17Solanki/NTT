// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1238.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NTTEvent is ERC1238 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private factory;

    struct EventInfo {
        address creator;
        string title;
        string description;
        string[] links;
        string imageHash;
        string associatedCommunity;
        uint256 startDate;
        uint256 endDate;
    }

    struct TokenInfo {
        Status status;
        address tokenOwner;
        uint256 tokenId;
    }

    enum Status {
        Revoked,
        Claimed,
        NotClaimed
    }

    //TODO: Try to optimize whitelist functionality
    address[] private receiverRegister;
    mapping(address => Status) private whitelist;
    mapping(uint256 => address) private tokenOwners;

    //TODO: Try if this info can be emitted as an event
    EventInfo private eventInfo;

    constructor(
        address _creator,
        string memory _title,
        string memory _description,
        string[] memory _links,
        string memory _imageHash,
        string memory _associatedCommunity,
        uint256 _startDate,
        uint256 _endDate,
        address _factory
    ) {
        eventInfo.creator = _creator;
        eventInfo.title = _title;
        eventInfo.description = _description;
        eventInfo.links = _links;
        eventInfo.imageHash = _imageHash;
        eventInfo.associatedCommunity = _associatedCommunity;
        eventInfo.startDate = _startDate;
        eventInfo.endDate = _endDate;
        factory = _factory;
    }

    function addToWhitelist(address[] memory list) public {
        require(
            block.timestamp < eventInfo.startDate,
            "Whitelist cannot be modified after the event has started"
        );
        require(
            msg.sender == eventInfo.creator || msg.sender == factory,
            "Only contract owner can call this function"
        );
        uint256 size = list.length;
        for (uint256 i = 0; i < size; i++) {
            if (whitelist[list[i]] == Status.Revoked) {
                whitelist[list[i]] = Status.NotClaimed;
                receiverRegister.push(list[i]);
            }
        }
    }

    function removeFromWhitelist(address[] memory list) public {
        require(
            block.timestamp < eventInfo.startDate,
            "Whitelist cannot be modified after the event has started"
        );
        require(
            msg.sender == eventInfo.creator,
            "Only contract owner can call this function"
        );
        uint256 size = list.length;
        for (uint256 i = 0; i < size; i++) {
            delete whitelist[list[i]];
        }
    }

    function getWhitelist() public view returns (address[] memory) {
        require(
            msg.sender == eventInfo.creator,
            "Only contract owner can call this function"
        );
        uint256 totalSize = receiverRegister.length;
        uint256 count = 0;
        uint256 curIndex = 0;

        //Get the count of token owners who are eligble to mint
        for (uint256 i = 0; i < totalSize; i++) {
            address _receiver = receiverRegister[i];
            if (whitelist[_receiver] != Status.Revoked) count += 1;
        }

        address[] memory addressList = new address[](count);

        for (uint256 i = 0; i < totalSize; i++) {
            address _receiver = receiverRegister[i];
            if (whitelist[_receiver] != Status.Revoked) {
                addressList[curIndex] = _receiver;
                curIndex += 1;
            }
        }

        return addressList;
    }

    function _validDate() private view returns (bool) {
        if (eventInfo.endDate == 0) {
            if (block.timestamp > eventInfo.startDate) return true;
            else return false;
        } else {
            if (
                block.timestamp > eventInfo.startDate &&
                block.timestamp < eventInfo.endDate
            ) return true;
            else return false;
        }
    }

    function mint(address _user) public returns (uint256) {
        require(
            msg.sender == factory,
            "Mint function can only be called by factory"
        );
        require(whitelist[_user] != Status.Claimed, "Token already minted");
        require(
            whitelist[_user] != Status.Revoked &&
                whitelist[_user] == Status.NotClaimed,
            "Not eligible to claim token!"
        );

        //check if time is within date range
        require(_validDate() == true, "Minting period expired/yet to begin");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(_user, tokenId);

        whitelist[_user] = Status.Claimed;

        tokenOwners[tokenId] = _user;

        return tokenId;
    }

    function burnTokenEvent(uint256 _tokenId) public {
        address _owner = tokenOwners[_tokenId];
        require(_owner != address(0), "Burn failed: Token does not exist!");
        require(
            msg.sender == _owner || msg.sender == eventInfo.creator,
            "only owner/issuer can burn"
        );

        _burn(_tokenId);

        whitelist[_owner] = Status.Revoked;
        delete tokenOwners[_tokenId];
    }

    function getEventDetails() public view returns (EventInfo memory) {
        return eventInfo;
    }

    function fetchTokenClaimed() public view returns (TokenInfo[] memory) {
        require(
            msg.sender == eventInfo.creator,
            "Only contract owner can call this function"
        );

        uint256 totalSize = _tokenIds.current();
        uint256 count = 0;
        uint256 curIndex = 0;

        //Get the count of users who have claimed the tokens
        for (uint256 i = 1; i <= totalSize; i++)
            if (tokenOwners[i] != address(0)) count += 1;

        TokenInfo[] memory tokenList = new TokenInfo[](count);

        for (uint256 id = 1; id <= totalSize; id++) {
            address _owner = tokenOwners[id];
            if (_owner != address(0)) {
                TokenInfo memory _tokenInfo = TokenInfo(
                    Status.Claimed,
                    _owner,
                    id
                );
                tokenList[curIndex] = _tokenInfo;
                curIndex += 1;
            }
        }

        return tokenList;
    }

    function fetchTokenRevoked() public view returns (TokenInfo[] memory) {
        require(
            msg.sender == eventInfo.creator,
            "Only contract owner can call this function"
        );

        uint256 totalSize = _tokenIds.current();
        uint256 count = 0;
        uint256 curIndex = 0;

        //Get the count of users whose tokens have been revoked after mint
        for (uint256 i = 1; i <= totalSize; i++)
            if (tokenOwners[i] == address(0)) count += 1;

        TokenInfo[] memory tokenList = new TokenInfo[](count);

        for (uint256 id = 1; id <= totalSize; id++) {
            address _owner = tokenOwners[id];
            if (_owner == address(0)) {
                TokenInfo memory _tokenInfo = TokenInfo(
                    Status.Revoked,
                    _owner,
                    id
                );
                tokenList[curIndex] = _tokenInfo;
                curIndex += 1;
            }
        }

        return tokenList;
    }

    //returns a list of users who are eligble but have not minted their token yet
    function fetchTokenNotClaimed() public view returns (TokenInfo[] memory) {
        require(
            msg.sender == eventInfo.creator,
            "Only contract owner can call this function"
        );

        uint256 totalSize = receiverRegister.length;
        uint256 count = 0;
        uint256 curIndex = 0;

        //Get the count of users who have not yet claimed the tokens
        for (uint256 i = 0; i < totalSize; i++) {
            address _receiver = receiverRegister[i];
            if (whitelist[_receiver] == Status.NotClaimed) count += 1;
        }

        TokenInfo[] memory tokenList = new TokenInfo[](count);

        for (uint256 i = 0; i < totalSize; i++) {
            address _receiver = receiverRegister[i];
            if (whitelist[_receiver] == Status.NotClaimed) {
                TokenInfo memory _tokenInfo = TokenInfo(
                    Status.NotClaimed,
                    _receiver,
                    0
                );
                tokenList[curIndex] = _tokenInfo;
                curIndex += 1;
            }
        }

        return tokenList;
    }

    function getReceiverStatus() public view returns (Status) {
        return whitelist[msg.sender];
    }

    function fetchTokenOwned() public view returns (EventInfo memory) {
        require(
            whitelist[msg.sender] == Status.Claimed,
            "No token claimed/issued."
        );
        return eventInfo;
    }
}
