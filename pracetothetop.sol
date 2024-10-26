// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

//COSTON2 =  https://coston2-explorer.flare.network/address/0x6D5d17B81cD0f49A970092326749538a233f4EeF?tab=read_contract

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v5.0/contracts/access/Ownable.sol";
import {TestFtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/TestFtsoV2Interface.sol";

contract PraceToTheTop is Ownable {

    TestFtsoV2Interface internal ftsoV2;
    bytes21[] public feedIds;

    uint256 public startTime;
    uint256[8] public startPrices;
    uint256 public bettingWindow = 100;
    bool public raceActive;

    uint256 public minBet = 1 ether;
    uint256 public maxBet = 100 ether;

    mapping(address => uint256[8]) public currentBets;
    address[] public activeUsers;
    mapping(address => bool) public isActiveUser;

    event BetPlaced(address indexed user, uint256 amount, uint256 coinIndex);
    event RaceFinished(uint256 winningCoinIndex, int256 priceChange);
    event Payout(address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {  
        ftsoV2 = TestFtsoV2Interface(0x3d893C53D9e8056135C26C8c638B76C8b60Df726);
        
        feedIds.push(bytes21(0x01464c522f55534400000000000000000000000000)); // flr
        feedIds.push(bytes21(0x015347422f55534400000000000000000000000000)); // sgb
        feedIds.push(bytes21(0x015852502f55534400000000000000000000000000)); // xrp
        feedIds.push(bytes21(0x01584c4d2f55534400000000000000000000000000)); // xlm
        feedIds.push(bytes21(0x014c54432f55534400000000000000000000000000)); // ltc
        feedIds.push(bytes21(0x014554482f55534400000000000000000000000000)); // eth
        feedIds.push(bytes21(0x014254432f55534400000000000000000000000000)); // btc
        feedIds.push(bytes21(0x01504f4c2f55534400000000000000000000000000)); // pol

        startRace();
    }

    function setFTSO(address _ftsoV2) external onlyOwner {
        ftsoV2 = TestFtsoV2Interface(_ftsoV2);
    }

    // Setting minimum and maximum bet range
    function setBetRange(uint256 _minBet, uint256 _maxBet) external onlyOwner {
        require(_minBet < _maxBet, "Invalid bet range");
        minBet = _minBet;
        maxBet = _maxBet;
    }

    // Placing a bet
    function placeBet(uint256 whichCoin) external payable {
        require(raceActive, "No active race");
        require(whichCoin <= 7, "Invalid Coin Index");
        require(msg.value >= minBet && msg.value <= maxBet, "Invalid bet amount");
        require(currentBets[msg.sender][whichCoin] == 0, "Already bet there");
        require(block.timestamp - startTime < bettingWindow, "Betting time is over");

        currentBets[msg.sender][whichCoin] = msg.value;

        if (!isActiveUser[msg.sender]) {
            activeUsers.push(msg.sender);
            isActiveUser[msg.sender] = true;
        }

        emit BetPlaced(msg.sender, msg.value, whichCoin);
    }

    // Canceling a bet (during betting window only)
    function cancelBet(uint256 whichCoin) external {
        require(currentBets[msg.sender][whichCoin] > 0, "No bet on this coin");
        require(block.timestamp - startTime < bettingWindow, "Betting time is over");

        uint256 refundAmount = currentBets[msg.sender][whichCoin];
        currentBets[msg.sender][whichCoin] = 0;
        payable(msg.sender).transfer(refundAmount);

        emit Payout(msg.sender, refundAmount);
    }

    // Finishing the race and distributing rewards, then starting a new race
    function finishRace() external onlyOwner {
        require(raceActive, "No active race");
        require(address(this).balance > 0, "No bets placed");

        uint256[] memory endPrices = new uint256[](feedIds.length);
        int256[] memory priceChanges = new int256[](feedIds.length);
        uint256 maxChangeIndex = 0;
        int256 maxChange = 0;

        // Get the latest prices and calculate the percent change
        for (uint256 i = 0; i < feedIds.length; i++) {
            (uint256 feedValue,,) = ftsoV2.getFeedById(feedIds[i]);
            endPrices[i] = feedValue;

            // Calculate percentage change
            if (endPrices[i] >= startPrices[i]) {
                priceChanges[i] = int256((endPrices[i] - startPrices[i]) * 10000 / startPrices[i]);
            } else {
                priceChanges[i] = -int256((startPrices[i] - endPrices[i]) * 10000 / startPrices[i]);
            }

            // Find the coin with the highest price increase
            if (priceChanges[i] > maxChange) {
                maxChange = priceChanges[i];
                maxChangeIndex = i;
            }
        }

        // Distribute the entire balance to users who bet on the winning coin
        uint256 totalPayout = address(this).balance;
        uint256 totalWinningBets = 0;

        // Calculate total bet amount on the winning coin
        for (uint256 i = 0; i < activeUsers.length; i++) {
            address user = activeUsers[i];
            totalWinningBets += currentBets[user][maxChangeIndex];
        }

        require(totalWinningBets > 0, "No winning bets");

        for (uint256 i = 0; i < activeUsers.length; i++) {
            address user = activeUsers[i];
            uint256 userBet = currentBets[user][maxChangeIndex];
            if (userBet > 0) {
                uint256 payout = (userBet * totalPayout) / totalWinningBets;
                payable(user).transfer(payout);
                emit Payout(user, payout);
            }
        }

        emit RaceFinished(maxChangeIndex, maxChange);

        // Reset state for a new race
        for (uint256 i = 0; i < activeUsers.length; i++) {
            address user = activeUsers[i];
            delete currentBets[user];
            isActiveUser[user] = false;
        }
        delete activeUsers;

        startRace(); // Automatically start the next race
    }

    // Start a new race
    function startRace() internal {
        raceActive = true;
        startTime = block.timestamp;

        // Set start prices for all feeds
        for (uint256 i = 0; i < feedIds.length; i++) {
            (uint256 feedValue,,) = ftsoV2.getFeedById(feedIds[i]);
            startPrices[i] = feedValue;
        }
    }

    // Viewer function to get all prices formatted as strings with decimals in the correct place
    function getAllPrices() external view returns (string[] memory) {
        string[] memory prices = new string[](feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            (uint256 feedValue, int8 decimals,) = ftsoV2.getFeedById(feedIds[i]);
            prices[i] = formatPriceWithDecimals(feedValue, decimals);
        }
        return prices;
    }

    // Viewer function for getting the current percentage increase, formatted to 4 decimals
    function getCurrentPercentChanges() external view returns (int256[] memory) {
        int256[] memory percentChanges = new int256[](feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            (uint256 currentPrice, ,) = ftsoV2.getFeedById(feedIds[i]);

            if (currentPrice >= startPrices[i]) {
                percentChanges[i] = int256(((currentPrice - startPrices[i]) * 10000) / startPrices[i]);
            } else {
                percentChanges[i] = -int256(((startPrices[i] - currentPrice) * 10000) / startPrices[i]);
            }
        }
        return percentChanges;
    }
    
    // Helper function to format price with decimals, accounting for positive and negative decimals
    function formatPriceWithDecimals(uint256 price, int8 decimals) internal pure returns (string memory) {
        if (decimals >= 0) {
            uint256 decimalPlaces = uint256(int256(decimals));
            uint256 integerPart = price / (10 ** decimalPlaces);
            uint256 fractionalPart = price % (10 ** decimalPlaces);
            return string(abi.encodePacked(uintToString(integerPart), ".", fractionalToString(fractionalPart, decimalPlaces)));
        } else {
            uint256 adjustedPrice = price * (10 ** uint256(-int256(decimals)));
            return uintToString(adjustedPrice);
        }
    }

    // Helper function to format fractional part with leading zeros if needed
    function fractionalToString(uint256 fractionalPart, uint256 decimals) internal pure returns (string memory) {
        bytes memory buffer = new bytes(decimals);
        for (uint256 i = decimals; i > 0; i--) {
            buffer[i - 1] = bytes1(uint8(48 + fractionalPart % 10));
            fractionalPart /= 10;
        }
        return string(buffer);
    }

    // Helper function to convert uint256 to string
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // panic/rugpull
    function collectFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
