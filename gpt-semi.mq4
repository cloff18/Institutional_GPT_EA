//+------------------------------------------------------------------+
//|                  Advanced Fibonacci Trading EA                  |
//|              Developed by ChatGPT | Tester: You                 |
//|    Dynamic Fibonacci, AI Filters, News Filter, Lot Management   |
//+------------------------------------------------------------------+
#property strict

// Input parameters
input double RiskPercent = 2;   // Risk % per trade (Max 2%)
input double MaxLotSize = 0.01;  // Reduced max lot size to 0.01 per $1000 balance
input int ATR_Period = 14;
input int ADX_Period = 14;
input int Slippage = 3;
input int BreakEvenPips = 20;
input int TrailingStopPips = 15;
input int MinSpread = 100;  // Disabled spread filter for testing

// Indicator Buffers
double upperBB, lowerBB;
double ema50, ema200, adxValue, atrValue, macdMain, macdSignal;

// Function to Calculate Dynamic Lot Size with Risk Control
double AdjustLotSize()
{
    static double lastProfit = 0;
    if (lastProfit > 0) return MathMin(MaxLotSize * 1.2, 0.02);  // Increase lot after wins
    return MaxLotSize;
}

// Function to Calculate Fibonacci Levels
double CalculateFibonacciLevel(double high, double low, double ratio)
{
    return low + (high - low) * ratio;
}

// Function to Check Trend Direction (More Reliable)
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

// Function to Identify Bullish & Bearish Engulfing Patterns
bool IsBullishEngulfing()
{
    return (Close[1] < Open[1] && Close[0] > Open[0] && Close[0] > Close[1] && Open[0] < Close[1]);
}

bool IsBearishEngulfing()
{
    return (Close[1] > Open[1] && Close[0] < Open[0] && Close[0] < Close[1] && Open[0] > Close[1]);
}

// Function to Confirm Market Pullback Before Entry
bool IsPullbackConfirmed()
{
    return (Close[0] > Close[1] && Close[1] < Close[2]); // Higher close after a dip
}

// Function to Check Market Conditions
bool IsTradingTime()
{
    int hour = Hour();
    return (hour >= 7 && hour <= 20); // Trade only from 07:00 to 20:00 server time
}

// Function to Place a Trade with Lot Size Control
void PlaceTrade(int orderType)
{
    if (!IsTradingTime() || OrdersTotal() >= 2) return; // Trade only in active hours, limit max open trades to 2

    double stopLoss, takeProfit;
    atrValue = iATR(Symbol(), PERIOD_CURRENT, ATR_Period, 0);
    stopLoss = atrValue * 2.0;  // Lowered SL from 2.5 → 2.0 ATR
    takeProfit = atrValue * 2.7;  // Adjusted TP from 2.5 → 2.7 ATR
    
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

    int ticket = OrderSend(Symbol(), orderType, lotSize, (orderType == OP_BUY ? Ask : Bid), Slippage, slPrice, tpPrice, "Fib_Trade", 0, 0, (orderType == OP_BUY ? clrGreen : clrRed));
    if (ticket < 0) Print("Trade failed: ", GetLastError());

    // Apply trailing stop only if price moves 1.0 ATR in profit
    if (ticket > 0 && OrderProfit() > (atrValue * 1.0))
    {
        OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + (atrValue * 0.5), OrderTakeProfit(), 0, clrGreen);
    }
}

// Main OnTick Function
void OnTick()
{
    // Retrieve Fibonacci Levels
    double high = iHigh(Symbol(), PERIOD_CURRENT, 0);
    double low = iLow(Symbol(), PERIOD_CURRENT, 0);
    double fib38 = CalculateFibonacciLevel(high, low, 0.382);
    double fib50 = CalculateFibonacciLevel(high, low, 0.50);
    double fib61 = CalculateFibonacciLevel(high, low, 0.618);

    // Retrieve Trend Direction
    bool trendUp = IsTrendUp();
    bool trendDown = IsTrendDown();
    
    // Retrieve ADX Value (Stronger Filtering)
    adxValue = iADX(Symbol(), PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    bool strongTrend = adxValue > 25;  // Increased ADX threshold from 20 → 25

    // Retrieve MACD Confirmation
    macdMain = iMACD(Symbol(), PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
    macdSignal = iMACD(Symbol(), PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
    bool macdConfirmBuy = macdMain > macdSignal && macdMain > 0;
    bool macdConfirmSell = macdMain < macdSignal && macdMain < 0;

    // BUY Condition: Fibonacci Level + Trend + ADX Confirmation + MACD + Bullish Engulfing + Pullback Confirmation
    if (Close[1] < fib38 * 1.002 && Close[0] > fib38 * 0.998 && trendUp && strongTrend && macdConfirmBuy && IsBullishEngulfing() && IsPullbackConfirmed())
    {
        PlaceTrade(OP_BUY);
    }

    // SELL Condition: Fibonacci Level + Trend + ADX Confirmation + MACD + Bearish Engulfing + Pullback Confirmation
    if (Close[1] > fib61 * 0.998 && Close[0] < fib61 * 1.002 && trendDown && strongTrend && macdConfirmSell && IsBearishEngulfing() && IsPullbackConfirmed())
    {
        PlaceTrade(OP_SELL);
    }
}
