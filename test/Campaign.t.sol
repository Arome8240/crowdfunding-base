// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Campaign.sol";
import "../src/ICampaign.sol";

contract CampaignTest is Test {
    Campaign public campaign;

    address public creator = makeAddr("creator");
    address public contributor1 = makeAddr("contributor1");
    address public contributor2 = makeAddr("contributor2");

    uint256 public constant FUNDING_GOAL = 10 ether;
    uint256 public constant CAMPAIGN_DURATION = 30 days;
    string public constant METADATA_HASH = "QmTestHash123";

    function setUp() public {
        vm.deal(contributor1, 100 ether);
        vm.deal(contributor2, 100 ether);

        campaign = new Campaign(
            creator,
            FUNDING_GOAL,
            block.timestamp + CAMPAIGN_DURATION,
            METADATA_HASH
        );
    }

    // --- Constructor & Details ---
    function test_Initialization() public {
        (
            address _creator,
            uint256 _goal,
            uint256 _deadline,
            string memory _metadataHash,
            uint256 _totalRaised,
            ICampaign.CampaignStatus _status,
            bool _withdrawn
        ) = campaign.getDetails();

        assertEq(_creator, creator);
        assertEq(_goal, FUNDING_GOAL);
        assertEq(_deadline, block.timestamp + CAMPAIGN_DURATION);
        assertEq(_metadataHash, METADATA_HASH);
        assertEq(_totalRaised, 0);
        assertEq(uint256(_status), uint256(ICampaign.CampaignStatus.Active));
        assertFalse(_withdrawn);
    }

    // --- Contribution ---
    function test_Contribute_Success() public {
        vm.prank(contributor1);
        campaign.contribute{value: 5 ether}();
        assertEq(campaign.totalRaised(), 5 ether);
        assertEq(campaign.getContribution(contributor1), 5 ether);
    }

    function test_Contribute_RevertZeroContribution() public {
        vm.prank(contributor1);
        vm.expectRevert(Campaign.ZeroContribution.selector);
        campaign.contribute{value: 0}();
    }

    function test_Contribute_RevertDeadlinePassed() public {
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        vm.prank(contributor1);
        vm.expectRevert(Campaign.DeadlinePassed.selector);
        campaign.contribute{value: 1 ether}();
    }

    // --- Finalization ---
    function test_Finalize_Success() public {
        vm.prank(contributor1);
        campaign.contribute{value: FUNDING_GOAL}();
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        
        campaign.finalize();
        assertEq(uint256(campaign.status()), uint256(ICampaign.CampaignStatus.Successful));
    }

    function test_Finalize_Fail() public {
        vm.prank(contributor1);
        campaign.contribute{value: FUNDING_GOAL - 1}();
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);

        campaign.finalize();
        assertEq(uint256(campaign.status()), uint256(ICampaign.CampaignStatus.Failed));
    }
    
    function test_Finalize_RevertDeadlineNotReached() public {
        vm.expectRevert(Campaign.DeadlineNotReached.selector);
        campaign.finalize();
    }

    // --- Withdrawal ---
    function test_WithdrawFunds_Success() public {
        vm.prank(contributor1);
        campaign.contribute{value: FUNDING_GOAL}();
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        campaign.finalize();

        uint256 creatorBalanceBefore = creator.balance;
        vm.prank(creator);
        campaign.withdrawFunds();

        assertEq(creator.balance, creatorBalanceBefore + FUNDING_GOAL);
        assertTrue(campaign.withdrawn());
        assertEq(uint256(campaign.status()), uint256(ICampaign.CampaignStatus.Claimed));
    }
    
    function test_WithdrawFunds_RevertNotCreator() public {
        _makeSuccessful();
        vm.prank(contributor1);
        vm.expectRevert(Campaign.NotCampaignCreator.selector);
        campaign.withdrawFunds();
    }
    
    function test_WithdrawFunds_RevertNotSuccessful() public {
        _makeFailed();
        vm.prank(creator);
        vm.expectRevert(Campaign.CampaignNotSuccessful.selector);
        campaign.withdrawFunds();
    }

    // --- Refund ---
    function test_ClaimRefund_Success() public {
        vm.prank(contributor1);
        campaign.contribute{value: 5 ether}();
        _makeFailed();

        uint256 contributorBalanceBefore = contributor1.balance;
        vm.prank(contributor1);
        campaign.claimRefund();

        assertEq(contributor1.balance, contributorBalanceBefore + 5 ether);
        assertTrue(campaign.hasClaimedRefund(contributor1));
    }

    function test_ClaimRefund_RevertNotFailed() public {
        _makeSuccessful();
        vm.prank(contributor1);
        vm.expectRevert(Campaign.CampaignNotFailed.selector);
        campaign.claimRefund();
    }

    function test_ClaimRefund_RevertNoContribution() public {
        _makeFailed();
        vm.prank(contributor2);
        vm.expectRevert(Campaign.NoContribution.selector);
        campaign.claimRefund();
    }
    
    function test_ClaimRefund_RevertAlreadyRefunded() public {
        vm.prank(contributor1);
        campaign.contribute{value: 5 ether}();
        _makeFailed();

        vm.prank(contributor1);
        campaign.claimRefund();

        vm.prank(contributor1);
        vm.expectRevert(Campaign.AlreadyRefunded.selector);
        campaign.claimRefund();
    }

    // --- Helper Functions ---
    function _makeSuccessful() internal {
        vm.prank(contributor1);
        campaign.contribute{value: FUNDING_GOAL}();
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        campaign.finalize();
    }

    function _makeFailed() internal {
        vm.prank(contributor1);
        campaign.contribute{value: FUNDING_GOAL - 1}();
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        campaign.finalize();
    }
}
