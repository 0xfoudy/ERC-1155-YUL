object "ERC1155" {
    code {
        // constructor
        datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
        return(0, datasize("Runtime"))
    }
    object "Runtime"{
        code {
            // Make sure no eth was sent (non payable functions)
            require(iszero(callvalue()))

            switch functionSelector()
            case 0x42842e0e {
                safeTransferFrom(getAddressParam(0), getAddressParam(1), getUintParam(2), getUintParam(3))
                returnTrue()
            }
            case 0x6b34485e {
                let thirdParam := getUintParam(2) //size of ids
                safeBatchTransferFrom(getAddressParam(0), getAddressParam(1), thirdParam, getUintParam(add(thirdParam, 3)))
                returnTrue()
            }
            case 0x00fdd58e {
                returnUint(balanceOf(getAddressParam(0), getUintParam(1)))
            }
            case 0x4e1273f4 {
                let firstParam := getUintParam(0)
                balanceOfBatch(firstParam, getUintParam(add(firstParam, 1)))
            }
            case 0xa22cb465 {
                setApprovalForAll(getAddressParam(0), getUintParam(1))
            }
            case 0x802e4e3d {
                if iszero(isApprovedForAll(getAddressParam(0), getAddressParam(1))) { returnFalse() }
                returnTrue()
            }
            case 0x156e29f6 {
                mint(getAddressParam(0), getUintParam(1), getUintParam(2))
                returnTrue()
            }
            case 0xd81d0a15 { // mintBatch(address, uint256[], uint256[])
                // 0x04 address, 0x24 offset of first array, 0x44 offset of second array
                // 0x64 or calldataload(0x24) length of first array , calldataload(0x44) length of second array
                let idOffset := add(4, getUintParam(1)) //size of ids
                let valuesOffset := add(4, getUintParam(2))
                mintBatch(getAddressParam(0), idOffset, valuesOffset)
                returnTrue()
            }
            case 0x4104c4f2 {
                burn(getAddressParam(0), getUintParam(1), getUintParam(2))
                returnTrue()
            }
            case 0xd52a7d0f {
                let secondParam := getUintParam(1)
                burnBatch(getAddressParam(0), secondParam, getUintParam(add(secondParam, 2)))
                returnTrue()
            }
            default {
                revert(0, 0)
            }
            function safeTransferFrom(from, to, id, value) {
                require(lte(value, balanceOf(from, id)))
                require(isApprovedForAll(from, caller()))
                deduceFromBalance(from, id, value)
                addToBalance(to, id, value)
            }
            function safeBatchTransferFrom(from, to, idsSize, valuesSize) {
                 require(eq(idsSize, valuesSize))

                 for { let i := 1 } lte(i, idsSize) { i := add(i, 1) }
                 {
                    let id := getUintParam(add(2,i))
                    let value := getUintParam(add(3, add(idsSize, i)))
                    require(lte(value, balanceOf(from, id)))
                    require(isApprovedForAll(from, caller()))
                    deduceFromBalance(from, id, value)
                    addToBalance(to, id, value)
                 }
            }
    
            function balanceOf(owner, id) -> bal {
                bal := sload(balanceAddressOffset(owner, id))
            }
            function balanceOfBatch(ownersSize, idsSize) {
                require(eq(ownersSize, idsSize))

                mstore(0x00, ownersSize) // stores the size of the array to return
                for { let i := 1 } lte(i, ownersSize) { i := add(i, 1) } // starting at i = 1 to skip the size word in each array
                {
                    let owner := getAddressParam(i)
                    let id := getUintParam(add(ownersSize, i))
                    mstore(mul(0x20, i), balanceOf(owner, id)) // stores the values adjacently
                }
                return(0x00, mul(0x20, ownersSize))
            }
            function setApprovalForAll(operator, approved) {
                require(lte(approved, 1))
                sstore(approvalsForAllOffset(caller(), operator), approved)
            }
            function isApprovedForAll(owner, operator) -> isApproved{
                isApproved := approvalsForAllOffset(owner, operator)
            }
            function mint(to, id, value) {
                addToBalance(to, id, value)

            }
            function mintBatch(to, idsOffset, valuesOffset) {
                let idsSize := calldataload(idsOffset)
                let valuesSize := calldataload(valuesOffset)
                require(eq(idsSize, valuesSize))
                for { let i := 1 } lte(i, idsSize) { i := add(i, 1) }
                {
                    let paramOffset := mul(0x20, i)
                    let id := calldataload(add(idsOffset, paramOffset))
                    let value := calldataload(add(valuesOffset, paramOffset))
                    let offset := balanceAddressOffset(to, id)
                    mint(to, id, value)
                }
                return(0x40, 0x20) // question, why do i have to return something with offset >= 40 for it to work??
            }
            function burn(from, id, value) {
                deduceFromBalance(from, id, value)
            }
            function burnBatch(from, idsSize, valuesSize) {
                require(eq(idsSize, valuesSize))

                for { let i := 1 } lte(i, idsSize) { i := add(i, 1) }
                {   
                    let id := getUintParam(add(1, i))
                    let value := getUintParam(add(add(idsSize, 1), i))
                    deduceFromBalance(from, id, value)
                }
            }

            /* ------- helpers ------- */

            function functionSelector() -> selector {
                // get function selector (need to shift right by 28 bytes => divide by 2^(8*28) or by 0x1 followed by 56 zeros)
                selector:= div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }
            // to load addresses easily from function arguments (offset is arg number starting at 0)
            function getAddressParam(offset) -> v {
                v := getUintParam(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))){
                    revert(0, 0)
                }
            }
            function getUintParam(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }
            function returnUint(v) {
                mstore(0x00 , v)
                return(0x00, 0x20)
            }
            function returnTrue() {
                returnUint(1)
            }
            function returnFalse() {
                returnUint(0)
            }
            function lte(a, b) -> r {
                r:= iszero(gt(a, b))
            }
            function gte(a, b) -> r {
                r:= iszero(lt(a, b))
            }
            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r,a) , lt(r, b)) { revert(0, 0) }
            }
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }

            /* ------- storage ------- */
            
            /* 
                slot 0: balance: map<uint, map<address, uint>>
                slot 1: approvals: map<address, map<address, bool>>

                map: keccak256(abi.encode(key, uint(slot))
                balance: keccak256(abi.encode(id, keccak256(abi.encode(owner, 0))))
                approvals: keccak256(abi.encode(owner, keccak256(abi.encode(operator, 1))))
            */
            function balanceAddressOffset(account, id) -> mapOffset {
                // abi.encode => mstore next to each other
                // keccak256 takes beginning and end of memory to hash
                mstore(0x00, account)
                mstore(0x20, 0)
                let nestedMapOffset := keccak256(0x00, 0x40)

                mstore(0x00, id)
                mstore(0x20, nestedMapOffset)
                mapOffset := keccak256(0x00, 0x40)
            }
            function approvalsForAllOffset(owner, operator) -> mapOffset {
                mstore(0x00, operator)
                mstore(0x20, 1)
                let nestedMapOffset := keccak256(0x00, 0x40)

                mstore(0x00, owner)
                mstore(0x20, nestedMapOffset)
                mapOffset := keccak256(0x00, 0x40)
            }
            function addToBalance(account, id, value) {
                let offset := balanceAddressOffset(account, id)
                sstore(offset, safeAdd(sload(offset), value))
            }
            function deduceFromBalance(account, id, amount) {
                let offset := balanceAddressOffset(account, id)
                let bal := sload(offset)
                require(lte(amount, bal))
                sstore(offset, sub(bal, amount))
            }
        }
    }
}