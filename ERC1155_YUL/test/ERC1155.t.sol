// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./lib/YulDeployer.sol";

interface ERC1155 {}

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();

    ERC1155 erc1155Contract;

    // address owner;
    address sofie;
    // address tom;

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event URI(string value, uint256 indexed id);

    constructor() {
        // owner = address(this);
        sofie = address(0x1);
        // tom = address(0x2);
    }

    function setUp() public {
        erc1155Contract = ERC1155(yulDeployer.deployContract("ERC1155"));

        bytes memory callDataBytes = abi.encodeWithSignature("setOwner(address)", address(this));
        (bool success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
    }

    function testSetOwner(address newOwner) public {
        // 1. Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(newOwner != address(0));

        // 2. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;
        bytes memory data;

        // 3. Test if a call to getOwner is successful and print it to the console
        callDataBytes = abi.encodeWithSignature("getOwner()");
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        console.log("The current owner is: ");
        console.log(abi.decode(data, (address)));

        // 4. Test if a call to setOwner is fails, because it is already set
        callDataBytes = abi.encodeWithSignature("setOwner(address)", newOwner);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertFalse(success);
    }

    /* ***********************************************************************
                            APPROVAL FOR ALL 
    *********************************************************************** */

    function testIsApprovedForAll(address approver, address operator) public {
        // 1. Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(approver != address(0) && operator != address(0));

        // 2. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;

        // 3. Test if access for current caller is allowed
        callDataBytes = abi.encodeWithSignature("isApprovedForAll(address,address)", approver, operator);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 4. make sure isapprovalforall can be called by anyone
        vm.startPrank(sofie);
        callDataBytes = abi.encodeWithSignature("isApprovedForAll(address,address)", approver, operator);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        vm.stopPrank();
    }

    function testSetApprovalForAll(address operator, bool approved) public {
        // 1: Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(operator != address(0) && operator != address(this));

        // 2. Expect emit Event
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(address(this), operator, approved);

        // 3. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;
        bytes memory data;

        // 4. set a new account as operator
        callDataBytes = abi.encodeWithSignature("setApprovalForAll(address,bool)", operator, approved);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 5. check if new account is approved as operator
        callDataBytes = abi.encodeWithSignature("isApprovedForAll(address,address)", address(this), operator);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        bool isApproved = abi.decode(data, (bool));
        assertEq(isApproved, approved);

        // 6. Should revert on approver == operator
        callDataBytes = abi.encodeWithSignature("setApprovalForAll(address,bool)", address(this), approved);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertFalse(success);
    }

    /* ***********************************************************************
                            MINT, BURN, BALANCEOF 
    *********************************************************************** */

    function testMintAndBurn(address to, uint256 id, uint256 amount) public {
        //  1. Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(to != address(0) && amount != 0);

        // 2. Expect emit Event
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), to, id, amount); // mint
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), to, address(0), id, amount); // burn: check: why to and not from?

        // 3. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;
        bytes memory data;
        uint256 balance;

        // 4. Mint
        callDataBytes = abi.encodeWithSignature("mint(address,uint256,uint256,bytes)", to, id, amount, 0);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 5. Check balance
        callDataBytes = abi.encodeWithSignature("balanceOf(address,uint256)", to, id);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balance = abi.decode(data, (uint256));
        assertEq(balance, amount);

        // 6. Burn
        callDataBytes = abi.encodeWithSignature("burn(address,uint256,uint256)", to, id, amount);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 7. Check balance
        callDataBytes = abi.encodeWithSignature("balanceOf(address,uint256)", to, id);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balance = abi.decode(data, (uint256));
        assertEq(balance, 0);
    }

    /* ***********************************************************************
                               BALANCE OF BATCH
    *********************************************************************** */

    function testBalanceOfBatch(address owner1, address owner2, address owner3, uint256 id1, uint256 id2, uint256 id3, uint256 amount1, uint256 amount2, uint256 amount3) public {
        //1. Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(owner1 != address(0) && owner2 != address(0) && owner3 != address(0) && amount1 != 0 && amount2 != 0 && amount3 != 0);

        // 2. Expect emit Event
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), owner1, id1, amount1);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), owner2, id2, amount2);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), owner3, id3, amount3);

        // 3. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;
        bytes memory data;

        // 1. Mint (to/id/amount/data)
        callDataBytes = abi.encodeWithSignature("mint(address,uint256,uint256,bytes)", owner1, id1, amount1, 0);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        callDataBytes = abi.encodeWithSignature("mint(address,uint256,uint256,bytes)", owner2, id2, amount2, 0);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        callDataBytes = abi.encodeWithSignature("mint(address,uint256,uint256,bytes)", owner3, id3, amount3, 0);
        (success, ) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 2. Check balance
        uint256[] memory ids = new uint256[](3);
        ids[0] = id1;
        ids[1] = id2;
        ids[2] = id3;

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        callDataBytes = abi.encodeWithSignature("balanceOfBatch(address[],uint256[])", owners, ids);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        uint256[] memory balances = abi.decode(data, (uint256[]));
        assertEq(balances[0], amount1);
        assertEq(balances[1], amount2);
        assertEq(balances[2], amount3);
    }

    /* ***********************************************************************
                    SAFE TRANSFER FROM, SAFE TRANSFER FROM BATCH
    *********************************************************************** */

    //test safeTransferFrom with data
    function testSafeTransferFrom(address to, uint256 id, uint256 amount) public {
        // 1. Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(to != address(0) && to != address(this) && amount != 0);

        // 2. Expect emit Event
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), address(this), id, amount); // mint
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(this), to, id, amount); // safe transfer

        // 3. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;
        bytes memory data;
        uint256 balance;

        // 4. Mint (to/id/amount/data)
        callDataBytes = abi.encodeWithSignature("mint(address,uint256,uint256,bytes)", address(this), id, amount, 0);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 5. Check balance
        callDataBytes = abi.encodeWithSignature("balanceOf(address,uint256)", address(this), id);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balance = abi.decode(data, (uint256));
        assertEq(balance, amount);

        // 6. Safe transfer
        callDataBytes = abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", address(this), to, id, amount, 0);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 7. Check balance of two accounts
        callDataBytes = abi.encodeWithSignature("balanceOf(address,uint256)", address(this), id);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balance = abi.decode(data, (uint256));
        assertEq(balance, 0);

        callDataBytes = abi.encodeWithSignature("balanceOf(address,uint256)", to, id);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balance = abi.decode(data, (uint256));
        assertEq(balance, amount);
    }

    function testSafeBatchTransferFrom(address owner, address receiver, uint256 id1, uint256 id2, uint256 id3, uint256 amount) public {
        // 1. Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(owner != address(0) && receiver != address(0) && owner != receiver && amount != 0 && id1 != id2 && id1 != id3 && id2 != id3);

        // 2. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;
        bytes memory data;
        uint256[] memory balances;
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);
        address[] memory owners = new address[](3);

        // 3. Expect emit Event
        ids[0] = id1;
        ids[1] = id2;
        ids[2] = id3;

        amounts[0] = amount;
        amounts[1] = amount;
        amounts[2] = amount;

        // mint event
        vm.expectEmit(true, true, true, false);
        emit TransferBatch(address(this), address(0x0), owner, ids, amounts);
        // transfer event
        vm.expectEmit(true, true, true, false);
        emit TransferBatch(owner, owner, receiver, ids, amounts);
        // burn event
        vm.expectEmit(true, true, true, false);
        emit TransferBatch(address(this), receiver, address(0), ids, amounts);

        // 4. MintBatch (to/id/amount/data)
        callDataBytes = abi.encodeWithSignature("mintBatch(address,uint256[],uint256[],bytes)", owner, ids, amounts, 0);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 5. Check balance
        owners[0] = owner;
        owners[1] = owner;
        owners[2] = owner;

        callDataBytes = abi.encodeWithSignature("balanceOfBatch(address[],uint256[])", owners, ids);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balances = abi.decode(data, (uint256[]));
        assertEq(balances[0], amount);
        assertEq(balances[1], amount);
        assertEq(balances[2], amount);

        // 6. safeBatchTransferFrom (from/to/ids/amounts/data)
        vm.startPrank(owner);
        callDataBytes = abi.encodeWithSignature("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)", owner, receiver, ids, amounts, 0);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        vm.stopPrank();

        // 7. Check balance of owner account
        callDataBytes = abi.encodeWithSignature("balanceOfBatch(address[],uint256[])", owners, ids);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balances = abi.decode(data, (uint256[]));
        assertEq(balances[0], 0);
        assertEq(balances[1], 0);
        assertEq(balances[2], 0);

        // 8. Check balance of receiver account
        owners[0] = receiver;
        owners[1] = receiver;
        owners[2] = receiver;

        callDataBytes = abi.encodeWithSignature("balanceOfBatch(address[],uint256[])", owners, ids);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balances = abi.decode(data, (uint256[]));
        assertEq(balances[0], amount);
        assertEq(balances[1], amount);
        assertEq(balances[2], amount);

        // 9. BurnBatch (receiver/id/amount)
        callDataBytes = abi.encodeWithSignature("burnBatch(address,uint256[],uint256[])", receiver, ids, amounts);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 10. Check balance of receiver account
        callDataBytes = abi.encodeWithSignature("balanceOfBatch(address[],uint256[])", owners, ids);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balances = abi.decode(data, (uint256[]));
        assertEq(balances[0], 0);
        assertEq(balances[1], 0);
        assertEq(balances[2], 0);
    }

    /* ***********************************************************************
                                Mint Batch and Burn Batch
    *********************************************************************** */

    function testMintAndBurnBatch(address owner, uint256 id1, uint256 id2, uint256 id3, uint256 amount1, uint256 amount2, uint256 amount3) public {
        // 1. Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(owner != address(0) && amount1 != 0 && amount2 != 0 && amount3 != 0 && id1 != id2 && id1 != id3 && id2 != id3);

        // 2. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;
        bytes memory data;
        uint256[] memory balances;
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);

        // 2. Expect emit Event
        ids[0] = id1;
        ids[1] = id2;
        ids[2] = id3;
        amounts[0] = amount1;
        amounts[1] = amount2;
        amounts[2] = amount3;

        vm.expectEmit(true, true, true, false);
        emit TransferBatch(address(this), address(0x0), owner, ids, amounts);
        vm.expectEmit(true, true, true, false);
        emit TransferBatch(address(this), owner, address(0x0), ids, amounts);

        // 4. Mint (to/id/amount/data)
        callDataBytes = abi.encodeWithSignature("mintBatch(address,uint256[],uint256[],bytes)", owner, ids, amounts, 0);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 5. Check balance
        address[] memory owners = new address[](3);
        owners[0] = owner;
        owners[1] = owner;
        owners[2] = owner;

        callDataBytes = abi.encodeWithSignature("balanceOfBatch(address[],uint256[])", owners, ids);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balances = abi.decode(data, (uint256[]));
        assertEq(balances[0], amount1);
        assertEq(balances[1], amount2);
        assertEq(balances[2], amount3);

        // 6. Burn
        callDataBytes = abi.encodeWithSignature("burnBatch(address,uint256[],uint256[])", owner, ids, amounts);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);

        // 7. Check balance of accounts
        callDataBytes = abi.encodeWithSignature("balanceOfBatch(address[],uint256[])", owners, ids);
        (success, data) = address(erc1155Contract).call{gas: 100000, value: 0}(callDataBytes);
        assertTrue(success);
        balances = abi.decode(data, (uint256[]));
        assertEq(balances[0], 0);
        assertEq(balances[1], 0);
        assertEq(balances[2], 0);
    }

    /* ***********************************************************************
                               Get URI and Set URI
    *********************************************************************** */

    function testSetAndGetUri(string memory uri) public {
        //string memory uri = "This is my very long string that brakes into three storage slots";
        //string memory uri = "This is";
        //string memory uri = "This is my very long string that brakes into many storage slots... This is my very long string that brakes into many storage slots... This is my very long string that brakes into many storage slots...";

        // 1. Fuzz testing: do not allow all values with vm.assume or variable = bound
        vm.assume(bytes(uri).length != 0);

        // 2. Reuse variables to avoid stack too deep
        bytes memory callDataBytes;
        bool success;
        bytes memory data;

        //set URI
        callDataBytes = abi.encodeWithSignature("setURI(string)", uri);
        (success, ) = address(erc1155Contract).call{gas: 10000000, value: 0}(callDataBytes);
        assertTrue(success);

        // //get URI
        callDataBytes = abi.encodeWithSignature("uri(uint256)", 0);
        (success, data) = address(erc1155Contract).call{gas: 10000000, value: 0}(callDataBytes);
        assertTrue(success);
        string memory uriReturned = abi.decode(data, (string));
        assertEq(uriReturned, uri);
    }
}
