// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDean20 {

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 _balance);

    function transfer(address _to, uint256 _value) external returns (bool _success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);

    function approve(address _spender, uint256 _value) external returns (bool _success);

    function allowance(address _owner, address _spender) external view returns (uint256 _remaining);

    function mint(address _account, uint256 _amount) external;
}