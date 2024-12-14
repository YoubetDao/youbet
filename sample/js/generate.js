const { ethers } = require("ethers");

async function generateAccount() {
  const wallet = ethers.Wallet.createRandom();

  console.log("Address:", wallet.address);
  console.log("Private Key:", wallet.privateKey);
}

generateAccount();