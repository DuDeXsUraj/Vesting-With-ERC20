// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

contract Vesting is Ownable (){
    IERC20 public token;
    uint256 public startTimestamp;
    uint256 public duration ; // In seconds
    uint256 public n;
    uint256 public totalDeposited;
    uint256 public amount;
    uint256 public decimals = 10**18; // New state variable
    address public receiver;
    
    event Deposited(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public claimedAmount;
    

    constructor(
        address _token,
        uint256 _durationInDays,
        uint256 _n,
        address _receiver
    ) {
        token = IERC20(_token);
        duration = _durationInDays * 1 days ; // Convert days to seconds
        n = _n;
        startTimestamp = block.timestamp;
        receiver = _receiver;
    }

    modifier onlyReceiver() {
        require(msg.sender == receiver, "Only receiver can withdraw");
        _;
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Invalid deposit amount");

        totalDeposited += _amount;
        deposits[msg.sender] += _amount;
        amount = _amount; // Set the amount state variable (you might want to remove this line)
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        emit Deposited(msg.sender, _amount);
    }

    function claimableAmount(address receiverAddress) public view returns(uint256) {
        require(startTimestamp >=block.timestamp || deposits[receiverAddress] == 0, "Vesting not started");
        uint256 timeElapsed = block.timestamp - startTimestamp;
        uint256 numPeriods = timeElapsed / duration;

        if (numPeriods >= n) {
            return deposits[receiverAddress];
        }

        uint256 tokensPerPeriod = (amount * decimals) / n; // Adjusted calculation with decimals
        uint256 claimable = (tokensPerPeriod * (numPeriods + 1)) / decimals; // Adjusted calculation with decimals
        return claimable;
    }

    function withdraw() external onlyReceiver {
    uint256 amountToClaim = claimableAmount(receiver);
    require(amountToClaim > 0, "No tokens to claim");

    claimedAmount[receiver] += amountToClaim; 
    deposits[receiver] -= amountToClaim; // Update deposits mapping for the receiver
    totalDeposited -= amountToClaim;
    require(token.transfer(receiver, amountToClaim), "Token transfer failed");
    emit Claimed(receiver, amountToClaim);
}

}
