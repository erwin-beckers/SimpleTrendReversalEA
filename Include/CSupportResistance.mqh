//+------------------------------------------------------------------+
//|                                           CSupportResistance.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict

enum Details 
{
   Minium,
   MediumLow,
   Medium,
   MediumHigh,
   Maximum
};

extern string      __srSettings__  = "---- S/R settings ----";
extern int         BarsHistory     = 3000;
extern Details     SR_Detail       = Medium;
extern bool        SR_1Hours       = false;
extern bool        SR_4Hours       = false;
extern bool        SR_Daily        = true;
extern bool        SR_Weekly       = true;

#include <CZigZag.mqh>

//+------------------------------------------------------------------+
class SRLine
{
public:
   int      StartBar;
   int      EndBar;
   datetime StartDate;
   datetime EndDate;
   double   Price;
   int      Touches;  
   int      Timeframe;
};


//+------------------------------------------------------------------+
class CSupportResistance
{
private:
   string _symbol;
   int     _maxLineH1;
   int     _maxLineH4;
   int     _maxLineD1;
   int     _maxLineW1;
   
   double  _maxDistanceH1;
   double  _maxDistanceH4;
   double  _maxDistanceD1;
   double  _maxDistanceW1;
   
   SRLine* _linesH1[];
   SRLine* _linesH4[];
   SRLine* _linesD1[];
   SRLine* _linesW1[];
   int     _previousDay;
   
public:
   CSupportResistance(string symbol)
   {
      _symbol      = symbol;
      _maxLineH1   = 0;
      _maxLineH4   = 0;
      _maxLineD1   = 0;
      _maxLineW1   = 0;
      _previousDay = -1;
      
      ArrayResize(_linesH1, 5000, 0);
      ArrayResize(_linesH4, 5000, 0);
      ArrayResize(_linesD1, 5000, 0);
      ArrayResize(_linesW1, 5000, 0);
   }
   
   //+------------------------------------------------------------------+
   ~CSupportResistance()
   {
      ArrayFree(_linesH1);
      ArrayFree(_linesH4);
      ArrayFree(_linesD1);
      ArrayFree(_linesW1);
   }
   
   //+------------------------------------------------------------------+
   bool IsAtSupportResistance(double price, double pips)
   {
      CalculateSR();
      double points   = MarketInfo(_symbol, MODE_POINT);
      double digits   = MarketInfo(_symbol, MODE_DIGITS);
      double mult     = (digits==3 || digits==5) ? 10.0:1;
      pips = pips * mult * points;
      
      if (DoesSRLevelExists(price, _linesW1, _maxLineW1, pips)) return true;
      if (DoesSRLevelExists(price, _linesD1, _maxLineD1, pips)) return true;
      if (DoesSRLevelExists(price, _linesH4, _maxLineH4, pips)) return true;
      if (DoesSRLevelExists(price, _linesH1, _maxLineH1, pips)) return true;
      return false;
   }
   
private:
   //+------------------------------------------------------------------+
   bool DoesSRLevelExists(double price, SRLine* &lines[], int maxlines, double maxDistance )
   {
      if (maxlines <= 0) return false;
       for (int i=0; i < maxlines;++i)
      {
         double diff = MathAbs(price - lines[i].Price);
         if (diff < maxDistance) 
         {
            return true;
         }
      }
      return false;
   }
   
   //+------------------------------------------------------------------+
   int GetTouches(CZigZag* &zigZag, int tfPeriod, int barPrice,int maxBars, double& price, datetime& startTime, int& startBar, double &maxDistance)
   {
      int    cnt        = 0;
      double totalPrice = price;
      double totalCnt   = 1.0; 
      double lowest     = price;
      double highest    = price;
      bool  logEnable   = false;// price >= 113.400 && price <=116.00;
      
      if (logEnable) Print("Get touches for price:",price);
      for (int bar = barPrice + 1; bar < maxBars; bar++)
      {  
         ARROW_TYPE arrow=zigZag.GetArrow(bar);
         if (arrow==ARROW_NONE) continue;
         
         double lo = iLow (_symbol, tfPeriod, bar);
         double hi = iHigh(_symbol, tfPeriod, bar);
         
         double diffLo = MathAbs(lo  - price);
         double diffHi = MathAbs(hi - price);
         if (diffLo < maxDistance )
         {
            cnt++;
            startTime   = iTime(_symbol, tfPeriod, bar);
            startBar    = bar;
            totalPrice += lo;
            totalCnt   += 1.0;
            lowest = MathMin(lowest,lo);
            double pips=diffLo / (10.0 * Point());
            //if (logEnable) Print("price:",price," bar:",bar, " low:",lo, " date:", startTime, " pips:",pips);
         }
         else if ( diffHi <= maxDistance) 
         {
            cnt++;
            startTime  = iTime(_symbol, tfPeriod, bar);
            startBar   = bar;
            totalPrice += hi;
            totalCnt   += 1.0;
            highest = MathMax(highest,hi);
            double pips=diffHi / (10.0 * Point());
            //if (logEnable) Print("price:",price," bar:",bar, " hi:",hi,"  date:",startTime, " pips:",pips);
         }
      }
      
      //if (logEnable) Print("lowest:", lowest,"  highest:", highest);
      //double diffHi=MathAbs(highest-price);
      //double diffLo=MathAbs(lowest-price);
      //if (diffHi > diffLo) price=diffHi;
      //else price=diffLo;
      
      
     //price = totalPrice / totalCnt;
      return cnt;
   }
   
   //+------------------------------------------------------------------+
   bool DoesLevelExists(int bar, SRLine* &lines[], int maxlines, double price, datetime mostRecent, double& maxDistance)
   {
      for (int i=0; i < maxlines;++i)
      {
         double diff = MathAbs(price - lines[i].Price);
         if (diff < maxDistance) 
         {
            if ( mostRecent > lines[i].EndDate)
            {
               lines[i].EndDate = mostRecent;   
               lines[i].EndBar  = bar;
            }
            return true;
         }
      }
      return false;
   }
   
   //+------------------------------------------------------------------+
   void CalculateSRForTimeFrame(int tfPeriod, int& maxLine, SRLine* &lines[], double& maxDistance )
   {
      int barsAvailable = iBars(_symbol, tfPeriod);
      int bars = MathMin( BarsHistory, barsAvailable); 
      
      
      ExtDepth             = 12;
      ExtDeviation         =  5;
      ExtBackstep          =  3; 
      
      int lowestBar       = iLowest(_symbol , tfPeriod, MODE_LOW , bars, 0);
      int highestBar      = iHighest(_symbol, tfPeriod, MODE_HIGH, bars, 0);
      double highestPrice = iHigh(_symbol, tfPeriod, highestBar);
      double lowestPrice  = iLow(_symbol , tfPeriod, lowestBar);
      
      double priceRange = highestPrice - lowestPrice;
     
      double mult   = (Digits==3 || Digits==5) ? 10.0 : 1.0;
      mult *= Point();
       
      double div = 30.0;
      switch (SR_Detail)
      {
         case Minium:
            div=10.0;
         break;
         case MediumLow:
            div=20.0;
         break;
         case Medium:
            div=30.0;
         break;
         case MediumHigh:
            div=40.0;
         break;
         case Maximum:
            div=50.0;
         break;
      }
      maxDistance =  priceRange/div;
      
      CZigZag* zigZag = new CZigZag(bars,  tfPeriod);  
      zigZag.Refresh(_symbol);
      
      bool skipFirstArrow=true;
      for (int bar = 1; bar < bars; bar++)
      {
         ARROW_TYPE arrow = zigZag.GetArrow(bar);
         if (arrow == ARROW_NONE) continue; 
         if (skipFirstArrow)
         {
            skipFirstArrow=false;
            continue;
         }
         
         if (arrow == ARROW_BUY) 
         {  
            double   price = iLow (_symbol, tfPeriod, bar);
            datetime time  = iTime(_symbol, tfPeriod, bar);
            datetime startTime = time;
            int startBar=bar;
            if (!DoesLevelExists(bar, lines, maxLine, price, startTime, maxDistance )) 
            {
               int touches = GetTouches(zigZag, tfPeriod, bar, bars, price, startTime, startBar, maxDistance);
               if (touches >= 0)
               {
                  lines[maxLine] = new SRLine();
                  lines[maxLine].Price     = price;
                  lines[maxLine].Touches   = touches;
                  lines[maxLine].EndBar    = bar;
                  lines[maxLine].EndDate   = time;
                  lines[maxLine].StartDate = startTime;
                  lines[maxLine].StartBar  = startBar;
                  lines[maxLine].Timeframe = tfPeriod;
                  maxLine++;
               }
             }
         }
         else if (arrow==ARROW_SELL) 
         {
            double   price  = iHigh(_symbol, tfPeriod, bar);
            datetime time   = iTime(_symbol, tfPeriod, bar);
            datetime startTime = time;
            int startBar = bar;
            if (!DoesLevelExists(bar, lines, maxLine, price, startTime, maxDistance) )
            {
               int touches = GetTouches(zigZag, tfPeriod, bar,bars, price, startTime, startBar, maxDistance);
               if (touches >= 0)
               {
                  lines[maxLine] = new SRLine();
                  lines[maxLine].Price     = price;
                  lines[maxLine].Touches   = touches;
                  lines[maxLine].EndBar    = bar;
                  lines[maxLine].EndDate   = time;
                  lines[maxLine].StartDate = startTime;
                  lines[maxLine].StartBar  = startBar;
                  lines[maxLine].Timeframe = tfPeriod;
                  maxLine++;
               }
            }
         }
      }
       
      // add s/r line for highest price
      datetime mostRecentTime = iTime(_symbol, tfPeriod,highestBar);
      if (!DoesLevelExists(highestBar, lines, maxLine, highestPrice, mostRecentTime, maxDistance) )
      {
         lines[maxLine] = new SRLine();
         lines[maxLine].Price     = highestPrice;
         lines[maxLine].Touches   = 1;
         lines[maxLine].StartBar  = highestBar;
         lines[maxLine].StartDate = iTime(_symbol, tfPeriod,highestBar);
         lines[maxLine].EndDate   = TimeCurrent();
         lines[maxLine].EndBar    = 0;
         lines[maxLine].Timeframe = tfPeriod;
         maxLine++;
      }
      
      // add s/r line for lowest price
      mostRecentTime = iTime(_symbol, tfPeriod, lowestBar);
      if (!DoesLevelExists(lowestBar, lines, maxLine, lowestPrice, mostRecentTime, maxDistance) )
      {
         lines[maxLine] = new SRLine();
         lines[maxLine].Price     = lowestPrice;
         lines[maxLine].Touches   = 1;
         lines[maxLine].StartBar  = lowestBar;
         lines[maxLine].StartDate = iTime(_symbol, tfPeriod,lowestBar);
         lines[maxLine].EndDate   = TimeCurrent();
         lines[maxLine].EndBar    = 0;
         lines[maxLine].Timeframe = tfPeriod;
         maxLine++;
      }
      
      
      delete zigZag;
      
   }
    
   
   //+------------------------------------------------------------------+
   void CalculateSR()
   {  
      int day = TimeDayOfYear(TimeCurrent());
      if (day == _previousDay) return;
      _previousDay = day;
      
      _maxLineH1 = 0;
      _maxLineH4 = 0;
      _maxLineD1 = 0;
      _maxLineW1 = 0;
      
      _maxDistanceH1 = 0;
      _maxDistanceH4 = 0;
      _maxDistanceD1 = 0;
      _maxDistanceW1 = 0;
      
      if (SR_Weekly)  CalculateSRForTimeFrame(PERIOD_W1, _maxLineW1, _linesW1, _maxDistanceW1);
      if (SR_Daily)   CalculateSRForTimeFrame(PERIOD_W1, _maxLineD1, _linesD1, _maxDistanceD1);
      if (SR_4Hours)  CalculateSRForTimeFrame(PERIOD_W1, _maxLineH4, _linesH4, _maxDistanceH4);
      if (SR_1Hours)  CalculateSRForTimeFrame(PERIOD_W1, _maxLineH1, _linesH1, _maxDistanceH1);
   }
};
