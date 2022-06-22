// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1238.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NTTEvent is ERC1238 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address private factory;

    struct EventInfo {
        uint256 contractId;
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

    event TokenMinted(
        address contractAddress,
        uint256 tokenId,
        address creatorAddress,
        address receiverAddress,
        string title,
        string associatedCommunity,
        bool isValid
    );
    event TokenBurnt(
        address contractAddress,
        uint256 tokenId,
        address creatorAddress,
        address receiverAddress,
        string title,
        string associatedCommunity,
        bool isValid
    );
    event WhitelistAdded(address contractAddress, address[] list);
    event WhitelistRemoved(address contractAddress, address[] list);
    event WhitelistUpdated(
        address contractAddress,
        address receiver,
        uint256 status
    );
    event NTTContractUpdated(
        uint256 contractId,
        address contractAddress,
        address creatorAddress,
        string title,
        string description,
        string[] links,
        string imageHash,
        string associatedCommunity,
        uint256 startDate,
        uint256 endDate
    );

    mapping(address => Status) private whitelist;
    mapping(uint256 => address) private tokenOwners;

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
        uint256 _contractId,
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
        eventInfo.contractId = _contractId;
        factory = _factory;
    }

    function mint() public returns (uint256) {
        require(
            whitelist[msg.sender] != Status.Claimed,
            "Token already minted"
        );
        require(
            whitelist[msg.sender] != Status.Revoked &&
                whitelist[msg.sender] == Status.NotClaimed,
            "Not eligible to claim token!"
        );
        require(_validDate() == true, "Minting period expired/yet to begin");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(msg.sender, tokenId);
        whitelist[msg.sender] = Status.Claimed;
        tokenOwners[tokenId] = msg.sender;

        emit WhitelistUpdated(address(this), msg.sender, 1);
        emit TokenMinted(
            address(this),
            tokenId,
            eventInfo.creator,
            msg.sender,
            eventInfo.title,
            eventInfo.associatedCommunity,
            true
        );
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

        emit WhitelistUpdated(address(this), _owner, 0);
        emit TokenBurnt(
            address(this),
            _tokenId,
            eventInfo.creator,
            _owner,
            eventInfo.title,
            eventInfo.associatedCommunity,
            false
        );
    }

    function addToWhitelist(address[] memory list) public {
        require(
            msg.sender == eventInfo.creator || msg.sender == factory,
            "Only contract owner can call this function"
        );
        require(
            block.timestamp < eventInfo.startDate,
            "Whitelist cannot be modified after the event has started"
        );
        uint256 size = list.length;
        for (uint256 i = 0; i < size; i++) {
            if (whitelist[list[i]] == Status.Revoked) {
                whitelist[list[i]] = Status.NotClaimed;
            }
        }

        emit WhitelistAdded(address(this), list);
    }

    function removeFromWhitelist(address[] memory list) public {
        require(
            msg.sender == eventInfo.creator,
            "Only contract owner can call this function"
        );
        require(
            block.timestamp < eventInfo.startDate,
            "Whitelist cannot be modified after the event has started"
        );
        uint256 size = list.length;
        for (uint256 i = 0; i < size; i++) {
            delete whitelist[list[i]];
        }

        emit WhitelistRemoved(address(this), list);
    }

    function updateDetails(
        string memory _title,
        string memory _description,
        string[] memory _links,
        string memory _imageHash,
        string memory _associatedCommunity
    ) public {
        require(
            msg.sender == eventInfo.creator,
            "Only contract owner can call this function"
        );
        require(
            block.timestamp < eventInfo.startDate,
            "Details cannot be modified after the event has started"
        );

        eventInfo.title = _title;
        eventInfo.description = _description;
        eventInfo.links = _links;
        eventInfo.imageHash = _imageHash;
        eventInfo.associatedCommunity = _associatedCommunity;

        emit NTTContractUpdated(
            eventInfo.contractId,
            address(this),
            eventInfo.creator,
            eventInfo.title,
            eventInfo.description,
            eventInfo.links,
            eventInfo.imageHash,
            eventInfo.associatedCommunity,
            eventInfo.startDate,
            eventInfo.endDate
        );
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

    function getReceiverStatus() public view returns (Status) {
        return whitelist[msg.sender];
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

        //Get the count of users who have claimed the tokens.
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
}