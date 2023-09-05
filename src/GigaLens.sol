// SPDX-License-Identifier: MIT
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

        (, bytes memory _returnData) = check.theTarget.staticcall(check.theCalldata);

        if (throwAtEnd) {
            assembly {
                revert(add(_returnData, 0x20), _returnData) // Pass Bytes with 1 word offset, must be because solidity allocates the bytes even if it's not showing it
            }
        }

        return _returnData;
    }

    function _doACall(Operation memory op) internal {
        op.theTarget.call{value: op.theValue}(op.theCalldata);
    }

    function quoteMulticall(Operation[] memory operations, TheCheck memory check, bool isComplex)
        external
        payable
        returns (bytes memory)
    {
        try this.multicall(operations, check, true) returns (bytes memory) {}
        catch (bytes memory reason) {
            uint256 asNumber = abi.decode(reason, (uint256));
            if (isComplex) {
                assembly {
                    return(add(reason, 0x20), reason) // Only if return value is a bytes array else this is not good
                }
            }
            return reason;
        }
    }
}
