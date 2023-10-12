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
    uint256 public amount;
    uint256 public decimals = 10**18; // New state variable

    event Deposited(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public claimedAmount;

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

    function deposit(uint256 _amount) external {
    require(_amount > 0, "Invalid deposit amount");
    require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

    totalDeposited += _amount;
    deposits[msg.sender] += _amount;
    amount = _amount; // Set the amount state variable
    emit Deposited(msg.sender, _amount);
}


    function claimableAmount(address receiverAddress) public view returns(uint256) {
        require(block.timestamp >= startTimestamp || deposits[receiverAddress] == 0, "Vesting not started");
        uint256 timeElapsed = block.timestamp - startTimestamp;
        uint256 numPeriods = timeElapsed / duration;

        if (numPeriods >= n) {
            return deposits[receiverAddress];
        }

        uint256 tokensPerPeriod = (amount * decimals) / n; // Adjusted calculation with decimals
        uint256 claimable = (tokensPerPeriod * (numPeriods + 1)) / decimals; // Adjusted calculation with decimals
        return claimable;
    }

    function withdraw() external {
        uint256 amountToClaim = claimableAmount(msg.sender);
        require(amountToClaim > 0, "No tokens to claim");
       
        require(token.transfer(msg.sender, amountToClaim), "Token transfer failed");
        claimedAmount[msg.sender] += amountToClaim;
        emit Claimed(msg.sender, amountToClaim);
    }
}
