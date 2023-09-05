// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {GigaLens} from "../src/GigaLens.sol";

contract TestReturnSingleWord {
    function doIt() external pure returns (uint256) {
        return 123456789;
    }
}

contract TestReturnBytes {
    function doIt() external pure returns (bytes memory) {
        uint256[] memory entries = new uint256[](2);
        entries[0] = 123456789;
        entries[1] = 123456789;
        return abi.encode(entries);
    }
}

contract GigaLensTest is Test {
    GigaLens lens;
    TestReturnSingleWord single;
    TestReturnBytes complex;

    function setUp() public {
        lens = new GigaLens();
        single = new TestReturnSingleWord();
        complex = new TestReturnBytes();

    }

    event DebugBytesTest(bytes);

    function testCanGetBalance() public {
        bytes memory data = abi.encodeWithSignature("doIt()");
        GigaLens.TheCheck memory uintBalanceCheck =
            GigaLens.TheCheck({theTarget: address(single), theCalldata: data});

        GigaLens.Operation[] memory operations = new GigaLens.Operation[](0);

        // == BASE ==//

        bytes memory resVal = lens.quoteMulticall(operations, uintBalanceCheck);
        emit DebugBytesTest(resVal);
        uint256 asNumber = abi.decode(resVal, (uint256));
        console2.log("asNumber", asNumber);

        uint256 secondNumber = abi.decode(lens.multicall(operations, uintBalanceCheck, false), (uint256));
        console2.log("secondNumber", secondNumber);

        // == COMPLEX == //
        GigaLens.TheCheck memory bytesBalanceCheck =
            GigaLens.TheCheck({theTarget: address(complex), theCalldata: data});

        bytes memory fromDirect = complex.doIt();
        emit DebugBytesTest(fromDirect);
        console2.log("about to decode");
        (uint256[] memory asNumber3) = abi.decode(fromDirect, (uint256[]));
        console2.log("asNumber3", asNumber3[0]);


        bytes memory resVal2 = lens.quoteMulticall(operations, bytesBalanceCheck);
        emit DebugBytesTest(resVal2);
        (uint256[] memory asNumber2) = abi.decode(resVal2, (uint256[]));
        console2.log("asNumber2", asNumber2[0]);
        console2.log("asNumber21", asNumber2[1]);
    }
}
