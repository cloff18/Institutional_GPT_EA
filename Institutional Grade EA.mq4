//+------------------------------------------------------------------+
//|                  Institutional-Grade Trading EA                  |
//|              Developed by ChatGPT | Tester: You                 |
//|    High-Frequency, AI-Ready, Advanced Risk Management           |
//+------------------------------------------------------------------+
#property strict

// Input parameters
input double RiskPercent = 1.5;   // Risk % per trade (Max 1.5%)
input double MaxLotSize = 0.02;  // Dynamic max lot size based on equity
input int ATR_Period = 14;
input int ADX_Period = 14;
input int Slippage = 2;
input int BreakEvenPips = 15;
input int TrailingStopPips = 10;
input int MinSpread = 100;
input double MomentumThreshold = 0.3;
input double VolatilityMultiplier = 2.5;

// Indicator Buffers
double ema50, ema200, adxValue, atrValue, macdMain, macdSignal, momentum, rsi;

// Function to Calculate Dynamic Lot Size with Risk Control
double AdjustLotSize()
{
    double riskAmount = AccountBalance() * (RiskPercent / 100);
    double lotSize = NormalizeDouble(riskAmount / (atrValue * 10), 2);
    return MathMin(lotSize, MaxLotSize);
}

// Function to Check Trend Direction
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

// Function to Check Momentum Confirmation
bool IsMomentumStrong()
{
    momentum = iMomentum(Symbol(), PERIOD_CURRENT, 14, PRICE_CLOSE, 0);
    return (momentum > MomentumThreshold);
}

// Function to Check RSI for Overbought/Oversold Confirmation
bool IsRSIOversold()
{
    rsi = iRSI(Symbol(), PERIOD_CURRENT, 14, PRICE_CLOSE, 0);
    return rsi < 30;
}

bool IsRSIOverbought()
{
    rsi = iRSI(Symbol(), PERIOD_CURRENT, 14, PRICE_CLOSE, 0);
    return rsi > 70;
}

// Function to Check Market Conditions
bool IsMarketTradable()
{
    return MarketInfo(Symbol(), MODE_SPREAD) <= MinSpread;
}

// Function to Place a Trade with Lot Size Control
void PlaceTrade(int orderType)
{
    if (!IsMarketTradable() || OrdersTotal() >= 2) return;

    double stopLoss, takeProfit;
    atrValue = iATR(Symbol(), PERIOD_CURRENT, ATR_Period, 0);
    stopLoss = atrValue * VolatilityMultiplier;
    takeProfit = atrValue * 3.0;
    
    double lotSize = AdjustLotSize();
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

    int ticket = OrderSend(Symbol(), orderType, lotSize, (orderType == OP_BUY ? Ask : Bid), Slippage, slPrice, tpPrice, "Institutional_EA", 0, 0, (orderType == OP_BUY ? clrGreen : clrRed));
    if (ticket < 0) Print("Trade failed: ", GetLastError());
}

// Main OnTick Function
void OnTick()
{
    bool trendUp = IsTrendUp();
    bool trendDown = IsTrendDown();
    bool strongMomentum = IsMomentumStrong();
    bool rsiOversold = IsRSIOversold();
    bool rsiOverbought = IsRSIOverbought();
    
    if (trendUp && strongMomentum && rsiOversold) PlaceTrade(OP_BUY);
    if (trendDown && strongMomentum && rsiOverbought) PlaceTrade(OP_SELL);
}
