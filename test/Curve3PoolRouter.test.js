const hre = require("hardhat");
const { ethers } = require("hardhat");
const { expect } = require("chai");

const registryAddress = "0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5";
const poolAddress = "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7";

const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

describe("Curve", function () {
  before(async () => {
    [admin, alice, bob] = await ethers.getSigners();

    const Router = await ethers.getContractFactory("Curve3PoolRouter");
    router = await Router.deploy(registryAddress);

    dai = await ethers.getContractAt("IERC20", "0x6b175474e89094c44da98b954eedeac495271d0f");
    usdt = await ethers.getContractAt("IERC20", "0xdAC17F958D2ee523a2206206994597C13D831ec7");
    usdc = await ethers.getContractAt("IERC20", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48");

    const daiTreasuryAddress = "0x60faae176336dab62e284fe19b885b095d29fb7f";
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [daiTreasuryAddress],
    });
    const daiSigner = await ethers.getSigner(daiTreasuryAddress);

    const daiAmount = ethers.parseEther("1000");
    await dai.connect(daiSigner).transfer(admin.address, daiAmount);

    const usdtTreasuryAddress = "0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503";
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [usdtTreasuryAddress],
    });
    const usdtSigner = await ethers.getSigner(usdtTreasuryAddress);

    const usdtAmount = ethers.parseUnits("1000", 6);
    await usdt.connect(usdtSigner).transfer(admin.address, usdtAmount);

    const usdcAmount = ethers.parseUnits("1000", 6);
    await usdc.connect(usdtSigner).transfer(admin.address, usdcAmount);
  });

  describe("USDT/USDC/DAI pool", function () {
    it("Could get tokens", async function () {
      const allCoins = await router.getCoins(poolAddress);
      
      expect(allCoins[0]).to.equal(daiAddress);
      expect(allCoins[1]).to.equal(usdcAddress);
      expect(allCoins[2]).to.equal(usdtAddress);
    });

    it("Could get lp-token address", async function () {
      expect(await router.getLiquidityToken(poolAddress)).to.equal("0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490");
    });

    it("Could add liquidity", async function () {
      const usdAmount = ethers.parseUnits("10", 6);
      const daiAmount = ethers.parseUnits("10", 18);
      await usdt.transfer(router.target, usdAmount);
      await usdc.transfer(router.target, usdAmount);
      await dai.transfer(router.target, daiAmount);

      const lpTokenAddress = await router.getLiquidityToken(poolAddress);
      const lpToken = await ethers.getContractAt("IERC20", lpTokenAddress);

      await router.addLiquidity(
        poolAddress,
        [dai.target, usdc.target, usdt.target],
        [daiAmount, usdAmount, usdAmount]
      );

      console.log("USDT", await usdt.balanceOf(router.target));
      console.log("USDC", await usdc.balanceOf(router.target));
      console.log("DAI", await dai.balanceOf(router.target));

      console.log("LP:", await lpToken.balanceOf(router.target));
    });

    it("Could remove liquidity", async function () {
      const lpTokenAddress = await router.getLiquidityToken(poolAddress);
      const lpToken = await ethers.getContractAt("IERC20", lpTokenAddress);

      const balance = await lpToken.balanceOf(router.target);
      await router.removeLiquidityOneToken(
        poolAddress, usdc.target, balance
      );

      console.log("USDC", await usdc.balanceOf(router.target));
      
      console.log("LP:", await lpToken.balanceOf(router.target));
    });

    it("Could swap", async function () {
      const balance = await usdc.balanceOf(router.target);
      await router.swapToken(
        poolAddress, usdc.target, dai.target, balance
      );

      console.log("USDC", await usdc.balanceOf(router.target));
      console.log("DAI", await dai.balanceOf(router.target));
    });
  });
});
