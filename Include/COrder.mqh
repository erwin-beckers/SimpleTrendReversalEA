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
   
   COrder(int ticket, double openPrice, double closePrice, double profit, datetime openTime, datetime closeTime, bool isBuyOrder)
   {
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
      double distanceInPrice = Ask - OpenPrice;
      double distanceInPips = _utils.PriceToPips(distanceInPrice);
      return distanceInPips >= pips ;
      
   }
   
   //------------------------------------------------------------------------------------
   //  returns true when current price is pips below the order open price
   //------------------------------------------------------------------------------------
   bool IsPricePipsBelowOpen(double pips)
   {
      double distanceInPrice = OpenPrice - Ask ;
      double distanceInPips = _utils.PriceToPips(distanceInPrice);
      return distanceInPips >= pips ;
   }
};
