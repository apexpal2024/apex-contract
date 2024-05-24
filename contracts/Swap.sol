// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAPXG.sol";
import "./interfaces/IApxgPrice.sol";
import "./interfaces/IEthPrice.sol";
import "./interfaces/IBlast.sol";

contract Swap is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IAPXG public APXG;
    IApxgPrice public ApxgPrice;
    IEthPrice public EthPrice;
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);

    uint256 public dailySwapLimit; 
    address public dailySwapLimitUpdater; 
    uint256 public swappedToday; 
    address public feeReceiver;
    uint256 public feeRate;
    uint256 public MIN_ETH_DEPOSIT;
    uint256 public MIN_APXG_DEPOSIT;
    address public autoRefresher;

    event SwappedETHForAPXG(
        address indexed user,
        uint256 amountETH,
        uint256 amountAPXG
    );

    event SwappedAPXGForETH(
        address indexed user,
        uint256 amountAPXG,
        uint256 amountETH
    );

    modifier onlyOwnerOrUpdater() {
        require(
            msg.sender == dailySwapLimitUpdater || msg.sender == owner(),
            "Swap: You are not the updater"
        );
        _;
    }

    function initialize(
        address _APXG,
        address _ApxgPrice,
        address _EthPrice,
        address _feeReceiver,
        address _dailySwapLimitUpdater
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        APXG = IAPXG(_APXG);
        ApxgPrice = IApxgPrice(_ApxgPrice);
        EthPrice = IEthPrice(_EthPrice);
        feeReceiver = _feeReceiver;
        dailySwapLimitUpdater = _dailySwapLimitUpdater;
        dailySwapLimit = 1000000 ether; 
        MIN_ETH_DEPOSIT = 3 * (10 ** 15);
        MIN_APXG_DEPOSIT = 200 ether;
        feeRate = 500;
        BLAST.configureClaimableGas();
        BLAST.configureClaimableYield();
    }

    function swapETHForAPXG() external payable nonReentrant {
        require(
            msg.value >= MIN_ETH_DEPOSIT,
            "Swap:ETH Value not enough(Min 0.003 Ether)"
        );
        uint256 priceETH = EthPrice.getPriceETH();
        uint256 priceAPXG = ApxgPrice.getPrice();
        uint256 fee = (msg.value * feeRate) / 10000;
        uint256 amountAPXG = ((msg.value - fee) * priceETH) / priceAPXG;

        require(
            swappedToday + amountAPXG <= dailySwapLimit,
            "Swap: Daily limit reached"
        );
        swappedToday += amountAPXG;
        
        (bool success, ) = feeReceiver.call{value: fee}("");
        require(success, "Call failed");

        APXG.convert(msg.sender, amountAPXG);

        emit SwappedETHForAPXG(msg.sender, msg.value, amountAPXG);
    }

    function swapAPXGForETH(uint256 _amount) external nonReentrant {
        require(_amount > MIN_APXG_DEPOSIT, "Swap:APXG amount not enough");
        uint256 priceETH = EthPrice.getPriceETH();
        uint256 priceAPXG = ApxgPrice.getPrice();
        uint256 equivalantETH = (_amount * priceAPXG) / priceETH;
        uint256 fee = (equivalantETH * feeRate) / 10000;
        uint256 deserveETH = equivalantETH - fee;

        require(
            deserveETH + fee <= address(this).balance,
            "Swap: Insufficient balance in contract"
        );
        require(
            APXG.allowance(msg.sender, address(this)) >= _amount,
            "Swap: Insufficient APXG allowance"
        );

        SafeERC20.safeTransferFrom(APXG, msg.sender, address(APXG), _amount);

        (bool successFee, ) = feeReceiver.call{value: fee}("");
        require(successFee, "Call fee failed");

        (bool success, ) = msg.sender.call{value: deserveETH}("");
        require(success, "Call ETH failed");

        emit SwappedAPXGForETH(msg.sender, _amount, deserveETH);
    }

    function refreshSwappedToday(uint256 _swappedToday) external {
        require(
            msg.sender == autoRefresher || msg.sender == owner(),
            "Swap: You are not the updater"
        );
        swappedToday = _swappedToday;
    }

    function setMinEthDeposit(
        uint256 _MIN_ETH_DEPOSIT
    ) public onlyOwnerOrUpdater {
        MIN_ETH_DEPOSIT = _MIN_ETH_DEPOSIT;
    }

    function setMinApxgDeposit(
        uint256 _MIN_APXG_DEPOSIT
    ) public onlyOwnerOrUpdater {
        MIN_APXG_DEPOSIT = _MIN_APXG_DEPOSIT;
    }

    function setDailySwapLimit(
        uint256 _dailySwapLimit
    ) public onlyOwnerOrUpdater {
        dailySwapLimit = _dailySwapLimit;
    }

    function setDailySwapLimitUpdater(
        address _dailySwapLimitUpdater
    ) public onlyOwner {
        dailySwapLimitUpdater = _dailySwapLimitUpdater;
    }

    function setFeeReceiver(address _feeReceiver) public onlyOwnerOrUpdater {
        feeReceiver = _feeReceiver;
    }

    function setAutoRefresher(
        address _autoRefresher
    ) public onlyOwnerOrUpdater {
        autoRefresher = _autoRefresher;
    }

    function setApxgPrice(address _ApxgPrice) public onlyOwner {
        ApxgPrice = IApxgPrice(_ApxgPrice);
    }

    function setEthPrice(address _EthPrice) public onlyOwner {
        EthPrice = IEthPrice(_EthPrice);
    }

    function withdrawETH(address to, uint256 amount) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Call failed");
    }

    function withdrawAPXG(address to, uint256 amount) external onlyOwner {
        SafeERC20.safeTransfer(APXG, to, amount);
    }

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAPXGBalance() public view returns (uint256) {
        return APXG.balanceOf(address(this));
    }

    function claimAllGas() external onlyOwner {
        BLAST.claimAllGas(address(this), msg.sender);
    }

    function claimAllYield() external onlyOwner {
        BLAST.claimAllYield(address(this), msg.sender);
    }

    fallback() external payable {}

    receive() external payable {}
}
