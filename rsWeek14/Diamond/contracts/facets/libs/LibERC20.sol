/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC20 {
    // each facet gets their own struct to store state into
    bytes32 constant ERC20_STORAGE_POSITION =
        keccak256("facet.erc20.diamond.storage");

    /**
     * @notice ERC20 storage for the ERC20 facet
     */
    struct Storage {
        uint256 _totalSupply;
        mapping(address => uint256) _balances;
        mapping(address => mapping(address => uint256)) _allowances;
    }

    // access erc20 storage via:
    function getStorage() internal pure returns (Storage storage ds) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    // @dev due to function naming clashes in the diamond we need to implement our own "namespace" here and prepend "erc20".
    function erc20mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _erc20_beforeTokenTransfer(address(0), account, amount);

        Storage storage ds = getStorage();

        ds._totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            ds._balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _erc20_afterTokenTransfer(address(0), account, amount);
    }

    function erc20balanceOf(address account) internal view returns (uint256) {
        Storage storage ds = getStorage();
        return ds._balances[account];
    }

    function erc20transferFrom(
        address spender,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _erc20_spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function erc20transfer(address to, uint256 amount) internal returns (bool) {
        address owner = _msgSender();

        _transfer(owner, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _erc20_beforeTokenTransfer(from, to, amount);

        Storage storage ds = getStorage();

        uint256 fromBalance = ds._balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            ds._balances[from] = fromBalance - amount;
            ds._balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _erc20_afterTokenTransfer(from, to, amount);
    }

    function erc20approve(
        address owner,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        _erc20_approve(owner, spender, amount);
        return true;
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function _erc20_transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _erc20_beforeTokenTransfer(from, to, amount);

        Storage storage ds = getStorage();

        uint256 fromBalance = ds._balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            ds._balances[from] = fromBalance - amount;
            ds._balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _erc20_afterTokenTransfer(from, to, amount);
    }

    function _erc20_spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = _erc20allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _erc20_approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _erc20allowance(
        address owner,
        address spender
    ) internal view returns (uint256) {
        Storage storage ds = getStorage();
        return ds._allowances[owner][spender];
    }

    function _erc20_approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        Storage storage ds = getStorage();

        ds._allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _erc20_beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _erc20_afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}
