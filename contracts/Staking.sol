// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "contracts/assignments/erc20/ERC20.sol";
import "./IDean20.sol";

contract Staking {
    //the erc 20 tokens for the staking and reward
    IDean20 private immutable stakingToken;
    IDean20  private immutable rewardToken;
    //the owner of the contract
    address private owner;
    //the duration of the staking
    uint public stakingDuration;
    //the end of the staking
    uint public endOfDuration;
    //the last time the staking was updated
    uint public updateAt;
    //the reward a user earn per second
    uint public rewardRate;
    //(sum of the reward rates multiplied by the duration) divided by the total supply
    uint public rewardForEachTokenStaked;
    //
    uint public totalStake;

    //to track the rewardForEachTokenStaked
    mapping(address => uint) public userRewardPerTokenPaid;
    //to tract the reward
    mapping(address => uint) public rewards;
    //to track the total token staked
    mapping(address => uint) public balanceOf;

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;

        stakingToken = IDean20(_stakingToken);

        rewardToken = IDean20(_rewardToken);
    }
    //executes first before the function is modifies execute
    //it's used to make sure only the owner of the contract can initiate this tx
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }
    modifier updateReward(address _account) {
        rewardForEachTokenStaked = rewardPerToken();

        updateAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardForEachTokenStaked;
        }
        _;
    }

    function setRewardDuration(uint _duration) external onlyOwner {
        //to make sure the duration is not changed when the staking duration has not ended
        require(endOfDuration < block.timestamp, "Reward duration not finished");

        stakingDuration = _duration;
    }
    //the owner of the contract sends the reward into the contract and set the reward rate
    function notifyRewardAmountAndSetRewardRate(uint _amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp > endOfDuration) { //todo: it has not ended
            rewardRate = _amount / stakingDuration;
        } else {    //todo: it has ended                    time left
            uint remainingReward = rewardRate * (endOfDuration - block.timestamp);
            rewardRate = (remainingReward + _amount) / stakingDuration;
        }
        require(rewardRate > 0, "Reward rate = 0");
        require(rewardRate * stakingDuration <= rewardToken.balanceOf(address(this)), "Reward amount > balance");
        endOfDuration = block.timestamp + stakingDuration;
        updateAt = block.timestamp;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender] + _amount;
        totalStake = totalStake + _amount;
    }

    function min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return min(block.timestamp, endOfDuration);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalStake == 0) {
            return rewardForEachTokenStaked;
        }
        return rewardForEachTokenStaked + (rewardRate *
        (lastTimeRewardApplicable() - updateAt) * 1e18) / totalStake;
    }


    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] = balanceOf[msg.sender] - _amount;
        totalStake = totalStake - _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint) {
        return (balanceOf[_account] *
            (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18
            + rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
        }
    }
}

/*
Scenario 1: When a user is coming to stake and there's no stake in the staking pool,
the updateReward sets everything to 0 because
rewardForEachTokenStaked = 0 because rewardPerToken() returns 0 into rewardForEachTokenStaked because
     if (totalStake == 0) {
            return rewardForEachTokenStaked;
        }... at this point, rewardForEachTokenStaked = 0 hence it returns 0;
rewards[_account] = 0 because earned() returns 0 because balanceOf[_account] = 0;
userRewardPerTokenPaid[_account] is set to 0 because rewardForEachTokenStaked which is 0 is used to set it hence it is equal to 0;

Scenario 2: When a user is coming to stake when there's stake int the staking pool.
in the updateReward, the rewardPerToken() sets the the rewardForEachTokenStaked using
1. (rewardRate * (lastTimeRewardApplicable() - updateAt(the last time there was an update)) for the calculation
2. updateAt = lastTimeRewardApplicable(): (this is either the current time or the endOfDuration, depending on the on the one that's lower)
3. rewards[_account] = earned(_account); earned() is used to update the user rewards[user]
4. userRewardPerTokenPaid[_account] = rewardForEachTokenStaked(which is actually the last rewardPerToken())

HOW TO USE
1. Deploy 2 ERC-20 contract
2. Copy their addresses into the staking contract
3. Once the staking contract is deployed, the first thing is for the owner of the contract to set the staking duration.
4. After setting the staking duration, it's to call the notifyRewardAmount function which sets the reward rate bt before that is done,
    you need to transfer reward token into the staking contract.
5. Mint some tokens to the owner and the owner tranfers it to the staking contract.
6. This amount is then used to call the notifyRewardAmount function.
7. Once the notifyRewardAmount function is called and the reward rate is set, stakers can then come to stake.
8. Some tokens are met to the staker from the staking ERC-20. He brings the token to the staking contracts, and stake.
9. After staking, he can check his balance staked from balanceOf function.
10. He can check the amount of rewards he has gotten over time
11. He can get his reward, which he can check in his erc-20 contract
12. He can withdraw his stake from the staking contract which reflect in his ERC-20 token wallet/contract

*/