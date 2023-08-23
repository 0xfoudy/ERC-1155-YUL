// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";

interface ERC1155 {}

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();

    ERC1155 exampleContract;

    function setUp() public {
        exampleContract = ERC1155(yulDeployer.deployContract("ERC1155"));
    }

    // Testing functions

    // function mint(address to, uint256 id, uint256 value, bytes memory data)
    function testMint() public {
        mint(address(1), 1, 'abc', 0x00);
        assertEq(balanceOf(address(1), 1), 1);
    }

    // function batchMint(address to, uint256[] memory ids, uint256[] memory values, bytes memory data)
    function testBatchMint() public {
        batchMint(address(1), [1,1,2], ['abc','def','ghi'], 0x00);
        assertEq(balanceOf(address(1),1), 2);
        assertEq(balanceOf(address(1),2), 1);
    }

    // function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function testSafeTransferFrom() public {
        batchMint(address(1), [1,1,1,1,2], ['abc','def','ghi','klm','cba'], 0x00);
        assertEq(balanceOf(address(1), 1), 4);
        assertEq(balanceOf(address(1), 2), 1);
        
        // single transfer
        vm.prank(address(1)); 
        safeTransferFrom(address(1), address(2), 1, 1, 0x00);
        assertEq(balanceOf(address(1), 1), 3);
        assertEq(balanceOf(address(2), 1), 1);
        
        // multiple transfer, same id
        vm.prank(address(1));
        safeTransferFrom(address(1), address(2), 1, 2, 0x00);
        assertEq(balanceOf(address(1), 1), 1);
        assertEq(balanceOf(address(2), 1), 3);

        // no allowance transfer from
        vm.expectRevert();
        vm.prank(address(1));
        safeTransferFrom(address(2), address(1), 1, 3, 0x00);

        // not enough tokens to transfer
        vm.expectRevert();
        vm.prank(address(1));
        safeTransferFrom(address(1), address(2), 1, 6, 0x00);

        // with allowance transfer from
        vm.prank(address(2));
        setApprovalForAll(address(1), true);
        vm.prank(address(1));
        safeTransferFrom(address(2), address(1), 1, 3, 0x00);
        assertEq(balanceOf(address(1), 1), 4);
        assertEq(balanceOf(address(2), 1), 0);    
    }

    // function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function testSafeBatchTransferFrom() public {
        batchMint(address(1), [1,1,1,1,2], ['abc','def','ghi','klm','cba'], 0x00);
        assertEq(balanceOf(address(1), 1), 4);
        assertEq(balanceOf(address(1), 2), 1);
        
        // single transfer
        vm.prank(address(1)); 
        safeBatchTransferFrom(address(1), address(2), [1,2], [2,1], 0x00);
        assertEq(balanceOf(address(1), 1), 2);
        assertEq(balanceOf(address(2), 1), 2);
        assertEq(balanceOf(address(1), 2), 0);
        assertEq(balanceOf(address(2), 2), 1);

        // no allowance transfer from
        vm.expectRevert();
        vm.prank(address(1));
        safeBatchTransferFrom(address(2), address(1), [1,2], [1,1], 0x00);

        // not enough tokens to transfer from
        vm.expectRevert();
        vm.prank(address(1));
        safeBatchTransferFrom(address(1), address(2), [1,2], [3,2], 0x00);

        vm.prank(address(2));
        setApprovalForAll(address(1), true);
        assertEq(isApprovedForAll(address(2),address(1), true));

        vm.prank(address(1));
        safeBatchTransferFrom(address(2), address(1), [1,2], [2,1], 0x00);
        assertEq(balanceOf(address(1), 1), 4);
        assertEq(balanceOf(address(2), 1), 0);
        assertEq(balanceOf(address(1), 2), 1);
        assertEq(balanceOf(address(2), 2), 0);        
    }


    // function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function testBalanceOf() public {
        batchMint(address(1), [1,1,1,1,2], ['abc','def','ghi','klm','cba'], 0x00);
        assertEq(balanceOf(address(1), 1), 4);
        assertEq(balanceOf(address(1), 1), 1);
        assertEq(balanceOf(address(1), 3), 0);
    }

    // function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function testBalanceOfBatch() public {
        batchMint(address(1), [1,1,1,1,2], ['abc','def','ghi','klm','cba'], 0x00);
        batchMint(address(2), [1,1,1,1,2], ['def','ghi','klm','nop','abc'], 0x00);
        assertEq(balanceOfBatch([address(1), address(2)], [1,1]), [4,4]);
        assertEq(balanceOfBatch([address(1), address(1)], [2,1]), [1,4]);
        assertEq(balanceOfBatch([address(1), address(2)], [2,2]), [1,1]);
    }

    // function setApprovalForAll(address _operator, bool _approved) external;
    // function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    

    // function burn(address from, uint256 id, uint256 value)
    function testBurn() public {
        batchMint(address(1), [1,1,1,1,2], ['abc','def','ghi','klm','cba'], 0x00);
        vm.prank(address(1));
        burn(address(1), 1, 2);
        assertEq(balanceOfBatch([address(1), address(1)], [1, 2]), [2, 1]);

        // invalid allowance
        vm.expectRevert();
        burn(address(1), 1, 1);

        // not enough tokens to burn
        vm.expectRevert();
        vm.prank(address(1));
        burn(address(1), 1, 6);
    }

    // function batchburn(address[] memory from, uint256[] memory id, uint256[] memory value)
    function testBatchBurn() public {
        batchMint(address(1), [1,1,1,1,2], ['abc','def','ghi','klm','cba'], 0x00);
        vm.prank(address(1));
        batchBurn(address(1), [1,2], [2,1]);
        assertEq(balanceOfBatch([address(1), address(1)], [2,0]), [2,0]);

        // not enough tokens
        vm.expectRevert();
        vm.prank(address(1));
        batchBurn(address(1), [1, 2], [1, 3]);
    }

    // Testing events emission

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    function testTransferSingleEvent() public {
        batchMint(address(1), [1,1,1,1,2], ['abc','def','ghi','klm','cba'], 0x00);

        // single transfer
        vm.prank(address(1)); 
        
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(1), address(1), address(2), 1, 1);

        safeTransferFrom(address(1), address(2), 1, 1, 0x00);
    }

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    function testTransferBatchEvent() public {
        batchMint(address(1), [1,2,3,4,5], [5,4,3,2,1], 0x00);
        
        vm.prank(address(1));
        
        for(uint i=1; i < 6; ++i){
            vm.expectEmit(true, true, true, true);
            emit TransferSingle(address(1), address(1), address(2), i, 6-i);
        }

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(address(1), address(1), address(2), [1,2,3,4,5], [5,4,3,2,1]);

        SafeBatchTransferFrom(address(1), address(2), [1,2,3,4,5], [5,4,3,2,1]);
    }

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function testApprovalForAll() public {
        mint(address(1), 1, 'abc', 0x00);
        vm.prank(address(1));

        vm.expectEmit(true, true, true);
        emit ApprovalForAll(addres(1), address(2), true);

        setApprovalForAll(address(2), true);
    }

    // event URI(**string** _value, **uint256** **indexed** _id);`

    /*
    function testExample() public {
        bytes memory callDataBytes = abi.encodeWithSignature("randomBytes()");

        (bool success, bytes memory data) = address(exampleContract).call{gas: 100000, value: 0}(callDataBytes);

        assertTrue(success);
        assertEq(data, callDataBytes);
    }
    */
}

