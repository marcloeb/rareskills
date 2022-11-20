import { useState, useEffect, useRef } from "react";
import Head from "next/head";
import { ethers } from "ethers";
import ConnectionModal from "../components/modal/connection";
import CatsTokenAbi from "../abis/CatsToken.json";
import ForgingAbi from "../abis/Forging.json";
import Item from "../components/item.js";
import { getParsedEthersError } from "@enzoferey/ethers-error-parser";

// TODO: Cooldown error message by user & Error messages & reject by user -> mint is turning.
// enzoferey/ethers-error-parser: Parse Ethers.js: UNKNOWN_ERROR. Errordescription: Internal JSON-RPC error.

export default function Home() {
  //set state
  const [defaultAccount, setDefaultAccount] = useState(null);
  const [isMetaMaskInstalled, setIsMetaMaskInstalled] = useState(false);
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [tokenContract, setTokenContract] = useState(null);
  const [forgeContract, setForgeContract] = useState(null);
  const [balances, setBalances] = useState([]);
  const [userCoinBalance, setUserCoinBalance] = useState([]);

  const myUseRef = useRef([]);
  const modal = useRef(null);

  //polygon mumbai
  const forgingAddress = "0x0a9bA622c16Fff4eeC161E9e441a985B2D885Fc7";
  const tokenAddress = "0x9E280C3E28dB45BacA48Ef63601404aaB90AE31b";

  //local hardhat
  // const forgingAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  // const tokenAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

  const connectWallet = async () => {
    if (window && window.ethereum && window.ethereum.isMetaMask) {
      setIsMetaMaskInstalled(true);
      window.ethereum
        .request({ method: "eth_requestAccounts" })
        .then(async (result) => {
          console.log("account: ", result);
          console.log("chainid: ", window.ethereum.chainId);
          if (window.ethereum.chainId === "0x7a69") {
            //0x89=Polygon Main, 3=Hardhat Node, 0x13881= Polygon Mumbay
            accountChangedHandler(result[0]);
          } else {
            setDefaultAccount(null);
            modal.current.setTitleAndDescAction(
              "Wrong Network:",
              "This app only works with Polygon Mumbai. Please select on the MetaMask Plugin the Mumbai Network."
            );
            modal.current.reopenModal();
          }
        })
        .catch((error) => {
          if (error.code === 4001) {
            console.log("Please connect to MetaMask.");
          } else {
            console.error(error);
          }
        });
    } else {
      setIsMetaMaskInstalled(false);
      console.log("Need to install MetaMask");
      // setErrorMessage('Please install MetaMask browser extension to interact');
    }
  };

  const accountChangedHandler = (newAccount) => {
    setDefaultAccount(newAccount);
    updateEthersJS();
  };

  const updateEthersJS = () => {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    setProvider(provider);

    const signer = provider.getSigner();
    setSigner(signer);

    const tokenContract = new ethers.Contract(tokenAddress, CatsTokenAbi, signer);
    const forgeContract = new ethers.Contract(forgingAddress, ForgingAbi, signer);
    setTokenContract(tokenContract);
    setForgeContract(forgeContract);
  };

  useEffect(() => {
    if (window && window.ethereum) {
      setIsMetaMaskInstalled(true);
    }
  }, []);

  useEffect(() => {
    if (window.ethereum) {
      if (window.ethereum._events["accountsChanged"] == undefined) {
        window.ethereum.on("accountsChanged", async (accounts) => {
          console.log("Account changed: " + accounts[0]);
          accountChangedHandler(accounts[0]);
        });
      }

      if (window.ethereum._events["chainChanged"] == undefined) {
        window.ethereum.on("chainChanged", (chain) => {
          console.log("Chain changed: " + chain);
          if (window.ethereum.chainId === "0x7a69") {
            //0x89=Polygon Main, 0x7a69=Hardhat Node, 0x13881= Polygon Mumbay
            connectWallet();
          } else {
            setDefaultAccount(null);
            modal.current.setTitleAndDescAction(
              "Wrong Network:",
              "This app only works with Polygon Mumbai. Please select on the MetaMask Plugin the Mumbai Network."
            );
            modal.current.reopenModal();
          }
        });
      }
    }
  });

  useEffect(() => {
    if (tokenContract) {
      unWatchProviderContract();
      watchProviderContract();
      getBalance();
    }
  }, [tokenContract]);

  useEffect(() => {
    if (provider) {
      getUserCoins();
    }
  }, [provider]);

  const getUserCoins = async () => {
    const balance = await provider.getBalance(defaultAccount);
    setUserCoinBalance(ethers.utils.formatEther(balance));
  };

  const getBalance = async () => {
    const accounts = [...Array(7)].map((_, __) => defaultAccount);
    const ids = [...Array(7)].map((_, i) => i);

    const balance = await tokenContract.balanceOfBatch(accounts, ids);
    const formattedBalance = balance.map((bal) => ethers.utils.formatUnits(bal, 0));
    console.log("formattedBalance:", formattedBalance);
    setBalances(formattedBalance);
  };

  const mint = async (tokenNumber) => {
    try {
      await tokenContract.mint(tokenNumber);
    } catch (error) {
      handleErrorMintForge(error, tokenNumber);
    }
  };

  const forge = async (tokenNumber) => {
    try {
      await forgeContract.forgeToken(tokenAddress, tokenNumber);
    } catch (error) {
      handleErrorMintForge(error, tokenNumber);
    }
  };

  const handleErrorMintForge = async (error, tokenNumber) => {
    const parsedEthersError = getParsedEthersError(error);
    if (parsedEthersError.errorCode == "UNKNOWN_ERROR") {
      if (error.error.data.data.message.includes("Cooldown: One minute between calls")) {
        alert("cooldown, please wait one minute.");
      }
      if (error.error.data.data.message.includes("Required Tokens not minted")) {
        alert("Cannot forge new token. Required tokens are not minted yet, please mint these first.");
      }
      console.error(error);
    } else {
      console.error("Errorcode: " + parsedEthersError.errorCode + ". Errordescription: " + parsedEthersError.context);
    }
    myUseRef.current[tokenNumber].togglePending(false);
  };

  const transfer = async (to, tokenId) => {
    await tokenContract.transfer(to, tokenId);
  };

  const burn = async (tokenNumber) => {
    await tokenContract.burn(tokenNumber);
  };

  const hasForgedToken = () => {
    const forgeableTokens = balances.filter((_, index) => index > 2 && index < 7);
    return Math.max(...forgeableTokens) > 0;
  };

  const hidePending = (targetId) => {
    myUseRef.current = myUseRef.current.filter((ref) => ref);
    myUseRef.current.forEach((ref) => {
      if (ref.tokenId() === parseInt(targetId)) {
        ref.togglePending(false);
      }
    });
  };

  const watchProviderContract = () => {
    provider.on("block", (blockNumber) => {
      // Emitted on every block change
      console.log("block", blockNumber);
    });

    ethereum.on("accountsChanged", (args) => {
      if (args[0] !== defaultAccount) {
        accountChangedHandler(args[0]);
      }
    });

    tokenContract.on("TransferSingle", (operator, _, to, id, amount) => {
      console.log("TransferSingle!!", operator, to, id, amount);
      getBalance();
      hidePending(ethers.utils.formatUnits(id, 0));
    });

    tokenContract.on("TransferBatch", (operator, _, to, ids, amount) => {
      console.log("TransferBatch", operator, to, ids, amount);
      getBalance();

      ids.forEach((id) => {
        hidePending(ethers.utils.formatUnits(id, 0));
      });
    });
  };

  const unWatchProviderContract = () => {
    provider.removeAllListeners;
    ethereum.removeAllListeners;
    tokenContract.removeAllListeners;
  };

  return (
    <div>
      <Head>
        <title>Cats minting, forging & trading</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="container">
        <h1 className="text-7xl mt-10 mb-10">Crypto Cats</h1>
        {isMetaMaskInstalled && !defaultAccount ? (
          <>
            <ConnectionModal ref={modal} connect={connectWallet} isConnect={true}></ConnectionModal>
          </>
        ) : (
          <></>
        )}

        <section className="user-info text-sm shadow-md">
          {!isMetaMaskInstalled ? (
            <>
              <p>
                <a href="https://metamask.io/" className="underline" target="_blank">
                  Please install Metamask
                </a>
              </p>
            </>
          ) : !defaultAccount ? (
            <>
              <div className="mt-4">
                <button
                  type="button"
                  className="inline-flex justify-center rounded-md border border-transparent bg-blue-100 px-4 py-2 text-sm font-medium text-blue-900 hover:bg-blue-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2"
                  onClick={() => {
                    connectWallet();
                  }}
                >
                  Connect
                </button>
              </div>
            </>
          ) : (
            <>
              <p className="cursor-pointer">You are: {defaultAccount}</p>
              <p className="text-coin cursor-pointer">
                You have: {userCoinBalance} <img className="icon-coin" src="/matic.png"></img>
              </p>
            </>
          )}
        </section>

        <section className="list-free-area mb-20">
          <h3 className="text-3xl font-bold underline text-center">NFTs to mint</h3>
          <section className="list-free-items">
            {[0, 1, 2].map((index) => (
              <Item
                className="cat-standard-item"
                key={index}
                ref={(elem) => (myUseRef.current[index] = elem)}
                buttonText={"Mint"}
                tokenNumber={index}
                mint={mint}
                transfer={transfer}
                totalSupply={balances[index]}
                defaultAccount={defaultAccount}
              ></Item>
            ))}
          </section>
        </section>

        <section className="list-forgeable-area mb-20">
          <h3 className="text-3xl font-bold underline text-center">NFTs to forge </h3>

          <div className="list-forge-items">
            {[3, 4, 5, 6].map((index) => (
              <Item
                className="cat-forgable-item"
                key={index}
                ref={(elem) => (myUseRef.current[index] = elem)}
                tokenNumber={index}
                mint={forge}
                buttonText={"Forge"}
                needed={true}
                defaultAccount={defaultAccount}
              ></Item>
            ))}
          </div>
        </section>

        <section className="list-forged-area mb-32 w-full">
          <h3 className="text-3xl font-bold underline text-center">Your forged NFTs</h3>

          <div className="list-forged-items">
            {balances.map((balance, index) => {
              if (index > 2 && index < 7 && balance > 0) {
                return (
                  <Item
                    className="cat-forged-item"
                    key={index}
                    ref={(elem) => myUseRef.current.push(elem)}
                    tokenNumber={index}
                    burn={burn}
                    totalSupply={balances[index]}
                    defaultAccount={defaultAccount}
                  ></Item>
                );
              }
            })}
            {!hasForgedToken() ? (
              <>
                <h4 className="p-16 text-xl font-normal text-center w-full">You have no forged NFT</h4>
              </>
            ) : (
              <></>
            )}
          </div>
        </section>
      </main>

      <style jsx>{`
        .container {
          max-width: 1600px;
          min-height: 100vh;
          padding: 0 0.5rem;
          margin: 0 auto;
        }

        .container {
          background-image: url("/bg_desert_1.png");
          background-size: cover;
          top: 0px;
          right: 0px;
          bottom: 0px;
          left: 0px;
          z-index: 11;
        }

        @media only screen and (min-width: 768px) {
          .container::before {
            background-size: contain;
          }
        }

        main {
          padding: 5rem 0;
          flex: 1;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
        }

        .list-free-items,
        .list-forge-items,
        .list-forged-items {
          display: flex;
          justify-content: center;
          flex-wrap: wrap;
          align-items: center;
        }

        .list-free-area,
        .list-forgeable-area,
        .list-forged-area {
          flex: 1;
        }

        @media only screen and (min-width: 768px) {
          .list-free-area,
          .list-forgeable-area,
          .list-forged-area {
            padding: 24px;
          }
        }

        .text-coin {
          display: flex;
        }

        .icon-coin {
          width: 24px;
          height: 24px;
          margin-left: 4px;
        }

        .user-info {
          position: sticky;
          top: 0;
          padding: 12px 16px;
          margin: 16px 0 32px 0;
          background: #ddd;
          border-radius: 4px;
          z-index: 10;
        }
      `}</style>

      <style jsx global>{`
        html,
        body {
          padding: 0;
          margin: 0;
          font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen, Ubuntu, Cantarell, Fira Sans,
            Droid Sans, Helvetica Neue, sans-serif;
        }

        * {
          box-sizing: border-box;
        }
      `}</style>
    </div>
  );
}
