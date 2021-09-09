//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LevelUp is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    mapping(uint256 => uint256) tokenLevel;
    uint256 public maxLevel = 1024;
    string[12] colors = ["chartreuse", "darkorchid", "crimson", "indigo", "mediumblue", "tomato", "chocolate", "aquamarine", "deeppink", "silver", "gold", "black"];

    uint256 public constant updatePrice = 0.01 ether;

    function getLevel(uint256 tokenId) public view returns (uint256) {
      return tokenLevel[tokenId];
    }
    
    function getColor(uint256 tokenId) public view returns (string memory) {
        uint256 level = getLevel(tokenId);
        string memory color = colors[log2(level + 1)];
        
        return color;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint256 level = getLevel(tokenId);
        string memory levelString = toString(level); 
        string memory color = getColor(tokenId);

        string[5] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400"><style>.base { fill: white; font-family: serif; font-size: 70px; }</style><rect width="100%" height="100%" fill="';
        parts[1] = color;
        parts[2] = '"/><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">';
        parts[3] = levelString;
        parts[4] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', toString(tokenId), '", "attributes": { "level":"',toString(level),'"}, "description": "LevelUp is a social experiment that mints the level zero with a base background. You can level up to 1024 levels with 12 different backgrounds colors. Background color changes every time a new base 2 exponential level is reached. As levels go up, backgrounds get harder to change. How high can you go?", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 8000, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
        tokenLevel[tokenId] = 0;
    }

    function log2(uint x) internal pure returns (uint y){
      assembly {
        let arg := x
        x := sub(x,1)
        x := or(x, div(x, 0x02))
        x := or(x, div(x, 0x04))
        x := or(x, div(x, 0x10))
        x := or(x, div(x, 0x100))
        x := or(x, div(x, 0x10000))
        x := or(x, div(x, 0x100000000))
        x := or(x, div(x, 0x10000000000000000))
        x := or(x, div(x, 0x100000000000000000000000000000000))
        x := add(x, 1)
        let m := mload(0x40)
        mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
        mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
        mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
        mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
        mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
        mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
        mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
        mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
        mstore(0x40, add(m, 0x100))
        let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
        let shift := 0x100000000000000000000000000000000000000000000000000000000000000
        let a := div(mul(x, magic), shift)
        y := div(mload(add(m,sub(255,a))), shift)
        y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
      }  
  }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7999 && tokenId < 8888, "Token ID invalid");
        _safeMint(owner(), tokenId);
        tokenLevel[tokenId] = 0;
    }

    function levelUpOne(uint256 tokenId) payable external nonReentrant returns (bool) {
      require(ownerOf(tokenId) == msg.sender, "You must own this number to level up");
      require (msg.value >= updatePrice, "Insufficient amount sent");
      require(tokenLevel[tokenId] + 1 <= maxLevel, "You reach the maximum level");
      
      tokenLevel[tokenId] += 1;
      
      return true;
    }


    function levelUp(uint256 tokenId, uint256 upLevels) payable external nonReentrant returns (bool) {
      require(ownerOf(tokenId) == msg.sender, "You must own this number to upgrade it");
      require (msg.value >= updatePrice.mul(upLevels), "Insufficient amount sent");
      require(tokenLevel[tokenId] + upLevels <= maxLevel, "You reach the maximum level");
            
      tokenLevel[tokenId] += upLevels;
      
      return true;
    }


    function withdrawOwner() external onlyOwner {
      payable(_msgSender()).transfer(address(this).balance);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    constructor() ERC721("LevelUp", "LevelUp") Ownable() {}
}

