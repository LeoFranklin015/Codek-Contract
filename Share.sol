// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract FractionalNFTMarketplace is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    address payable owner;
    uint256 listPrice = 0.01 ether;

    mapping(uint256 => uint256) private tokenIdToTotalShares;
    mapping(uint256 => mapping(address => uint256)) private tokenIdToSharesOwned;

    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 pricePerShare,
        uint256 totalShares,
        uint256 availableShares
    );

    constructor() ERC721("Codek", "CDK") {
        owner = payable(msg.sender);
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function createFractionalToken(string memory tokenURI, uint256 pricePerShare, uint256 totalShares) public payable returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // require(msg.value == listPrice, "Please send the correct listing price");
        require(pricePerShare > 0 && totalShares > 0, "Invalid price or total shares");
        

        tokenIdToTotalShares[newTokenId] = totalShares;
        tokenIdToSharesOwned[newTokenId][msg.sender] = totalShares;
        
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        emit TokenListedSuccess(
            newTokenId,
            address(this),
            msg.sender,
            pricePerShare,
            totalShares,
            totalShares
        );

        return newTokenId;
    }

    function executeFractionalPurchase(uint256 tokenId, uint256 shares) public payable {
        uint pricePerShare = listPrice; // Use list price as price per share for simplicity
        uint totalPrice = pricePerShare * shares;
        address seller = ownerOf(tokenId);

        require(msg.value == totalPrice, "Please submit the correct payment for the shares");
        require(shares > 0 && shares <= tokenIdToSharesOwned[tokenId][seller], "Invalid number of shares");

        tokenIdToSharesOwned[tokenId][seller] -= shares;
        tokenIdToSharesOwned[tokenId][msg.sender] += shares;

        _itemsSold.increment();
        
        payable(owner).transfer(totalPrice);
    }

    // function getSharesOwned(uint256 tokenId, address owner) public view returns (uint256) {
    //     return tokenIdToSharesOwned[tokenId][owner];
    // }
    function getAllNFTs() public view returns (uint256[] memory) {
        uint256 totalTokens = _tokenIds.current();
        uint256[] memory tokenIds = new uint256[](totalTokens);

        for (uint256 i = 0; i < totalTokens; i++) {
            tokenIds[i] = i + 1; // Assuming token IDs start from 1
        }

        return tokenIds;
    }

    function getSharesOwned(uint256 tokenId, address account) public view returns (uint256) {
        return tokenIdToSharesOwned[tokenId][account];
    }


    function getTotalShares(uint256 tokenId) public view returns (uint256) {
        return tokenIdToTotalShares[tokenId];
    }


    function getTokenData(uint256 tokenId) public view returns (
        string memory URI,
        uint256 pricePerShare,
        uint256 totalShares,
        uint256 availableShares
    ) {
        // require(_exists(tokenId), "Token does not exist");
        // string memory uri = tokenURI(tokenId);

        URI = tokenURI(tokenId);
        pricePerShare = getListPrice(); // Assuming list price is the price per share
        totalShares = getTotalShares(tokenId);
        availableShares = tokenIdToSharesOwned[tokenId][msg.sender];
        return (URI, pricePerShare, totalShares, availableShares);
    }

}
