pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

interface IEth2 {
    function mint(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract EthStaking {
    using SafeMath for uint256;

    address payable private _admin;
    address payable private _contr;
    address private _developer;

    bool private _isPaused;
    mapping(address => uint256) private _isPausedAddress;

    uint256 private constant _minimumEther = 0.01 ether;
    uint256 _tierAmount = 32000000000000000000;

    address[] private _stakers;

    mapping(address => uint256) private _stakingTimes;
    mapping(address => uint256) private _withdrawalTimes;
    mapping(address => uint256) private _stakingTierChange;
    mapping(address => uint256) private _totalStakingAmount;
    mapping(address => uint256) private _totalWithdrawalAmount;
    mapping(address => uint256) private _totalAwardedEth2Amount;

    mapping(address => mapping(uint256 => uint256)) private _stakingAmount;
    mapping(address => mapping(uint256 => uint256)) private _stakingTimestamp;
    mapping(address => mapping(uint256 => uint256))
        private _stakingWithdrawalTimestamp;
    mapping(address => mapping(uint256 => uint256)) private _withdrawalAmount;
    mapping(address => mapping(uint256 => uint256))
        private _withdrawalTimestamp;

    constructor(address payable contr, address developer) public {
        _admin = msg.sender;
        _contr = contr;
        _developer = developer;
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender);
        _;
    }

    modifier adminOrDeveloper() {
        require(_admin == msg.sender || _developer == msg.sender);
        _;
    }

    modifier whenNotPaused() {
        require(!_isPaused, "Pausable: paused Eth");
        _;
    }

    modifier whenPaused() {
        require(_isPaused, "Pausable: not paused Eth");
        _;
    }

    event Staking(
        address indexed staker,
        uint256 stakingTimes,
        uint256 stakeEtherAmount,
        uint256 stakeTotalEtherAmount,
        uint256 stakeTimestamp
    );

    event DividendItem(uint256 category, uint256 dividendAmount);

    event Withdrawal(
        address indexed staker,
        uint256 withdrawTimes,
        uint256 withdrawnEtherDividendAmount,
        uint256 withdrawnTotalEtherDividendAmount,
        uint256 eth2AmountToBeMint,
        uint256 awardedTotalEth2Amount,
        uint256 withdrawalTimestamp
    );

    function changeAdmin(address payable admin) public onlyAdmin {
        require(admin != address(0));
        _admin = admin;
    }

    function changeContract(address payable contr) public onlyAdmin {
        require(contr != address(0));
        _contr = contr;
    }

    function changeDeveloper(address developer) public onlyAdmin {
        require(developer != address(0));
        _developer = developer;
    }

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function getContract() external view returns (address) {
        return _contr;
    }

    function getDeveloper() external view returns (address) {
        return _developer;
    }

    function isPaused() external view returns (bool) {
        return _isPaused;
    }

    function getStakers() external view returns (address[] memory) {
        return _stakers;
    }

    function getStakingTimes(address sender) external view returns (uint256) {
        return _stakingTimes[sender];
    }

    function getStakingTierChange(address sender)
        external
        view
        returns (uint256)
    {
        return _stakingTierChange[sender];
    }

    function getTotalStakingAmount(address sender)
        external
        view
        returns (uint256)
    {
        return _totalStakingAmount[sender];
    }

    function getTotalWithdrawalAmount(address sender)
        external
        view
        returns (uint256)
    {
        return _totalWithdrawalAmount[sender];
    }

    function getStakingAmount(address sender, uint256 times)
        external
        view
        returns (uint256)
    {
        return _stakingAmount[sender][times];
    }

    function getStakingTimestamp(address sender, uint256 times)
        external
        view
        returns (uint256)
    {
        return _stakingTimestamp[sender][times];
    }

    function getStakingWithdrawalTimestamp(address sender, uint256 times)
        external
        view
        returns (uint256)
    {
        return _stakingWithdrawalTimestamp[sender][times];
    }

    function getWithdrawalTimes(address sender)
        external
        view
        returns (uint256)
    {
        return _withdrawalTimes[sender];
    }

    function getTotalAwardedEth2Amount(address sender)
        external
        view
        returns (uint256)
    {
        return _totalAwardedEth2Amount[sender];
    }

    function getWithdrawalAmount(address sender, uint256 times)
        external
        view
        returns (uint256)
    {
        return _withdrawalAmount[sender][times];
    }

    function getWithdrawalTimestamp(address sender, uint256 times)
        external
        view
        returns (uint256)
    {
        return _withdrawalTimestamp[sender][times];
    }

    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function setTierAmount(uint256 tierAmount) external onlyAdmin {
        _tierAmount = tierAmount;
    }

    function paused() public onlyAdmin whenNotPaused {
        _isPaused = true;
    }

    function unpaused() public onlyAdmin whenPaused {
        _isPaused = false;
    }

    function stake() external payable {
        require(
            msg.value >= _minimumEther,
            "It is unable to stake if the received ether is less than the minimum required value."
        );

        uint256 stakingTimes = _stakingTimes[msg.sender];

        if (stakingTimes == 0) {
            _stakers.push(msg.sender);
        }

        _stakingAmount[msg.sender][stakingTimes] = msg.value;
        _stakingTimestamp[msg.sender][stakingTimes] = block.timestamp;
        _stakingWithdrawalTimestamp[msg.sender][stakingTimes] = block.timestamp;
        _totalStakingAmount[msg.sender] =
            _totalStakingAmount[msg.sender] +
            msg.value;

        if (
            _stakingAmount[msg.sender][0] < _tierAmount &&
            _totalStakingAmount[msg.sender] >= _tierAmount
        ) {
            _stakingTierChange[msg.sender] = stakingTimes;
        }

        emit Staking(
            msg.sender,
            stakingTimes,
            msg.value,
            _totalStakingAmount[msg.sender],
            block.timestamp
        );

        _stakingTimes[msg.sender]++;
    }

    function withdrawDividend() external {
        require(
            !_isPaused,
            "It is unable to withdraw any dividend while paused."
        );

        uint256 stakingTimes = _stakingTimes[msg.sender];
        uint256 totalEthDividend = 0;
        uint256 stakingTierChange = _stakingTierChange[msg.sender];

        if (stakingTierChange == 0) {
            uint256 stakingAmount = _stakingAmount[msg.sender][0];

            if (stakingAmount < _tierAmount) {
                for (uint256 i = 0; i < stakingTimes; i++) {
                    uint256 timestampDifference = block.timestamp -
                        _stakingWithdrawalTimestamp[msg.sender][i];
                    uint256 ethDividend = withdrawDividendItem(
                        true,
                        timestampDifference,
                        i
                    );

                    emit DividendItem(1, ethDividend);
                    totalEthDividend = totalEthDividend.add(ethDividend);
                }
            } else {
                for (uint256 i = 0; i < stakingTimes; i++) {
                    uint256 timestampDifference = block.timestamp -
                        _stakingWithdrawalTimestamp[msg.sender][i];
                    uint256 ethDividend = withdrawDividendItem(
                        false,
                        timestampDifference,
                        i
                    );

                    emit DividendItem(2, ethDividend);
                    totalEthDividend = totalEthDividend.add(ethDividend);
                }
            }
        } else {
            for (uint256 i = 0; i < stakingTierChange; i++) {
                uint256 timestampDifference = _stakingWithdrawalTimestamp[msg
                    .sender][stakingTierChange] -
                    _stakingWithdrawalTimestamp[msg.sender][i];

                uint256 ethDividend = withdrawDividendItem(
                    true,
                    timestampDifference,
                    i
                );

                emit DividendItem(3, ethDividend);
                totalEthDividend = totalEthDividend.add(ethDividend);
            }

            for (uint256 i = 0; i <= stakingTimes; i++) {
                uint256 timestampDifference = block.timestamp -
                    _stakingWithdrawalTimestamp[msg.sender][stakingTierChange];
                uint256 ethDividend = withdrawDividendItem(
                    false,
                    timestampDifference,
                    i
                );

                emit DividendItem(4, ethDividend);
                totalEthDividend = totalEthDividend.add(ethDividend);
            }
        }

        uint256 totalStakingAmount = 0;

        for (uint256 i = 0; i <= stakingTimes; i++) {
            totalStakingAmount = totalStakingAmount.add(
                _stakingAmount[msg.sender][i]
            );
            _stakingWithdrawalTimestamp[msg.sender][i] = block.timestamp;
        }

        _totalStakingAmount[msg.sender] = totalStakingAmount;

        uint256 withdrawalTimes = _withdrawalTimes[msg.sender];
        _withdrawalAmount[msg.sender][withdrawalTimes] = totalEthDividend;
        _withdrawalTimestamp[msg.sender][withdrawalTimes] = block.timestamp;
        _withdrawalTimes[msg.sender]++;

        _totalWithdrawalAmount[msg.sender] = _totalWithdrawalAmount[msg.sender]
            .add(totalEthDividend);

        uint256 totalAwardedEth2Amount = 0;

        for (uint256 i = 0; i <= stakingTimes; i++) {
            uint256 timestampDifference = block.timestamp -
                _stakingTimestamp[msg.sender][i];

            uint256 stakingAmount = _stakingAmount[msg.sender][i];

            uint256 awardedEth2Amount = (((stakingAmount * 1500000) / 524888) *
                timestampDifference) / 2592000;

            totalAwardedEth2Amount = totalAwardedEth2Amount.add(
                awardedEth2Amount
            );
        }

        uint256 previousAwardedTotalEth2Amount = _totalAwardedEth2Amount[msg
            .sender];
        _totalAwardedEth2Amount[msg.sender] = totalAwardedEth2Amount;

        uint256 awardedEth2Amount = totalAwardedEth2Amount.sub(
            previousAwardedTotalEth2Amount
        );

        if (awardedEth2Amount > 0) {
            IEth2 contr = IEth2(_contr);
            //Eth2 contr = new Eth2(msg.sender, msg.sender);
            contr.mint(msg.sender, awardedEth2Amount);
        }

        emit Withdrawal(
            msg.sender,
            withdrawalTimes,
            totalEthDividend,
            _totalWithdrawalAmount[msg.sender],
            awardedEth2Amount,
            totalAwardedEth2Amount,
            block.timestamp
        );

        msg.sender.transfer(totalEthDividend);
    }

    function withdrawDividendItem(
        bool isTier1,
        uint256 timestampDifference,
        uint256 times
    ) internal view returns (uint256 dividend) {
        uint256 percentage = 0;

        if (isTier1) {
            percentage = 150;
        } else {
            percentage = 216;
        }

        uint256 stakingAmount = _stakingAmount[msg.sender][times];
        uint256 ethDividend = (stakingAmount *
            percentage *
            timestampDifference) /
            1000 /
            2592000;

        return ethDividend;
    }

    function deposit() external payable onlyAdmin {}

    function withdraw(uint256 amount) external onlyAdmin {
        _admin.transfer(amount);
    }

    function withdrawAll() external onlyAdmin {
        _admin.transfer(address(this).balance);
    }

    function kill() external onlyAdmin {
        selfdestruct(_admin);
    }

    receive() external payable {
        revert();
    }
}
