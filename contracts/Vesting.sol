// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

contract Vesting is Ownable {
    IERC20 public token;
    address public receiver;
    uint256 public startTimestamp;
    uint256 public duration; // In seconds
    uint256 public n;
    uint256 public totalAmount;
    uint256 public claimedAmount;

    constructor(
        address _token,
        address _receiver,
        uint256 _durationInDays,
        uint256 _n,
        uint256 _totalAmount
    ) {
        token = IERC20(_token);
        receiver = _receiver;
        duration = _durationInDays ;
        n = _n;
        totalAmount = _totalAmount;
        startTimestamp = block.timestamp;
    }

    function claimableAmount() public view returns (uint256) {
        require(block.timestamp >= startTimestamp, "Vesting has not started yet");
        
        uint256 timeElapsed = block.timestamp - startTimestamp;
        uint256 numPeriods = timeElapsed / duration;

        if (numPeriods >= n) {
            return totalAmount - claimedAmount;
        }

        uint256 tokensPerPeriod = totalAmount / n;
        uint256 claimable = tokensPerPeriod * (numPeriods + 1);
        if (claimable > totalAmount) {
            claimable = totalAmount;
        }

        return claimable - claimedAmount;
    }

    function withdraw() public onlyOwner {
        uint256 amountToClaim = claimableAmount();
        require(amountToClaim > 0, "No tokens to claim");

        claimedAmount += amountToClaim;
        token.transfer(receiver, amountToClaim);
    }
}
