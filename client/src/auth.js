export function metamaskAuth() {
  let provider;
  let connectedAccount;

  function connect() {
    sdk
      .connect()
      .then((res) => {
        provider = sdk.getProvider();
        console.log(res);
        connectedAccount = res;
      })
      .catch((e) => console.log("request accounts ERR", e));
  }

  function addEthereumChain() {
    provider
      .request({
        method: "wallet_addEthereumChain",
        params: [
          {
            chainId: "0x61",
            chainName: "BSC Testnet",
            blockExplorerUrls: ["https://testnet.bscscan.com"],
            nativeCurrency: { symbol: "BSC", decimals: 18 },
            rpcUrls: ["https://bsc-testnet-dataseed.bnbchain.org/"],
          },
        ],
      })
      .then((res) => console.log("add", res))
      .catch((e) => console.log("ADD ERR", e));
  }

  return {
    connect,
    addEthereumChain,
    connectedAccount,
  };
}
