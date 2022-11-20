import { useState, forwardRef, useImperativeHandle } from "react";
import { clsx } from "clsx";
import Spinner from "./spinner";

const Item = forwardRef(
  ({ tokenNumber, needed, mint, transfer, burn, totalSupply, defaultAccount, buttonText }, ref) => {
    const [isPending, setPending] = useState(false);
    const [transferText, setTransferText] = useState("");
    const myKiddies = [
      { name: "BLUE_ATTACKER", displayName: "Blue Attacker" },
      { name: "BLUE_EYE_KID", displayName: "Blue Eye Kid" },
      { name: "FIGHTING_LADY", displayName: "Fighting Lady" },
      {
        name: "HELPLESS_HUNGRY",
        displayName: "Helpless Hungry",
        neededName: "needs 1x Blue Attacker and 1x Blue Eye Kid",
      },
      {
        name: "HOPLESS_IN_LOVE",
        displayName: "Hopeless in Love",
        neededName: "needs 1x Blue Eye Kid and 1x Fighting Lady",
      },
      {
        name: "MEANY_BEFORE_ATTACK",
        displayName: "Meany before Attack",
        neededName: "needs 1x Blue Attacker and 1x Fighting Lady",
      },
      {
        name: "MOM_AND_BABE",
        displayName: "Mom and Babe",
        neededName: "needs 1x Blue Attacker, 1x Blue Eye Kid and 1x Fighting Lady",
      },
    ];

    const name = myKiddies[tokenNumber].name;
    const displayName = myKiddies[tokenNumber].displayName;
    const neededName = myKiddies[tokenNumber].neededName;

    const togglePending = (isPending = true) => {
      setPending(isPending);
    };

    const handleTransferText = (event) => {
      setTransferText(event.target.value);
    };

    useImperativeHandle(ref, () => ({
      togglePending(isPending = true) {
        setPending(isPending);
      },

      tokenId() {
        return tokenNumber;
      },
    }));

    const renderTokenNeededUI = (needed) => {
      return needed ? (
        <>
          <div className="text-center min-h-50">{neededName}</div>
        </>
      ) : (
        <></>
      );
    };
    const renderMintButton = (mint) => {
      return mint ? (
        <>
          <button
            type="button"
            className={clsx(
              "mt-2",
              "w-full",
              "text-white",
              "font-bold",
              "py-2",
              "px-4",
              { "bg-green-600": !isPending },
              { "hover:bg-green-900": !isPending },
              { "bg-gray-400": isPending || !defaultAccount },
              { disabled: isPending || !defaultAccount }
            )}
            onClick={() => mint(parseInt(tokenNumber), togglePending())}
          >
            {isPending ? (
              <>
                <Spinner isShown={isPending}></Spinner>
              </>
            ) : (
              <></>
            )}
            {buttonText}
          </button>
        </>
      ) : (
        <></>
      );
    };

    const renderTransferUI = (transfer) => {
      return transfer ? (
        <>
          <section className="transfer-wrapper mt-4">
            <input
              className="input-to"
              placeholder="enter transfer address"
              type="text"
              onChange={handleTransferText}
              value={transferText}
            />
            <button
              type="button"
              className={clsx(
                "btn-transfer",
                "w-full",
                "text-white",
                "font-bold",
                "py-2",
                "px-4",
                { "bg-green-600": transferText },
                "hover:bg-green-900",
                { "bg-gray-400": !transferText || !defaultAccount },
                { disabled: !transferText || !defaultAccount }
              )}
              onClick={() => {
                transfer(transferText, parseInt(tokenNumber), togglePending()), setTransferText("");
              }}
            >
              Transfer
            </button>
          </section>
          <style jsx>{`
            @media only screen and (min-width: 768px) {
              .transfer-wrapper {
                display: flex;
                position: relative;
              }
            }

            .input-to {
              width: 100%;
              padding: 8px;
            }

            @media only screen and (min-width: 768px) {
              .input-to {
                padding: 8px 108px 8px 8px;
              }
            }

            .btn-transfer {
              margin-top: 8px;
            }

            @media only screen and (min-width: 768px) {
              .btn-transfer {
                position: absolute;
                right: 0;
                max-width: 98px;
                margin-top: 0;
              }
            }
          `}</style>
        </>
      ) : (
        <></>
      );
    };

    const renderBurnButton = (burn) => {
      return burn ? (
        <>
          <button
            type="button"
            className={clsx(
              "mt-2",
              "w-full",
              "text-white",
              "font-bold",
              "py-2",
              "px-4",
              { "bg-red-400": !isPending },
              { "hover:bg-red-700": !isPending },
              { "bg-gray-400": isPending || !defaultAccount },
              { disabled: isPending || !defaultAccount }
            )}
            onClick={() => burn(parseInt(tokenNumber), togglePending())}
          >
            {isPending ? (
              <>
                <Spinner isShown={isPending}></Spinner>
              </>
            ) : (
              <></>
            )}
            Burn
          </button>
        </>
      ) : (
        <></>
      );
    };

    return (
      <div className="container-item">
        <div className="wrapper-item">
          <img className="img-kiddy" src={`/${name}.png`}></img>
          <p className="txt-character text-lg mt-3">{displayName}</p>
          {renderTokenNeededUI(needed)}
          {renderMintButton(mint)}
          {renderTransferUI(transfer)}
          {renderBurnButton(burn)}

          <p>
            {totalSupply ? (
              <>
                <span className="total-supply">{totalSupply}</span>
              </>
            ) : (
              <></>
            )}
          </p>
        </div>

        <style jsx>{`
          .moka {
            font-size: 30px;
          }

          .container-item {
            position: relative;
            width: 100% !important;
          }

          @media only screen and (min-width: 768px) {
            .container-item {
              width: 50% !important;
            }
          }

          @media only screen and (min-width: 1200px) {
            .container-item {
              width: 33% !important;
            }
          }

          @media only screen and (min-width: 1600px) {
            .container-item {
              width: 25% !important;
            }
          }

          .wrapper-item {
            padding: 16px;
            margin: 16px;
            background: #eee;
            border-radius: 4px;
            box-shadow: 1px 1px 5px rgb(0 0 0 / 23%);
          }

          .img-kiddy {
            width: 100%;
            margin: 15px, 15px;
            display: block;
          }

          .txt-character {
            text-align: center;
            font-weight: bold;
            margin-bottom: 4px;
          }

          .total-supply {
            position: absolute;
            top: 20px;
            left: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            min-width: 50px;
            min-height: 50px;
            background: #ffd622;
            border-radius: 50px;
            font-size: 18px;
            font-weight: bold;
            color: #444;
          }
        `}</style>
      </div>
    );
  }
);

export default Item;
