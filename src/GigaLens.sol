// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/// @notice Turn any contract into a "view" like contract meant to be used offChain to perform a sequence of operations and get a return value

contract GigaLens {
    struct Operation {
        uint96 theValue;
        address theTarget;
        bytes theCalldata;
    }

    struct TheCheck {
        address theTarget;
        bytes theCalldata;
    }

    function multicall(Operation[] memory operations, TheCheck memory check, bool throwAtEnd)
        external
        payable
        returns (bytes memory)
    {
        uint256 length = operations.length;
        for (uint256 i; i < length;) {
            _doACall(operations[i]);
            unchecked {
                ++i;
            }
        }

        // is this bytes or bytes32? // In the case of a balance it's a bytes32
        // For some reason this get's capped
        (, bytes memory res) = check.theTarget.staticcall(check.theCalldata);
        emit DebugBytes("after call", res);
        uint256 asNumber = abi.decode(res, (uint256));

        uint256 _toCopy;

        address theTarget  = check.theTarget;
        bytes memory theCalldata = check.theCalldata;
        bytes memory _returnData;
        
        // NOTE: We revert here
        
        assembly {
            let success := staticcall(
                gas(), // gas
                theTarget, // recipient
                add(theCalldata, 0x20), // inloc
                mload(theCalldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }

        if(throwAtEnd){
            assembly {
                revert(add(_returnData, 0x20), _toCopy) // Pass Bytes with 1 word offset, must be because solidity allocates the bytes even if it's not showing it
            }
        }

        return _returnData;
    }

    function _doACall(Operation memory op) internal {
        op.theTarget.call{value: op.theValue}(op.theCalldata);
    }

    event DebugBytes(string, bytes);
    event Debug(string, uint256);

    function quoteMulticall(Operation[] memory operations, TheCheck memory check, bool isComplex)
        external
        payable
        returns (bytes memory)
    {
        try this.multicall(operations, check, true) returns (bytes memory) {}
        catch (bytes memory reason) {
            emit DebugBytes("caught", reason);
            uint256 asNumber = abi.decode(reason, (uint256));
            emit Debug("asNumber", asNumber);
            if(isComplex) {
                assembly {
                    return(add(reason, 0x20), reason) // Only if return value is a bytes array else this is not good
                }
            }
            return reason;
        }
    }
}
