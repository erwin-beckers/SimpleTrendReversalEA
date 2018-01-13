//+------------------------------------------------------------------+
//|                                                  CTimeFilter.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict


extern string  __timeFilter__    = "----- Time filter ------";
extern int     StartHour         = 00;
extern int     StartMinute       = 00;
extern int     FinishHour        = 24;
extern int     FinishMinute      = 0;
extern bool    TradeOnMonday     = true;
extern bool    TradeOnTuesDay    = true;
extern bool    TradeOnWednessDay = true;
extern bool    TradeOnThursDay   = true;
extern bool    TradeOnFriday     = true;
extern bool    TradeOnSunday     = true;

//--------------------------------------------------------------------
class CTimeFilter
{
public:

   //--------------------------------------------------------------------
   bool CanTrade()
   {  
      int dayOfWeek = TimeDayOfWeek( TimeCurrent() );
      int min       = TimeMinute( TimeCurrent() );
      int hour      = TimeHour( TimeCurrent() );
       
      switch(dayOfWeek)
      {
         case 0: // sunday
            if (!TradeOnSunday) return false;
         break;
         
         case 1: // monday
            if (!TradeOnMonday) return false;
         break;
         
         case 2: // tuesday
            if (!TradeOnTuesDay) return false;
         break;
         
         case 3: // wednessday
            if (!TradeOnWednessDay) return false;
         break;
         
         case 4: // thursday
            if (!TradeOnThursDay) return false;
         break;
         
         case 5: // friday
            if (!TradeOnFriday) return false;
         break;
         
         case 6: // saturday
            return false;   // forex is closed on saturday
            
         default:
            return false;   // should never occur
      }
      
      // check if we can trade from 00:00 - 24:00
      if (StartHour == 0 && FinishHour == 24)
      {
         if (StartMinute==0 && FinishMinute==0)
         {
            // yes then return true
            return true; 
         } 
      } 
      
      if (StartHour > FinishHour) 
      {
         return(true);
      } 
       
      // suppose we're allowed to trade from 14:15 - 19:30
      
      // 1) check if hour is < 14 or hour > 19
      if ( hour < StartHour || hour > FinishHour ) 
      {   
         // if so then we are not allowed to trade
         return false;
      }
      
      // if hour is 14, then check if minute < 15
      if ( hour == StartHour && min < StartMinute )
      {
         // if so then we are not allowed to trade
         return false;
      } 
      
      // if hour is 19, then check  minute > 30
      if ( hour == FinishHour && min > FinishMinute )
      {
         // if so then we are not allowed to trade
         return false;
      }
      return true;
   }
};