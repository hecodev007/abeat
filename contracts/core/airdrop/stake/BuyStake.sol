// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract BuyStakePool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 stakeTime; // Reward debt. See explanation below.
        uint lockType;
    }

    // IERC20  public abeatsERC20;
    IERC20  public tokenERC20;
    IERC20 public depositToken;
    //IERC20 public rewardToken;
    uint256 public price;
    uint256 public price_bnb;
    uint256 public limit;
    // uint256 public maxStaking;


    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo[]) public userInfo;
    mapping(address => uint256) public userStake;
    mapping(uint => uint256) public percent; //6 decimals
    // Total amount pledged by users
    uint256 public totalDeposit;


    event Deposit(address user, uint lockType, uint256 amount);
    event BuyDeposit(address user, uint lockType, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event BuyEvent(address owner, uint token, uint256 amount);

    constructor(
        address _depositToken
    ) public {
        depositToken = IERC20(_depositToken);
    }

    function setPercent(uint _lockType, uint256 _percent) public onlyOwner {
        percent[_lockType] = _percent;
    }

    function setPrice(uint256 _price, uint256 _price_bnb) public onlyOwner returns (bool) {
        price = _price;
        price_bnb = _price_bnb;
        return true;
    }

    function setLimit(uint256 _limit) public onlyOwner {
        limit = _limit;
    }

    function setBuyToken(address _tokenERC20, address _abeats) public onlyOwner {
        tokenERC20 = IERC20(_tokenERC20);
        depositToken = IERC20(_abeats);
    }
    // Stake tokens to Pool
    function buyDeposit(uint256 _amount, uint _lockType) public payable {
        require(_amount >= limit, "param error");
        require(_lockType == 6 || _lockType == 12, "wrong type");
        require(userInfo[msg.sender].length <= 100, "much times");
        if (msg.value > 0) {
            require(price_bnb > 0, "please set price");
            require(msg.value >= price_bnb.mul(_amount), "BNB value is not enough");
        } else {
            require(price > 0, "please set price");
            require(tokenERC20.balanceOf(msg.sender) >= price.mul(_amount), "token balance is not enough");
            require(tokenERC20.allowance(msg.sender, address(this)) >= price.mul(_amount), "token allowance is not enough");
            SafeERC20.safeTransferFrom(tokenERC20, msg.sender, address(this), price.mul(_amount));
        }
        emit BuyEvent(msg.sender, 0, _amount);

        if (_amount > 0) {
            uint256 amount = _amount * 1e18;
            // depositToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            userInfo[msg.sender].push(UserInfo({
            amount : amount,
            lockType : _lockType,
            stakeTime : block.timestamp
            }));
            userStake[msg.sender] = userStake[msg.sender].add(amount);
            totalDeposit = totalDeposit.add(amount);
            emit BuyDeposit(address(msg.sender), _lockType, amount);
        }

    }

    function adminDeposit(uint256 _amount, address _user, uint _lockType) public onlyOwner {

        require(_lockType == 6 || _lockType == 12, "wrong type");
        require(userInfo[_user].length <= 100, "much times");
        if (_amount > 0) {
            // depositToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            userInfo[_user].push(UserInfo({
            amount : _amount,
            lockType : _lockType,
            stakeTime : block.timestamp
            }));
            userStake[_user] = userStake[_user].add(_amount);
            totalDeposit = totalDeposit.add(_amount);
            emit Deposit(_user, _lockType, _amount);
        }

    }
    function withdrawToken() external onlyOwner {
        SafeERC20.safeTransfer(
            tokenERC20,
            owner(),
            tokenERC20.balanceOf(address(this))
        );
    }

    function withdrawBnb() external onlyOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }
    // Withdraw tokens from STAKING.
    function withdraw(uint256 _amount) public {
        console.log("begin:", userInfo[msg.sender].length);
        uint256 tmpAmount;
        uint256 rewardAmount;
        for (uint256 i = 0; i < userInfo[msg.sender].length; i++) {
            if (block.timestamp.sub(userInfo[msg.sender][i].stakeTime) >= userInfo[msg.sender][i].lockType * 30 days) {
                if (tmpAmount.add(userInfo[msg.sender][i].amount) >= _amount) {
                    if (tmpAmount.add(userInfo[msg.sender][i].amount) == _amount) {
                        rewardAmount = rewardAmount.add(userInfo[msg.sender][i].amount.mul(percent[userInfo[msg.sender][i].lockType]).div(1000000));
                        userInfo[msg.sender][i] = userInfo[msg.sender][userInfo[msg.sender].length - 1];
                        userInfo[msg.sender].pop();

                    } else {
                        rewardAmount = rewardAmount.add((_amount.sub(tmpAmount)).mul(percent[userInfo[msg.sender][i].lockType]).div(1000000));
                        UserInfo storage user = userInfo[msg.sender][i];
                        user.amount = tmpAmount.add(userInfo[msg.sender][i].amount).sub(_amount);

                    }
                    tmpAmount = _amount;
                    break;
                } else {
                    rewardAmount = rewardAmount.add(userInfo[msg.sender][i].amount.mul(percent[userInfo[msg.sender][i].lockType]).div(1000000));
                    userInfo[msg.sender][i] = userInfo[msg.sender][userInfo[msg.sender].length - 1];
                    userInfo[msg.sender].pop();
                    tmpAmount = tmpAmount.add(userInfo[msg.sender][i].amount);
                }
            }
        }
        if (tmpAmount > 0) {
            totalDeposit = totalDeposit.sub(tmpAmount);
            console.log("reward:", rewardAmount);
            tmpAmount = tmpAmount.add(rewardAmount);
            depositToken.safeTransfer(address(msg.sender), tmpAmount);
            userStake[msg.sender] = userStake[msg.sender].sub(tmpAmount);
            emit Withdraw(address(msg.sender), tmpAmount);
        }
        console.log("end:", userInfo[msg.sender].length);
    }


    function MyBadge(address _addr) public view returns (uint256) {
        if (userStake[_addr] >= 10000e18) {
            return 4;
        } else if (userStake[_addr] >= 6000e18) {
            return 3;
        } else if (userStake[_addr] >= 3000e18) {
            return 2;
        } else if (userStake[_addr] >= 500e18) {
            return 1;
        }
        return 0;
    }
    // Withdraw reward. EMERGENCY ONLY.
    //    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
    //        require(_amount <= rewardToken.balanceOf(address(this)), 'not enough token');
    //        rewardToken.safeTransfer(address(msg.sender), _amount);
    //    }

}