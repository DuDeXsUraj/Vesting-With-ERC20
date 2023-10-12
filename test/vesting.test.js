const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vesting Contract", function () {
  let Token, Vesting;
  let token, vesting, owner, user;

  const DURATION = 86400; // 1 day in seconds
  const N = 10;
  const AMOUNT = 100 ; // Initial deposit amount

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    Token = await ethers.getContractFactory("Token");
    Vesting = await ethers.getContractFactory("Vesting");

    token = await Token.deploy(AMOUNT);
    await token.deployed();

    vesting = await Vesting.deploy(token.address, DURATION, N);
    await vesting.deployed();
  });

  it("Should allow users to deposit tokens", async function () {
    await token.connect(user).approve(vesting.address, AMOUNT);
    await vesting.connect(user).deposit(AMOUNT);

    const userDeposits = await vesting.deposits(user.address);
    expect(userDeposits).to.equal(AMOUNT);
  });

  it("Should allow users to claim tokens after vesting period", async function () {
    // Fast-forward time by 10 days
    await ethers.provider.send("evm_increaseTime", [DURATION * N]);
    await ethers.provider.send("evm_mine");

    const initialUserBalance = await token.balanceOf(user.address);
    await vesting.connect(user).withdraw();
    const finalUserBalance = await token.balanceOf(user.address);

    const claimedAmount = await vesting.claimedAmount(user.address);
    expect(finalUserBalance.sub(initialUserBalance)).to.equal(claimedAmount);
  });
});
