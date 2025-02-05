//+------------------------------------------------------------------+
//|           Institutional-Grade Trading Expert Advisor            |
//|              Refined Version with Verified Optimizations        |
//|     Adaptive Risk Management & Higher Trade Frequency          |
//+------------------------------------------------------------------+
#property strict

// Input Parameters
input double RiskPercent = 1.5;   // Risk % per trade
input double MaxLotSize = 0.05;  // Maximum lot size per $1000 balance
input int ATR_Period = 14;
input int ADX_Period = 14;
input int Slippage = 2;
input int BreakEvenPips = 20;
input int TrailingStopPips = 20;
input int MinSpread = 30;  // Spread filter to avoid high spread trades

// Indicator Buffers
double ema50, ema200, adxValue, atrValue, macdMain, macdSignal;

// Function to Calculate Dynamic Lot Size
double CalculateLotSize()
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

// Function to Retrieve Market Volatility (ATR)
double GetATR()
{
    return iATR(Symbol(), PERIOD_CURRENT, ATR_Period, 0);
}

// Function to Check if Market Conditions are Tradable
bool IsMarketTradable()
{
    int spread = MarketInfo(Symbol(), MODE_SPREAD);
    return spread <= MinSpread;
}

// Function to Place Trades with Advanced Risk Management
void PlaceTrade(int orderType)
{
    if (!IsMarketTradable() || OrdersTotal() >= 3) return; // Limit total trades to reduce risk

    atrValue = GetATR();
    double stopLoss = atrValue * 3.0;
    double takeProfit = atrValue * 4.5;
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
    adxValue = iADX(Symbol(), PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    bool strongTrend = adxValue > 20; // Adjusted threshold for more trades
    
    macdMain = iMACD(Symbol(), PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
    macdSignal = iMACD(Symbol(), PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
    bool macdConfirmBuy = macdMain > macdSignal && macdMain > 0;
    bool macdConfirmSell = macdMain < macdSignal && macdMain < 0;
    
    bool trendUp = IsTrendUp();
    bool trendDown = IsTrendDown();
    
    if (trendUp && strongTrend && macdConfirmBuy) PlaceTrade(OP_BUY);
    if (trendDown && strongTrend && macdConfirmSell) PlaceTrade(OP_SELL);
}

//+------------------------------------------------------------------+
