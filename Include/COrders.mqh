//+------------------------------------------------------------------+
//|                                                      COrders.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict

#include <COrder.mqh>
#include <AnalyseSymbol.mqh>

enum MoneyManagementType 
{
   UseFixedLotSize,
   UseFixedAmount,
   UsePercentageOfAccountBalance,
};

extern string               __Orders__          = "----- Money management settings------";;
extern MoneyManagementType MoneyManagement      = UseFixedLotSize;      
extern double              FixedLotSize         = 0.01;              
extern double              FixedAmount          = 100;                         
extern double              RiskPercentage       = 2;             
extern int                 MagicNumberBuy       = 1122;
extern int                 MagicNumberSell      = 2211;
extern string              BuyComment           = "buy";
extern string              SellComment          = "sell";
extern int                 MaxSpreadInPips      = 8;
extern int                 MaxOpenTrades        = 100;

class COrders
{
private:
   string _symbol;
   
public:
   
   //------------------------------------------------------------------------------------
   COrders(string symbol)
   {  
      _symbol=symbol;
   }
   
   //------------------------------------------------------------------------------------
   bool CanOpenNewOrder()
   {
     return GetGlobalOrderCount() < MaxOpenTrades;
   }
   
   //------------------------------------------------------------------------------------
   double IsSpreadOk()
   {
      RefreshRates();
      double askPrice = MarketInfo(_symbol, MODE_ASK);
      double bidPrice = MarketInfo(_symbol, MODE_BID);
      double points   = MarketInfo(_symbol, MODE_POINT);
      double digits   = MarketInfo(_symbol, MODE_DIGITS);
      double mult = 1;
      if (digits ==3 || digits==5) mult = 10;
      
      // return when spread too high
      double spreadNowPips = MathAbs(askPrice - bidPrice) / ( mult * points);
      if (spreadNowPips > MaxSpreadInPips) return false;
      return true;
   }
   
   //------------------------------------------------------------------------------------
   //  GetOrderCount for symbol
   //------------------------------------------------------------------------------------
   int GetOrderCount()
   {
      int cnt=0;
      for (int i=0; i < OrdersTotal();++i)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderSymbol() == _symbol)
            {
               if (OrderMagicNumber() == MagicNumberBuy || OrderMagicNumber() == MagicNumberSell) cnt++;
            }
         }
      }
      return cnt;
   }
   
   //------------------------------------------------------------------------------------
   //  GetGlobalOrderCount 
   //------------------------------------------------------------------------------------
   int GetGlobalOrderCount()
   {
      int cnt=0;
      for (int i=0; i < OrdersTotal();++i)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
           if (OrderMagicNumber() == MagicNumberBuy || OrderMagicNumber() == MagicNumberSell) cnt++;
         }
      }
      return cnt;
   }
   
   //------------------------------------------------------------------------------------
   //  Returns if order type is a buy or a sell
   //------------------------------------------------------------------------------------
   bool IsBuy(int orderType)
   {
      return (orderType  == OP_BUY ||  orderType== OP_BUYLIMIT || orderType== OP_BUYSTOP);
   }
    
    //------------------------------------------------------------------------------------
    //  Close order by ticket
    //------------------------------------------------------------------------------------
    bool CloseOrderByTicket(int ticket)
    {
      Print("  COrders:CloseOrderByTicket #", ticket);
      bool success = false;
      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      {
         Print("  order selected : closetime:", OrderCloseTime() );
         RefreshRates();
         double price   = MarketInfo(OrderSymbol(), MODE_ASK);
         int orderType  = OrderType();
         if (IsBuy(orderType)) price = MarketInfo(OrderSymbol(), MODE_BID);
         
         Print("  market price:",price, " OpenPrice:", OrderOpenPrice());
         Print("Closing order ", OrderSymbol(),"  #",OrderTicket(), " lots:", OrderLots(), " price:", price);
         success = OrderClose(OrderTicket(), OrderLots(), price, 3, Red);
         if (success)
         {
            Print("  order #", ticket, " closed");
            if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY))
            {
            }
            else Print("------ UNABLE TO FIND ORDER IN HISTORY AFTER CLOSE --------");
         }
         else 
         {
            Print("------ UNABLE TO CLOSE ORDER -------- err:", GetLastError());
         }
      }
      else 
      {
         Print("------ UNABLE TO FIND ORDER TO CLOSE --------");
      }
      return success;
    }
    
    //------------------------------------------------------------------------------------
    //  Close order by ticket
    //------------------------------------------------------------------------------------
    void CloseOrderByType(int orderType)
    {
      bool orderClosed;
      int  cnt=0;
      do
      {
         orderClosed=false;
         for (int i=0; i < OrdersTotal(); i++)
         {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
               if (OrderSymbol() == _symbol && orderType == OrderType() )
               {
                  if (OrderMagicNumber() == MagicNumberBuy || OrderMagicNumber() == MagicNumberSell)
                  {
                     double price = MarketInfo(OrderSymbol(), MODE_ASK);
                     if (IsBuy(orderType))  price = MarketInfo(OrderSymbol(), MODE_BID);
                     
                     Print("Closing order ", OrderSymbol(),"  #",OrderTicket(), " lots:", OrderLots(), " price", price);
                     bool success = OrderClose(OrderTicket(), OrderLots(), price, 3, Red);
                     orderClosed=true;
                     cnt++;
                     break;
                  }
               }
             }
          }
       } while (orderClosed);
    }
    
    
    //------------------------------------------------------------------------------------
    //  Open a new buy order
    //------------------------------------------------------------------------------------
    int OpenBuyOrder(double lotSize, double sl=0, double tp=0)
    {
      RefreshRates();
      double price  = MarketInfo(_symbol, MODE_ASK);
      Print(_symbol, " Open buy order lots:", lotSize, " price:", price,"  sl:",sl, " tp:",tp);
      int ticket    = OrderSend(_symbol, OP_BUY, lotSize, price, 3, sl, tp, BuyComment, MagicNumberBuy);
      if (ticket < 0)
      {
         int ErrNumber = GetLastError();
         Print("  buy order failed err# ",ErrNumber, " symbol:", _symbol, " lots:", lotSize, " price:", price, " sl:", sl, "  tp:",tp);
      }
      return ticket;
    }
    
    //------------------------------------------------------------------------------------
    //  Open a new sell order
    //------------------------------------------------------------------------------------
    int OpenSellOrder(double lotSize, double sl=0, double tp=0)
    {
      RefreshRates();
      double price  = MarketInfo(_symbol, MODE_BID);
      Print(_symbol, " Open sell order for lots:", lotSize, " price:", price,"  sl:",sl, " tp:",tp);
      int ticket    = OrderSend(_symbol, OP_SELL, lotSize, price, 3, sl,tp, SellComment, MagicNumberSell);
      if (ticket < 0)
      {
         int ErrNumber = GetLastError();
         Print("  sell order failed err# ",ErrNumber, " symbol:", _symbol, " lots:", lotSize, " price:", price, " sl:", sl, "  tp:",tp);
      }
      return ticket;
    }


    //------------------------------------------------------------------------------------
   double GetLotSize(double stopLossPrice, int orderType)
   {
      double lotSize=0;
      double amount=0;
      
      switch (MoneyManagement)
      {
         case UseFixedLotSize:
            Print("Use fixed lot size:",  FixedLotSize);
            return NormalizeLotSize(FixedLotSize);
         break;
         
         case UseFixedAmount:
            if (FixedAmount <=0)
            {
               Print("Use FixedAmount, but fixed amount <=0-> return fixed lotsize: ",  FixedLotSize);
               return NormalizeLotSize(FixedLotSize);
            }
            Print("Use FixedAmount ",  FixedAmount, "  lots:", lotSize);
            lotSize= CalcLotSize(FixedAmount, stopLossPrice, orderType);
            return lotSize;
         break;
         
         case UsePercentageOfAccountBalance:
            if (RiskPercentage <=0)
            {
               Print("Use RiskPercentage, but percentage <=0-> return fixed lotsize: ",  FixedLotSize);
               return NormalizeLotSize(FixedLotSize);
            }
            amount  = AccountBalance() * (RiskPercentage / 100.0);
            lotSize = CalcLotSize(amount, stopLossPrice, orderType);
            Print("Use Risk percentage ",RiskPercentage,"%  amount:", amount, " lots:", lotSize);
            return lotSize;
         break;
      }
      Print("unknown mode-> return fixed lot size:",  FixedLotSize);
      return NormalizeLotSize(FixedLotSize);
   }
   
    //------------------------------------------------------------------------------------
   double CalcLotSize(double amountToRisk,double stopLossPrice,int orderType,bool returnNormalizedLots=true)
   {  
      RefreshRates();
      int    symbolType                 = GetSymbolType(_symbol);
      string currentCounterPairForCross = GetCounterPairForCross(_symbol);
      double ask           = MarketInfo(_symbol, MODE_ASK);
      double bid           = MarketInfo(_symbol, MODE_BID);
      double symbolLotSize = MarketInfo(_symbol, MODE_LOTSIZE) ;
      double points        = MarketInfo(_symbol, MODE_POINT) ;
      double digits        = MarketInfo(_symbol, MODE_DIGITS) ;
      double mult = (digits==3 || digits==5) ? 10.0 : 1.0;
      double lotSize=0.0;
      
      if (orderType == OP_BUY)
      {
          double slPips = MathAbs(stopLossPrice - bid) / (mult * points);
          Print(_symbol," CalcLotSize buy: type:", symbolType, "  amount:", DoubleToStr(amountToRisk,2), " sl price:", DoubleToStr(stopLossPrice,5), " ask:", DoubleToStr(ask,5), "sl pips", DoubleToStr(slPips,2));
      }
      else
      {
         double slPips = MathAbs(stopLossPrice - ask) / (mult * points);
         Print(_symbol," CalcLotSize sell: type:", symbolType, "  amount:", DoubleToStr(amountToRisk,2), " sl price:", DoubleToStr(stopLossPrice,5), " bid:", DoubleToStr(bid,5), "sl pips",  DoubleToStr(slPips,2));
     }
     
      switch (symbolType) // Determine the equity at risk based on the SymbolType for the financial instrument
      {
         case 1:  
            switch(orderType)   // Currency Pairs with USD as base - e.g. USDJPY
            {
               case OP_BUY:  
                  lotSize = (-amountToRisk * stopLossPrice) / (symbolLotSize * (stopLossPrice - ask)); 
               break;
               
               case OP_SELL:  
                  lotSize = (-amountToRisk * stopLossPrice) / (symbolLotSize * (bid - stopLossPrice)); 
               break;
               
               default:  
                  Print("Error encountered in the OrderType() routine for calculating the EquityAtRisk"); // The expression did not generate a case value
               break;   
            }
            break;

         case 2:  
            switch(orderType)   // Currency Pairs with USD as counter - e.g. EURUSD
            {
               case OP_BUY:  
                  lotSize = -amountToRisk / (symbolLotSize * (stopLossPrice - ask)); 
               break;
               
               case OP_SELL:  
                  lotSize = -amountToRisk / (symbolLotSize * (bid - stopLossPrice)); 
               break;
               
               default:  
                  Print("Error encountered in the OrderType() routine for calculating the EquityAtRisk"); // The expression did not generate a case value
               break;
            }
         break;
            
         case 3:  // e.g. Symbol() = CHFJPY, the counter currency is JPY and the USD is the base to the JPY in the pair USDJPY
               // falls thru and is treated the same as SymbolType()==4 for the purpose of these calculations
            
         case 4:  
            switch(orderType)  // e.g. Symbol() = AUDCAD, the counter currency is CAD and the USD is the base to the CAD in the pair USDCAD
            {
               case OP_BUY:  
                  lotSize = (-amountToRisk * MarketInfo(currentCounterPairForCross, MODE_BID)) / (symbolLotSize * (stopLossPrice - ask)); 
               break;
               
               case OP_SELL:  
                  lotSize = (-amountToRisk * MarketInfo(currentCounterPairForCross, MODE_ASK)) / (symbolLotSize * (bid - stopLossPrice)); 
               break;
               
               default:  
                  Print("Error encountered in the OrderType() routine for calculating the EquityAtRisk"); // The expression did not generate a case value
               break;
            }
         break;

         case 5:  
            switch(orderType)  // e.g. Symbol() = EURGBP, the counter currency is GBP and the USD is the counter to the GBP in the pair GBPUSD
            {
               case OP_BUY:  
                  lotSize = -amountToRisk / (symbolLotSize * MarketInfo(currentCounterPairForCross, MODE_BID) * (stopLossPrice - ask)); 
               break;
               
               case OP_SELL:  
                  lotSize = -amountToRisk / (symbolLotSize * MarketInfo(currentCounterPairForCross, MODE_ASK) * (bid - stopLossPrice)); 
               break;
               
               default:  
                  Print("Error encountered in the OrderType() routine for calculating the EquityAtRisk"); // The expression did not generate a case value
               break;
            }
         break;
         
         default:  
            Print("Error encountered in the SWITCH routine for calculating the EquityAtRisk"); // The expression did not generate a case value
         break;
      }
      if (lotSize < 0) lotSize=0;
      if (returnNormalizedLots) lotSize = NormalizeLotSize(lotSize);
      Print(" lotSize:", lotSize);
      return lotSize;
   }  // LotSize body end

   //------------------------------------------------------------------------------------
   double NormalizeLotSize(double lotSize)
   {
      double   normalizedLotSize = 0.;
      int      lotSizeDigits = 0; 
      double   lotSizeStep = MarketInfo(_symbol, MODE_LOTSTEP);
      double   minLots     = MarketInfo(_symbol, MODE_MINLOT);
      lotSizeDigits        = (int)-MathRound( MathLog( lotSizeStep) / MathLog(10.) ); // Number of digits after decimal point for the Lot for the current broker, like Digits for symbol prices
      normalizedLotSize    = NormalizeDouble(MathFloor((lotSize - minLots) / lotSizeStep) * lotSizeStep + minLots, lotSizeDigits);
      return normalizedLotSize ;
   } 


   //------------------------------------------------------------------------------------
   //  Get last closed order for a symbol
   //------------------------------------------------------------------------------------
   COrder* GetLastClosedOrder()
   {
      bool     first         = true;
      double   openPrice     =  0;
      double   closePrice    =  0;
      int      ticket        = -1;
      double   profit        =  0;
      datetime openTime      =  0;
      datetime closeTime     =  0;
      bool     isBuy         = false; 
      
      for (int i=0; i < OrdersHistoryTotal(); ++i)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         {
            if (OrderMagicNumber() == MagicNumberBuy || OrderMagicNumber() == MagicNumberSell)
            {
               if (OrderSymbol() == _symbol)
               {
                  if (ticket == -1 || OrderOpenTime() > openTime)
                  {
                     ticket    = OrderTicket();
                     openPrice = OrderOpenPrice();
                     closePrice= OrderClosePrice();
                     profit    = OrderProfit() + OrderSwap() + OrderCommission();
                     openTime  = OrderOpenTime();
                     closeTime = OrderCloseTime();
                     isBuy     = IsBuy(OrderType() );
                  }
               }
            }
         }
      }
       if ( ticket < 0) return NULL;
       return new COrder(ticket, openPrice, closePrice, profit, openTime, closeTime, isBuy);
   }
};