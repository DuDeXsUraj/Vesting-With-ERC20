// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

contract Vesting is Ownable {
    IERC20 public token;
    uint256 public startTimestamp;
    uint256 public duration; // In seconds
    uint256 public n;
    uint256 public totalDeposited;
    uint256 public claimedAmount;
    uint256 public amount;

    event Deposited(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);

    mapping(address => uint256) public deposits; // Mapping to store deposited amounts for each receiver

    constructor(
        address _token,
        uint256 _durationInDays,
        uint256 _n
    ) {
        token = IERC20(_token);
        duration = _durationInDays; // Convert days to seconds
        n = _n;
        startTimestamp = block.timestamp;
    }

    function deposit(uint256) external {
        require(amount > 0, "Invalid deposit amount");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        totalDeposited += amount;
        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function claimableAmount(address receiverAddress) public view returns (uint256) {
        require(block.timestamp >= startTimestamp || deposits[receiverAddress] == 0 ,"Vesting has not started");
        uint256 timeElapsed = block.timestamp - startTimestamp;
        uint256 numPeriods = timeElapsed  / duration;

        if (numPeriods >= n) {
            return deposits[receiverAddress];
        }

        uint256 tokensPerPeriod = amount / n;
        uint256 claimable = tokensPerPeriod * (numPeriods + 1);
        if (claimable > totalDeposited) {
            claimable = totalDeposited;
        }

        return claimable;
    }

    function withdraw() external {
        uint256 amountToClaim = claimableAmount(msg.sender);
        require(amountToClaim > 0, "No tokens to claim");

        require(token.transfer(msg.sender, amountToClaim), "Token transfer failed");

        emit Claimed(msg.sender, amountToClaim);
    }
}
