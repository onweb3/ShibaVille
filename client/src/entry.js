import { createScene } from "./main.js";
import { createVille } from "./ville.js";

async function createGame() {
  let currentAccount;

  const connectBtn = document.getElementById("metamask-btn");
  const chainBtn = document.getElementById("chain-state");
  if (window.ethereum && window.ethereum.isMetaMask) {
    window.ethereum.on("accountsChanged", handleAccountsChanged);
    window.ethereum.on("chainChanged", handleChainChanged);
    window.ethereum.on("connect", checkChainId);
    connectBtn.addEventListener("click", connect);
    chainBtn.addEventListener("click", changeChain);
    checkConnection();
    checkChainId();
  } else {
    connectBtn.innerText = "Please install MetaMask!";
  }

  function connect() {
    window.ethereum
      .request({ method: "eth_requestAccounts" })
      .then(handleAccountsChanged)
      .catch((err) => {
        if (err.code === 4001) {
          console.log("Please connect to MetaMask.");
        } else {
          console.error(err);
        }
      });
  }

  function checkConnection() {
    window.ethereum
      .request({ method: "eth_accounts" })
      .then(handleAccountsChanged)
      .catch(console.error);
  }

  function checkChainId() {
    window.ethereum
      .request({ method: "eth_chainId" })
      .then(handleChainChanged)
      .catch(console.error);
  }

  function changeChain() {
    window.ethereum
      .request({
        method: "wallet_addEthereumChain",
        params: [
          {
            chainId: "0x15eb",
            chainName: "opBNB",
            blockExplorerUrls: ["https://testnet.opbnbscan.com"],
            nativeCurrency: { symbol: "tBNB", decimals: 18 },
            rpcUrls: ["https://opbnb-testnet-rpc.bnbchain.org"],
          },
        ],
      })
      .then((res) => console.log("add", res))
      .catch((e) => console.log("ADD ERR", e));
  }

  function handleChainChanged(chainId) {
    console.log(chainId);

    if (chainId !== "0x15eb") {
      chainBtn.innerText = "Wrong Network!";
      chainBtn.disabled = false;
    } else {
      chainBtn.innerText = "OPBNB";
      chainBtn.disabled = true;
    }
  }
  function handleAccountsChanged(accounts) {
    console.log(accounts);

    if (accounts.length === 0) {
      connectBtn.innerText = "Connect to MetaMask";
    } else if (accounts[0] !== currentAccount) {
      currentAccount = accounts[0];
      connectBtn.innerText = `Address: ${currentAccount}`;
    }
  }

  const scene = createScene(window);
  const ville = createVille();
  scene.initScene(ville);
  scene.onObjectSelected = (selectedObject) => {
    console.log(selectedObject);
    let { x, y } = selectedObject.userData;
    const tile = ville.lands[x][y];
    console.log(tile);
  };

  const gameUpdater = {
    update() {
      ville.update();
      scene.update(ville);
    },
  };

  setInterval(() => {
    gameUpdater.update();
  }, 1000);

  addEventListener("mousedown", scene.onMouseDown.bind(scene), false);
  addEventListener("mouseup", scene.onMouseUp.bind(scene), false);
  addEventListener("mousemove", scene.onMouseMove.bind(scene), false);
  addEventListener("contextmenu", (e) => e.preventDefault(), false);

  scene.start();

  return gameUpdater;
}
window.onload = () => {
  createGame();
};
