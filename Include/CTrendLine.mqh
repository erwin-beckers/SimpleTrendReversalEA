//+------------------------------------------------------------------+
//|                                                  CTtrendLine.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                              www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "www.erwinbeckers.nl"
#property strict


// inputs for trend line
extern string     __trendline          = " ------- trendline settings ------------";
extern double     FilterNumber         = 3;
extern int        period               = 10;
extern int        ma_method            = 3;
extern int        applied_price        = 0;

//--------------------------------------------------------------------
class CTrendLine
{
private:
   double            _trendNone[];

   //--------------------------------------------------------------------
   double TrendMA(string symbol,int shift,int p)
   {
      return iMA(symbol, 0, p, 0, ma_method, applied_price, shift);   
   }
   
public:   
   double            _trendRed[];
   
   //--------------------------------------------------------------------
   CTrendLine()
   {   
      ArrayResize(_trendNone , 2048, 0);
      ArrayResize(_trendRed  , 2048, 0);
      ArraySetAsSeries(_trendNone, true);   
   }

   //--------------------------------------------------------------------
   bool IsGreen(int bar)
   {
      if (bar < 0 || bar >= 500) return false;
      double x0 = bar > 0 ? _trendRed[bar - 1]:0;
      double x1 = _trendRed[bar];
      double x2 = _trendRed[bar+1];
      if (x0 >= x1) return true;
      if (x0 >= x2) return true;
      return false;
   }
   
   //--------------------------------------------------------------------
   bool IsRed(int bar)
   {
      if (bar < 0 || bar >= 500) return false;
      double x0 = bar > 0 ? _trendRed[bar - 1]:0;
      double x1 = _trendRed[bar];
      double x2 = _trendRed[bar+1];
      if (x0 <= x1) return true;
      if (x0 <= x2) return true;
      return false;
   }
   
   //--------------------------------------------------------------------
   void Refresh(string symbol)
   {
      int limit = 500;
      ArrayFill(_trendNone, 0, ArraySize(_trendNone), 0);
      
      for(int i = 0; i < limit; i++)
      {
         _trendNone[i] = 2 * TrendMA(symbol, i,(int)MathRound((double)period / FilterNumber)) - TrendMA(symbol, i, period);
      }
      
      int maPeriod = (int)MathRound(MathSqrt(period));
      for(int i = 0; i < limit; i++)
      {
         _trendRed[i] = iMAOnArray(_trendNone, 0, maPeriod, 0, ma_method, i);
      }
      
   }
};
