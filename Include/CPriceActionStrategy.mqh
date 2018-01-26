//+------------------------------------------------------------------+
//|                                               CMrdFXStrategy.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict


extern string     __trendfilter                = " ------- SMA 200 Daily Trend Filter ------------";
extern bool        UseSma200TrendFilter        = false;

#include <CStrategy.mqh>
#include <CSupportResistance.mqh>

//--------------------------------------------------------------------
class CPriceActionStrategy : public IStrategy
{
private:
   CSupportResistance* _supportResistanceW1;
   int                 _indicatorCount;
   CIndicator*         _indicators[];
   CSignal*            _signal;
   string              _symbol;
   
public:
   //--------------------------------------------------------------------
   CPriceActionStrategy(string symbol)
   {
      _symbol              = symbol;
      _supportResistanceW1 = new CSupportResistance(_symbol, PERIOD_W1);
      _signal              = new CSignal();
         
      _indicatorCount = 2; // S&R and pinbar
       
      ArrayResize(_indicators, 10);
      int index=0;
      _indicators[index++] = new CIndicator("S&R");
      _indicators[index++] = new CIndicator("Pinbar");
   }
   
   //--------------------------------------------------------------------
   ~CPriceActionStrategy()
   {
      delete _signal;
      delete _supportResistanceW1;
      
      for (int i=0; i < _indicatorCount;++i)
      {
         delete _indicators[i];
      }
      ArrayFree(_indicators);
   }
   
   //--------------------------------------------------------------------
   CSignal* Refresh()
   {
      double priceOpen = iOpen(_symbol,0,1);
      double priceClose= iClose(_symbol,0,1);
      double priceHi   = iHigh(_symbol,0,1);
      double priceLow  = iLow(_symbol,0,1);
      
      double bodyLo = MathMin(priceOpen, priceClose);
      double bodyHi = MathMax(priceOpen, priceClose);
      double wickLo = MathAbs(bodyLo - priceLow);
      double wickHi = MathAbs(priceHi - bodyHi);
      double body   = MathAbs(bodyHi - bodyLo); 
      
      double points   = MarketInfo(_symbol, MODE_POINT);
      double digits   = MarketInfo(_symbol, MODE_DIGITS);
      double mult = 1;
      if (digits ==3 || digits==5) mult = 10;
            
      _signal.Reset();
     _indicators[0].IsValid = false;
     _indicators[1].IsValid = false;
     
      if (priceClose < priceOpen)
      {
         // red candle
         bool isPinBar = false;
         if (wickHi >= 2 * body)  
         {
            if (wickHi > 2 * wickLo)
            {
               isPinBar=true;
            }
         }
         double pips= MathAbs(priceHi - bodyHi);
         pips /= mult;
         pips /= points;
      
        _indicators[1].IsValid = isPinBar;
        _indicators[0].IsValid = _supportResistanceW1.IsAtSupportResistance(priceHi, pips);
        _signal.IsSell=true;
        _signal.StopLoss = priceHi;
      }
      else if (priceClose > priceOpen )
      {
         // green candle
         bool isPinBar = false;
         if (wickLo >= 2 * body)  
         {
            if (wickLo > 2 * wickHi )
            {
               isPinBar=true;
            }
         }
         
      
         double pips= MathAbs(priceLow - bodyLo);
         pips /= mult;
         pips /= points;
        _indicators[1].IsValid = isPinBar;
        _indicators[0].IsValid = _supportResistanceW1.IsAtSupportResistance(priceLow, pips);
        _signal.IsBuy=true;
        _signal.StopLoss = priceLow;
      }
      if (! _indicators[1].IsValid && !  _indicators[0].IsValid)
      {
         _signal.IsBuy=false;
         _signal.IsSell=false;
      }
      return _signal;
   }
   
   //--------------------------------------------------------------------
   int GetIndicatorCount()
   {
      return _indicatorCount;
   }
   
   //--------------------------------------------------------------------
   CIndicator* GetIndicator(int indicator)
   {
      return _indicators[indicator];
   }
   
   //--------------------------------------------------------------------
   double GetStopLossForOpenOrder()
   {
      return 0;
   }
};