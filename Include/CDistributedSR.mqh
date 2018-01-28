//+------------------------------------------------------------------+
//|                                               CDistributedSR.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict

#include <CDownloadFile.mqh>

class CDistributedSR
{
private:
   CDownloadFile* _http;
   string         _symbol;
   int            _prevDay;
   double         _srLevelsW1[];
   int            _levelCountW1;
   
   double         _srLevelsD1[];
   int            _levelCountD1;
   
   //----------------------------------------------------------------------
   bool IsKnownSymbol()
   {
     string availableSymbols = "asx200 audcad audchf audjpy audnzd audusd btcusd cadchf cadjpy chfjpy ethusd euraud eurcad eurchf eurgbp eurjpy eurnzd eurusd gbpaud gbpcad gbpchf gbpjpy gbpnzd  gbpusd nzdcad nzdchf nzdjpy nzdusd ukousd us500 usdcad usdchf usdjpy usdollar usdsgd usousd ws30 xagusd xauusd";
     string symLower = _symbol;
     StringToLower(symLower);
     return StringFind(availableSymbols, symLower) >=0;
   }
   
   //----------------------------------------------------------------------
   void Clear()
   {
      bool deleted = false;
      do 
      {
         deleted = false;
         for (int i = 0; i < ObjectsTotal();++i)
         {
            string name = ObjectName(0, i);
            if (StringSubstr(name, 0, 1) == "~")
            {
               ObjectDelete(0, name);
               deleted = true;
               break;
            }
         }
      } while (deleted);
   }
   
   //----------------------------------------------------------------------
   void LoadSR()
   {
      _levelCountW1 = 0;
      _levelCountD1 = 0;
      string key    = _symbol;
      StringToLower(key);
      
      if (!IsKnownSymbol()) 
      {
         Print("UNKNOWN symbol:" + _symbol);
         return;
      }
      
      string url    = "https://www.erwinbeckers.nl/sr/" + key + ".txt";
      string httpResult = "";
      
      //if (Symbol() == _symbol) Print(Symbol(), " grab:", url);
      if (!_http.GrabWeb(url, httpResult))
      {
      
         Print("download failed for:" + url);
         // maybe there is no network connection ?
         return;
      }
       
      string lines[]; 
      int lineCount = StringSplit(httpResult, 10,lines);
      //if (Symbol() == _symbol) Print(Symbol(), "  lines:", lineCount);
      for (int i=0; i < lineCount;++i)
      {
         string priceTxt = lines[i];
         StringReplace(priceTxt,"\r","");
         StringReplace(priceTxt,"\t","");
         priceTxt = StringTrimLeft(priceTxt);
         priceTxt = StringTrimRight(priceTxt);
         if (StringLen(priceTxt) == 0) continue;
         
         if (StringGetChar(priceTxt,0) == 100) // = d
         {
            priceTxt = StringSubstr(priceTxt, 1);
            double price= StringToDouble(priceTxt);
            //if (Symbol() == _symbol) Print(Symbol(), "  add D1:", price);
            _srLevelsD1[_levelCountD1++] = price;
         }
         else
         {
            double price= StringToDouble(priceTxt);
            //if (Symbol() == _symbol) Print(Symbol(), "  add W1:", price);
            _srLevelsW1[_levelCountW1++] = price;
         }
      }
   }
   
public:
   //----------------------------------------------------------------------
   bool HasLevels()
   {
      return _levelCountW1 >0 || _levelCountD1 > 0;
   }

   //----------------------------------------------------------------------
   void DrawSR()
   {
      //Print(_symbol, "sr: draw w:",_levelCountW1," d:",_levelCountD1);
      Clear();
      
      // weekly levels
      for (int i=0; i < _levelCountW1; ++i)
      {
         string name= "~w"+IntegerToString(i);
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, _srLevelsW1[i]);
         ObjectSet(name, OBJPROP_COLOR, clrBlack);
         ObjectSet(name, OBJPROP_WIDTH, 1);
         ObjectSet(name, OBJPROP_BACK, true);
         ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
      }
      
      // daily levels
      for (int i=0; i < _levelCountD1; ++i)
      {
         string name= "~d"+IntegerToString(i);
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, _srLevelsD1[i]);
         ObjectSet(name, OBJPROP_COLOR, clrPeru);
         ObjectSet(name, OBJPROP_WIDTH, 1);
         ObjectSet(name, OBJPROP_BACK, true);
         ObjectSet(name, OBJPROP_STYLE, STYLE_DASH);
      }
   }
   
   //----------------------------------------------------------------------
   CDistributedSR(string symbol)
   {
      _symbol     = symbol;
      _prevDay    = 0;
      _http       = new CDownloadFile();
      ArrayResize(_srLevelsW1, 5000);
      ArrayResize(_srLevelsD1, 5000);
   }
   
   //----------------------------------------------------------------------
   ~CDistributedSR()
   {
      Clear();
      delete _http;
      ArrayFree(_srLevelsW1);
      ArrayFree(_srLevelsD1);
   }
   
   //----------------------------------------------------------------------
   void Refresh()
   {
      int day = TimeDayOfYear(TimeCurrent());
      if (day == _prevDay) return;
      _prevDay = day;
      
      LoadSR();
      DrawSR();
   }
   
   //----------------------------------------------------------------------
   bool IsLevelAt(int period, int bar, double pips)
   {
      int day = TimeDayOfYear(TimeCurrent());
      if (day != _prevDay) 
      {
         _prevDay = day;
         LoadSR();
      }
      
      if ( IsLevel(_srLevelsW1, _levelCountW1, period, bar, pips))
         return true; 
         
      if ( IsLevel(_srLevelsD1, _levelCountD1, period, bar, pips))
         return true;
         
      return false;
   } 
      
private:      
   //----------------------------------------------------------------------
   bool IsLevel(double &levels[], int levelCount, int period, int bar, double pips)
   {
      for (int i=0; i < levelCount;++i)
      {
         double price = levels[i];
         if (iLow(_symbol, period, bar) - pips <= price)
         {
           if (iHigh(_symbol, period, bar) + pips  >= price) return true;
         }
         
         if (iHigh(_symbol, period, bar) + pips >= price)
         {
           if (iLow(_symbol, period, bar) - pips  <= price) return true;
         }
      }
      return false;
   }
};