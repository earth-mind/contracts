// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MockProvider {
    mapping(bytes4 functionSignature => bytes returnData) public mockConfigurations;
    mapping(bytes4 functionSignature => bool exists) public mockConfigurationExists;
    bytes4 public lastFunctionSignature; // @dev We store the last specified function signature to have a chaining pattern with thenReturns()

    function when(bytes4 _functionSig) external returns (MockProvider) {
        lastFunctionSignature = _functionSig;
        return this; // @dev We return the current contract instance to have a chaining pattern with thenReturns()
    }

    function thenReturns(bytes memory _data) external {
        if (lastFunctionSignature == bytes4(0)) {
            revert("MockProvider: No function signature specified");
        }

        mockConfigurations[lastFunctionSignature] = _data;
        mockConfigurationExists[lastFunctionSignature] = true;

        lastFunctionSignature = bytes4(0); // Reset the current function signature
    }

    fallback(bytes calldata) external payable returns (bytes memory) {
        bytes4 selectorKey = msg.sig;

        if (!mockConfigurationExists[selectorKey]) {
            revert("MockProvider: No configuration found for the given function signature");
        }

        return mockConfigurations[selectorKey];
    }

    receive() external payable {
        revert("MockProvider: receive() not allowed");
    }
}
