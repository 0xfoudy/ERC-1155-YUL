// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";

interface ERC1155 {
    function mint(address to, uint256 id, uint256 value) external;
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata values) external;
    function burn(address from, uint256 id, uint256 value) external;
    function burnBatch(address from, uint256[] memory id, uint256[] memory value) external;
    function balanceOf(address _owner, uint256 _id) external returns(uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address owner, address _operator) external returns (bool);
}

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();

    ERC1155 erc1155Contract;

    function setUp() public {
        erc1155Contract = ERC1155(yulDeployer.deployContract("ERC1155"));
    }

    // Testing functions

    // function mint(address to, uint256 id, uint256 value)
    function testMint() public {
        erc1155Contract.mint(address(123), 1, 2);
        assertEq(erc1155Contract.balanceOf(address(123), 1), 2);
    }

    // function mintBatch(address to, uint256[] memory ids, uint256[] memory values)
    function testBatchMint() public {
        uint256[] memory ids = new uint256[](3);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 1;

        uint256[] memory values = new uint256[](3);
        values[0] = 2;
        values[1] = 2;
        values[2] = 3;

        erc1155Contract.mintBatch(address(123), ids, values);
        assertEq(erc1155Contract.balanceOf(address(123),1), 5);
        assertEq(erc1155Contract.balanceOf(address(123),2), 2);
    }

    // function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function testSafeTransferFrom() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 4;
        values[1] = 1;

        erc1155Contract.mintBatch(address(123), ids, values);
        assertEq(erc1155Contract.balanceOf(address(123), 1), 4);
        assertEq(erc1155Contract.balanceOf(address(123), 2), 1);
        
        // single transfer
        vm.prank(address(123)); 
        erc1155Contract.safeTransferFrom(address(123), address(321), 1, 1);
        assertEq(erc1155Contract.balanceOf(address(123), 1), 3);
        assertEq(erc1155Contract.balanceOf(address(321), 1), 1);
    }

    function testSafeTransferFromApproval() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1;
        ids[1] = 1;
        ids[2] = 1;
        ids[3] = 1;
        ids[4] = 2;

        uint256[] memory values = new uint256[](5);
        values[0] = 1;
        values[1] = 1;
        values[2] = 1;
        values[3] = 1;
        values[4] = 1;

        erc1155Contract.mintBatch(address(1), ids, values);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 4);
        assertEq(erc1155Contract.balanceOf(address(1), 2), 1);
        
        // single transfer
        vm.prank(address(1)); 
        erc1155Contract.safeTransferFrom(address(1), address(2), 1, 1);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 3);
        assertEq(erc1155Contract.balanceOf(address(2), 1), 1);
        // multiple transfer, same id
        vm.prank(address(1));
        erc1155Contract.safeTransferFrom(address(1), address(2), 1, 2);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 1);
        assertEq(erc1155Contract.balanceOf(address(2), 1), 3);

        // no allowance transfer from
        vm.expectRevert();
        vm.prank(address(1));
        erc1155Contract.safeTransferFrom(address(2), address(1), 1, 3);
        
        // not enough tokens to transfer
        vm.expectRevert();
        vm.prank(address(1));
        erc1155Contract.safeTransferFrom(address(1), address(2), 1, 6);

        // with allowance transfer from
        vm.prank(address(2));
        erc1155Contract.setApprovalForAll(address(1), true);
        vm.prank(address(1));
        erc1155Contract.safeTransferFrom(address(2), address(1), 1, 3);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 4);
        assertEq(erc1155Contract.balanceOf(address(2), 1), 0);    
    }


    // function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function testSafeBatchTransferFrom() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 4;
        values[1] = 1;
        erc1155Contract.mintBatch(address(1), ids, values);
        
        assertEq(erc1155Contract.balanceOf(address(1), 1), 4);
        assertEq(erc1155Contract.balanceOf(address(1), 2), 1);
        
        uint256[] memory valuesToTransfer = new uint256[](2);
        valuesToTransfer[0] = 2;
        valuesToTransfer[1] = 1;

        // single transfer
        vm.prank(address(1)); 
        erc1155Contract.safeBatchTransferFrom(address(1), address(2), ids, valuesToTransfer);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 2);
        assertEq(erc1155Contract.balanceOf(address(2), 1), 2);
        assertEq(erc1155Contract.balanceOf(address(1), 2), 0);
        assertEq(erc1155Contract.balanceOf(address(2), 2), 1);

        // no allowance transfer from
        vm.expectRevert();
        vm.prank(address(1));
        erc1155Contract.safeBatchTransferFrom(address(2), address(1), ids, valuesToTransfer);

        // not enough tokens to transfer from
        uint256[] memory invalidValuesToTransfer = new uint256[](2);
        invalidValuesToTransfer[0] = 5;
        invalidValuesToTransfer[1] = 2;

        vm.expectRevert();
        vm.prank(address(1));
        erc1155Contract.safeBatchTransferFrom(address(1), address(2), ids, invalidValuesToTransfer);

        vm.prank(address(2));
        erc1155Contract.setApprovalForAll(address(1), true);
        assertEq(erc1155Contract.isApprovedForAll(address(2),address(1)), true);

        vm.prank(address(1));
        erc1155Contract.safeBatchTransferFrom(address(2), address(1), ids, valuesToTransfer);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 4);
        assertEq(erc1155Contract.balanceOf(address(2), 1), 0);
        assertEq(erc1155Contract.balanceOf(address(1), 2), 1);
        assertEq(erc1155Contract.balanceOf(address(2), 2), 0);        
    }


    // function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function testBalanceOf() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 4;
        values[1] = 1;
        erc1155Contract.mintBatch(address(1), ids, values);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 4);
        assertEq(erc1155Contract.balanceOf(address(1), 2), 1);
        assertEq(erc1155Contract.balanceOf(address(1), 3), 0);
    }

    // function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function testBalanceOfBatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        
        uint256[] memory values = new uint256[](2);
        values[0] = 1;
        values[1] = 4;
        
        erc1155Contract.mintBatch(address(1), ids, values);
        erc1155Contract.mintBatch(address(2), ids, values);
        
        uint256[] memory balance1_2_id_1_1 = new uint256[](2);
        balance1_2_id_1_1[0] = 1;
        balance1_2_id_1_1[1] = 1;
        
        uint256[] memory balance1_1_id_2_1 = new uint256[](2);
        balance1_1_id_2_1[0] = 4;
        balance1_1_id_2_1[1] = 1;
        
        uint256[] memory balance1_2_id_2_2 = new uint256[](2);
        balance1_2_id_2_2[0] = 4;
        balance1_2_id_2_2[1] = 4;

        address[] memory addresses1_2 = new address[](2);
        addresses1_2[0] = address(1);
        addresses1_2[1] = address(2);
        
        address[] memory addresses1_1 = new address[](2);
        addresses1_1[0] = address(1);
        addresses1_1[1] = address(1);

        uint256[] memory ids1_1 = new uint256[](2);
        ids1_1[0] = 1;
        ids1_1[1] = 1;
        
        uint256[] memory ids2_1 = new uint256[](2);
        ids2_1[0] = 2;
        ids2_1[1] = 1;
        
        uint256[] memory ids2_2 = new uint256[](2);
        ids2_2[0] = 2;
        ids2_2[1] = 2;
        
        /*                       balanceOfBatch([address(1),address(2)], [1,1]) = [1,1] */
        assertEq(erc1155Contract.balanceOfBatch(addresses1_2, ids1_1), balance1_2_id_1_1);
        /*                       balanceOfBatch([address(1),address(1)], [2,1]) = [4,1] */
        assertEq(erc1155Contract.balanceOfBatch(addresses1_1, ids2_1), balance1_1_id_2_1);
        /*                       balanceOfBatch([address(1),address(2)], [2,2]) = [4,4] */
        assertEq(erc1155Contract.balanceOfBatch(addresses1_2, ids2_2), balance1_2_id_2_2);
    }


    // function burn(address from, uint256 id, uint256 value)
    function testBurn() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        
        uint256[] memory values = new uint256[](2);
        values[0] = 4;
        values[1] = 1;

        erc1155Contract.mintBatch(address(1), ids, values);
        vm.prank(address(1));
        erc1155Contract.burn(address(1), 1, 2);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 2);
        assertEq(erc1155Contract.balanceOf(address(1), 2), 1);

        // invalid allowance
        vm.expectRevert();
        erc1155Contract.burn(address(1), 1, 1);

        // not enough tokens to burn
        vm.expectRevert();
        vm.prank(address(1));
        erc1155Contract.burn(address(1), 1, 6);
    }

    // function batchburn(address[] memory from, uint256[] memory id, uint256[] memory value)
    function testBatchBurn() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        
        uint256[] memory values = new uint256[](2);
        values[0] = 4;
        values[1] = 1;

        
        erc1155Contract.mintBatch(address(1), ids, values);
        erc1155Contract.mintBatch(address(2), ids, values);
        
        uint256[] memory valuesToBurn = new uint256[](2);
        valuesToBurn[0] = 2;
        valuesToBurn[1] = 1;
        
        vm.prank(address(1));
        erc1155Contract.burnBatch(address(1), ids, valuesToBurn);
        assertEq(erc1155Contract.balanceOf(address(1), 1), 2);
        assertEq(erc1155Contract.balanceOf(address(1), 2), 0);

        uint256[] memory invalidValuesToBurn = new uint256[](2);
        invalidValuesToBurn[0] = 1;
        invalidValuesToBurn[1] = 3;
        // not enough tokens
        vm.expectRevert();
        vm.prank(address(1));
        erc1155Contract.burnBatch(address(1), ids, invalidValuesToBurn);
    }
/*
    // Testing events emission

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    function testTransferSingleEvent() public {
        erc1155Contract.batchMint(address(1), [1,1,1,1,2], ['abc','def','ghi','klm','cba']);

        // single transfer
        vm.prank(address(1)); 
        
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(1), address(1), address(2), 1, 1);

        erc1155Contract.safeTransferFrom(address(1), address(2), 1, 1);
    }

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    function testTransferBatchEvent() public {
        erc1155Contract.batchMint(address(1), [1,2,3,4,5], [5,4,3,2,1]);
        
        vm.prank(address(1));
        
        for(uint i=1; i < 6; ++i){
            vm.expectEmit(true, true, true, true);
            emit TransferSingle(address(1), address(1), address(2), i, 6-i);
        }

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(address(1), address(1), address(2), [1,2,3,4,5], [5,4,3,2,1]);

        erc1155Contract.safeBatchTransferFrom(address(1), address(2), [1,2,3,4,5], [5,4,3,2,1]);
    }

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function testApprovalForAll() public {
        erc1155Contract.mint(address(1), 1, 'abc');
        vm.prank(address(1));

        vm.expectEmit(true, true, true);
        emit ApprovalForAll(address(1), address(2), true);

        erc1155Contract.setApprovalForAll(address(2), true);
    }

    // event URI(**string** _value, **uint256** **indexed** _id);`

    /*
    function testExample() public {
        bytes memory callDataBytes = abi.encodeWithSignature("randomBytes()");

        (bool success) = address(exampleContract).call{gas: 100000, value: 0}(callDataBytes);

        assertTrue(success);
        assertEq(data, callDataBytes);
    }
    */
    
}

