//+------------------------------------------------------------------+
//|                                                    CStrategy.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict


class CIndicator
{
public:
   string   Name;
   bool     IsValid;
   
   CIndicator(string name)
   {
      Name    = name;
      IsValid = false;
   }
};

class CSignal
{
public:
   bool   IsBuy;
   bool   IsSell;
   double StopLoss;
   
   void Reset()
   {
      IsBuy    = false;
      IsSell   = false;
      StopLoss = 0;
   }
};

interface IStrategy
{
   CSignal*       Refresh(string symbol);
   int            GetIndicatorCount();
   CIndicator*    GetIndicator(int indicator);
   double         GetStopLossForOpenOrder(string symbol);

};