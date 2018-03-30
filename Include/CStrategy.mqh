//+------------------------------------------------------------------+
//|                                                    CStrategy.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict


//--------------------------------------------------------------------
class CIndicator
{
public:
   string   Name;
   bool     IsValid;
   
//--------------------------------------------------------------------
   CIndicator(string name)
   {
      Name    = name;
      IsValid = false;
   }
};

//--------------------------------------------------------------------
class CSignal
{
public:
   bool   IsBuy;
   bool   IsSell;
   double StopLoss;
   int    Age;      // # of hours passed since start of signal
   double PipsAway; // # of pips price is away since start of 1st signal

   //--------------------------------------------------------------------
   void Reset()
   {
      IsBuy    = false;
      IsSell   = false;
      StopLoss = 0;
      Age      = 1000;
      PipsAway = 1000;
   }
};

//--------------------------------------------------------------------
interface IStrategy
{
   CSignal*       Refresh();
   int            GetIndicatorCount();
   CIndicator*    GetIndicator(int indicator);
   double         GetStopLossForOpenOrder();
};