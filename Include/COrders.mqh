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
#include <CUtils.mqh>

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
      if (_utils.Spread(_symbol) > MaxSpreadInPips) return false;
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
         double price   = _utils.AskPrice(OrderSymbol());
         int orderType  = OrderType();
         if (IsBuy(orderType)) price = _utils.BidPrice(OrderSymbol());
         
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
                     double price = _utils.AskPrice(OrderSymbol());
                     if (IsBuy(orderType))  price = _utils.BidPrice(OrderSymbol());
                     
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
      double price  = _utils.AskPrice(_symbol);
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
      double price  = _utils.BidPrice(_symbol);
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
            Print("COrders:GetLotSize() Use fixed lot size:",  FixedLotSize);
            return _utils.NormalizeLotSize(_symbol, FixedLotSize);
         break;
         
         case UseFixedAmount:
            if (FixedAmount <=0)
            {
               Print("COrders:GetLotSize() Use FixedAmount, but fixed amount <=0-> return fixed lotsize: ",  FixedLotSize);
               return _utils.NormalizeLotSize(_symbol, FixedLotSize);
            }
            Print("COrders:GetLotSize() Use FixedAmount ",  FixedAmount, "  lots:", lotSize);
            lotSize = CalcLotSize(FixedAmount, stopLossPrice, orderType);
            return lotSize;
         break;
         
         case UsePercentageOfAccountBalance:
            if (RiskPercentage <=0)
            {
               Print("COrders:GetLotSize() Use RiskPercentage, but percentage <=0-> return fixed lotsize: ",  FixedLotSize);
               return _utils.NormalizeLotSize(_symbol, FixedLotSize);
            }
            amount  = AccountBalance() * (RiskPercentage / 100.0);
            lotSize = CalcLotSize(amount, stopLossPrice, orderType);
            Print("COrders:GetLotSize() Use Risk percentage ",RiskPercentage,"%  amount:", amount, " lots:", lotSize);
            return lotSize;
         break;
      }
      Print("COrders:GetLotSize() unknown mode-> return fixed lot size:",  FixedLotSize);
      return _utils.NormalizeLotSize(_symbol, FixedLotSize);
   }
   
    //------------------------------------------------------------------------------------
   double CalcLotSize(double amountToRisk,double stopLossPrice,int orderType,bool returnNormalizedLots=true)
   {  
      RefreshRates();
      int    symbolType                 = GetSymbolType(_symbol);
      string currentCounterPairForCross = GetCounterPairForCross(_symbol);
      double lotSize = 0.0;
      double bid           = _utils.BidPrice(_symbol);
      double ask           = _utils.AskPrice(_symbol);
      double symbolLotSize = _utils.GetLotSize(_symbol);
      
      if (orderType == OP_BUY)
      {
          double slPips = _utils.PriceToPips(_symbol, MathAbs(stopLossPrice - bid));
          Print(_symbol," CalcLotSize buy: type:", symbolType, "  amount:", DoubleToStr(amountToRisk,2), " sl price:", DoubleToStr(stopLossPrice,5), " ask:", DoubleToStr(ask,5), "sl pips", DoubleToStr(slPips,2));
      }
      else
      {
         double slPips =_utils.PriceToPips(_symbol, MathAbs(stopLossPrice - ask));
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
                  lotSize = (-amountToRisk * _utils.BidPrice(currentCounterPairForCross)) / (symbolLotSize * (stopLossPrice - ask)); 
               break;
               
               case OP_SELL:  
                  lotSize = (-amountToRisk * _utils.AskPrice(currentCounterPairForCross)) / (symbolLotSize * (bid - stopLossPrice)); 
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
                  lotSize = -amountToRisk / (symbolLotSize * _utils.BidPrice(currentCounterPairForCross) * (stopLossPrice - ask)); 
               break;
               
               case OP_SELL:  
                  lotSize = -amountToRisk / (symbolLotSize * _utils.AskPrice(currentCounterPairForCross) * (bid - stopLossPrice)); 
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
      if (lotSize < 0) lotSize = 0;
      if (returnNormalizedLots) lotSize = _utils.NormalizeLotSize(_symbol, lotSize);
      Print(" lotSize:", lotSize);
      return lotSize;
   }  // LotSize body end


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
       return new COrder(ticket, _symbol, openPrice, closePrice, profit, openTime, closeTime, isBuy);
   }
};