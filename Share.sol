// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShareNFT is ERC721, Ownable {
    uint256 public sharePrice;
    uint256 public totalShares;
    address public Owner;
    mapping(address => uint256) public sharesOwned;
    uint256 public contractBalance;

    constructor(string memory _name, string memory _symbol, uint256 _totalShares, uint256 _initialPrice) ERC721(_name, _symbol) Ownable(msg.sender) payable {
        sharePrice = _initialPrice;
        // Mint initial shares to the contract owner
        _mint(msg.sender, _totalShares);
        Owner=msg.sender;
        sharesOwned[Owner] = _totalShares;
        totalShares=_totalShares;
        if (msg.value > 0) {
            payable(address(this)).transfer(msg.value);
        }
    }

function buyShares(uint256 _amount) external payable {
    require(_amount > 0 && _amount <= totalShares - sharesOwned[msg.sender], "Invalid share amount");
    uint256 cost = _amount * sharePrice;
    require(msg.value >= cost, "Insufficient funds sent");

    sharesOwned[msg.sender] += _amount;
    sharesOwned[Owner] -= _amount;
    totalShares -= _amount; // Update totalShares directly by deducting the bought shares
    sharePrice = totalShares > 0 ? address(this).balance / totalShares : 0; // Recalculate share price

    _mint(msg.sender, _amount);
}


  function sellShares(uint256 _amount, address recipient) external {
    require(_amount > 0 && _amount <= sharesOwned[msg.sender], "Invalid share amount");
    require(recipient != address(0), "Invalid recipient address");

    sharesOwned[msg.sender] -= _amount;
    totalShares +=  sharesOwned[Owner];
    uint256 proceeds = _amount * sharePrice;

    // Update the share price if there are available shares after the transaction
    sharePrice = (totalShares == 0) ? 0 : sharePrice * totalShares / (totalShares - sharesOwned[owner()]);

    _burn(_amount);
    payable(recipient).transfer(proceeds);
}

    function sendEthToRecipient(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient contract balance");
        require(recipient != address(0), "Invalid recipient address");
        
        recipient.transfer(amount);
    }

}


