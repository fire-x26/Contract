// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import  "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import  "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITokenFactory} from "./interfaces/ITokenFactory.sol";
import {IWETH} from "./interfaces/IWETH9.sol";
import {BondingCurve} from "./BondingCurve.sol";
import {Token} from "./Token.sol";
import {IProtocolRewards} from "./interfaces/IProtocolRewards.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Beam is ITokenFactory ,ReentrancyGuard, Ownable {

    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000e18; // 1B tokens
    uint256 internal  PRIMARY_MARKET_SUPPLY = 1_000e18; // 800M tokens
    uint256 internal constant SECONDARY_MARKET_SUPPLY = 200_000_000e18; // 200M tokens

    uint256 public constant TOTAL_FEE_BPS = 100; // 1%

    uint256 public constant TOKEN_CREATOR_FEE_BPS = 5000; // 50% (of TOTAL_FEE_BPS)
    uint256 public constant PROTOCOL_FEE_BPS = 2000; // 20% (of TOTAL_FEE_BPS)
    uint256 public constant PLATFORM_REFERRER_FEE_BPS = 1500; // 15% (of TOTAL_FEE_BPS)
    uint256 public constant ORDER_REFERRER_FEE_BPS = 1500; // 15% (of TOTAL_FEE_BPS)\

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public  MIN_ORDER_SIZE = 0.01 ether;

    uint160 public  POOL_SQRT_PRICE_X96_WETH_0 = 29009506658839187631412005462673;
    uint160 public  POOL_SQRT_PRICE_X96_TOKEN_0 = 216380850912335312768135958;
    uint24 internal  LP_FEE = 500;
    int24 internal  LP_TICK_LOWER = -886800;
    int24 internal  LP_TICK_UPPER = 886800;


    address public  protocolFeeRecipient;
    address public  protocolRewards;

    mapping(address => address) public tokenCreator;
    mapping(address => address) public platformReferrer;
    mapping(address => uint256) public ZetaAmount; // 记录每个代币地址对应的质押ZETA数量
    mapping(address => address) public poolAddress;

    // 记录每个代币地址的当前状态（未创建/募资中/交易中）
    mapping(address => TokenState) public tokens;

    address[] public tokenAddresses;

    // 代币合约的实现地址（用于代理克隆）
    address public tokenImplementation;
    //0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf
    address public immutable WZETA;
    //0x084d4177923f85C23C8BadB2400BAE6cA919caF3
    address public immutable nonfungiblePositionManager;
    //0x9b30CfbACD3504252F82263F72D6acf62bf733C2
    address public immutable swapRouter;

    // Uniswap V3路由器合约地址
    address public uniswapV3Router;

    // Uniswap V3工厂合约地址
    address public uniswapV3Factory;

    // 用于计算代币价格的曲线合约
    BondingCurve public bondingCurve;

    // 手续费百分比（以基点计算，1bp = 0.01%）
    uint256 public feePercent;

    // 累计收取的手续费（以Zeta计）
    uint256 public totalFee;

    struct BuyParams {
    uint256 totalCost;
    uint256 trueOrderSize;
    uint256 fee;
    uint256 refund;
    uint256 remainingEth;
    bool shouldGraduateMarket;
}

    constructor(address _tokenImplementation,address _bondingCurve,
        uint256 _feePercent,address _WZETA,
        address _nonfungiblePositionManager,
        address _swapRouter,address _protocolRewards,address _protocolFeeRecipient
    )Ownable(msg.sender){

        if (_bondingCurve == address(0)) revert AddressZero();
        if (_tokenImplementation == address(0)) revert AddressZero();
        if (_protocolFeeRecipient == address(0)) revert AddressZero();
        if (_protocolRewards == address(0)) revert AddressZero();
        if (_WZETA == address(0)) revert AddressZero();
        if (_nonfungiblePositionManager == address(0)) revert AddressZero();
        if (_swapRouter == address(0)) revert AddressZero();
       
        bondingCurve = BondingCurve(_bondingCurve);
        tokenImplementation = _tokenImplementation;
        feePercent = _feePercent;
        WZETA = _WZETA;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
        protocolRewards = _protocolRewards;
        protocolFeeRecipient = _protocolFeeRecipient;
    }
    function depositZeta(address tokenAddr) public payable {
        uint256 zetaLiquidity = ZetaAmount[tokenAddr];
        IWETH(WZETA).deposit{value: zetaLiquidity}();
    }
    function withdrawZeta(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
    function createToken(string memory name, string memory symbol,address _platformReferrer)
        external
        payable
        returns (address)
    {
        address tokenAddress = Clones.clone(tokenImplementation);
        Token token = Token(tokenAddress);
        token.initialize(name, symbol);

        tokens[tokenAddress] = TokenState.FUNDING;
        tokenCreator[tokenAddress] = msg.sender;
        if (_platformReferrer == address(0)) {
            _platformReferrer = protocolFeeRecipient;
        }

        platformReferrer[tokenAddress] = _platformReferrer;
        tokenAddresses.push(tokenAddress);

        address token0 = WZETA < tokenAddress ? WZETA : tokenAddress;
        address token1 = WZETA < tokenAddress ? tokenAddress : WZETA;
        uint160 sqrtPriceX96 = token0 == WZETA ? POOL_SQRT_PRICE_X96_WETH_0 : POOL_SQRT_PRICE_X96_TOKEN_0;

        poolAddress[tokenAddress] = INonfungiblePositionManager(nonfungiblePositionManager).createAndInitializePoolIfNecessary(
            token0, token1, sqrtPriceX96
        );

        if (msg.value > 0){
            buy(tokenAddress, msg.sender,  msg.sender,  address(0), "", TokenState.FUNDING, 0,0);
        }
        emit TokenCreated(msg.sender, tokenAddress, block.timestamp);
        return tokenAddress;
    }

    function buy(
        address _tokenAddr,
        address recipient,
        address refundRecipient,
        address orderReferrer,
        string memory comment,
        TokenState expectedTokenState,
        uint256 minOrderSize,
        uint160 sqrtPriceLimitX96
    ) public payable nonReentrant returns (uint256) {
        require(msg.value > 0, "ETH not enough");
        // Ensure the market type is expected
        TokenState tokenStateNow = tokens[_tokenAddr];

        if (tokenStateNow != expectedTokenState)
            revert InvalidMarketType(); 

        // Ensure the order size is greater than the minimum order size
        if (msg.value < MIN_ORDER_SIZE) revert EthAmountTooSmall();

        // Ensure the recipient is not the zero address
        if (recipient == address(0)) revert AddressZero();

        // Initialize variables to store the total cost, true order size, fee, refund, and whether the market should graduate
        BuyParams memory buyParams;
        buyParams.totalCost = msg.value;
        // 是否需要毕业
        bool shouldGraduateMarket;
        // calculate fee
        Token token = Token(_tokenAddr);
        if (tokenStateNow == TokenState.TRADING) {
            // Calculate the fee
            buyParams.fee = _calculateFee(msg.value, TOTAL_FEE_BPS);

            // Calculate the remaining ETH
            buyParams.remainingEth = msg.value - buyParams.fee;

            // Handle the fees
            _disperseFees(buyParams.fee, orderReferrer,_tokenAddr);

            // Convert the ETH to WETH and approve the swap router
            IWETH(WZETA).deposit{value: buyParams.remainingEth}();
            IWETH(WZETA).approve(swapRouter, buyParams.remainingEth);

            // Set up the swap parameters
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: WZETA,
                tokenOut: _tokenAddr,
                recipient: recipient,
                deadline: block.timestamp + 500,
                amountIn: buyParams.remainingEth,
                amountOutMinimum: minOrderSize,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });

            // Execute the swap
            buyParams.trueOrderSize = ISwapRouter(swapRouter).exactInputSingle(params);
        }
        // 募资阶段
        if (tokenStateNow == TokenState.FUNDING) {
            (
                buyParams.totalCost,
                buyParams.trueOrderSize,
                buyParams.fee,
                buyParams.refund,
                shouldGraduateMarket,
                buyParams.remainingEth
            ) = _validateBondingCurveBuy(minOrderSize, token);

            // Mint the tokens to the recipient
            token.mint(recipient, buyParams.trueOrderSize);
            ZetaAmount[_tokenAddr] += buyParams.remainingEth;
            // Handle the fees，后续需接入具体逻辑
            _disperseFees(buyParams.fee, orderReferrer, _tokenAddr);
            // Refund any excess ETH
            if (buyParams.refund > 0) {
                (bool success, ) = refundRecipient.call{value: buyParams.refund}("");
                if (!success) revert EthTransferFailed();
            }
        }
        // Dex 交易阶段
        // Start the market if this is the final bonding market buy order.
        if (shouldGraduateMarket) {
            _graduateMarket(_tokenAddr);
        }
        emit TokenBuy(
            msg.sender,
            recipient,
            _tokenAddr,
            tokenStateNow,
            msg.value,
            buyParams.fee,
            buyParams.totalCost,
            buyParams.trueOrderSize,
            comment
        );
        return buyParams.trueOrderSize;
    }

    function sell(
        address _tokenAddr,
        uint256 tokensToSell,
        address recipient,
        address orderReferrer,
        string memory comment,
        TokenState expectedTokenState,
        uint256 minPayoutSize,
        uint160 sqrtPriceLimitX96
    ) external nonReentrant returns (uint256) {
        // 确认代币状态符合预期
        TokenState tokenStateNow = tokens[_tokenAddr];
        if (tokenStateNow != expectedTokenState)
            revert InvalidMarketType();

        Token token = Token(_tokenAddr);
        // 确认卖家有足够的代币
        if (tokensToSell > token.balanceOf(msg.sender))
            revert InsufficientLiquidity();

        // 确认接收者地址不为0
        if (recipient == address(0)) revert AddressZero();

        // 初始化实际支付金额
        uint256 truePayoutSize;
        // Dex 阶段
        if (tokenStateNow == TokenState.TRADING) {
            truePayoutSize = _handleUniswapSell(tokensToSell, minPayoutSize, sqrtPriceLimitX96,_tokenAddr,token);
        }
        // 募资阶段
        if (tokenStateNow == TokenState.FUNDING) {
            truePayoutSize = _handleBondingCurveSell(
                tokensToSell,
                minPayoutSize,
                token
            );
        }

        // 计算手续费
        uint256 fee = _calculateFee(truePayoutSize, TOTAL_FEE_BPS);

        // 扣除手续费后的实际支付金额
        uint256 payoutAfterFee = truePayoutSize - fee;

        // 处理手续费分配
        _disperseFees(fee, orderReferrer, _tokenAddr);
        if (tokenStateNow == TokenState.FUNDING) {
            ZetaAmount[_tokenAddr] -= payoutAfterFee;
        }
        // 转账ETH给接收者
        (bool success, ) = recipient.call{value: payoutAfterFee}("");
        if (!success) revert EthTransferFailed();

        emit TokenSell(
            msg.sender, 
            recipient, 
            _tokenAddr,
            tokenStateNow, 
            truePayoutSize, 
            fee, 
            payoutAfterFee, 
            tokensToSell, 
            comment
        );

        return truePayoutSize;
    }

    function _handleUniswapSell(uint256 tokensToSell, uint256 minPayoutSize, uint160 sqrtPriceLimitX96,address tokenAddr,Token token)
        private
        returns (uint256)
    {
        // Transfer the tokens from the seller to this contract
        token.transferFrom(msg.sender, address(this), tokensToSell);

        // Approve the swap router to spend the tokens
        token.approve(swapRouter, tokensToSell);

        // Set up the swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenAddr,
            tokenOut: WZETA,
            recipient: address(this),
            deadline: block.timestamp + 500,
            amountIn: tokensToSell,
            amountOutMinimum: minPayoutSize,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        // Execute the swap
        uint256 payout = ISwapRouter(swapRouter).exactInputSingle(params);

        // Withdraw the ETH from the contract
        IWETH(WZETA).withdraw(payout);

        return payout;
    }

    function _handleBondingCurveSell(
        uint256 tokensToSell,
        uint256 minPayoutSize,
        Token token
    ) private returns (uint256) {
        // 获取当前总供应量
        uint256 totalSupply = token.totalSupply();

        // 使用bonding curve计算可获得的ETH数量
        uint256 payout = bondingCurve.getTokenSellQuote(
            totalSupply,
            tokensToSell
        );

        // 确保支付金额大于最小卖出金额
        if (payout < minPayoutSize) revert SlippageBoundsExceeded();

        // 确保支付金额大于最小订单金额
        if (payout < MIN_ORDER_SIZE) revert EthAmountTooSmall();

        // 销毁卖家的代币
        token.burn(msg.sender, tokensToSell);

        return payout;
    }

    function _validateBondingCurveBuy(uint256 minOrderSize, Token token)
        internal
        returns (
            uint256 totalCost,
            uint256 trueOrderSize,
            uint256 fee,
            uint256 refund,
            bool startMarket,
            uint256 remainingEth
        )
    {
        uint256 totalSupply = token.totalSupply();
        totalCost = msg.value;
        fee = _calculateFee(totalCost, TOTAL_FEE_BPS);

        remainingEth = totalCost - fee;

        trueOrderSize = bondingCurve.getEthBuyQuote(totalSupply, remainingEth);
        if (trueOrderSize < minOrderSize) revert SlippageBoundsExceeded();

        uint256 maxRemainingTokens = PRIMARY_MARKET_SUPPLY - token.totalSupply();

        // 如果超出 FUNDING_GOAL
        if (trueOrderSize == maxRemainingTokens) {
            startMarket = true;
        }
        if (trueOrderSize > maxRemainingTokens) {
            trueOrderSize = maxRemainingTokens;

            // 计算购买这些代币需要的 ETH
            uint256 ethNeeded = bondingCurve.getTokenBuyQuote(
                totalSupply,
                trueOrderSize
            );

            // 重新计算手续费和总成本
            fee = _calculateFee(ethNeeded, TOTAL_FEE_BPS);
            totalCost = ethNeeded + fee;
            remainingEth = ethNeeded;
            // 计算需要退还的 ETH
            if (msg.value > totalCost) {
                refund = msg.value - totalCost;
            }

            startMarket = true;
        }
    }

    function _graduateMarket(address _tokenAddr) internal {
        // 更新代币状态为交易阶段
        tokens[_tokenAddr] = TokenState.TRADING;
        // 0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf
        // 获取当前合约中的ETH余额
        uint256 zetaLiquidity = ZetaAmount[_tokenAddr];

        require(address(this).balance >= zetaLiquidity, "Insufficient ETH balance");

        IWETH(WZETA).deposit{value: zetaLiquidity}();
        // Mint the secondary market supply to this contract
        Token(_tokenAddr).mint(address(this), SECONDARY_MARKET_SUPPLY);

        // Approve the nonfungible position manager to transfer the WETH and tokens
        SafeERC20.safeIncreaseAllowance(IERC20(WZETA), address(nonfungiblePositionManager), zetaLiquidity);
        SafeERC20.safeIncreaseAllowance(IERC20(_tokenAddr), address(nonfungiblePositionManager), SECONDARY_MARKET_SUPPLY);

        // Determine the token order
        bool isWZETAToken0 = address(WZETA) < _tokenAddr;
        address token0 = isWZETAToken0 ? WZETA : _tokenAddr;
        address token1 = isWZETAToken0 ? _tokenAddr : WZETA;
        uint256 amount0 = isWZETAToken0 ? zetaLiquidity : SECONDARY_MARKET_SUPPLY;
        uint256 amount1 = isWZETAToken0 ? SECONDARY_MARKET_SUPPLY : zetaLiquidity;

        // Get the current and desired price of the pool
        
        // uint160 currentSqrtPriceX96 = IUniswapV3Pool(poolAddress[_tokenAddr]).slot0().sqrtPriceX96;
        // uint160 desiredSqrtPriceX96 = isWZETAToken0 ? POOL_SQRT_PRICE_X96_WETH_0 : POOL_SQRT_PRICE_X96_TOKEN_0;

        // // If the current price is not the desired price, set the desired price
        // if (currentSqrtPriceX96 != desiredSqrtPriceX96) {
        //     bool swap0To1 = currentSqrtPriceX96 > desiredSqrtPriceX96;
        //     IUniswapV3Pool(poolAddress[_tokenAddr]).swap(address(this), swap0To1, 100, desiredSqrtPriceX96, "");
        // }
        // Set up the liquidity position mint parameters
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            tickLower: LP_TICK_LOWER,
            tickUpper: LP_TICK_UPPER,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 500
        }); 

        // Mint the liquidity position to this contract. It will be non-transferable and fees will be non-claimable.
        (uint256 positionId,,,) = INonfungiblePositionManager(nonfungiblePositionManager).mint(params);
        tokens[_tokenAddr] = TokenState.TRADING;

        emit MarketGraduated(
            _tokenAddr, poolAddress[_tokenAddr], zetaLiquidity, SECONDARY_MARKET_SUPPLY, positionId, TokenState.TRADING
        );

    }

    function _calculateFee(uint256 _value, uint256 _feeBps)
        internal
        pure
        returns (uint256)
    {
        return (_value * _feeBps) / 10_000;
    }

    function _disperseFees(
        uint256 _fee,
        address _orderReferrer,
        address tokenAddress
    ) internal {
        if (_orderReferrer == address(0)) {
            _orderReferrer = protocolFeeRecipient;
        }
        uint256 tokenCreatorFee = _calculateFee(_fee, TOKEN_CREATOR_FEE_BPS);
        uint256 platformReferrerFee = _calculateFee(
            _fee,
            PLATFORM_REFERRER_FEE_BPS
        );
        uint256 orderReferrerFee = _calculateFee(_fee, ORDER_REFERRER_FEE_BPS);
        uint256 protocolFee = _calculateFee(_fee, PROTOCOL_FEE_BPS);
        uint256 totalFeeInSwap = tokenCreatorFee +
            platformReferrerFee +
            orderReferrerFee +
            protocolFee;

        address[] memory recipients = new address[](4);
        uint256[] memory amounts = new uint256[](4);
        bytes4[] memory reasons = new bytes4[](4);

        recipients[0] = tokenCreator[tokenAddress];
        amounts[0] = tokenCreatorFee;
        reasons[0] = bytes4(keccak256("WOW_CREATOR_FEE"));

        recipients[1] = platformReferrer[tokenAddress];
        amounts[1] = platformReferrerFee;
        reasons[1] = bytes4(keccak256("WOW_PLATFORM_REFERRER_FEE"));

        recipients[2] = _orderReferrer;
        amounts[2] = orderReferrerFee;
        reasons[2] = bytes4(keccak256("WOW_ORDER_REFERRER_FEE"));

        recipients[3] = protocolFeeRecipient;
        amounts[3] = protocolFee;
        reasons[3] = bytes4(keccak256("WOW_PROTOCOL_FEE"));

        IProtocolRewards(protocolRewards).depositBatch{value: totalFeeInSwap}(
            recipients,
            amounts,
            reasons,
            ""
        );

        emit TokenFees(
            tokenCreator[tokenAddress],
            platformReferrer[tokenAddress],
            _orderReferrer,
            protocolFeeRecipient,
            tokenCreatorFee,
            platformReferrerFee,
            orderReferrerFee,
            protocolFee
        );
    }

    /// @notice The current exchange rate of the token if the market has not graduated.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function currentExchangeRate(address _tokenAddr)
        public
        view
        returns (uint256)
    {
        if (tokens[_tokenAddr] == TokenState.TRADING)
            revert MarketAlreadyGraduated();

        uint256 remainingTokenLiquidity = Token(_tokenAddr).totalSupply();
        uint256 ethBalance = ZetaAmount[_tokenAddr];

        if (ethBalance < 0.01 ether) {
            ethBalance = 0.01 ether;
        }

        return remainingTokenLiquidity / ethBalance;    
    }

    function getZetaByQuote(address _tokenAddr, uint256 totalcost) external view returns (uint256){
        if (tokens[_tokenAddr] != TokenState.FUNDING)
            revert InvalidMarketType();

        uint256 fee = _calculateFee(totalcost, TOTAL_FEE_BPS);
        totalcost -= fee;
        uint256 totalSupply = Token(_tokenAddr).totalSupply();
        uint256 trueOrderSize = bondingCurve.getEthBuyQuote(totalSupply, totalcost);

        return trueOrderSize;
    } 
    function getTokenBuyQuote(address _tokenAddr,uint256 tokenOrderSize) public view returns (uint256) {
        if (tokens[_tokenAddr] != TokenState.FUNDING)
            revert InvalidMarketType();
        uint256 fee = _calculateFee(tokenOrderSize, TOTAL_FEE_BPS);
        tokenOrderSize -= fee;
        uint256 totalSupply = Token(_tokenAddr).totalSupply();
        return bondingCurve.getTokenBuyQuote(totalSupply, tokenOrderSize);
    }

    function getTokenSellQuote(address _tokenAddr, uint256 tokenOrderSize) public view returns (uint256) { 
        if (tokens[_tokenAddr] != TokenState.FUNDING)
            revert InvalidMarketType();
      
        uint256 totalSupply = Token(_tokenAddr).totalSupply();
        uint256 payout =  bondingCurve.getTokenSellQuote(totalSupply, tokenOrderSize);
        uint256 fee = _calculateFee(payout, TOTAL_FEE_BPS);
        payout -= fee;
        return payout;
    }
   
    /// @notice Receives ETH and executes a buy order.
    receive() external payable {
        if (msg.sender == WZETA) {
            return;
        }
    }


    function setPOOL_SQRT_PRICE_X96_WETH_0(uint160 newValue) external onlyOwner {
        POOL_SQRT_PRICE_X96_WETH_0 = newValue;
    }
    function setPOOL_SQRT_PRICE_X96_TOKEN_0(uint160 newValue) external onlyOwner {
        POOL_SQRT_PRICE_X96_TOKEN_0 = newValue;
    }

    function setLP_FEE(uint24 newFee) external onlyOwner {
        LP_FEE = newFee;
    }

    function setLP_TICK_LOWER(int24 newTickLower) external onlyOwner {
        LP_TICK_LOWER = newTickLower;
    }

    function setLP_TICK_UPPER(int24 newTickUpper) external onlyOwner {
        LP_TICK_UPPER = newTickUpper;
    }
    // 设置相关合约参数，后续应该删除
    function setFeePercent(uint256 _feePercent) external onlyOwner {
        feePercent = _feePercent;
    }
    function setTokenImpl(address _tokenImpl) external onlyOwner {
        tokenImplementation = _tokenImpl;
    }
    function setBondingCurve(address _bondingCurve) external onlyOwner {
        bondingCurve = BondingCurve(_bondingCurve);
    }
    function setProtocolRewards(address _protocolRewards) external onlyOwner {
        protocolRewards = _protocolRewards;
    }
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
    }

    function setPrimaryMarketSupply(uint256 _primaryMarketSupply) external onlyOwner {
        PRIMARY_MARKET_SUPPLY = _primaryMarketSupply;
    }
    
    function setMinOrderSize(uint256 _minOrderSize) external onlyOwner {
        MIN_ORDER_SIZE = _minOrderSize;
    }

}
