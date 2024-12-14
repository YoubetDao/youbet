require("dotenv").config();
const { ethers, JsonRpcProvider } = require("ethers");

// Define the contract ABI
const abi = [
  "function createRedPacket(string uuid, string[] githubIds, uint256[] amounts) external",
  "function claimRedPacket(string uuid, string githubId, bytes signature) external",
  "function refundRedPacket(string uuid) external",
  "function token() external view returns (address)",
  "event RedPacketCreated(string indexed uuid, address indexed creator, uint256 totalAmount, string[] githubIds, uint256[] amounts)",
  "event RedPacketClaimed(string indexed uuid, string githubId, address indexed claimer, uint256 amount)",
  "event RedPacketRefunded(string indexed uuid, uint256 amount)",
];

// ERC20 token ABI
const tokenAbi = [
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function allowance(address owner, address spender) external view returns (uint256)",
  "function balanceOf(address account) external view returns (uint256)",
];

// Contract addresses
const distributorAddress = "0xBE639b42A3818875D59992d80F18280387cFB412";
const provider = new JsonRpcProvider("https://sepolia.optimism.io");

// Create a signer
const privateKey = process.env.PRIVATE_KEY;
if (!privateKey) {
  console.error("Please set your PRIVATE_KEY environment variable.");
  process.exit(1);
}

const wallet = new ethers.Wallet(privateKey, provider);
const distributor = new ethers.Contract(distributorAddress, abi, wallet);

async function main() {
  // 1. Get token address
  const tokenAddress = await distributor.token();
  const token = new ethers.Contract(tokenAddress, tokenAbi, wallet);

  // 2. Approve tokens
  const totalAmount = ethers.parseUnits("100", 18);
  const allowance = await token.allowance(wallet.address, distributorAddress);
  if (allowance < totalAmount) {
    const approveTx = await token.approve(
      distributorAddress,
      ethers.MaxUint256
    );
    await approveTx.wait();
    console.log("Token approved");
  } else {
    console.log("Token already approved with allowance:", allowance);
  }

  // 3. Create red packet
  const uuid = Date.now().toString(36);
  const githubIds = ["user1", "user2"];
  const amounts = [ethers.parseUnits("20", 18), ethers.parseUnits("10", 18)];

  const createTx = await distributor.createRedPacket(uuid, githubIds, amounts);
  await createTx.wait();
  console.log("Red packet created with UUID:", uuid);

  // 4. Generate signature for claiming
  const signerWallet = new ethers.Wallet(privateKey, provider);
  const message = ethers.solidityPackedKeccak256(
    ["string", "string"],
    [uuid, githubIds[0]]
  );
  const messageHashBytes = ethers.getBytes(message);
  const signature = await signerWallet.signMessage(messageHashBytes);

  // 5. Claim red packet
  const claimTx = await distributor.claimRedPacket(
    uuid,
    githubIds[0],
    signature
  );
  await claimTx.wait();
  console.log("Red packet claimed");

  // 6. read create event
  // const currentBlock = await provider.getBlockNumber();
  // console.log("Current block:", currentBlock);

  // const createdEvents = await distributor.queryFilter(
  //   "RedPacketCreated",
  //   currentBlock - 1000,
  //   currentBlock
  // );

  // console.log("Created events:", createdEvents.length);
  // for (const event of createdEvents) {
  //   console.log(event);
  //   const decodedData = distributor.interface.parseLog({
  //     topics: event.topics,
  //     data: event.data,
  //   });
  //   console.log("UUID:", decodedData.args[0]);
  //   console.log("Amount:", decodedData.args[2]);
  // }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

// async function sign() {
//   const signerWallet = new ethers.Wallet(privateKey, provider);
//   const message = ethers.solidityPackedKeccak256(
//     ["string", "string"],
//     ["674c79142909c827f31f89fd", "wfnuser"]
//   );
//   const messageHashBytes = ethers.getBytes(message);
//   const signature = await signerWallet.signMessage(messageHashBytes);
//   console.log(signature);
// }

// sign();