import { Wallet, verifyMessage } from "ethers";
import dotenv from "dotenv";

// 加载 .env.production 文件
dotenv.config({ path: ".env.production" });
// dotenv.config({ path: ".env" });

const PRIVATE_KEY = process.env.PRIVATE_KEY;
if (!PRIVATE_KEY) {
  console.error("❌ Set PRIVATE_KEY env var first");
  process.exit(1);
}

const MESSAGE =
  "I verify that my contracts are for Project 0x1eeed44f5c5f5a2df23c2fb82d1c2e9d6c374ee54c2fa8509bdc0fc70a0ac5f3 and I'm an optimist.";

async function main() {
  const wallet = new Wallet(PRIVATE_KEY);

  // EIP-191 personal_sign
  const signature = await wallet.signMessage(MESSAGE);
  const recovered = verifyMessage(MESSAGE, signature);

  console.log("Address:          ", wallet.address);
  console.log("Message:          ", MESSAGE);
  console.log("Signature:        ", signature);
  console.log("Recovered address:", recovered);
  console.log(
    "Match:            ",
    recovered.toLowerCase() === wallet.address.toLowerCase()
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
