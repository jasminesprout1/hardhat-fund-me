// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.9;
// Imports
import "./PriceConverter.sol";
// Error Codes
error FundMe__NotOwner();

// Interfaces / Libraries go here (don't have any in the contract rn)
// Contracts

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        ); // 1e18 = 1 * 10 ** 18 == 1000000000000000000 wei
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // starting index, ending index, step amount
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex = funderIndex + 1
        ) {
            // funderIndex++    ===    funderIndex = funderIndex + 1;
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the array

        s_funders = new address[](0);

        // actually withdraw the funds

        // transfer
        // send
        // call

        // payable(msg.sender).transfer(address(this).balance);

        // bool sendFundSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendFundSuccess, "Sending failed");

        (bool callFundSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callFundSuccess, "Calling failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }
}

fallback() external payable {
        if (msg.value > 100) {
            fund();
        }
    }