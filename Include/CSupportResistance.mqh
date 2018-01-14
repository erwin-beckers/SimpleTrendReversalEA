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

#include <CZigZag.mqh>
#include <CSelectionSort.mqh>

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
class SRLevelComparer: public ICompare<SRLine*>
{
public:
   int Compare(SRLine* el1, SRLine* el2)
   {
      if (  el1.Price < el2.Price) return -1;
      if (  el1.Price > el2.Price) return 1;
      return 0;
   }
};

//+------------------------------------------------------------------+
class CSupportResistance
{
private:
   string  _symbol;
   int     _maxLine;
   double  _maxDistance;
   int     _previousDay;
   int     _period;
   SRLine* _lines[];
   
public:
   //+------------------------------------------------------------------+
   CSupportResistance(string symbol, int timeperiod)
   {
      _period      = timeperiod;
      _symbol      = symbol;
      _maxLine     = 0;
      _previousDay = -1;
      ArrayResize(_lines, 5000, 0);
   }
   
   //+------------------------------------------------------------------+
   ~CSupportResistance()
   {
      ArrayFree(_lines);
   }
   
private:
   //+------------------------------------------------------------------+
   bool DoesSRLevelExists(double price, double pips )
   { 
      if (_maxLine <= 0) return false;
      for (int i=0; i < _maxLine;++i)
      {
         double diff = MathAbs(price - _lines[i].Price);
         if (diff <= pips) 
         {
            return true;
         }
      }
      return false;
   }
   
   //+------------------------------------------------------------------+
   int GetTouches(CZigZag* zigZag, int barPrice, int maxBars, double& price, datetime& startTime, int& startBar)
   {
      int    cnt        = 0;
      double totalPrice = price;
      double totalCnt   = 1.0; 
      double lowest     = price;
      double highest    = price; 
      
      for (int bar = barPrice + 1; bar < maxBars; bar++)
      {  
         ARROW_TYPE arrow = zigZag.GetArrow(bar);
         if (arrow == ARROW_NONE) continue;
         
         double lo = iLow (_symbol, _period, bar);
         double hi = iHigh(_symbol, _period, bar);
         
         double diffLo = MathAbs(lo - price);
         double diffHi = MathAbs(hi - price);
         if (diffLo < _maxDistance )
         {
            cnt++;
            startTime   = iTime(_symbol, _period, bar);
            startBar    = bar;
            totalPrice += lo;
            totalCnt   += 1.0;
            lowest      = MathMin(lowest,lo);
            double pips = diffLo / (10.0 * Point());
            //if (logEnable) Print("price:",price," bar:",bar, " low:",lo, " date:", startTime, " pips:",pips);
         }
         else if ( diffHi <= _maxDistance) 
         {
            cnt++;
            startTime  = iTime(_symbol, _period, bar);
            startBar   = bar;
            totalPrice += hi;
            totalCnt   += 1.0;
            highest    = MathMax(highest,hi);
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
   bool DoesLevelExists(int bar, double price, datetime mostRecent)
   {
      for (int i=0; i < _maxLine;++i)
      {
         double diff = MathAbs(price - _lines[i].Price);
         if (diff < _maxDistance) 
         {
            if ( mostRecent > _lines[i].EndDate)
            {
               _lines[i].EndDate = mostRecent;   
               _lines[i].EndBar  = bar;
            }
            return true;
         }
      }
      return false;
   }
   
   //+------------------------------------------------------------------+
   void Refresh( )
   {
      int barsAvailable = iBars(_symbol, _period);
      int bars          = MathMin( BarsHistory, barsAvailable); 
      
      int lowestBar       = iLowest(_symbol , _period, MODE_LOW , bars, 0);
      int highestBar      = iHighest(_symbol, _period, MODE_HIGH, bars, 0);
      double highestPrice = iHigh(_symbol, _period, highestBar);
      double lowestPrice  = iLow(_symbol , _period, lowestBar);
      
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
      _maxDistance =  priceRange/div;
      
      CZigZag* zigZag      = new CZigZag(bars, _period);  
      zigZag._extDepth     = 12;
      zigZag._extDeviation = 5;
      zigZag._extBackstep  = 3;
      zigZag.Refresh(_symbol);
      
      bool skipFirstArrow=true;
      for (int bar = 1; bar < bars; bar++)
      {
         ARROW_TYPE arrow = zigZag.GetArrow(bar);
         if (arrow == ARROW_NONE) continue; 
         if (skipFirstArrow)
         {
            skipFirstArrow = false;
            continue;
         }
         
         if (arrow == ARROW_BUY) 
         {  
            double   price = iLow (_symbol, _period, bar);
            datetime time  = iTime(_symbol, _period, bar);
            datetime startTime = time;
            int startBar = bar;
            if (!DoesLevelExists(bar, price, startTime )) 
            {
               int touches = GetTouches(zigZag, bar, bars, price, startTime, startBar);
               if (touches >= 0)
               {
                  _lines[_maxLine] = new SRLine();
                  _lines[_maxLine].Price     = price;
                  _lines[_maxLine].Touches   = touches;
                  _lines[_maxLine].EndBar    = bar;
                  _lines[_maxLine].EndDate   = time;
                  _lines[_maxLine].StartDate = startTime;
                  _lines[_maxLine].StartBar  = startBar;
                  _lines[_maxLine].Timeframe = _period;
                  _maxLine++;
               }
             }
         }
         else if (arrow == ARROW_SELL) 
         {
            double   price     = iHigh(_symbol, _period, bar);
            datetime time      = iTime(_symbol, _period, bar);
            datetime startTime = time;
            int startBar = bar;
            if (!DoesLevelExists(bar, price, startTime) )
            {
               int touches = GetTouches(zigZag, bar,bars, price, startTime, startBar);
               if (touches >= 0)
               {
                  _lines[_maxLine] = new SRLine();
                  _lines[_maxLine].Price     = price;
                  _lines[_maxLine].Touches   = touches;
                  _lines[_maxLine].EndBar    = bar;
                  _lines[_maxLine].EndDate   = time;
                  _lines[_maxLine].StartDate = startTime;
                  _lines[_maxLine].StartBar  = startBar;
                  _lines[_maxLine].Timeframe = _period;
                  _maxLine++;
               }
            }
         }
      }
       
      // add s/r line for highest price
      datetime mostRecentTime = iTime(_symbol, _period, highestBar);
      if (!DoesLevelExists(highestBar, highestPrice, mostRecentTime) )
      {
         _lines[_maxLine] = new SRLine();
         _lines[_maxLine].Price     = highestPrice;
         _lines[_maxLine].Touches   = 1;
         _lines[_maxLine].StartBar  = highestBar;
         _lines[_maxLine].StartDate = iTime(_symbol, _period,highestBar);
         _lines[_maxLine].EndDate   = TimeCurrent();
         _lines[_maxLine].EndBar    = 0;
         _lines[_maxLine].Timeframe = _period;
         _maxLine++;
      }
      
      // add s/r line for lowest price
      mostRecentTime = iTime(_symbol, _period, lowestBar);
      if (!DoesLevelExists(lowestBar, lowestPrice, mostRecentTime) )
      {
         _lines[_maxLine] = new SRLine();
         _lines[_maxLine].Price     = lowestPrice;
         _lines[_maxLine].Touches   = 1;
         _lines[_maxLine].StartBar  = lowestBar;
         _lines[_maxLine].StartDate = iTime(_symbol, _period,lowestBar);
         _lines[_maxLine].EndDate   = TimeCurrent();
         _lines[_maxLine].EndBar    = 0;
         _lines[_maxLine].Timeframe = _period;
         _maxLine++;
      }
      delete zigZag;
   }
   
   //+------------------------------------------------------------------+
   void DrawLine(int& lineCnt, SRLine* line, int maxTouches, int maxBars, string key, color colorText,color &colors[], bool showAgeLabels, bool showLastTouch)
   {
      string name = "@"+key+" (" + DoubleToStr(line.Price,5) + ") " + TimeToStr(line.StartDate,TIME_DATE)+" - " + TimeToStr(line.EndDate,TIME_DATE);
      
      if (showAgeLabels)
      {
         int xoff = showLastTouch ? 210:90;
         string timeFrame = "H4";
         if (line.Timeframe == PERIOD_H1) timeFrame = "H1";
         if (line.Timeframe == PERIOD_H4) timeFrame = "H4";
         if (line.Timeframe == PERIOD_D1) timeFrame = "D1";
         if (line.Timeframe == PERIOD_W1) timeFrame = "W1";
         
         double daysLastTouch = (double)(TimeCurrent() - line.EndDate) / (60*60*24);
         double days = (double) (TimeCurrent()  - line.StartDate) / (60*60*24);
         int yrs     = MathFloor(days / 356.0);
        
         if (yrs >= 1 )
         {
            int X = 0;
            int Y = 0;
            ChartTimePriceToXY(0,0,TimeCurrent(), line.Price, X, Y);
            ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
            ObjectSet(name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
            ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
            ObjectSet(name, OBJPROP_XDISTANCE, xoff);
            ObjectSet(name, OBJPROP_YDISTANCE, Y-13);
            ObjectSet(name, OBJPROP_BACK, false);
            string txt= timeFrame+" "+ IntegerToString((int)yrs)+ " years old.";
            if (showLastTouch) txt=txt+" Last touch:"+IntegerToString( (int)daysLastTouch)+" days ago";
            ObjectSetText(name, txt, 8, "Arial", colorText);
            lineCnt++;
         }
         else
         {
            int months     = TimeMonth( TimeCurrent() ) - TimeMonth(line.StartDate);
            if (months < 0) months += 12;
            if (months > 1)
            {
               int X = 0;
               int Y = 0;
               ChartTimePriceToXY(0,0,TimeCurrent(),line.Price, X, Y);
               ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
               ObjectSet(name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
               ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
               ObjectSet(name, OBJPROP_XDISTANCE, xoff);
               ObjectSet(name, OBJPROP_YDISTANCE, Y-13);
               ObjectSet(name, OBJPROP_BACK, false);
               string txt=timeFrame+" "+IntegerToString((int)months)+ " months old.";
               if (showLastTouch) txt=txt+" Last touch:"+IntegerToString((int)daysLastTouch)+" days ago";
               ObjectSetText(name, txt, 8, "Arial", colorText);
               lineCnt++;
            }
            else
            {
               int X = 0;
               int Y = 0;
               ChartTimePriceToXY(0,0,TimeCurrent(),line.Price, X, Y);
               ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
               ObjectSet(name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
               ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
               ObjectSet(name, OBJPROP_XDISTANCE, xoff);
               ObjectSet(name, OBJPROP_YDISTANCE, Y-13);
               ObjectSet(name, OBJPROP_BACK, false);
               string txt=timeFrame+" "+IntegerToString((int)days)+ " days old.";
               if (showLastTouch) txt=txt+" Last touch:"+IntegerToString((int)daysLastTouch)+" days ago";
               ObjectSetText(name, txt, 8, "Arial", colorText);
               lineCnt++;
            }
         }
      }
      
      name = "@"+key+" " + DoubleToStr(line.Price,4) + " " + TimeToStr(line.StartDate, TIME_DATE) + " - " + TimeToStr(line.EndDate, TIME_DATE) + "  #:" + IntegerToString(line.Touches);
      lineCnt++;
      
      int width = 1;
      double bars = MathAbs(line.EndBar - line.StartBar);
      if (bars > 0) 
      {
         double percentage = bars / ((double)maxBars);
         width =(int)MathAbs(4 * percentage);
      }
      
      color clr = colors[0];
      double percentage = (((double)line.Touches) / maxTouches) ;
      if (percentage <= 0.25) clr = colors[0];
      else if (percentage <= 0.50) clr = colors[1];
      else if (percentage <= 0.75) clr = colors[2];
      else clr = colors[3];
      
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, line.Price);
      ObjectSet(name, OBJPROP_COLOR, clr);
      ObjectSet(name, OBJPROP_WIDTH, width);
      ObjectSet(name, OBJPROP_BACK, true);
      ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
   }
   
    
public: 
   //+------------------------------------------------------------------+
   void Draw( string key, color colorText, color &colors[], bool showAgeLabels, bool showLastTouch, bool showAllSRLines)
   {
      ClearAll(key);
      
      // draw lines
      int lineCnt    = 0;
      int maxTouches = 0;  
      int maxBars    = 0;  
       
      for (int i=0; i < _maxLine;++i)
      {  
          maxTouches = MathMax(maxTouches, _lines[i].Touches);
          maxBars    = MathMax(maxBars, MathAbs(_lines[i].EndBar - _lines[i].StartBar));
      }
      
      if (!showAllSRLines)
      {
         double marketPrice = MarketInfo(_symbol, MODE_BID); 
         for (int i=0; i < _maxLine; ++i)
         {
            if ( _lines[i].Price > marketPrice)
            {
               if (i-2 >= 0) DrawLine(lineCnt, _lines[i-2], maxTouches, maxBars, key, colorText,colors,  showAgeLabels,  showLastTouch);
               if (i-1 >= 0) DrawLine(lineCnt, _lines[i-1], maxTouches, maxBars, key, colorText,colors,  showAgeLabels,  showLastTouch);
               DrawLine(lineCnt, _lines[i], maxTouches, maxBars, key, colorText,colors,  showAgeLabels,  showLastTouch);
               if (i+1 < _maxLine) DrawLine(lineCnt, _lines[i+1], maxTouches, maxBars, key, colorText,colors,  showAgeLabels,  showLastTouch);
               break;
            }
         }
      }
      else
      {
         for (int i=0; i < _maxLine;++i)
         {
             DrawLine(lineCnt, _lines[i], maxTouches, maxBars, key, colorText,colors,  showAgeLabels,  showLastTouch);
         }
      }
   }  
   
   //+------------------------------------------------------------------+
   void ClearAll(string key="")
   { 
      bool deleted = false;
      do 
      {
         deleted = false;
         for (int i = 0; i < ObjectsTotal();++i)
         {
            string name = ObjectName(0, i);
            if (name== "@info" || StringSubstr(name, 0, 1+StringLen(key)) == "@"+key)
            {
               ObjectDelete(0, name);
               deleted = true;
               break;
            }
         }
      } while (deleted);
   }
   
   //+------------------------------------------------------------------+
   void Calculate(bool forceRefresh = false)
   {  
      int day = TimeDayOfYear(TimeCurrent());
      if (day != _previousDay || forceRefresh) 
      {
         _previousDay = day;
         _maxLine = 0;
         _maxDistance = 0;
         Refresh( );
         
         CSelectionSort<SRLine*>* sorter = new CSelectionSort<SRLine*> ();
         SRLevelComparer* comparer = new SRLevelComparer();
         sorter.Sort(_lines, _maxLine, comparer);
         delete sorter;
         delete comparer;
      }
   }
   
   //+------------------------------------------------------------------+
   bool IsAtSupportResistance(double price, double pips)
   {
      Calculate();
      double points   = MarketInfo(_symbol, MODE_POINT);
      double digits   = MarketInfo(_symbol, MODE_DIGITS);
      double mult     = (digits==3 || digits==5) ? 10.0:1;
      pips = pips * mult * points;
      
      if (DoesSRLevelExists(price, pips)) return true;
      return false;
   }
   
};
