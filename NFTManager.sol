//SPDX-License-Identifier: MIT
//nww7sm, Prabhath Tangella

pragma solidity ^0.8.33;

import "./INFTManager.sol";
import "./ERC721.sol";

contract NFTManager is INFTManager, ERC721 {
    uint public count;
    mapping(string => bool) public taken_uris; 
    mapping(uint => string) public tokenid_uri_mapping;

    constructor() ERC721("smNFTManager", "7SNFT") {}

    function mintWithURI(address _to, string memory _uri) public returns (uint){
        require(!taken_uris[_uri], "_uri is already used");
        taken_uris[_uri] = true;
        tokenid_uri_mapping[count] = _uri;
        _safeMint(_to, count);
        count++;
        return count-1;
    }

    function mintWithURI(string memory _uri) external returns (uint){
        return mintWithURI(msg.sender, _uri);
    }

    function tokenURI(uint256 tokenId) override (ERC721, IERC721Metadata) public view returns (string memory) {
        ownerOf(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenid_uri_mapping[tokenId]) : "";
    }

    function _baseURI() override internal pure returns (string memory){
        return "https://andromeda.cs.virginia.edu/ccc/ipfs/files/";
    }

    function supportsInterface(bytes4 interfaceId) override(ERC721, IERC165) public pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId ||
              interfaceId == type(IERC721Metadata).interfaceId || interfaceId == type(INFTManager).interfaceId;
    }
}

