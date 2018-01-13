//+------------------------------------------------------------------+
//|                                                      CZigZag.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                              www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "www.erwinbeckers.nl"
#property strict


// inputs for zigzag
extern string     __zigzag             = " ------- ZigZag settings------------";
extern int        ExtDepth             = 60;
extern int        ExtDeviation         =  5;
extern int        ExtBackstep          =  3; 


enum ARROW_TYPE
{
   ARROW_NONE,
   ARROW_BUY,
   ARROW_SELL
};

//--------------------------------------------------------------------
class CZigZag
{
private: 
   double            _zigZagBufferBuy[];
   double            _zigZagBufferSell[];
   int               _maxBars;
   int               _period;
   
public: 
   int               _extDepth;
   int               _extDeviation;
   int               _extBackstep;
   
   //--------------------------------------------------------------------
   CZigZag(int maxBars = 500, int timePeriod = 0)
   {
      _extDepth     = ExtDepth;
      _extDeviation = ExtDeviation;
      _extBackstep  = ExtBackstep;
      _maxBars      = maxBars;
      _period       = timePeriod;
      
      ArrayResize(_zigZagBufferBuy , _maxBars + 5, 0);
      ArrayResize(_zigZagBufferSell, _maxBars + 5, 0);
   }
      
   //--------------------------------------------------------------------
   ~CZigZag()
   {
      ArrayFree(_zigZagBufferBuy);
      ArrayFree(_zigZagBufferSell);
   }
   
   //--------------------------------------------------------------------
   void Refresh(string symbol, int startBar = 0)
   {       
      int    shift, back,lasthighpos,lastlowpos;
      double val,res;
      double curlow,curhigh,lasthigh,lastlow;
      lastlow  = 0;
      lasthigh = 0;
   
      double symbolPoint=MarketInfo(symbol, MODE_POINT);
      
      ArrayInitialize(_zigZagBufferBuy,  0);
      ArrayInitialize(_zigZagBufferSell, 0);
      
      for(shift = _maxBars - _extDepth; shift >= 0; shift--)
      {
         val = iLow(symbol, _period, iLowest(symbol, _period, MODE_LOW, _extDepth, shift + startBar));
         if(val == lastlow) 
         {
            val = 0.0;
         }
         else 
         { 
            lastlow = val; 
            if (( iLow(symbol, _period, shift+startBar) - val) > (_extDeviation * symbolPoint)) 
            {
               val = 0.0;
            }
            else
            {
               for(back = 1; back <= _extBackstep; back++)
               {
                  res = _zigZagBufferBuy[shift + back];
                  if ((res != 0) && (res > val)) _zigZagBufferBuy[shift + back] = 0.0; 
               }
            }
         } 
         _zigZagBufferBuy[shift] = val;
         
         //--- high
         val = iHigh(symbol, _period, iHighest(symbol, _period,MODE_HIGH,_extDepth, shift + startBar));
         if (val == lasthigh) 
         {
            val = 0.0; 
         }
         else 
         {
            lasthigh = val;
            if ( (val - iHigh(symbol, _period, shift + startBar)) > (_extDeviation * symbolPoint))
            {
              val = 0.0;
            }
            else
            {
               for (back = 1; back <= _extBackstep; back++)
               {
                  res = _zigZagBufferSell[shift + back];
                  if ( (res != 0) && (res < val)) _zigZagBufferSell[shift + back] = 0.0; 
               } 
            }
         }
         _zigZagBufferSell[shift] = val;
      }
   
      // final cutting 
      lasthigh    = -1; 
      lasthighpos = -1;
      lastlow     = -1;  
      lastlowpos  = -1;
   
      for(shift = _maxBars - _extDepth; shift >= 0; shift--)
      {
         curlow  = _zigZagBufferBuy[shift];
         curhigh = _zigZagBufferSell[shift];
         if ((curlow == 0) && (curhigh == 0)) continue;
         
         if(curhigh != 0)
         {
            if(lasthigh > 0) 
            {
               if (lasthigh<curhigh) _zigZagBufferSell[lasthighpos] = 0;
               else _zigZagBufferSell[shift] = 0;
            }
            if (lasthigh < curhigh || lasthigh < 0)
            {
               lasthigh    = curhigh;
               lasthighpos = shift;
            }
            lastlow = -1;
         }
         
         if(curlow != 0)
         {
            if (lastlow > 0)
            {
               if (lastlow > curlow) _zigZagBufferBuy[lastlowpos] = 0;
               else _zigZagBufferBuy[shift] = 0;
            }
            if ((curlow < lastlow) || (lastlow < 0))
            {
               lastlow    = curlow;
               lastlowpos = shift;
            } 
            lasthigh = -1;
         }
      }
     
      for (shift = _maxBars-1; shift >= 0; shift--)
      {
         if (shift >= _maxBars - _extDepth) 
         {
            _zigZagBufferBuy[shift] = 0.0;
         }
         else
         {
            res = _zigZagBufferSell[shift];
            if (res != 0.0) _zigZagBufferSell[shift]=res;
         }
      }
   }
   
   //--------------------------------------------------------------------
   ARROW_TYPE GetArrow(int bar)
   {
      if (bar < 0 || bar >= _maxBars) return ARROW_NONE;
      if ( _zigZagBufferBuy[bar]  !=0 ) return ARROW_BUY;
      if ( _zigZagBufferSell[bar] !=0 ) return ARROW_SELL;
      return ARROW_NONE;
   }
};