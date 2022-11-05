// SPDX-License-Identifier: MIT

/*
 ██████   ██
░█░░░░██ ░░            █████
░█   ░██  ██ ███████  ██░░░██  ██████
░██████  ░██░░██░░░██░██  ░██ ██░░░░██
░█░░░░ ██░██ ░██  ░██░░██████░██   ░██
░█    ░██░██ ░██  ░██ ░░░░░██░██   ░██
░███████ ░██ ███  ░██  █████ ░░██████
░░░░░░░  ░░ ░░░   ░░  ░░░░░   ░░░░░░

https://tomorrowland.love
*/

pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 * @title BingoToken
 * @dev The name of the token issued by Tomorrowland is: $BINGO
        Token agreement: $BINGO is based on the issuance on the Binance Smart Chain agreement
        Total amount of token: 10,000,000,000  (10 billion pieces)
*/
contract BingoToken is Context, IERC20, Ownable{

    using Address for address;
    using SafeMath for uint;

    string private _name = 'TomorrowLand';
    string private _symbol = '$Bingo';
    uint8 private _decimals = 18;
    uint private _totalSupply;
    uint private _totalFee;

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping (address => uint) public _excludeFee;
    mapping (address => uint) public _banListMap;
    mapping (address => uint) public _totalReceiveFeeMap;
    mapping (address => uint) public _feeRateMap;
    mapping (address => uint) public _swapAddrMap;

    address public _jackpotPoolAddr =  0xa93829524E0213e3FA261C353e2dB400779e2dd6;
    address public _clubRewardAddr = 0xe7F1EE9d254a1836E7313F5E1571BF02b347c30C;
    address public _miningRewardAddr = 0xcbaF099D0544E7a7a2cdc08D69Ece4E53Fb75e11;
    address public _groupAddr = 0x74D1DDBDCFd0068EDebfc4b366dB8cc86430d69B;
    address public _IDOAddr = 0x2e8E8eeb390c7021d749C23fBF88Cb19B103fa61;
    address public _institutionalFinancingAddr = 0xF411724b82BaD44d125983409dD407E8285707EB;
    address public _transferFeeReceiveAddr = 0xa93829524E0213e3FA261C353e2dB400779e2dd6;
    address public _specialRewardAddr = 0xF536F30811FD6b1122a161e07f355D42662d1E1B;
    address public _deadAddr = 0x000000000000000000000000000000000000dEaD;

    bool _pauseTransfer = true;

    event PauseTransfer(bool isPause);
    event SetBanListEvent(address addr, uint val);
    event SetExcludeFeeEvent(address addr, uint val);
    event SetJackpotFeeEvent(uint fee);
    event SetMiningRewardFeeEvent(uint fee);
    event SetDeadFeeEvent(uint fee);
    event SetTransferFeeEvent(uint fee);
    event SetSwapAddrMapEvent(address addr, uint val);
    event SetGroupAddrEvent(address addr);
    event SetInstitutionalFinancingAddrEvent(address addr);
    event SetJackPotPoolAddrEvent(address addr);
    event SetIDOAddrEvent(address addr);
    event SetMiningRewardAddrEvent(address addr);

    /**
     * @dev constructor
     */
    constructor () {
        //total supply 10,000,000,000
        _mint(_groupAddr, 600_000_000 ether);
        _mint(_institutionalFinancingAddr, 400_000_000 ether);
        _mint(_jackpotPoolAddr, 3_000_000_000 ether);
        _mint(_IDOAddr, 2_000_000_000 ether);
        _mint(_clubRewardAddr, 500_000_000 ether);
        _mint(_specialRewardAddr, 500_000_000 ether);
        _mint(_miningRewardAddr, 3_000_000_000 ether);

        //init buyFeeRateMap
        _feeRateMap[_jackpotPoolAddr] = 2;
        _feeRateMap[_miningRewardAddr] = 1;
        _feeRateMap[_deadAddr] = 2;
        _feeRateMap[_groupAddr] = 1;
        _feeRateMap[_transferFeeReceiveAddr] = 0;

        //init whiteList
        _excludeFee[_groupAddr] = 1;
        _excludeFee[_institutionalFinancingAddr] = 1;
        _excludeFee[_jackpotPoolAddr] = 1;
        _excludeFee[_IDOAddr] = 1;
        _excludeFee[_miningRewardAddr] = 1;
        _excludeFee[_transferFeeReceiveAddr] = 1;
    }

    function _mint(address account, uint amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
}

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalFee() public view returns (uint256) {
        return _totalFee;
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint amount) internal{
        require(_pauseTransfer == false || sender == owner(), "ERC20: transfer is paused");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_banListMap[sender] == 0, "ERC20: sender be pulled black");
        require(_banListMap[recipient] == 0, "ERC20: recipient be pulled black");

        _balances[sender] = _balances[sender].sub(amount);

        if(recipient == _deadAddr){
            _totalSupply -= amount;
            emit Transfer(sender, _deadAddr, amount);
            return;
        }

        uint addValue = amount;
        uint onePercent = amount.div(100);

        if(_swapAddrMap[recipient] == 1 && _excludeFee[sender] != 1){
            uint jackpotFee = onePercent.mul(_feeRateMap[_jackpotPoolAddr]);
            uint miningRewardFee = onePercent.mul(_feeRateMap[_miningRewardAddr]);
            uint deadFee = onePercent.mul(_feeRateMap[_deadAddr]);
            uint groupFee = onePercent.mul(_feeRateMap[_groupAddr]);

            _totalReceiveFeeMap[_jackpotPoolAddr] = _totalReceiveFeeMap[_jackpotPoolAddr].add(jackpotFee);
            _totalReceiveFeeMap[_miningRewardAddr] = _totalReceiveFeeMap[_miningRewardAddr].add(miningRewardFee);
            _totalReceiveFeeMap[_deadAddr] = _totalReceiveFeeMap[_deadAddr].add(deadFee);
            _totalReceiveFeeMap[_groupAddr] = _totalReceiveFeeMap[_groupAddr].add(groupFee);

            _balances[_jackpotPoolAddr] = _balances[_jackpotPoolAddr].add(jackpotFee);
            _balances[_miningRewardAddr] = _balances[_miningRewardAddr].add(miningRewardFee);
            _balances[_deadAddr] = _balances[_deadAddr].add(deadFee);
            _balances[_groupAddr] = _balances[_groupAddr].add(groupFee);

            uint currentFee = jackpotFee.add(miningRewardFee).add(deadFee).add(groupFee);
            _totalFee = _totalFee.add(currentFee);
            addValue = addValue.sub(currentFee);

            _totalSupply -= deadFee;
            _balances[recipient] = _balances[recipient].add(addValue);
            emit Transfer(sender, recipient, amount);
            return;
        }

        if(_excludeFee[sender] != 1 && _excludeFee[recipient] != 1){
            uint transferFee = onePercent.mul(_feeRateMap[_transferFeeReceiveAddr]);
            _totalReceiveFeeMap[_transferFeeReceiveAddr] = _totalReceiveFeeMap[_transferFeeReceiveAddr].add(transferFee);
            _balances[_transferFeeReceiveAddr] = _balances[_transferFeeReceiveAddr].add(transferFee);
            _totalFee = _totalFee.add(transferFee);
            addValue = addValue.sub(transferFee);

            _balances[recipient] = _balances[recipient].add(addValue);
            emit Transfer(sender, recipient, amount);
            return;
        }

        _balances[recipient] = _balances[recipient].add(addValue);
        emit Transfer(sender, recipient, amount);
    }

    function setBanList(address addr, uint val) onlyOwner public returns (bool) {
        require(addr != address(0), "ERC20: cannot set zero address");
        _banListMap[addr] = val;
        emit SetBanListEvent(addr, val);
        return true;
    }

    function setExcludeFee(address account, uint val) onlyOwner public returns (bool) {
        require(account != address(0), "ERC20: cannot set zero address");
        _excludeFee[account] = val;
        emit SetExcludeFeeEvent(account, val);
        return true;
    }

    function pauseTransfer(bool isPause) onlyOwner external returns (bool){
        _pauseTransfer = isPause;
        emit PauseTransfer(isPause);
        return true;
    }

    function setJackpotFee(uint fee) onlyOwner external returns (bool) {
        _feeRateMap[_jackpotPoolAddr] = fee;
        emit SetJackpotFeeEvent(fee);
        return true;
    }

    function setMiningRewardFee(uint fee) onlyOwner external returns (bool) {
        _feeRateMap[_miningRewardAddr] = fee;
        emit SetMiningRewardFeeEvent(fee);
        return true;
    }

    function setDeadFee(uint fee) onlyOwner external returns (bool) {
        _feeRateMap[_deadAddr] = fee;
        emit SetDeadFeeEvent(fee);
        return true;
    }

    function setTransferFee(uint fee) onlyOwner external returns (bool) {
        _feeRateMap[_transferFeeReceiveAddr] = fee;
        emit SetTransferFeeEvent(fee);
        return true;
    }

    function setSwapAddrMap(address addr, uint val) onlyOwner external returns (bool) {
        require(addr != address(0), "ERC20: cannot set zero address");
        _swapAddrMap[addr] = val;
        emit SetSwapAddrMapEvent(addr, val);
        return true;
    }

    function setGroupAddr(address addr) onlyOwner external returns (bool) {
        require(addr != address(0), "ERC20: cannot set zero address");
        _groupAddr = addr;
        emit SetGroupAddrEvent(addr);
        return true;
    }

    function setInstitutionalFinancingAddr(address addr) onlyOwner external returns (bool) {
        require(addr != address(0), "ERC20: cannot set zero address");
        _institutionalFinancingAddr = addr;
        emit SetInstitutionalFinancingAddrEvent(addr);
        return true;
    }

    function setJackpotPoolAddr(address addr) onlyOwner external returns (bool) {
        require(addr != address(0), "ERC20: cannot set zero address");
        _jackpotPoolAddr = addr;
        emit SetJackPotPoolAddrEvent(addr);
        return true;
    }

    function setIDOAddr(address addr) onlyOwner external returns (bool) {
        require(addr != address(0), "ERC20: cannot set zero address");
        _IDOAddr = addr;
        emit SetIDOAddrEvent(addr);
        return true;
    }

    function setMiningRewardAddr(address addr) onlyOwner external returns (bool) {
        require(addr != address(0), "ERC20: cannot set zero address");
        _miningRewardAddr = addr;
        emit SetMiningRewardAddrEvent(addr);
        return true;
    }
}