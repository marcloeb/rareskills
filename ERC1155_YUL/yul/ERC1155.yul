object "ERC1155YulPure" {
    code {
        // needs to be commented out to make the setOwner function work
        // sstore(0, caller()) 
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            /* ***********************************************************************
                                           INITALIZATION 
               *********************************************************************** */

            // Initializing Free Memory Pointer, start from 0 with every function call
            setMPtr(0x80)

            // Nobody should send Ether to this contract, its not prepared to handle it 
            require(iszero(callvalue())) 

            /* ***********************************************************************
                                      EVENTS AS FUNCTIONS 
               *********************************************************************** */

            // Emit a debug event
            // sample param 1:  emitDebug_uint("isApprovedForAll-first", calldataParamAsAddress(0))
            // sample param 2:  emitDebug_uint("isApprovedForAll-second", calldataParamAsAddress(1))
            function emitDebug_uint(text,value)   /* Debug_uint(string,uint256) */{
                let signatureHash := 0x17b1603e30aea0ee8634580836929e19be2013ed89c620b96a5a1968ad101a70
                log3(0x00, 0x00, signatureHash, text, value)
            }

            // Emit a Transfer Single event
            function emitTransferSingle(operator, from, to, id, value) {
                /* TransferSingle(address,address,address,uint256,uint256) */
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                mstore(0x00, id)
                mstore(0x20, value)
                log4(0x00, 0x40, signatureHash, operator, from, to)
            }

            // Emit a Transfer Batch event
            function emitTransferBatch(operator, from, to, offsetIdsArr, offsetAmountsArr) {
                /* TransferBatch(address,address,address,uint256[],uint256[]) */
                let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb

                //0x80: Store Offset of Ids 
                let offsetStart := getMPtr() 
                mstore(offsetStart, 0x40) //storage position need to refer to 0x00, because it will be a stand alone array
                incrMPtr()

                //0xa0: Prepare slot to store offset of Amounts
                let offsetAmounts := getMPtr() //save Storage slot
                incrMPtr()

                //0xc0 Length, 0xf0 Value 1, 0x120 Value 2, 0x140 Value 3
                copyArrayToMemory(offsetIdsArr) //copy the array to memory

                // store Offset of Amounts
                mstore(offsetAmounts, safeSub(getMPtr(),offsetStart)) //storage position need to refer to 0x00, because it will be a stand alone array
                
                copyArrayToMemory(offsetAmountsArr)

                log4(offsetStart, safeSub(getMPtr(), offsetStart), signatureHash, operator, from, to)
            }

            // Emit an approval for all event
            function emitApprovalForAll(owner, operator, approved) {
                /* ApprovalForAll(address,address,bool) */
                let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
                mstore(0x00, approved)
                log3(0x00, 0x20, signatureHash, owner, operator)
            }

            // Emit an URI event
            function emitURI(value,id){
                /* URI(string,uint256) */
                let signatureHash :=0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b
                /* Not implemented yet, unsure if needed - solemate does not use it, openzeppelin does not use it */
            }


            /* ***********************************************************************
                                        FUNCTIONS 
               *********************************************************************** */
            //approved mapping = 0, balance mapping = 1
            switch functionSelector()
            case 0x893d20e8 /* getOwner() */ {
                returnWord(sload(0))
            }
            case 0x13af4035 /* "setOwner(address)" */{
                require(eq(sload(0),0x0))
                sstore(0, caller()) // Store the contract creator in the storage slot 0 (this is the constructor)
                //emitDebug_uint("The owner is: ", sload(ownerPos()))
            }
            case 0xe985e9c5 /* "isApprovedForAll(address,address)" account/operator */ {
               let approved := _isApprovedForAll(calldataParamAsAddress(0), calldataParamAsAddress(1))
                returnWord(approved)
            }
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {
                let owner := caller()
                let operator := calldataParamAsAddress(0)
                let approved := calldataParamAsBool(1)

                require(iszero(eq(owner,operator))) // Cannot approve yourself

                let offset := nestedMappingPos(0, owner, operator)
                sstore(offset, approved)
                
                emitApprovalForAll(owner, operator, approved)
            }
            case 0x731133e9 /* mint(address,uint256,uint256,bytes) to/id/amount/data, needed for balanceOf */ {
                _mint(calldataParamAsAddress(0),calldataParamAsUint(1), calldataParamAsUint(2), calldataParamAsUint(3),true)
            }
            case 0xf5298aca /* burn(address,uint256,uint256), from/id/amount needed for balanceOf */ {
                _burn(calldataParamAsAddress(0),calldataParamAsUint(1), calldataParamAsUint(2),true)
            }
            case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
                let offset := nestedMappingPos(1, calldataParamAsAddress(0), calldataParamAsUint(1))
                returnWord(sload(offset))
            }
            case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" accounts/ids */ {
                 //from calldata get offset, then get arr length, then values
                let offsetAccountsArr := calldataParamAsUint(0)
                let lenAccountsArr := calldataload(calldataValuesRawOffset(offsetAccountsArr))

                let offsetIdsArr := calldataParamAsUint(1)
                let lenIdsArr := calldataload(calldataValuesRawOffset(offsetIdsArr))

                require(eq(lenAccountsArr, lenIdsArr))

                // prepare return array of balances: first offset, length, then values
                let startOffset := getMPtr()

                //store the offset of the array, zero based (because the return array is a stand alone array)
                mstore(getMPtr(),0x20) 
                incrMPtr()

                //Array length
                mstore(getMPtr(), lenAccountsArr)
                incrMPtr()

                //Array values
                for {let i:=0 } lt(i, lenAccountsArr) {i:=add(i,1)} {
                    let acc := calldataload(calldataValuesRawOffset(safeAdd(offsetAccountsArr,mul(safeAdd(i,1),0x20))))
                    let id := calldataload(calldataValuesRawOffset(safeAdd(offsetIdsArr, mul(safeAdd(i,1),0x20))))
                    let bal := sload(nestedMappingPos(1, acc, id))
                    
                    mstore(getMPtr(), bal)
                    incrMPtr()
                }
                returnData(startOffset, getMPtr())
            }
            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" from/to/id/amount/data */ {
                _safeTransferFrom (calldataParamAsAddress(0), calldataParamAsAddress(1), calldataParamAsUint(2), calldataParamAsUint(3), calldataParamAsUint(4),true)
            }
            case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"  from/to/ids/amounts/data */ {
                let from := calldataParamAsAddress(0)
                let to := calldataParamAsAddress(1)
                let offsetIdsArr := calldataParamAsUint(2)
                let offsetAmountsArr := calldataParamAsUint(3)
                let _data :=  calldataParamAsUint(4) 

                let lenIdsArr := calldataload(calldataValuesRawOffset(offsetIdsArr))
                let lenAmountsArr := calldataload(calldataValuesRawOffset(offsetAmountsArr))
                require(eq(lenIdsArr, lenAmountsArr))

                for {let i:=0 } lt(i, lenIdsArr) {i:=add(i,1)} {
                    let id := calldataload(calldataValuesRawOffset(safeAdd(offsetIdsArr, mul(safeAdd(i,1),0x20))))
                    let amount := calldataload(calldataValuesRawOffset(safeAdd(offsetAmountsArr,mul(safeAdd(i,1),0x20))))
                    _safeTransferFrom(from, to, id, amount, _data, false)               
                }
                emitTransferBatch(caller(), from, to, offsetIdsArr, offsetAmountsArr)
            }
            case 0x1f7fdffa  /* mintBatch(address,uint256[],uint256[],bytes) to/ids/amounts/data) */ {     
                let to := calldataParamAsAddress(0)

                let offsetIdsArr := calldataParamAsUint(1)
                let lenIdsArr := calldataload(calldataValuesRawOffset(offsetIdsArr))

                let offsetAmountsArr := calldataParamAsUint(2)
                let lenAmountsArr := calldataload(calldataValuesRawOffset(offsetAmountsArr))

                let _data := calldataParamAsUint(3) // not implemented

                require(isCalledByOwner())
                
                //Mint
                for {let i:=0 } lt(i, lenIdsArr) {i:=add(i,1)} {
                    let id := calldataload(calldataValuesRawOffset(safeAdd(offsetIdsArr, mul(safeAdd(i,1),0x20))))
                    let amount := calldataload(calldataValuesRawOffset(safeAdd(offsetAmountsArr,mul(safeAdd(i,1),0x20))))
                    _mint(to,id,amount,_data,false)                
                }
                emitTransferBatch(caller(), 0x0, to, offsetIdsArr, offsetAmountsArr)
            }
            case 0x6b20c454  /* burnBatch(address,uint256[],uint256[]) from/ids/amounts */ {      
                let from := calldataParamAsAddress(0)

                let offsetIdsArr := calldataParamAsUint(1)
                let lenIdsArr := calldataload(calldataValuesRawOffset(offsetIdsArr))

                let offsetAmountsArr := calldataParamAsUint(2)
                let lenAmountsArr := calldataload(calldataValuesRawOffset(offsetAmountsArr))

                let _data := calldataParamAsUint(3)

                require(isCalledByOwner())
                require(eq(lenAmountsArr, lenIdsArr))

                //Burn
                for {let i:=0 } lt(i, lenAmountsArr) {i:=add(i,1)} {
                    let id := calldataload(calldataValuesRawOffset(safeAdd(offsetIdsArr, mul(safeAdd(i,1),0x20))))
                    let amount := calldataload(calldataValuesRawOffset(safeAdd(offsetAmountsArr,mul(safeAdd(i,1),0x20))))
                    _burn(from, id, amount,false)
                }             
                emitTransferBatch(caller(), from, 0x0, offsetIdsArr, offsetAmountsArr)
            }
            case 0x0e89341C /* uri(uint256) */ {
                let tokenId := calldataParamAsUint(0) // ignored

                //get length of uri
                let strLen := sload(uriPos())

                //get storage position of uri first value
                mstore(0x0, uriPos())
                let firstValuePos := keccak256(0x0, 0x20)

                //calculate how many storage slots
                let numSlots := div(strLen, 32)
                if gt(mod(strLen, 32), 0) {
                    numSlots := add(numSlots, 1)
                }

                // memory: offset zero based, length
                let startOffset := getMPtr()
                mstore(getMPtr(), 0x20)
                incrMPtr()
                mstore(getMPtr(), strLen)
                incrMPtr()

                //copy uri from storage and save to memory
                for {let i:=0} lt(i, numSlots) {i:=add(i,1)} {
                    mstore(getMPtr(), sload(safeAdd(firstValuePos, i)))
                    incrMPtr()
                }
                returnData(startOffset, safeSub(getMPtr(),startOffset))
            }
            case 0x02fe5305 /* setURI(string) */ {
                //get length of uri
                let offsetUri := calldataParamAsUint(0)
                let lenUri := calldataload(calldataValuesRawOffset(offsetUri))
                //emitDebug_uint("lenUri", lenUri)

                //save length to storage
                sstore(uriPos(), lenUri)

                //get storage position of uri first value
                mstore(0x0, uriPos())
                let firstValuePosStorage := keccak256(0x0, 0x20)

                //calculate how many storage slots
                let numSlots := div(lenUri, 32)
                if gt(mod(lenUri, 32), 0) {
                    numSlots := add(numSlots, 1)
                }
                //emitDebug_uint("numSlots", numSlots)

                let firstValuePosCallData := safeAdd(calldataValuesRawOffset(offsetUri),0x20)

                //copy uri from calldata and save to storage
                for {let i:=0} lt(i, numSlots) {i:=add(i,1)} {
                    let stringChunck := calldataload(safeAdd(firstValuePosCallData, mul(i,0x20)))
                    sstore(add(firstValuePosStorage, i), stringChunck)
                }
            }
            default {
                revert(0, 0)
            }

            /* ***********************************************************************
                                        REPEATING FUNCTIONS
            ************************************************************************** */

            function _isApprovedForAll(account,operator) -> approved {
                let offset := nestedMappingPos(0,account, operator)
                approved :=sload(offset)
            }

            function _burn(from, id, amount, emitEvent){

                require(from) // Cannot burn from address(0)
        
                let fromBalance := sload(nestedMappingPos(1, from, id))

                require(gte(fromBalance, amount)) // Cannot burn more than balance (underflow)
                require(isCalledByOwner())

                sstore(nestedMappingPos(1, from, id), safeSub(fromBalance, amount))    
                
                if emitEvent {
                    emitTransferSingle(caller(), from, 0x0, id, amount) 
                }
            }

            function _mint(to,id,amount,_data, emitEvent){
                require(isCalledByOwner())
                require(to)
            
                let offset := nestedMappingPos(1, to, id)
                let oldBalance := sload(offset) 
                let newAmount := safeAdd(oldBalance, amount)

                sstore(offset, newAmount)

                if emitEvent {
                    emitTransferSingle(caller(), 0x0, to, id, newAmount) 
                }
            }

            function _safeTransferFrom(from, to, id, amount, _data, emitEvent) {
                 //_data offset, not used so far, because I did not implement the ERC1155Receiver interface nor the before/after hooks

                require(or(eq(from, caller()), _isApprovedForAll(from, caller()))) // todo: clear the approval after the transfer
                        
                // set balance for FROM
                let offsetFrom := nestedMappingPos(1, from, id)
                let balanceFrom := sload(offsetFrom)
                
                require(gte(balanceFrom, amount)) // Cannot transfer more than balance (underflow)
                let newAmountFrom := sub(balanceFrom, amount)
                sstore(offsetFrom, newAmountFrom)

                // set balance for TO
                let offsetTo := nestedMappingPos(1, to, id)
                let balanceTo := sload(offsetTo)
                
                let newAmountTo := safeAdd(balanceTo, amount)
                sstore(offsetTo, newAmountTo)             

                // do not emit a event if this function is called from safeBatchTransferFrom
                if emitEvent {
                    emitTransferSingle(caller(), from, to, id, amount) 
                }
            }

            /* ***********************************************************************
                                        HELPER FUNCTIONS
            ************************************************************************** */
                
            /* ----------   functionselector and parameters from calldata  ---------- */
             //keeping first 4 bytes of calldata with integer devision of 28 bytes hex number
            function functionSelector() -> s {   
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function calldataParamAsUint(pos) -> v {
                //calldataload gets a 32 byte word from the offset I enter, here from 5th bit on.
                let offset := calldataValuesPosOffset(pos)
                if lt(calldatasize(), safeAdd(offset, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(offset)
            }

            function calldataParamAsAddress(offset) -> v {
                let val := calldataParamAsUint(offset)
                //check if the address is valid (only if 20 bytes or lower)
                if iszero(iszero(and(val, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
                require(val)
                v := val
            }

            function calldataParamAsBool(offset) -> v {
                v := calldataParamAsUint(offset)
                //check if bool is 0 or 1, else reverts.
                if gt(v,1){
                    revert(0, 0)
                }
            }

            function calldataValuesRawOffset(offset) -> len {
                len := safeAdd(4, offset)
            }

            function calldataValuesPosOffset(position)-> len {
                len := calldataValuesRawOffset(mul(position, 0x20))
            }

            function copyArrayToMemory(offsetArr) {
                let offsetArrMod := add(offsetArr, 4) // skip function selector -> already done in calldataParamAsUint
                let lenArr := calldataload(offsetArrMod) // get array length
                let lenTotal := add(0x20, mul(lenArr, 0x20)) // len+arrData

                calldatacopy(getMPtr(), offsetArrMod, lenTotal) // copy len+data to memory
                setMPtr(safeAdd(getMPtr(), safeAdd(lenTotal,0x20))) // set new mptr, +0x20 for next empty slot
            }
                
            /* -------- storage layout, mapping and array position ---------- */
            function ownerPos() -> p { p := 0 }
            function uriPos() -> p { p := 1 }

            // 2 nested mappings are uint256->address and address->address
            // are saved as address->address and address->uint256
            // prepended by one byte id to avoid collisions
            function nestedMappingPos(id,key1, key2) -> p {
                mstore(0, key1)
                mstore8(0,id)
                mstore(0x20, key2)
                p := keccak256(0, 0x40)
            }

            /* -------- memory pointer management ---------- */
            function mPtrPos() -> p { p := 0x40 } // storage location of memory pointer
            function getMPtr() -> p { p := mload(mPtrPos()) }
            function setMPtr(v) { mstore(mPtrPos(), v) } // set memory pointer value to v
            function incrMPtr() { mstore(mPtrPos(), safeAdd(getMPtr(), 0x20)) } // increase memory pointer by one word

            /* ----------  return functions ---------- */
            function returnWord(v) {
                mstore(0, v)
                return(0, 0x20)
            }

            function returnData(from, to) {
                return(from, to)
            }

            /* ----------  other functions ---------- */
            // Mimic the Solidity require function for convenience
            // if true, continue, else revert.
            function require(condition) {
                if iszero(condition) {
                    revert(0, 0)
                }
            }

            function isCalledByOwner() -> v {
                v := eq(sload(ownerPos()), caller())
            }

            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }

            function gte(a, b) -> r {
                r := iszero(lt(a, b))
            }

            
            //safe math add
            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }

            //safe math sub
            function safeSub(a, b) -> r {
                r := sub(a, b)
                if gt(r, a) { revert(0, 0) }
            }

        }
    }
}