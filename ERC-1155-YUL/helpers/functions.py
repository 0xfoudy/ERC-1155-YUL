from web3 import Web3

def generate_function_selector(function_signature):
    """
    Generate the function selector for a given Ethereum function signature.
    """
    keccak_hash = Web3.keccak(text=function_signature)
    function_selector = keccak_hash.hex()[0:10]  # Take only the first 4 bytes (8 hex characters + '0x')
    return function_selector

if __name__ == "__main__":
    # List of function signatures you want to generate selectors for
    function_signatures = [
        "mint(address,uint256,uint256)",
        "mintBatch(address,uint256[],uint256[])",
        "safeTransferFrom(address,address,uint256,uint256)",
        "burn(address,uint256,uint256)",
        "burnBatch(address,uint256[],uint256[])",
        "safeBatchTransferFrom(address,address,uint256[],uint256[])",
        "isApprovedForAll(address,address)"
    ]
    
    for signature in function_signatures:
        selector = generate_function_selector(signature)
        print(f"Function: {signature} \t Selector: {selector}")