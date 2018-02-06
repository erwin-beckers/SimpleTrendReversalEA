//+------------------------------------------------------------------+
//|                                               CMrdFXStrategy.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict

enum SRTypes
{
   Daily,
   Weekly,
   DailyAndWeekly
};


extern string     __trendfilter                 = " ------- Pinbar settings ------------";
extern bool        Use50PercentRetracementEntry = true;
extern SRTypes     SupportResistanceLines       = Weekly;

#include <CStrategy.mqh>
#include <CSupportResistance.mqh>

//--------------------------------------------------------------------
class CPriceActionStrategy : public IStrategy
{
private:
   CSupportResistance* _supportResistanceD1;
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
      _signal              = new CSignal();
      _supportResistanceD1 = new CSupportResistance(_symbol, PERIOD_D1);
      _supportResistanceW1 = new CSupportResistance(_symbol, PERIOD_W1);
         
      ArrayResize(_indicators, 10);
      _indicatorCount = 0; 
      _indicators[_indicatorCount++] = new CIndicator("Pinbar");
      _indicators[_indicatorCount++] = new CIndicator("S&R");
      if (Use50PercentRetracementEntry) 
      {
         _indicators[_indicatorCount++] = new CIndicator("50%rt");
      }
   }
   
   //--------------------------------------------------------------------
   ~CPriceActionStrategy()
   {
      delete _signal;
      delete _supportResistanceD1;
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
      double priceOpen   = iOpen (_symbol, 0, 1);
      double priceClose  = iClose(_symbol, 0, 1);
      double priceHi     = iHigh (_symbol, 0, 1);
      double priceLow    = iLow  (_symbol, 0, 1);
      double pinbarRange = priceHi - priceLow ;
      double priceRetracement = priceLow + (pinbarRange * 0.5);
      
      double bodyLo      = MathMin(priceOpen, priceClose);
      double bodyHi      = MathMax(priceOpen, priceClose);
      double wickLoRange = MathAbs(bodyLo - priceLow);
      double wickHiRange = MathAbs(priceHi - bodyHi);
      double bodyRange   = MathAbs(bodyHi - bodyLo); 
      
      double priceNow    = MarketInfo(_symbol, MODE_BID); 
      double points      = MarketInfo(_symbol, MODE_POINT);
      double digits      = MarketInfo(_symbol, MODE_DIGITS);
      double mult = 1;
      if (digits ==3 || digits==5) mult = 10;
            
      _signal.Reset();
      
      for (int i=0; i < _indicatorCount;++i)
      {
         _indicators[i].IsValid = false;
      }
      
      if (priceClose < priceOpen)
      {
         // red candle
         // do we have a pinbar with a large upper wick ?
         bool isPinBar = false;
         if (wickHiRange >= 2 * bodyRange)  
         {
            if (wickHiRange >= 2 * wickLoRange)
            {
               isPinBar = true;
            }
         }
         if (isPinBar)
         {
            double pips = MathAbs(priceHi - bodyHi);
            pips /= mult;
            pips /= points;
            _indicators[0].IsValid = isPinBar;
           
            bool srValid    = false;
            double stopLoss = priceHi;
            // and is it at a weekly S/R level ?
            switch (SupportResistanceLines)
            {
               case Daily:
                   srValid = _supportResistanceD1.IsAtResistance(priceHi, pips, stopLoss);
               break;
               
               case Weekly:
                   srValid = _supportResistanceW1.IsAtResistance(priceHi, pips, stopLoss);
               break;
               
               case DailyAndWeekly:
                   srValid = _supportResistanceD1.IsAtResistance(priceHi, pips, stopLoss) ||
                             _supportResistanceW1.IsAtResistance(priceHi, pips, stopLoss);
               break;
            }
           _indicators[1].IsValid = srValid;
           _signal.IsSell   = true;
           _signal.StopLoss = stopLoss;
           
            // check if price is now at a 50% retracement of the pinbar
            if (Use50PercentRetracementEntry) 
            {
               if ( priceNow >= priceRetracement && priceNow < stopLoss )
               {
                   _indicators[2].IsValid = true;
               }
            }
         }
      }
      else if (priceClose > priceOpen )
      {
         // green candle
         // do we have a pinbar with a large lower wick ?
         bool isPinBar = false;
         if (wickLoRange >= 2 * bodyRange)  
         {
            if (wickLoRange >= 2 * wickHiRange )
            {
               isPinBar=true;
            }
         }
         if (isPinBar)
         {
            double pips= MathAbs(priceLow - bodyLo);
            pips /= mult;
            pips /= points;
            _indicators[0].IsValid = isPinBar;
           
            // and is it at a weekly S/R level ?
            bool srValid    = false;
            double stopLoss = priceLow;
            switch (SupportResistanceLines)
            {
               case Daily:
                   srValid = _supportResistanceD1.IsAtSupport(priceLow, pips, stopLoss);
               break;
               
               case Weekly:
                   srValid = _supportResistanceW1.IsAtSupport(priceLow, pips, stopLoss);
               break;
               
               case DailyAndWeekly:
                   srValid = _supportResistanceD1.IsAtSupport(priceLow, pips, stopLoss) ||
                             _supportResistanceW1.IsAtSupport(priceLow, pips, stopLoss);
               break;
            }
            
           _indicators[1].IsValid = srValid;
           _signal.IsBuy    = true;
           _signal.StopLoss = stopLoss;
           
            // check if price is now at a 50% retracement of the pinbar
            if (Use50PercentRetracementEntry) 
            {
               if ( priceNow <= priceRetracement && priceNow > stopLoss )
               {
                   _indicators[2].IsValid = true;
               }
            }
         }
      }
      
      // do we have a pinbar
      if (!_indicators[0].IsValid)
      {
         // no then we dont have a signal
         _signal.IsBuy  = false;
         _signal.IsSell = false;
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