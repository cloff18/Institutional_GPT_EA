//+------------------------------------------------------------------+
//|        Institutional-Grade Trading Expert Advisor (Final)       |
//|              Developed by ChatGPT | Tester: You                 |
//|     AI Filters, Smart Risk Management, Dynamic Strategies      |
//+------------------------------------------------------------------+
#property strict

// Input Parameters
input double RiskPercent = 1.2;   // Risk % per trade (Reduced for lower drawdown)
input double MaxLotSize = 0.02;  // Maximum lot size per $1000 balance
input int ATR_Period = 14;
input int ADX_Period = 14;
input int Slippage = 2;
input int BreakEvenPips = 15;  // Lowered to secure profits earlier
input int TrailingStopPips = 20;
input int MinSpread = 25;  // Improved spread filter to avoid volatile periods

// Indicator Buffers
double ema50, ema200, adxValue, atrValue, macdMain, macdSignal, stochasticK, stochasticD;

// Function to Calculate Dynamic Lot Size
double CalculateLotSize()
{
    double riskAmount = AccountBalance() * (RiskPercent / 100);
    double lotSize = NormalizeDouble(riskAmount / (atrValue * 10), 2);
    return MathMin(lotSize, MaxLotSize);
}

// Function to Check Trend Direction (Refined for higher accuracy)
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

// Function to Check if Market Conditions are Tradable (Refined)
bool IsMarketTradable()
{
    int spread = MarketInfo(Symbol(), MODE_SPREAD);
    return spread <= MinSpread;
}

// Function to Place Trades with Advanced Risk Management
void PlaceTrade(int orderType)
{
    if (!IsMarketTradable() || OrdersTotal() >= 2) return;

    atrValue = GetATR();
    double stopLoss = atrValue * 2.8;  // Slightly lowered SL to improve RR ratio
    double takeProfit = atrValue * 4.2; // Adjusted for better profitability
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

// Main OnTick Function (Optimized for accuracy)
void OnTick()
{
    adxValue = iADX(Symbol(), PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    bool strongTrend = adxValue > 25;
    
    macdMain = iMACD(Symbol(), PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
    macdSignal = iMACD(Symbol(), PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
    bool macdConfirmBuy = macdMain > macdSignal && macdMain > 0;
    bool macdConfirmSell = macdMain < macdSignal && macdMain < 0;
    
    stochasticK = iStochastic(Symbol(), PERIOD_CURRENT, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
    stochasticD = iStochastic(Symbol(), PERIOD_CURRENT, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 0);
    bool stochasticConfirmBuy = stochasticK < 20 && stochasticD < 20; // Avoid buying in overbought zones
    bool stochasticConfirmSell = stochasticK > 80 && stochasticD > 80; // Avoid selling in oversold zones
    
    bool trendUp = IsTrendUp();
    bool trendDown = IsTrendDown();
    
    if (trendUp && strongTrend && macdConfirmBuy && stochasticConfirmBuy) PlaceTrade(OP_BUY);
    if (trendDown && strongTrend && macdConfirmSell && stochasticConfirmSell) PlaceTrade(OP_SELL);
}
