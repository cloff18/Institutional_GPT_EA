//+------------------------------------------------------------------+
//|                Institutional-Grade Trading EA                    |
//|        Developed by ChatGPT | Institutional Strategy             |
//|    Smart Money Concepts | Liquidity | Institutional Order Flow    |
//+------------------------------------------------------------------+
#property strict

// Input Parameters
input double RiskPercent = 1.0;    // Lowered Risk per trade (% of equity)
input double MaxDrawdown = 3.0;    // Reduced Max daily drawdown (% of equity)
input int ATR_Period = 14;
input int ADX_Period = 14;
input int RSI_Period = 14;
input int Slippage = 3;
input int MinSpread = 30;         // Adjusted spread filters
input int MaxSpread = 200;        // More dynamic spread control
input int BreakEvenPips = 15;
input int TrailingStopPips = 25;

// Institutional Trading Variables
double ema50, ema200, adxValue, atrValue, rsiValue, liquidityZone;
bool strongTrend;

// Function to Check Institutional Trend (Smart Money Concept)
bool IsInstitutionalTrendUp()
{
    ema50 = iMA(Symbol(), PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
    ema200 = iMA(Symbol(), PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
    return (ema50 > ema200 && Close[0] > ema50);
}

bool IsInstitutionalTrendDown()
{
    ema50 = iMA(Symbol(), PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
    ema200 = iMA(Symbol(), PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
    return (ema50 < ema200 && Close[0] < ema50);
}

// Function to Check Liquidity Zones
bool IsLiquidityZone()
{
    double high = iHigh(Symbol(), PERIOD_CURRENT, 10);
    double low = iLow(Symbol(), PERIOD_CURRENT, 10);
    liquidityZone = (high + low) / 2;
    return (Close[0] > liquidityZone * 0.995 && Close[0] < liquidityZone * 1.005);
}

// Function to Calculate Dynamic Lot Size Based on Risk
double CalculateLotSize()
{
    double riskAmount = AccountBalance() * (RiskPercent / 100);
    double lotSize = NormalizeDouble(riskAmount / (atrValue * 10), 2);
    return MathMin(lotSize, 0.05); // Max lot size limit
}

// Function to Place Institutional Trade
void PlaceInstitutionalTrade(int orderType)
{
    if (MarketInfo(Symbol(), MODE_SPREAD) > MaxSpread || !IsLiquidityZone()) return; // Avoid trading high spread & confirm liquidity
    
    double stopLoss, takeProfit;
    atrValue = iATR(Symbol(), PERIOD_CURRENT, ATR_Period, 0);
    stopLoss = atrValue * 2.0;  // Adjusted SL
    takeProfit = atrValue * 3.5; // Adjusted TP
    
    double lotSize = CalculateLotSize();
    
    double slPrice, tpPrice;
    if (orderType == OP_BUY)
    {
        slPrice = Bid - stopLoss;
        tpPrice = Bid + takeProfit;
    }
    else
    {
        slPrice = Ask + stopLoss;
        tpPrice = Ask - takeProfit;
    }

    int ticket = OrderSend(Symbol(), orderType, lotSize, (orderType == OP_BUY ? Ask : Bid), Slippage, slPrice, tpPrice, "Institutional_Trade", 0, 0, (orderType == OP_BUY ? clrGreen : clrRed));
    if (ticket < 0) Print("Trade failed: ", GetLastError());
}

// Main OnTick Function
void OnTick()
{
    // Retrieve Trend Direction
    bool trendUp = IsInstitutionalTrendUp();
    bool trendDown = IsInstitutionalTrendDown();
    
    // Retrieve ADX Value (Confirm Trend Strength)
    adxValue = iADX(Symbol(), PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    strongTrend = adxValue > 25;
    
    // Retrieve RSI Confirmation
    rsiValue = iRSI(Symbol(), PERIOD_CURRENT, RSI_Period, PRICE_CLOSE, 0);
    bool rsiConfirmBuy = rsiValue > 55;
    bool rsiConfirmSell = rsiValue < 45;
    
    Print("ADX: ", adxValue, " | RSI: ", rsiValue, " | Spread: ", MarketInfo(Symbol(), MODE_SPREAD));
    
    // BUY Condition
    if (trendUp && strongTrend && rsiConfirmBuy && IsLiquidityZone())
    {
        PlaceInstitutionalTrade(OP_BUY);
    }

    // SELL Condition
    if (trendDown && strongTrend && rsiConfirmSell && IsLiquidityZone())
    {
        PlaceInstitutionalTrade(OP_SELL);
    }
}
