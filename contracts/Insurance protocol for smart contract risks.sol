// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SmartContractInsurance is Ownable {
    enum ClaimStatus { None, Submitted, Approved, Rejected }

    struct Policy {
        uint256 coverageAmount;
        uint256 premiumPaid;
        uint256 startTime;
        uint256 duration;
        bool active;
    }

    struct Claim {
        uint256 claimAmount;
        ClaimStatus status;
    }

    mapping(address => Policy) public policies;
    mapping(address => Claim) public claims;

    event PolicyPurchased(address indexed user, uint256 amount, uint256 premium);
    event ClaimSubmitted(address indexed user, uint256 amount);
    event ClaimApproved(address indexed user, uint256 amount);
    event ClaimRejected(address indexed user, string reason);

    receive() external payable {}

    constructor(address initialOwner) Ownable(initialOwner) {}

    function purchasePolicy(uint256 durationInDays) external payable {
        require(msg.value > 0, "Premium must be > 0");
        require(!policies[msg.sender].active, "Policy already active");

        uint256 coverageAmount = msg.value * 10;
        policies[msg.sender] = Policy({
            coverageAmount: coverageAmount,
            premiumPaid: msg.value,
            startTime: block.timestamp,
            duration: durationInDays * 1 days,
            active: true
        });

        emit PolicyPurchased(msg.sender, coverageAmount, msg.value);
    }

    function submitClaim(uint256 amount) external {
        Policy storage policy = policies[msg.sender];
        require(policy.active, "No active policy");
        require(block.timestamp <= policy.startTime + policy.duration, "Policy expired");
        require(amount <= policy.coverageAmount, "Claim exceeds coverage");
        require(claims[msg.sender].status == ClaimStatus.None, "Claim already submitted");

        claims[msg.sender] = Claim({
            claimAmount: amount,
            status: ClaimStatus.Submitted
        });

        emit ClaimSubmitted(msg.sender, amount);
    }

    function approveClaim(address user) external onlyOwner {
        Claim storage claim = claims[user];
        Policy storage policy = policies[user];

        require(claim.status == ClaimStatus.Submitted, "No claim to approve");
        require(address(this).balance >= claim.claimAmount, "Insufficient funds");

        claim.status = ClaimStatus.Approved;
        policy.active = false;

        payable(user).transfer(claim.claimAmount);
        emit ClaimApproved(user, claim.claimAmount);
    }

    function rejectClaim(address user, string memory reason) external onlyOwner {
        Claim storage claim = claims[user];
        require(claim.status == ClaimStatus.Submitted, "No claim to reject");

        claim.status = ClaimStatus.Rejected;
        emit ClaimRejected(user, reason);
    }

    function getPolicyStatus(address user) external view returns (bool active, uint256 expiryTime) {
        Policy memory policy = policies[user];
        active = policy.active;
        expiryTime = policy.startTime + policy.duration;
    }

    function getClaimStatus(address user) external view returns (ClaimStatus) {
        return claims[user].status;
    }
}
