//+------------------------------------------------------------------+
//|                                                       COrder.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                              www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "www.erwinbeckers.nl"
#property strict

#include <CUtils.mqh>;

class COrder
{
   
public:
   int           Ticket;
   bool          IsBuy;
   bool          IsSell;
   double        OpenPrice;
   double        ClosePrice;
   double        Profit;
   datetime      OpenTime;
   datetime      CloseTime;
   string        Currency;
   
   COrder(int ticket, string symbol, double openPrice, double closePrice, double profit, datetime openTime, datetime closeTime, bool isBuyOrder)
   {
      Currency   = symbol;
      Ticket     = ticket; 
      OpenPrice  = openPrice;
      ClosePrice = closePrice;
      Profit     = profit;
      OpenTime   = openTime;
      CloseTime  = closeTime;
      IsBuy      = isBuyOrder;
      IsSell     = !isBuyOrder;
   }
   
   ~COrder()
   { 
   }   

   //------------------------------------------------------------------------------------
   //  returns true when current price is pips above the order open price
   //------------------------------------------------------------------------------------
   bool IsPricePipsAboveOpen(double pips)
   {
      double distanceInPrice = _utils.AskPrice(Currency) - OpenPrice;
      double distanceInPips = _utils.PriceToPips(Currency, distanceInPrice);
      return distanceInPips >= pips;
   }
   
   //------------------------------------------------------------------------------------
   //  returns true when current price is pips below the order open price
   //------------------------------------------------------------------------------------
   bool IsPricePipsBelowOpen(double pips)
   {
      double distanceInPrice = OpenPrice - _utils.AskPrice(Currency)  ;
      double distanceInPips = _utils.PriceToPips(Currency, distanceInPrice);
      return distanceInPips >= pips ;
   }
};
