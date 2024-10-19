// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    // Mapping of address to amount staked
    mapping(address => uint256) public stakedBalance;
    // Threshold amount that needs to be met
    uint256 public constant threshold = 1 ether;
    // Deadline for staking (72 hours from contract deployment)
    uint256 public deadline = block.timestamp + 72 hours;
    // Flag to allow withdrawals if threshold is not met
    bool public openForWithdraw = false;

    // Event emitted when a stake is made
    event Stake(address indexed staker, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    /// @notice Allows users to stake ETH
    /// @dev Updates the user's balance and emits a Stake event
    function stake() public payable {
        require(block.timestamp < deadline, "Staking period has ended");
        stakedBalance[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    /// @notice Executes the staking process after the deadline
    /// @dev If threshold is met, sends funds to external contract; otherwise, allows withdrawals
    function execute() public {
        require(block.timestamp >= deadline, "Deadline has not been reached");
        require(!openForWithdraw, "Contract is open for withdrawal");

        if (address(this).balance >= threshold) {
            // If threshold is met, send funds to external contract
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            // If threshold is not met, allow withdrawals
            openForWithdraw = true;
        }
    }

    /// @notice Allows users to withdraw their stake if threshold was not met
    /// @dev Can only be called if openForWithdraw is true
    function withdraw() public {
        require(openForWithdraw, "Contract is not open for withdrawal");
        require(stakedBalance[msg.sender] > 0, "No balance to withdraw");

        uint256 amount = stakedBalance[msg.sender];
        stakedBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Returns the time left before the staking deadline
    /// @return uint256 Time left in seconds, or 0 if deadline has passed
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    /// @notice Allows the contract to receive ETH and automatically stake it
    /// @dev This function is called for plain Ether transfers, i.e. for every call with empty calldata
    receive() external payable {
        stake();
    }
}
