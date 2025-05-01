// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    error Staker__SendSomeEth();
    error Staker__DeadlinePassed();

    event Stake(address staker, uint256 amount);

    mapping ( address => uint256 ) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw = false;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    function stake() public payable {
        if (msg.value == 0) {
            revert Staker__SendSomeEth();
        }

        if (block.timestamp > deadline) {
            revert Staker__DeadlinePassed();
        }

        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() public {
        bool hasDeadlinePassed = deadline < block.timestamp;
        bool hasEnoughThreshold = address(this).balance >= threshold;

        if (hasDeadlinePassed && hasEnoughThreshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }

        if (hasDeadlinePassed && !hasEnoughThreshold) {
            openForWithdraw = true;
        }
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    function withdraw() public {
        if (openForWithdraw) {
            (bool success, ) = payable(msg.sender).call{value: balances[msg.sender]}("");
            require(success, "Failed to send ETH");
        }
    }

    receive() external payable {
        stake();
    }
}
