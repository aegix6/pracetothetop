// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v5.0/contracts/access/Ownable.sol";

import {TestFtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/TestFtsoV2Interface.sol";
import {IFeeCalculator} from "@flarenetwork/flare-periphery-contracts/coston2/IFeeCalculator.sol";

contract PraceToTheTop is Ownable {

    TestFtsoV2Interface internal ftsoV2;
    IFeeCalculator internal feeCalc;
    bytes21[] public feedIds;
    bytes21 public flrUsdId;
    uint256 public fee;


    constructor() Ownable(msg.sender) {  
              
        ftsoV2 = TestFtsoV2Interface(0x3d893C53D9e8056135C26C8c638B76C8b60Df726);
        feeCalc = IFeeCalculator(0x88A9315f96c9b5518BBeC58dC6a914e13fAb13e2);
        
        feedIds.push(bytes21(0x01464c522f55534400000000000000000000000000));//flr
        feedIds.push(bytes21(0x015347422f55534400000000000000000000000000));//sgb
        feedIds.push(bytes21(0x015852502f55534400000000000000000000000000));//xrp
        feedIds.push(bytes21(0x01584c4d2f55534400000000000000000000000000));//xlm
        feedIds.push(bytes21(0x014c54432f55534400000000000000000000000000));//ltc
        feedIds.push(bytes21(0x014554482f55534400000000000000000000000000));//eth
        feedIds.push(bytes21(0x014254432f55534400000000000000000000000000));//btc
        feedIds.push(bytes21(0x01504f4c2f55534400000000000000000000000000));//pol


    }


    function setPeripherals(address _ftsoV2, address _feeCalc, bytes21 _flrUsdId) external onlyOwner {
        ftsoV2 = TestFtsoV2Interface(_ftsoV2);
        feeCalc = IFeeCalculator(_feeCalc);
        flrUsdId = _flrUsdId;
    }

    function checkFees() external returns (uint256 _fee) {
        fee = feeCalc.calculateFeeByIds(feedIds);
        return fee;
    }

    function getAllPrices() external view returns (uint256, int8, uint64) {
        (uint256 feedValue, int8 decimals, uint64 timestamp) = ftsoV2.getFeedById(flrUsdId);

        return (feedValue, decimals, timestamp);
    }



}

