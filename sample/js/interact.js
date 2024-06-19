require("dotenv").config();
const { ethers, JsonRpcProvider, parseEther, parseUnits } = require("ethers");

// Define the contract ABI
const abi = [
  // Add your contract ABI here
  "function createGoal(string _name, string _description, uint256 _requiredStake, uint256 _taskCount) public",
  "function confirmTaskCompletion(uint256 _goalId, address _user) public",
];

// Define the contract address
const contractAddress = "0x902e2f3179aA959137Fdc823754555b10c40F5b1";

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
  //   const tx = await contract.createProject(name, description, requiredStake, 2, {
  //     gasPrice: adjustedGasPrice,
  //   });

  const tx = await contract.confirmTaskCompletion(0, "0x4808df9a90196d41459a3fe37d76dca32f795338", {
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
