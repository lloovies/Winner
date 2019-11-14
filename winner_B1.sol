pragma solidity ^0.4.25;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Utils {
    function bytes32ToString(bytes32 x) internal pure returns (string) {
        uint charCount = 0;
        bytes memory bytesString = new bytes(32);
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            } else if (charCount != 0) {
                break;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];

        }
        return string(bytesStringTrimmed);
    }

    function _stringToBytes(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _stringEq(string a, string b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return _stringToBytes(a) == _stringToBytes(b);
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;

    }
}

contract SeroInterface {
    bytes32 private topic_sero_issueToken = 0x3be6bf24d822bcd6f6348f6f5a5c2d3108f04991ee63e80cde49a8c4746a0ef3;
    bytes32 private topic_sero_balanceOf = 0xcf19eb4256453a4e30b6a06d651f1970c223fb6bd1826a28ed861f0e602db9b8;
    bytes32 private topic_sero_send = 0x868bd6629e7c2e3d2ccf7b9968fad79b448e7a2bfb3ee20ed1acbc695c3c8b23;
    bytes32 private topic_sero_currency = 0x7c98e64bd943448b4e24ef8c2cdec7b8b1275970cfe10daf2a9bfa4b04dce905;

    function sero_msg_currency() internal returns (string) {
        bytes memory tmp = new bytes(32);
        bytes32 b32;
        assembly {
            log1(tmp, 0x20, sload(topic_sero_currency_slot))
            b32 := mload(tmp)
        }
        return Utils.bytes32ToString(b32);
    }

    function sero_issueToken(uint256 _total, string memory _currency) internal returns (bool success){
        bytes memory temp = new bytes(64);
        assembly {
            mstore(temp, _currency)
            mstore(add(temp, 0x20), _total)
            log1(temp, 0x40, sload(topic_sero_issueToken_slot))
            success := mload(add(temp, 0x20))
        }
        return;
    }

    function sero_balanceOf(string memory _currency) internal view returns (uint256 amount){
        bytes memory temp = new bytes(32);
        assembly {
            mstore(temp, _currency)
            log1(temp, 0x20, sload(topic_sero_balanceOf_slot))
            amount := mload(temp)
        }
        return;
    }

    function sero_send_token(address _receiver, string memory _currency, uint256 _amount) internal returns (bool success){
        return sero_send(_receiver, _currency, _amount, "", 0);
    }

    function sero_send(address _receiver, string memory _currency, uint256 _amount, string memory _category, bytes32 _ticket) internal returns (bool success){
        bytes memory temp = new bytes(160);
        assembly {
            mstore(temp, _receiver)
            mstore(add(temp, 0x20), _currency)
            mstore(add(temp, 0x40), _amount)
            mstore(add(temp, 0x60), _category)
            mstore(add(temp, 0x80), _ticket)
            log1(temp, 0xa0, sload(topic_sero_send_slot))
            success := mload(add(temp, 0x80))
        }
        return;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract WINNER_B is SeroInterface, Ownable {
    using SafeMath for uint256;
    using Utils for Utils;

    string private constant SERO_CURRENCY = "SERO";
    string private constant TOKEN_CURRENCY = "LUCKY";

    bool private canPlay = true;
    bool private canPlayByLucky = true;

    address private luckyAddr;
    address public luckyStarAddr;

    mapping(uint256 => Player) private betsMap;
    mapping(uint8 => Winner3) private bigWinnerMap;
    mapping(address => LuckyStar) private addrTimesMap;

    address[] private addrList;

    uint256 private index;
    uint256 public luckyStarPool;
    uint256 public winnerPool;

    struct LuckyStar {
        uint256 times;
        uint256 luckyCode;
    }

    struct Player {
        uint256 investTimestamp;
        uint256 investCode_1;
        uint256 investCode_2;
        uint256 investCode_3;
        address investAddress;
        uint256 curBlockNumber;
    }

    struct Winner3 {
        uint256 investTimestamp;
        uint256 investCode_1;
        uint256 investCode_2;
        uint256 investCode_3;
        address investAddress;
        uint256 dummy;
    }

    constructor(address _luckyAddr) public payable {
        luckyAddr = _luckyAddr;
    }

    function() public payable { }

    function getCurrentIndex() public view returns (uint256) {
        return index;
    }

    function symbol() public pure returns (string memory) {
        return TOKEN_CURRENCY;
    }

    function balanceOfSero() public view returns (uint256) {
        return sero_balanceOf(SERO_CURRENCY);
    }

    function setLuckyAddr(address _addr) public onlyOwner {
        luckyAddr = _addr;
    }

    function transferSero(address _to, uint256 _value) public onlyOwner {
        require(sero_balanceOf(SERO_CURRENCY) >= _value);
        require(sero_send_token(_to,SERO_CURRENCY,_value));
    }

    function transferToken(address _to, uint256 _value) public onlyOwner {
        require(sero_balanceOf(TOKEN_CURRENCY) >= _value);
        require(sero_send(_to, TOKEN_CURRENCY, _value, "", 0));
    }

    function enableCanPlay() public onlyOwner {
        require(!canPlay);
        canPlay = true;
    }

    function disableCanPlay() public onlyOwner {
        require(canPlay);
        canPlay = false;
    }

    function enableCanPlayByLucky() public onlyOwner {
        require(!canPlayByLucky);
        canPlayByLucky = true;
    }

    function disableCanPlayByLucky() public onlyOwner {
        require(canPlayByLucky);
        canPlayByLucky = false;
    }

    function getThird() public view returns(uint256, uint256, uint256) {
        return (bigWinnerMap[2].investCode_1, bigWinnerMap[2].investCode_2, bigWinnerMap[2].investCode_3);
    }

    function getBetsMap(uint256 i) public onlyOwner view returns(uint256, uint256, uint256, uint256, address, uint256) {
        return (betsMap[i].investTimestamp, betsMap[i].investCode_1, betsMap[i].investCode_2, betsMap[i].investCode_3,  betsMap[i].investAddress, betsMap[i].curBlockNumber);
    }

    function sendBigPrize() public onlyOwner {
        require(canPlay);
        canPlay = false;

        require(sero_send_token(bigWinnerMap[0].investAddress, SERO_CURRENCY, winnerPool));
        require(sero_send_token(bigWinnerMap[0].investAddress, TOKEN_CURRENCY, 1e21));
        if (luckyStarAddr != 0) {
            require(!canPlayByLucky);
            require(sero_send_token(luckyStarAddr, SERO_CURRENCY, luckyStarPool));
            luckyStarPool = 0;
            luckyStarAddr = 0;
            canPlayByLucky = true;
        }

        delete bigWinnerMap[0];
        delete bigWinnerMap[1];
        delete bigWinnerMap[2];

        for (uint256 i = 0; i < addrList.length; i++) {
            delete addrTimesMap[addrList[i]];
        }
        delete addrList;
        winnerPool = 0;
        canPlay = true;
    }

    function insertBets(uint256 loopTimes, address _addr) private {
        for (uint256 i = 0; i < loopTimes; i++) {
            betsMap[index].investTimestamp = now;
            (betsMap[index].investCode_1, betsMap[index].investCode_2, betsMap[index].investCode_3) = getRandomResult(i);
            betsMap[index].investAddress = _addr;
            betsMap[index].curBlockNumber = block.number;
            updateBigWinner(betsMap[index].investCode_1, betsMap[index].investCode_2, betsMap[index].investCode_3, betsMap[index].investTimestamp, betsMap[index].investAddress);
            index += 1;
        }
    }

    function updateBigWinner(uint256 code1, uint256 code2, uint256 code3, uint256 timestamp, address _addr) private {
        uint256 newDummy = calculateDummy(code1, code2, code3);
        if (newDummy > bigWinnerMap[0].dummy) {
            bigWinnerMap[2] = bigWinnerMap[1];
            bigWinnerMap[1] = bigWinnerMap[0];
            bigWinnerMap[0].investTimestamp = timestamp;
            bigWinnerMap[0].investCode_1 = code1;
            bigWinnerMap[0].investCode_2 = code2;
            bigWinnerMap[0].investCode_3 = code3;
            bigWinnerMap[0].investAddress = _addr;
            bigWinnerMap[0].dummy = newDummy;
        } else if (newDummy > bigWinnerMap[1].dummy && newDummy <= bigWinnerMap[0].dummy) {
            bigWinnerMap[2] = bigWinnerMap[1];
            bigWinnerMap[1].investTimestamp = timestamp;
            bigWinnerMap[1].investCode_1 = code1;
            bigWinnerMap[1].investCode_2 = code2;
            bigWinnerMap[1].investCode_3 = code3;
            bigWinnerMap[1].investAddress = _addr;
            bigWinnerMap[1].dummy = newDummy;
        } else if (newDummy > bigWinnerMap[2].dummy && newDummy <= bigWinnerMap[1].dummy) {
            bigWinnerMap[2].investTimestamp = timestamp;
            bigWinnerMap[2].investCode_1 = code1;
            bigWinnerMap[2].investCode_2 = code2;
            bigWinnerMap[2].investCode_3 = code3;
            bigWinnerMap[2].investAddress = _addr;
            bigWinnerMap[2].dummy = newDummy;
        }
    }

    function calculateDummy(uint256 code1, uint256 code2, uint256 code3) private pure returns(uint256) {
        if (code1 == code2 && code1 == code3) {
            return code1 * 10000;
        }
        if (code1 == code2) {
            return code1 * 100 + code3 + 2364;
        }
        if (code1 == code3) {
            return code1 * 100 + code2 + 2364;
        }
        if (code2 == code3) {
            return code2 * 100 + code1 + 2364;
        }
        if (code1 > code2 && code2 > code3) {
            return code1 * 169 + code2 * 13 + code3;
        }
        if (code1 > code3 && code3 > code2) {
            return code1 * 169 + code3 * 13 + code2;
        }
        if (code2 > code1 && code1 > code3) {
            return code2 * 169 + code1 * 13 + code3;
        }
        if (code2 > code3 && code3 > code1) {
            return code2 * 169 + code3 * 13 + code1;
        }
        if (code3 > code1 && code1 > code2) {
            return code3 * 169 + code1 * 13 + code2;
        }
        if (code3 > code2 && code2 > code1) {
            return code3 * 169 + code2 * 13 + code1;
        }
    }

    function betBig() public payable returns (bool) {
        require(canPlay);
        require(Utils._stringEq(SERO_CURRENCY, sero_msg_currency()));
        require(!Utils.isContract(msg.sender));
        require(msg.value >= 1e20 && msg.value <= 1e21);
        uint256 count = msg.value.div(1e20);
        insertBets(count, msg.sender);
        uint256 fee = msg.value.div(10);
        require(sero_send_token(luckyAddr, SERO_CURRENCY, fee));
        uint256 luckyStarFee = msg.value.sub(fee).div(10);
        winnerPool += msg.value.sub(fee).sub(luckyStarFee);
        luckyStarPool += luckyStarFee;
        if (addrTimesMap[msg.sender].times == 0) {
            addrList.push(msg.sender);
        }
        addrTimesMap[msg.sender].times += count;
        return true;
    }

    function getRandomResult(uint256 i) private view returns (uint256, uint256, uint256) {
        uint256 lastBlockNumberUsed = block.number - 1;
        bytes32 lastBlockHashUsed = blockhash(lastBlockNumberUsed);
        uint256 lastBlockHashUsed_uint = uint256(lastBlockHashUsed) + uint256(msg.sender);
        uint256 ret1 = rand(now + now + lastBlockHashUsed_uint + i, lastBlockHashUsed_uint);
        uint256 ret2 = rand(lastBlockHashUsed_uint + now - i, lastBlockHashUsed_uint);
        uint256 ret3 = rand(lastBlockHashUsed_uint - now + i, lastBlockHashUsed_uint);

        return (ret1, ret2, ret3);

    }

    function rand(uint256 nance, uint256 _lastBlockHashUsed) private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, now, _lastBlockHashUsed, nance))).mod(13) + 1;
    }

    function randLucky(uint256 nance, uint256 _lastBlockHashUsed) private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, now, _lastBlockHashUsed, nance))).mod(100);
    }

    function getTimes(address _addr) public view returns (uint256) {
        return addrTimesMap[_addr].times;
    }

    function getLuckyCode(address _addr) public view returns (uint256) {
        return addrTimesMap[_addr].luckyCode;
    }

    function calculateLucky(address _addr) private {
        uint256 lastBlockNumberUsed = block.number - 1;
        bytes32 lastBlockHashUsed = blockhash(lastBlockNumberUsed);
        uint256 lastBlockHashUsed_uint = uint256(lastBlockHashUsed) + uint256(msg.sender);
        uint256 randCode = randLucky(now, lastBlockHashUsed_uint);
        addrTimesMap[_addr].luckyCode = randCode;
        if (randCode == 66) {
            luckyStarAddr = _addr;
            canPlayByLucky = false;
        }
    }

    function toBeLuckyStar() public payable returns (bool) {
        require(canPlay);
        require(canPlayByLucky);
        require(Utils._stringEq(TOKEN_CURRENCY, sero_msg_currency()));
        require(!Utils.isContract(msg.sender));
        uint256 times = getTimes(msg.sender);
        require(times >= 1);
        require(msg.value == luckyStarPool);
        calculateLucky(msg.sender);
        addrTimesMap[msg.sender].times -= 1;
        require(sero_send_token(luckyAddr, TOKEN_CURRENCY, msg.value));
        return true;
    }
}
