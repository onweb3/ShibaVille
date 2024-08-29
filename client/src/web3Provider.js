const { Web3 } = require("web3");

export async function createWeb3(abi, address) {
  const web3 = new Web3(window.ethereum);
  const accounts = await web3.eth.getAccounts();
  console.log(accounts);
  const Contract = new web3.eth.Contract(abi, address);

  return Contract;
}
