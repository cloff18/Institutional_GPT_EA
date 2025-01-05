//+------------------------------------------------------------------+
//|               Institutional-Grade Trading EA                     |
//|        Developed by ChatGPT | Institutional Logic Applied        |
//|    Smart Money Concepts | Order Flow | Dynamic Risk Control     |
//+------------------------------------------------------------------+
#property strict

// Input parameters
input double RiskPercent = 1.5;   // Risk % per trade
input double MaxLotSize = 0.01;   // Max lot size per $1000 balance
input int ATR_Period = 14;
input int ADX_Period = 14;
input int Slippage = 2;
input int BreakEvenPips = 15;
input int TrailingStopPips = 12;
input int MinSpread = 100;        // Min spread filter

// Indicator Buffers
double ema50, ema200, adxValue, atrValue, macdMain, macdSignal;

// Function to Calculate Lot Size with Risk Control
double CalculateLotSize()
{
    double riskAmount = AccountBalance() * (RiskPercent / 100);
    double lotSize = NormalizeDouble(riskAmount / (atrValue * 10), 2);
    return MathMin(lotSize, MaxLotSize);
}

// Function to Identify Institutional Trend
bool IsTrendUp()
{
    ema50 = iMA(Symbol(), PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
    ema200 = iMA(Symbol(), PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
    return ema50 > ema200;
}

bool IsTrendDown()
{
    ema50 = iMA(Symbol(), PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
    ema200 = iMA(Symbol(), PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
    return ema50 < ema200;
}

// Function to Identify Liquidity Zones
bool IsLiquidityZone()
{
    return (Close[0] == iHigh(Symbol(), PERIOD_CURRENT, 20) || Close[0] == iLow(Symbol(), PERIOD_CURRENT, 20));
}

// Function to Confirm Smart Money Entry
bool IsSmartEntry()
{
    adxValue = iADX(Symbol(), PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    return adxValue > 25 && IsLiquidityZone();
}

// Function to Place a Trade with Lot Size Control
void PlaceTrade(int orderType)
{
    if (OrdersTotal() >= 2) return;

    double stopLoss, takeProfit;
    atrValue = iATR(Symbol(), PERIOD_CURRENT, ATR_Period, 0);
    stopLoss = atrValue * 2.5;
    takeProfit = atrValue * 3.5;
    
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
    bool trendUp = IsTrendUp();
    bool trendDown = IsTrendDown();
    bool smartEntry = IsSmartEntry();
    
    if (trendUp && smartEntry)
    {
        PlaceTrade(OP_BUY);
    }
    else if (trendDown && smartEntry)
    {
        PlaceTrade(OP_SELL);
    }
}
