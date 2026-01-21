// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ICampaign.sol";

/// @title Campaign
/// @notice A contract for an individual crowdfunding campaign.
/// @dev Implements the ICampaign interface and contains all logic for a single campaign.
contract Campaign is ICampaign {
    // --- State Variables ---

    address public immutable creator;
    uint256 public immutable goal;
    uint256 public immutable deadline;
    string public immutable metadataHash;

    uint256 public totalRaised;
    CampaignStatus public status;
    bool public withdrawn;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public refundClaimed;

    uint256 private _reentrancyStatus;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // --- Errors (from Crowdfunding.sol) ---
    error CampaignNotActive();
    error DeadlineNotReached();
    error DeadlinePassed();
    error ZeroContribution();
    error NotCampaignCreator();
    error CampaignNotSuccessful();
    error AlreadyWithdrawn();
    error CampaignNotFailed();
    error NoContribution();
    error AlreadyRefunded();
    error TransferFailed();

    // --- Modifier ---

    modifier nonReentrant() {
        require(_reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        _reentrancyStatus = _ENTERED;
        _;
        _reentrancyStatus = _NOT_ENTERED;
    }

    // --- Constructor ---

    constructor(
        address _creator,
        uint256 _goal,
        uint256 _deadline,
        string memory _metadataHash
    ) {
        creator = _creator;
        goal = _goal;
        deadline = _deadline;
        metadataHash = _metadataHash;

        status = CampaignStatus.Active;
        _reentrancyStatus = _NOT_ENTERED;
    }

    // --- ICampaign Implementation ---

    function getDetails()
        external
        view
        override
        returns (
            address,
            uint256,
            uint256,
            string memory,
            uint256,
            CampaignStatus,
            bool
        )
    {
        return (creator, goal, deadline, metadataHash, totalRaised, status, withdrawn);
    }

    function contribute() external payable override nonReentrant {
        if (msg.value == 0) revert ZeroContribution();
        if (status != CampaignStatus.Active) revert CampaignNotActive();
        if (block.timestamp >= deadline) revert DeadlinePassed();

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit ContributionMade(msg.sender, msg.value, block.timestamp);
    }

    function finalize() external override {
        if (status != CampaignStatus.Active) revert CampaignNotActive();
        if (block.timestamp < deadline) revert DeadlineNotReached();

        if (totalRaised >= goal) {
            status = CampaignStatus.Successful;
        } else {
            status = CampaignStatus.Failed;
        }

        emit CampaignFinalized(status, totalRaised, block.timestamp);
    }

    function withdrawFunds() external override nonReentrant {
        if (msg.sender != creator) revert NotCampaignCreator();
        if (status != CampaignStatus.Successful) revert CampaignNotSuccessful();
        if (withdrawn) revert AlreadyWithdrawn();

        withdrawn = true;
        status = CampaignStatus.Claimed;
        uint256 amount = totalRaised;

        (bool success, ) = payable(creator).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit FundsWithdrawn(creator, amount, block.timestamp);
    }

    function claimRefund() external override nonReentrant {
        if (status != CampaignStatus.Failed) revert CampaignNotFailed();
        uint256 contributionAmount = contributions[msg.sender];
        if (contributionAmount == 0) revert NoContribution();
        if (refundClaimed[msg.sender]) revert AlreadyRefunded();

        refundClaimed[msg.sender] = true;

        (bool success, ) = payable(msg.sender).call{value: contributionAmount}("");
        if (!success) revert TransferFailed();

        emit RefundClaimed(msg.sender, contributionAmount, block.timestamp);
    }

    function getContribution(address contributor) external view override returns (uint256) {
        return contributions[contributor];
    }

    function hasClaimedRefund(address contributor) external view override returns (bool) {
        return refundClaimed[contributor];
    }
}
