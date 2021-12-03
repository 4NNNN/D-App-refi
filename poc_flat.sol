// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/tokenHelpers/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/tokenHelpers/IERC20Metadata.sol

// : MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/utils/Context.sol

// : MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/tokenHelpers/RERC20.sol

// : MIT

pragma solidity ^0.8.0;



interface ComptrollerInterface {
    
    /**
     * @notice Marker function used for light validation when updating the comptroller of a market
     * @dev Implementations should simply return true.
     * @return true
     */
    function liquidationIncentiveMantissa() external view returns (uint);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimComp(address holder) external;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external view returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);
}

/**
 * @dev Implementation of the {IERC20} interface NOTE: + Changes in ONLY _transfer function/variable declarations.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal userCSupply;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /// @notice Instance of Refi's controller
    ComptrollerInterface RefiTroller;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_,address refitroller) {
        _name = name_;
        _symbol = symbol_;
        RefiTroller = ComptrollerInterface(refitroller);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return userCSupply[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint allowed = RefiTroller.transferAllowed(address(this), sender, recipient, amount);
        if (allowed != 0) {
            revert('Shortfall');
        }

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = userCSupply[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            userCSupply[sender] = senderBalance - amount;
        }
        userCSupply[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        userCSupply[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = userCSupply[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            userCSupply[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/utils/Ownable.sol

// : MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/ErrorReporter8.sol

pragma solidity ^0.8.0;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}


// File contracts/utils/Pausable.sol

// : MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event PausedAll(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event UnpausedAll(address account);

    bool private _paused;

    bool private _pausedAll;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
        _pausedAll = false;
    }

    /**
     * @dev Returns true if the contract's function is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function pausedAll() public view virtual returns (bool) {
        return _pausedAll;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPausedAll() {
        require(!pausedAll(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pauseAll() internal virtual whenNotPaused {
        _pausedAll = true;
        emit PausedAll(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpauseAll() internal virtual whenPaused {
        _pausedAll = false;
        emit UnpausedAll(_msgSender());
    }
}


// File contracts/utils/ReentrancyGuard.sol

// : MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/Ievaluator.sol

//: MIT
pragma solidity ^0.8.0; 

interface Ieval{
    function borrowCheck(address user,uint amount) external view returns (uint);

    function vaultLTV() external returns(uint);

    function withdrawCheck(address account,uint cAmount) external returns (uint);

    function evalCommit(address user,uint initialH, uint finalH) external view returns (uint rewards,uint lastRewards);
}


// File contracts/Ioracle.sol

//: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}


// File contracts/IrefiSwap.sol

//: MIT
pragma solidity ^0.8.0; 

interface IrSwap{
    function checkPrice(address token0,address token1) external view returns (uint24);
    function swap(address token0,address token1,uint amountIn) external returns (uint);
    function swapDaiforEth(uint amount) external returns (uint);
    function oracleMismatch() external view returns (bool);
}


// File contracts/poc.sol

//: MIT
pragma solidity ^0.8.0;




//import "./ISwapRouter.sol";





interface interfaceVault {
    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function setVaultFractionToInvest(uint256 numerator, uint256 denominator)
        external;

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerFullShare() external returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;

    function rebalance() external;
}

interface interfacePool {
    //view staked fUsdc
    function balanceOf(address) external returns (uint256);

    // stake funds
    function stake(uint256 amount) external;

    //Unstake funds
    function withdraw(uint256 amount) external;

    //Rewards
    function getReward() external;

    function exit() external; //exit from Expool and withdraw all along with this, get rewards

    //the rewards should be first transferred to this Expool, then get "notified" by calling `notifyRewardAmount`
    function notifyRewardAmount(uint256 reward) external;

    function migrate() external;
}

interface error {
    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }
}

interface CErc20 is error {
    //  enum MathError {
    //     NO_ERROR,
    //     DIVISION_BY_ZERO,
    //     INTEGER_OVERFLOW,
    //     INTEGER_UNDERFLOW
    // }

    function borrowIndex() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (MathError, uint256);
}

interface IchainlinkComp {
    function latestAnswer() external returns (uint256);

    function decimals() external returns (uint8);
}

interface CEth is error, IERC20 {
    function mint() external payable;

    //function balanceOf(address owner) external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}

contract poc is
    ERC20,
    Ownable,
    error,
    TokenErrorReporter,
    Pausable,
    ReentrancyGuard
{
    //mapping(address=>uint) userDeposits;
    /// @notice Instance of Compound's ceth
    CEth Exceth;
    /// @notice Instance of Compound's Excdai
    CErc20 Excdai;
    /// @notice Instance of DAI token
    IERC20Metadata constant dai =
        IERC20Metadata(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    /// @notice Instance of Compound's Oracle
    IOracle Exoracle;
    /// @notice Instance of Compound's Comptroller
    ComptrollerInterface ExCompTroller;
    /// @notice Instance of Harvest.finance's Expool
    interfacePool Expool;
    /// @notice The number of harvest don till now
    uint256 public index;
    /// @notice address of Compound's Comp Tokens
    address public constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    /// @notice Instance of Harvest.finance's FARM token
    IERC20 constant farm = IERC20(0xa0246c9032bC3A600820415aE600c6388619A14D);
    /// @notice Instance of Harvest.finance's ExfUSDC token
    IERC20 ExfUSDC = IERC20(0xab7FA2B2985BCcfC13c6D86b1D5A17486ab1e04C);
    /// @notice Instance of Harvest.finance's USDC Vault
    interfaceVault Exvault;
    /// @notice Minimum amount of USDC required to Deposit on Harvest.Finance
    //uint256 public min_depo = 1000000;
    /**
     * @notice Container for Harvest Information
     * @member priceEth Conversion factor from Eth to Dai
     * @member lendingAmt amount of profit obtained from lender protocol
     * @member yieldAmt amount of profit earned from Yield protocol
     * @membersupplyEth Total Eth supplied to the lender
     * @member blockNo block number at the time of harvest
     * @member tLTV target LTV of Vault at the time of Harvest
     * @member reserveAmount reserve Factor of the Vault at the time of harvest
     * @member exchangeRate the factor which multiplies with cEth to give Eth amount (scaled to 10^18)
     * @member totalBorrowsEth total borrow Amount taken by the users
     */
    struct harvestSnapshot {
        uint256 priceEth;
        uint256 lendingAmt;
        uint256 yieldAmt;
        uint256 supplyEth;
        uint256 blockNo;
        uint256 tLTV;
        uint256 reserveAmount;
        uint256 exchangeRate;
        uint256 totalBorrowsEth;
    }

    //mapping(address => uint256) public userBorrow;
    //uint256 public totalUserBorrows;
    /**
     * @notice Container for user earnings in a harvest information
     * @member uptillHarvest till which harvest the data has been calculated
     * @member positionLender User's share of the earning from lender protocol
     * @member positionYield User's share of the earning from Yield protocol
     */
    struct data {
        uint256 uptillHarvest;
        // uint256 positionLender;
        // uint256 positionYield;
        uint256 rewards;
        uint256 lastRewards;
        // uint256 lastLender;
        // uint256 lastYield;
        uint256 repaid;
    }
    /// @notice Earnings of user in all the harvests
    mapping(address => data) public userData;
    /// @notice Array string Data of Each Harvest
    harvestSnapshot[] public harvestData;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) public accountBorrows;
    /**
     * @notice Total outstanding borrow balances of users
     */
    BorrowSnapshot public totalUserBorrows;
    struct Store {
        uint256 tLTV;
        uint256 maxLTV;
        uint256 minLTV;
        uint256 min_depo;
        uint256 reserveFactor;
        // Mainnet uint min_conversion;
    }
    //Set maximum, minimum and target LTV for the Vault
    Store public store;

    IrSwap rswap;

    address constant weth = 0x0537F3f7fF3c15A63B0CF7EC155E54FF91C0754D;

    IchainlinkComp constant compOracle =
        IchainlinkComp(0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5);

    /// @notice Stored LTV of Vault
    uint256 public vaultLTVStored;

    //events

    event ConfigUpdated(
        uint256 tLTV,
        uint256 maxLTV,
        uint256 minLTV,
        uint256 minimum_deposit_Harvest
    );
    event refitrollerChanged(address newcontroller);

    event raccrued(uint256 principal, uint256 interestIndex);

    event deposited(address user, uint256 amount, uint256 cAmount);

    event withdrawn(address user, uint256 amount, uint256 cAmount);

    event claimedVault(uint256 time, uint256 comp, uint256 farm);

    event harvested(
        uint256 harvestNo,
        uint256 priceEthusdc,
        uint256 lenderUSDC,
        uint256 yieldUSDC,
        uint256 supplyEth,
        uint256 tltv,
        uint256 reserveEarned,
        uint256 exchangeRate,
        uint256 totalBorrowsEthUsers
    );

    event borrowed(address user, uint amount);

    address[] public users;

    uint256 public lastHarvest;

    uint256 public invested;
    //Note: edit remaining
    Ieval eval;

    address stabilityUserContract;

    constructor()
        ERC20("MTFi", "MTFI", 0x90339ddb33C2B71E4E6F92Bbbe9FB2546E285F0C)
    {
        initialize();
    }

    /// @notice This sets the initial values in the contract
    function initialize() internal {
        RefiTroller = ComptrollerInterface(
            0x90339ddb33C2B71E4E6F92Bbbe9FB2546E285F0C
        );
        Exceth = CEth(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
        Exoracle = IOracle(0x6D2299C48a8dD07a872FDd0F8233924872Ad1071);
        ExCompTroller = ComptrollerInterface(
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        );
        address[] memory any = new address[](2);
        any[0] = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
        any[1] = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
        Excdai = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        ExCompTroller.enterMarkets(any);
        harvestData.push();
        index = 0;
        Exvault = interfaceVault(0xab7FA2B2985BCcfC13c6D86b1D5A17486ab1e04C);
        Expool = interfacePool(0x15d3A64B2d5ab9E152F16593Cdebc4bB165B5B4A);
        store.tLTV = 5 * 10**17; // 0.5
        store.maxLTV = 7 * 10**17; // 0.7
        store.minLTV = 3 * 10**17; //0.3
        store.min_depo = 10 * 10**6; // 10USDC
        store.reserveFactor = 10**16; //1%
        rswap = IrSwap(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    }

    receive() external payable {
        //emit Received(msg.sender, msg.value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pauseAll() public onlyOwner {
        _pauseAll();
        _pause();
    }

    function unpauseAll() external onlyOwner {
        _unpauseAll();
        _unpause();
    }

    /**
     * @notice changes current refitroller
     * @param newCompt the address of new implementation
     */
    function changeAddresses(address newCompt,address newrs,address _eval) external onlyOwner {
        RefiTroller = ComptrollerInterface(newCompt);
        stabilityUserContract = newrs;
        eval = Ieval(_eval);
        emit refitrollerChanged(newCompt);
    }

    /**
     * @notice Sets the values of LTVs
     * @param tLTV target LTV of Vault, This is the LTV we want the Vault to hold at maximum times
     * @param maxLTV Maximum value of LTV, If vaultLTV exceeds this value, Rebalance needs to be triggered
     * @param minLTV Minimum value of LTV, If vaultLTV preceeds this value, Rebalance needs to be triggered
     */
    function setConfig(
        uint256 tLTV,
        uint256 maxLTV,
        uint256 minLTV,
        uint256 min_depo
    )
        external
        //, uint min_conversion
        onlyOwner
    {
        store.tLTV = tLTV;
        store.maxLTV = maxLTV;
        store.minLTV = minLTV;
        store.min_depo = min_depo;
        // store.min_conversion = min_conversion;
        emit ConfigUpdated(tLTV, maxLTV, minLTV, min_depo);
    }

    //receive () external payable {
    //    _deposit(msg.sender,msg.value);
    // }

    // function transfer
    /**
     * @notice Commits Users and applies accrued interest to total Borrows
     * @param user Address of the user to be committed
     * @dev need to be called before any User operation
     */
    function _beforeEach(address user) internal whenNotPausedAll {
        raccrueInterest();
        _commitUser(user, index);
        //Auto Repayment
        uint256 borrowBal = borrowBalanceCurrent(user);
        if (borrowBal > 0) {
            if (
                userData[user].rewards - userData[user].lastRewards >= borrowBal
            ) {
                accountBorrows[user].principal = 0;
                userData[user].rewards -= borrowBal;
            } else {
                userData[user].rewards = userData[user].lastRewards;
                accountBorrows[user].principal -= (userData[user].rewards -
                    userData[user].lastRewards);
            }
        }
    }

    /**
     * @notice Applies accrued interest to total borrows
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage./
     */
    function raccrueInterest() public {
        uint256 err = Excdai.accrueInterest();
        if (err != uint256(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            //revert('Compound accrue error');
        }
        uint256 principalTimesIndex;
        uint256 result;
        uint256 borrowIndex = Excdai.borrowIndex();
        if (totalUserBorrows.principal == 0) {
            return;
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        principalTimesIndex = totalUserBorrows.principal * borrowIndex;

        result = (principalTimesIndex / totalUserBorrows.interestIndex);

        totalUserBorrows.interestIndex = borrowIndex;
        totalUserBorrows.principal = result;
        //return (MathError.NO_ERROR, result);
        emit raccrued(result, borrowIndex);
    }

    /**
     * @notice Evaluates current borrow balance of a user
     * @param account The address whose balance should be calculated
     * @return borrow balance of the user
     */

    function borrowBalanceCurrent(address account) public returns (uint256) {
        raccrueInterest();
        uint256 borrowIndex = Excdai.borrowIndex();
        accountBorrows[account].principal = borrowBalanceStored(account);
        accountBorrows[account].interestIndex = borrowIndex;
        return accountBorrows[account].principal;
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account)
        public
        view
        returns (uint256)
    {
        (MathError err, uint256 result) = borrowBalanceStoredInternal(account);
        require(
            err == MathError.NO_ERROR,
            "borrowBalanceStored: borrowBalanceStoredInternal failed"
        );
        return result;
    }

    /**swapRouter
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account)
        internal
        view
        returns (MathError, uint256)
    {
        /* Note: we do not assert that the market is up to date */
        //MathError mathErr;
        uint256 principalTimesIndex;
        uint256 result;
        uint256 borrowIndex = Excdai.borrowIndex();

        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        principalTimesIndex = borrowSnapshot.principal * borrowIndex;

        result = (principalTimesIndex / borrowSnapshot.interestIndex);

        return (MathError.NO_ERROR, result);
    }

    /**
     * @notice Returns the current LTV of the Vault
     * @return The calculated LTV scaled by 10^18
     */
    function vaultLTVmantissa() public returns (uint256) {
        // (uint256 err, uint256 liquidity, uint256 shortfall) = ExCompTroller
        //     .getAccountLiquidity(address(this));

        vaultLTVStored = eval.vaultLTV();
        return vaultLTVStored;
    }

    /**
     * @notice Sender Supplies Eth and Receives Reth in return
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     */
    function deposit() public payable {
        _beforeEach(msg.sender);
        _deposit(msg.sender, msg.value);
    }

    /**
     * @notice Sender Supplies Eth and Receives Reth in return
     * @param account The User Address Supplying Eth
     * @param amount Amount of Eth that User Supplied
     */
    function _deposit(address account, uint256 amount) internal {
        users.push(account);
        uint256 init = Exceth.balanceOf(address(this));
        Exceth.mint{value: amount}();
        uint256 camt = Exceth.balanceOf(address(this)) - init;
        _mint(account, camt);
        //userCSupply[account] += camt;
        emit deposited(account, amount, camt);
    }

    /**
     * @notice Sender redeems Rtokens in exchanges of unserlying asset
     * @param cAmount The amount of Ctokens to be Redeemed
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     */
    function withdraw(uint256 cAmount) public {
        _beforeEach(msg.sender);
        _withdraw(msg.sender, cAmount);
    }

    /**
     * @notice Sender redeems Rtokens in exchanges of unserlying asset
     * @param cAmount The amount of Ctokens to be Redeemed
     * @param account The Account who wants to Redeem
     */
    function _withdraw(address account, uint256 cAmount) internal {
        uint256 shortfall = eval.withdrawCheck(account, cAmount);
        if (shortfall > 0) {
            _withdrawPool(shortfall);
            require(
                dai.balanceOf(address(this)) > shortfall,
                "insuff from pool"
            );
            dai.approve(address(Excdai), 0);
            dai.approve(address(Excdai), shortfall);
            Excdai.repayBorrow(shortfall );
        }
        _burn(account, cAmount);
        require(Exceth.redeem(cAmount) == 0, "EXT_COMP_ERROR");
        //userCSupply[account] -= cAmount;
        uint256 amount = address(this).balance;
        (bool sent, ) = payable(account).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        emit withdrawn(account, amount, cAmount);
        // } else {
        //     //revert("repay");
        // }
        // return err;
    }

    function _withdrawPool(uint256 amount) internal {
        uint256 amountf = ((amount ) * ExfUSDC.totalSupply()) /
            Exvault.underlyingBalanceWithInvestment();
        invested -= amount;
        Expool.withdraw(amountf);
        ExfUSDC.approve(address(Exvault), 0);
        ExfUSDC.approve(address(Exvault), amountf);
        Exvault.withdraw(amountf);
    }

    /**
     * @notice Initials a new Harvest if any of the condition is statisfied for more infomation refer Documentation
     */
    function harvest() public whenNotPaused {
        raccrueInterest();
        lastHarvest = block.timestamp;
        // uint256 temp = IERC20(comp).balanceOf(address(this));
        uint256 amount = (Expool.balanceOf(address(this)) *
            Exvault.underlyingBalanceWithInvestment()) / ExfUSDC.totalSupply();
        amount = amount - invested;
        invested += amount;
        // uint256 temp2 = farm.balanceOf(address(this))
        IERC20(comp).approve(
            address(rswap),
            IERC20(comp).balanceOf(address(this))
        );
        uint256 amountOut = rswap.swap(
            comp,
            address(dai),
            IERC20(comp).balanceOf(address(this))
        );

        farm.approve(address(rswap), farm.balanceOf(address(this)));
        uint256 amountOut2 = rswap.swap(
            address(farm),
            address(dai),
            farm.balanceOf(address(this))
        );

        _capture(amountOut, amountOut2 + amount);
        _commitUser(stabilityUserContract, index);
        if (
            dai.balanceOf(address(this)) <
            userData[stabilityUserContract].rewards
        ) {
            _withdrawPool(
                userData[stabilityUserContract].rewards -
                    dai.balanceOf(address(this))
            );
        }
        dai.approve(address(rswap), userData[stabilityUserContract].rewards);
        uint256 amountEth = rswap.swapDaiforEth(
            userData[stabilityUserContract].rewards
        );
        _deposit(stabilityUserContract, amountEth);
    }

    function claimRewards() external {
        ExCompTroller.claimComp(address(this));
        Expool.getReward();
        emit claimedVault(
            block.timestamp,
            IERC20(comp).balanceOf(address(this)),
            farm.balanceOf(address(this))
        );
    }

    /**
     * @notice Captures and stores data at the time of Harvest
     * @param comprewards The amount earned through lender protocol
     * @param farmrewards The amount earned through yield protocol
     */
    function _capture(uint256 comprewards, uint256 farmrewards) internal {
        harvestData[index] = harvestSnapshot({
            priceEth: (Exoracle.getUnderlyingPrice(address(Exceth)) * 10**18) /
                Exoracle.getUnderlyingPrice(address(Excdai)),
            lendingAmt: comprewards,
            yieldAmt: farmrewards,
            supplyEth: Exceth.balanceOfUnderlying(address(this)),
            blockNo: block.timestamp,
            tLTV: store.tLTV,
            reserveAmount: harvestData[index - 1].reserveAmount +
                (farmrewards * store.reserveFactor) /
                10**18,
            exchangeRate: Exceth.exchangeRateCurrent(),
            totalBorrowsEth: totalUserBorrows.principal *
                harvestData[index].priceEth *
                10**12
        });

        index++;
        harvestData.push();
        emit harvested(
            index - 1,
            harvestData[index - 1].priceEth,
            comprewards,
            farmrewards,
            harvestData[index - 1].supplyEth,
            store.tLTV,
            harvestData[index - 1].reserveAmount,
            harvestData[index - 1].exchangeRate,
            harvestData[index - 1].totalBorrowsEth
        );
    }

    function claimUser() external {
        _beforeEach(msg.sender);
        uint256 amountTotal = userData[msg.sender].rewards -
            userData[msg.sender].lastRewards;
        require(amountTotal > 0, "No rewards");

        if (dai.balanceOf(address(this)) < amountTotal) {
            _withdrawPool(amountTotal - dai.balanceOf(address(this)));
        }
        dai.transfer(msg.sender, amountTotal);
    }

    function commitUsers(address[] memory userToCommit, uint256 tillHarvest)
        external
    {
        for (uint256 i = 0; i < userToCommit.length; i++) {
            _commitUser(userToCommit[i], tillHarvest);
        }
        //rewards
    }

    function _commitUser(address user, uint256 tillH) internal {
        if (userData[user].uptillHarvest < tillH) {
            (userData[user].rewards,userData[user].lastRewards) = eval.evalCommit(user, userData[user].uptillHarvest, tillH);
            userData[user].uptillHarvest = tillH;
        }
    }

    function borrow(uint256 amount) external whenNotPaused {
        _beforeEach(msg.sender);

        _borrow(msg.sender, amount);
    }

    function _borrow(address user, uint256 amount) internal returns (uint256) {
        uint256 liquidity = eval.borrowCheck(user,amount);
        require(liquidity > 0, "error getting liquidity");
        uint256 borrowIndex = Excdai.borrowIndex();
        Excdai.borrow(amount);
        //userBorrow[user] += amount / 10**12;
        //harvestData[index].totalBorrowsEth += amount / 10**12;
        totalUserBorrows.principal += amount ;
        totalUserBorrows.interestIndex = borrowIndex;
        accountBorrows[user].principal += amount ;
        accountBorrows[user].interestIndex = borrowIndex;
        //totalBorrows = vars.totalBorrowsNew;
        dai.transfer(user, amount);
        emit borrowed(user,amount);
        return uint256(Error.NO_ERROR);
    }

    function takeLoan(uint256 amountOut)
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        _beforeEach(msg.sender);
        _deposit(msg.sender, msg.value);
        return _borrow(msg.sender, amountOut);
    }

    //uint256 result1;

    function rebalance() external whenNotPaused {
        raccrueInterest();
        uint256 currentLTV = vaultLTVmantissa();
        uint256 bal = dai.balanceOf(address(this));
        if (currentLTV >= store.maxLTV) {
            uint256 currentCollateral = (Exceth.balanceOfUnderlying(
                address(this)
            ) * Exoracle.getUnderlyingPrice(address(Exceth))) / 10**18;
            uint256 amountRequired = ((currentLTV - store.tLTV) *
                currentCollateral) / (store.tLTV );
            if (amountRequired <= bal) {
                dai.approve(address(Excdai), 0);
                dai.approve(address(Excdai), amountRequired);
                Excdai.repayBorrow(amountRequired);
            } else {
                //fetch from defi
                amountRequired = amountRequired - dai.balanceOf(address(this));
                invested -= amountRequired;
                require(
                    (ExfUSDC.balanceOf(address(this)) *
                        Exvault.underlyingBalanceWithInvestment()) /
                        ExfUSDC.totalSupply() >=
                        amountRequired,
                    "Insufficient money in defi protocol"
                );
                _withdrawPool(amountRequired);
                Excdai.repayBorrow(amountRequired);
            }
        } else if (currentLTV <= store.minLTV) {
            uint256 currentCollateral = (Exceth.balanceOfUnderlying(
                address(this)
            ) * Exoracle.getUnderlyingPrice(address(Exceth))) / 10**18;
            uint256 amountRequired = ((store.tLTV - currentLTV) *
                currentCollateral) / (10**18);
            // (uint256 err, uint256 liquidity, uint256 shortfall) = ExCompTroller
            //     .getAccountLiquidity(address(this));
            // if (liquidity > 0 && err == 0 && shortfall == 0) {
            //     uint256 price = Exoracle.getUnderlyingPrice(address(Excdai));
            //     uint256 borrowamt = (liquidity * 10**18) / price;
            Excdai.borrow(amountRequired);
            bal += amountRequired;
            //require((liquidity*10**30/price)>=amount,'Not Sufficient Liquidity');
        } //else {
        //result1 = 1;
        //}
        if (bal > store.min_depo) {
            //require(bal>min_depo,"balance<min_deposit_amount");
            dai.approve(address(Exvault), 0);
            dai.approve(address(Exvault), bal);
            Exvault.deposit(bal);
            invested += bal;
            _stake();
        } //else {
        //    result1 = 2;
        //}
    }

    function _stake() internal {
        uint256 amt = ExfUSDC.balanceOf(address(this));
        ExfUSDC.approve(address(Expool), 0);
        ExfUSDC.approve(address(Expool), amt);
        Expool.stake(amt);
    }

    // function review() external view returns (uint256) {
    //     uint256 bal = dai.balanceOf(address(this));
    //     (uint256 err, uint256 liquidity, uint256 shortfall) = ExCompTroller
    //         .getAccountLiquidity(address(this));
    //     //check =err;
    //     if (liquidity > 0 && err == 0 && shortfall == 0) {
    //         uint256 price = Exoracle.getUnderlyingPrice(address(Excdai));
    //         uint256 borrowamt = (liquidity * 10**18) / price;
    //         //Excdai.borrow(borrowamt);
    //         bal += borrowamt;
    //         //require((liquidity*10**30/price)>=amount,'Not Sufficient Liquidity');
    //     }
    //     return bal;
    // }

    function repay(address user, uint256 amount) public {
        _beforeEach(msg.sender);
        _repay(msg.sender, user, amount);
    }

    function _repay(
        address payer,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        uint256 borrowIndex = Excdai.borrowIndex();
        accountBorrows[user].principal -= amount;
        accountBorrows[user].interestIndex = borrowIndex;
        //userBorrow[user] = 0;
        dai.transferFrom(payer, address(this), amount);
        //dai.approve(address(Excdai), 0);
        //dai.approve(address(Excdai), amount);
        //return Excdai.repayBorrow(amount);
        return amount;
    }

    function repaywithdraw(
        address user,
        uint256 amount,
        uint256 cAmount
    ) public {
        _beforeEach(user);
        _repay(msg.sender, user, amount);
        _withdraw(msg.sender, cAmount);
    }

    // function exit() external {
    //     _beforeEach(msg.sender);
    //     require(
    //         accountBorrows[msg.sender].principal == 0,
    //         "Please Repay your Borrow First"
    //     );
    //     uint256 amount = balanceOf(msg.sender);
    //     _burn(msg.sender, amount);
    //     Exceth.redeem(amount);
    //     (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
    //         ""
    //     );
    //     require(sent, "Failed to send Ether");
    // }

    function liquidateBorrow(address reciever,address borrower, uint256 repayAmount) external {
        (uint256 err, ) = liquidateBorrowInternal(reciever,borrower, repayAmount);
        require(uint256(Error.NO_ERROR) == err, "error in liquidation");
    }

    function liquidateBorrowInternal(address reciever,address borrower, uint256 repayAmount)
        internal
        nonReentrant
        returns (uint256, uint256)
    {
        raccrueInterest();

        return liquidateBorrowFresh(reciever, borrower, repayAmount);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function liquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) internal returns (uint256, uint256) {
        /* Fail if liquidate not allowed */
        uint256 allowed = RefiTroller.liquidateBorrowAllowed(
            address(this),
            address(this),
            liquidator,
            borrower,
            repayAmount
        );
        if (allowed != 0) {
            return (
                failOpaque(
                    Error.COMPTROLLER_REJECTION,
                    FailureInfo.LIQUIDATE_COMPTROLLER_REJECTION,
                    allowed
                ),
                0
            );
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return (
                fail(
                    Error.INVALID_ACCOUNT_PAIR,
                    FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER
                ),
                0
            );
        }

        /* Fail if repayAmount = 0 */
        if (repayAmount == 0) {
            return (
                fail(
                    Error.INVALID_CLOSE_AMOUNT_REQUESTED,
                    FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO
                ),
                0
            );
        }

        /* Fail if repayAmount = UnLimited */
        if (repayAmount == ~uint256(0)) {
            return (
                fail(
                    Error.INVALID_CLOSE_AMOUNT_REQUESTED,
                    FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX
                ),
                0
            );
        }

        /* Fail if repayBorrow fails */
        uint256 actualRepayAmount = _repay(liquidator, borrower, repayAmount);
        // if (repayBorrowError != uint256(Error.NO_ERROR)) {
        //     return (
        //         fail(
        //             Error(repayBorrowError),
        //             FailureInfo.LIQUIDATE_REPAY_BORROW_FRESH_FAILED
        //         ),
        //         0
        //     );
        // }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We calculate the number of collateral tokens that will be seized */
        (uint256 amountSeizeError, uint256 seizeTokens) = RefiTroller
            .liquidateCalculateSeizeTokens(
                address(Excdai),
                address(Exceth),
                actualRepayAmount
            );
        require(
            amountSeizeError == uint256(Error.NO_ERROR),
            "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED"
        );

        /* Revert if borrower collateral token balance < seizeTokens */
        require(
            this.balanceOf(borrower) >= seizeTokens,
            "LIQUIDATE_SEIZE_TOO_MUCH"
        );

        // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
        uint256 seizeError = seizeInternal(liquidator, borrower, seizeTokens);

        /* Revert if seize tokens fails (since we cannot be sure of side effects) */
        if (seizeError != uint256(Error.NO_ERROR)) {
            return (seizeError, 0);
        }
        return (uint256(Error.NO_ERROR), actualRepayAmount);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer cToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of cTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seizeInternal(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) internal returns (uint256) {
        /* Fail if seize not allowed */
        uint256 allowed = RefiTroller.seizeAllowed(
            address(this),
            address(this),
            liquidator,
            borrower,
            seizeTokens
        );
        if (allowed != 0) {
            return allowed;
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return (
                fail(
                    Error.INVALID_ACCOUNT_PAIR,
                    FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER
                )
            );
        }

        uint256 incentive = RefiTroller.liquidationIncentiveMantissa();
        uint256 val = ((incentive - 10**18) * seizeTokens) / incentive;
        userCSupply[borrower] = userCSupply[borrower] - seizeTokens;
        seizeTokens -= val;
        userCSupply[liquidator] += seizeTokens;
        userCSupply[stabilityUserContract] += val;
        return uint256(Error.NO_ERROR);
    }

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rTokenBalance = userCSupply[account];
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;

        MathError mErr;

        (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
        if (mErr != MathError.NO_ERROR) {
            return (uint256(Error.MATH_ERROR), 0, 0, 0);
        }

        (exchangeRateMantissa) = Exceth.exchangeRateStored();
        return (
            uint256(Error.NO_ERROR),
            rTokenBalance,
            borrowBalance,
            exchangeRateMantissa
        );
    }

    function claimReserve() external onlyOwner {
        uint256 amountTotal = harvestData[index - 1].reserveAmount;
        require(amountTotal > 0, "No rewards for claim");
        harvestData[index - 1].reserveAmount = 0;
        if (dai.balanceOf(address(this)) < amountTotal) {
            _withdrawPool(amountTotal - dai.balanceOf(address(this)));
        }
        invested -= amountTotal;
        dai.transfer(msg.sender, amountTotal);
    }

    function emergencyWithdraw() external {
        require(rswap.oracleMismatch(), "Require Mismatch");
        _pauseAll();
        _pause();
    }
}
