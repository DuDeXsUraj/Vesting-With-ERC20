const { expect } = require("chai");

describe("vesting Contract", function () {
  let Vesting;
  let vesting;
  let Token;
  let token;
  let owner;
  let receiver;

  beforeEach(async function () {
    [owner, receiver] = await ethers.getSigners();

    Token = await ethers.getContractFactory("Token");
    token = await Token.deploy(1000000);

    Vesting = await ethers.getContractFactory("Vesting");
    vesting = await Vesting.deploy(token.address, 30, 4, receiver.address);
  });

  it("Should deposit tokens", async function () {
    const depositAmount = ethers.utils.parseEther("100");
    await token.connect(owner).approve(vesting.address, depositAmount);
    await vesting.connect(owner).deposit(depositAmount);
    const receiverBalance = await token.balanceOf(vesting.address);
    expect(receiverBalance).to.equal(depositAmount);
  });

  it("Should not allow non-receiver to withdraw", async function () {
    const depositAmount = ethers.utils.parseEther("100");
    await token.connect(owner).approve(vesting.address, depositAmount);
    await vesting.connect(owner).deposit(depositAmount);

    await expect(vesting.connect(owner).withdraw()).to.be.revertedWith("Only receiver can withdraw");
  });

  it("Should calculate claimable amount correctly", async function () {
    const depositAmount = ethers.utils.parseEther("100");
    await token.connect(owner).approve(vesting.address, depositAmount);
    await vesting.connect(owner).deposit(depositAmount);

    // Fast-forward 40 days
    await network.provider.send("evm_increaseTime", [40 * 24 * 60 * 60]);
    await network.provider.send("evm_mine");

    const claimableAmount = await vesting.connect(receiver).claimableAmount(receiver.address);
    expect(claimableAmount).to.equal(depositAmount);
  });

  it("Should allow receiver to withdraw claimable amount", async function () {
    const depositAmount = ethers.utils.parseEther("100");
    await token.connect(owner).approve(vesting.address, depositAmount);
    await vesting.connect(owner).deposit(depositAmount);

    // Fast-forward 40 days
    await network.provider.send("evm_increaseTime", [40 * 24 * 60 * 60]);
    await network.provider.send("evm_mine");

    await vesting.connect(receiver).withdraw();
    const receiverBalance = await token.balanceOf(receiver.address);
    expect(receiverBalance).to.equal(depositAmount);
  });

  it("Should not allow double withdrawal", async function () {
    const depositAmount = ethers.utils.parseEther("100");
    await token.connect(owner).approve(vesting.address, depositAmount);
    await vesting.connect(owner).deposit(depositAmount);

    // Fast-forward 40 days
    await network.provider.send("evm_increaseTime", [40 * 24 * 60 * 60]);
    await network.provider.send("evm_mine");

    await vesting.connect(receiver).withdraw();

    // Try to withdraw again
    await expect(vesting.connect(receiver).withdraw()).to.be.revertedWith("No tokens to claim");
  });
});
