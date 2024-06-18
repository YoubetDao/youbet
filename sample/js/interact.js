require("dotenv").config();
const { ethers, JsonRpcProvider, parseEther, parseUnits } = require("ethers");

// Define the contract ABI
const abi = [
  // Add your contract ABI here
  "function createProject(string _name, string _description, uint256 _requiredStake) public",
];

// Define the contract address
const contractAddress = "0x009B2B2509d08f4Ed860b2f528ef2166bBE33D00";

// Connect to the Ethereum network
const rpcUrl = "https://rpc.sepolia.linea.build";
const provider = new JsonRpcProvider(rpcUrl);

// Create a signer (use your wallet private key or connect through MetaMask)
const privateKey = process.env.PRIVATE_KEY; // Set your private key as an environment variable
if (!privateKey) {
  console.error("Please set your PRIVATE_KEY environment variable.");
  process.exit(1);
}

const wallet = new ethers.Wallet(privateKey, provider);

// Create a contract instance
const contract = new ethers.Contract(contractAddress, abi, wallet);

async function main() {
  const name = "Example Project";
  const description = "This is an example project";
  const requiredStake = parseEther("0.01");

  const adjustedGasPrice = parseUnits("10", "gwei");
  console.log(`Using gas price: ${adjustedGasPrice}`);
  const tx = await contract.createProject(name, description, requiredStake, {
    gasPrice: adjustedGasPrice,
  });
  console.log(`Transaction hash: ${tx.hash}`);

  // Wait for transaction confirmation
  await tx.wait();
  console.log("Project created successfully.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
