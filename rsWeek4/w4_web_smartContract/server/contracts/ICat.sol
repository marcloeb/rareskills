// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICat {
    struct Cat {
        uint256 id;
        string name;
        bool tradable;
        uint256[] requiresBurning;
        uint256 lastTouched;
    }

    function getCat(uint256 _tokenId) external view returns (Cat memory);

    function adminMint(address _to, uint256 _tokenId) external;

    function burnBatch(
        address _from,
        uint256[] memory _tokenIds,
        uint256[] memory amounts
    ) external;

    function adminBalanceOf(address account, uint256 id) external view returns (uint256);
}
