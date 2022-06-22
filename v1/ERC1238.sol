// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC1238 {
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC1238: owner query for nonexistent token"
        );
        return owner;
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(
            to != address(0),
            "ERC1238: mint to the zero address not permitted"
        );
        require(!_exists(tokenId), "ERC1238: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(
            _exists(tokenId),
            "ERC1238: cannot burn a token that does not exist"
        );
        require(_balances[owner] > 0, "ERC1238: no tokens to burn");

        _balances[owner] -= 1;
        delete _owners[tokenId];
    }
}
