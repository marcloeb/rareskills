// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./ICat.sol";

/*
You will build an ERC1155 token with a front-end. Here are the requirements:
● 2 separate contracts: 1) ERC1155 token, 2) forging logic with mint privileges.
● 7 tokens (0-6) in ERC1155, no supply limit
● [0-2] mintable without requirement
● 1-minute cooldown between mints
● Mints are free (exept gas)
● Minting Token 3 needs burning token 0 and 1
● Minting Token 4 needs burning token 1 and 2
● Minting Token 5 needs by burning 0 and 2
● Minting Token 6 can be minted by burning 0, 1, and 2
● Burn Tokens [3-6], no trade no forge
● Trade Tokens [0-2] by hitting the trade this button.
● Burn + Mint = Forge 
● Webapp: how much matic
● Webapp: how much tokens
● Webapp: link to the OpenSea 
● Webapp: Not on Poligon -> prompt to change (autofill the feeds for changing the network)
● Webapp: Styling with bootstrap, tailwind CSS, etc

https://wiki.polygon.technology/docs/develop/hardhat/
-> Private Key from Metamask
*/

contract CatsToken is ERC1155, ICat {
    uint8 public constant COOLDOWN = 60;
    address public forgingContract;

    mapping(uint256 => Cat) public cats;
    mapping(address => uint256) public usersLastAccess;

    modifier onlyForgingContract() {
        require(forgingContract == msg.sender, "Only an admin can ");
        _;
    }

    constructor(address _forgingContract) ERC1155("https://game.example/api/item/{id}.json") {
        forgingContract = _forgingContract;

        cats[0].id = 0;
        cats[0].name = "BLUE_ATTACKER";

        cats[1].id = 1;
        cats[1].name = "BLUE_EYE_KID";

        cats[2].id = 2;
        cats[2].name = "FIGHTING_LADY";

        cats[3].id = 3;
        cats[3].name = "HELPLESS_HUNGRY";
        cats[3].requiresBurning = [0, 1];

        cats[4].id = 4;
        cats[4].name = "HOPLESS_IN_LOVE";
        cats[4].requiresBurning = [1, 2];

        cats[5].id = 5;
        cats[5].name = "MEANY_BEFORE_ATTACK";
        cats[5].requiresBurning = [0, 2];

        cats[6].id = 6;
        cats[6].name = "MOM_AND_BABE";
        cats[6].requiresBurning = [0, 1, 2];
    }

    function mint(uint256 _tokenId) external {
        require(_tokenId < 3, "Selected token is not mintable");
        require(calcCooldown(msg.sender), "Cooldown: One minute between calls");
        _mint(msg.sender, _tokenId, 1, "0x0");
    }

    function calcCooldown(address _user) private view returns (bool) {
        uint256 lastAccess = usersLastAccess[_user];
        return (block.timestamp - lastAccess) > COOLDOWN;
    }

    function _beforeTokenTransfer(
        address, /* operator */
        address, /* from */
        address, /* to */
        uint256[] memory, /* ids */
        uint256[] memory, /* amounts */
        bytes memory /* data */
    ) internal override {
        usersLastAccess[msg.sender] = block.timestamp;
    }

    //Q: cooldown does not work if a item is forged first, as if block timestamp not safed
    function adminMint(address _to, uint256 _tokenId) external onlyForgingContract {
        require(calcCooldown(_to), "Cooldown: One minute between calls");
        _mint(_to, _tokenId, 1, "0x0");
    }

    function transfer(address _to, uint256 _tokenId) external {
        require(_tokenId < 3, "Selected cat is not tradable.");
        _safeTransferFrom(msg.sender, _to, _tokenId, 1, "0x0");
    }

    function burn(uint256 _tokenId) external {
        _burn(msg.sender, _tokenId, 1);
    }

    function burnBatch(
        address _from,
        uint256[] memory _tokenIds,
        uint256[] memory amounts
    ) external onlyForgingContract {
        _burnBatch(_from, _tokenIds, amounts);
    }

    function getCat(uint256 _tokenId) external view onlyForgingContract returns (ICat.Cat memory) {
        return cats[_tokenId];
    }

    function adminBalanceOf(address account, uint256 id) external view onlyForgingContract returns (uint256) {
        return balanceOf(account, id);
    }
}
