// SPDX-License-Identifier: GPLv3

pragma solidity >=0.7.0 <0.9.0;

import './ITideBitSwapFactory.sol';
import './TransferHelper.sol';

import './ITideBitSwapRouter.sol';
import './TideBitSwapLibrary.sol';
import './SafeMath.sol';
import './IERC20.sol';
import './IWETH.sol';

contract ecHarvest {
  using SafeMath for uint;

  address public immutable WETH;
  address private immutable owner;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'TideBitSwapRouter: EXPIRED');
    _;
  }

  constructor(address _WETH) {
    WETH = _WETH;
    owner = msg.sender;
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, address[] memory path, address _to, address factory) internal virtual {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = TideBitSwapLibrary.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? TideBitSwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
      ITideBitSwapPair(TideBitSwapLibrary.pairFor(factory, input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }
  
  function deposit() 
    external
    virtual
    payable
  {
    IWETH(WETH).deposit{value: msg.value}();
  }
  
  function withdraw(
    uint amount
  )
    external
    virtual
  {
    IWETH(WETH).withdrawTo(payable(owner), amount);
  }

  function balance()
    external
    view
  returns (uint) {
     uint contractBalance = IWETH(WETH).balanceOf(address(this));
     return contractBalance;
  }
  
  function harvest(
    address factory0,
    address factory1,
    address token,
    uint amount
  )
    external
    virtual
  {
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = token;
    uint[] memory amounts = TideBitSwapLibrary.getAmountsOut(factory0, amount, path);

    assert(IWETH(WETH).transfer(TideBitSwapLibrary.pairFor(factory0, WETH, token), amounts[0]));
    _swap(amounts, path, address(this), factory0);
    
    
    path[0] = token;
    path[1] = WETH;
    uint amountIn = IERC20(token).balanceOf(address(this));
    amounts = TideBitSwapLibrary.getAmountsOut(factory1, amountIn, path);
    TransferHelper.safeTransfer(
      token, TideBitSwapLibrary.pairFor(factory1, token, WETH), amounts[0]
    );
    _swap(amounts, path, address(this), factory1);
    
    require(amounts[amounts.length - 1] > amount);
  }
}