

extern string      __trading                    = " ------- trading & alerts settings ------------";
extern bool        allowTrading                 = false;
extern bool        sendAlerts                   = false;
extern bool        emailAlerts                  = false;
extern bool        stopLossAtZigZagArrow        = true;
extern int         minsBetween2TradesOnSamePair = 720;
extern bool        AllowReEntriesOnSamePair     = false;
extern int         SignalInvalidAfterHours      = 12;
extern int         SignalInvalidAfterPips       = 30;
extern string      TradePairs                   = "EURUSD USDJPY GBPUSD USDCHF USDCAD AUDUSD NZDUSD EURCHF EURGBP EURCAD EURAUD EURNZD EURJPY GBPJPY CHFJPY CADJPY AUDJPY NZDJPY GBPCHF GBPAUD GBPCAD GBPNZD AUDCHF AUDCAD AUDNZD CADCHF NZDCHF NZDCAD";


#include <COrders.mqh>
#include <CTrailingStop.mqh>
#include <CTimeFilter.mqh>
#include <CNewsFilter.mqh>
#include <CStrategy.mqh>

//--------------------------------------------------------------------
class CPair
{
private:
   CNewsFilter*   _newsFilter;
   CTimeFilter*   _timeFilter;
   CTrailingStop* _trailingStop;
   COrders*       _orders;
   CUtils*        _utils;
   string         _symbol;
   NEWS_IMPACT    _impact;
   bool           _allowedToTradeNews;
   bool           _allowedToTradeTimeFilter;
   IStrategy*     _strategy;
   CSignal*       _signal;
   
public: 
   //--------------------------------------------------------------------
   CPair(string symbol, IStrategy* strategy, CNewsFilter* newsFilter, CUtils* utils)
   {
      //_log=symbol=="EURCAD";
      _symbol       = symbol;
      _utils        = utils;
      _trailingStop = new CTrailingStop(symbol);
      _newsFilter   = newsFilter;
      _timeFilter   = new CTimeFilter();
      _orders       = new COrders(symbol);
      _strategy     = strategy;
      _signal       = NULL;
      SetStoplossOnOpenOrder();
   }
   
   //--------------------------------------------------------------------
   ~CPair()
   {
      delete _orders;
      delete _timeFilter;
      delete _trailingStop;
      delete _strategy;
   }
   
private:
   //--------------------------------------------------------------------
   void DrawRect(int line, int xPos,color clr, int width, int height=17, int yoff=0)
   {
      string id="_l"+IntegerToString(line)+"c"+IntegerToString(xPos); 
      ObjectCreate(0,id,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0, id, OBJPROP_XDISTANCE, xPos);
      ObjectSetInteger(0, id, OBJPROP_YDISTANCE, line*17+22+yoff);
      ObjectSetInteger(0, id, OBJPROP_BGCOLOR  , clr);
      ObjectSetInteger(0, id, OBJPROP_XSIZE    , width);
      ObjectSetInteger(0, id, OBJPROP_YSIZE    , height);
      ObjectSetInteger(0, id, OBJPROP_BACK     , true);
      ObjectSetInteger(0, id, OBJPROP_WIDTH    , 0);
   }
   //--------------------------------------------------------------------
   void DrawRectBg(int x, int y, int width, int height,color clr)
   {
      string id="_r"+IntegerToString(x)+"c"+IntegerToString(y); 
      ObjectCreate(0,id,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0, id, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, id, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, id, OBJPROP_BGCOLOR  , clr);
      ObjectSetInteger(0, id, OBJPROP_XSIZE    , width);
      ObjectSetInteger(0, id, OBJPROP_YSIZE    , height);
      ObjectSetInteger(0, id, OBJPROP_BACK     , true);
      ObjectSetInteger(0, id, OBJPROP_WIDTH    , 0);
   }
   
   //--------------------------------------------------------------------
   void DrawTextLine(int line, int column, string text, color clr, int xoff=0, int yoff=0)
   {
      string id="_l"+IntegerToString(line)+"c"+IntegerToString(column);
      double x= column==0 ?  20 : (column*70+35);
      if (line ==0 && column > 0) x=x-10;
      ObjectCreate(0,id,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0, id, OBJPROP_XDISTANCE, ((int)x)+xoff);
      ObjectSetInteger(0, id, OBJPROP_YDISTANCE, line*17+20+yoff);
      ObjectSetString (0, id, OBJPROP_TEXT     , text);
      ObjectSetString (0, id, OBJPROP_FONT     , "Courier New");
      ObjectSetInteger(0, id, OBJPROP_ANCHOR   , ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, id, OBJPROP_FONTSIZE , 10);
      ObjectSetInteger(0, id, OBJPROP_COLOR    , clr);
   }
   //--------------------------------------------------------------------
   void DrawText(int line, int xPos, string text, color clr, int yoff=0)
   {
      string id="_l"+IntegerToString(line)+"c"+IntegerToString(xPos);
      ObjectCreate(0,id,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0, id, OBJPROP_XDISTANCE, xPos);
      ObjectSetInteger(0, id, OBJPROP_YDISTANCE, line*17+20+yoff);
      ObjectSetString (0, id, OBJPROP_TEXT     , text);
      ObjectSetString (0, id, OBJPROP_FONT     , "Courier New");
      ObjectSetInteger(0, id, OBJPROP_ANCHOR   , ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, id, OBJPROP_FONTSIZE , 10);
      ObjectSetInteger(0, id, OBJPROP_COLOR    , clr);
      ObjectSetInteger(0, id, OBJPROP_BGCOLOR  , clrBlack);
   }
   
public:   
   //--------------------------------------------------------------------
   int SignalCount()
   {
      int cnt =0;
      if (_signal == NULL ) return 0; 
      if (_signal.IsBuy == false && _signal.IsSell == false) return 0;
      for (int i=0; i < _strategy.GetIndicatorCount(); ++i)
      {
         CIndicator* ind = _strategy.GetIndicator(i);
         if (ind.IsValid) cnt++;
      }
      if ( _allowedToTradeNews && UseNewsFilter )  cnt = cnt + 1;
      if ( _allowedToTradeTimeFilter ) cnt = cnt + 1;
      if (_signal.Age <= SignalInvalidAfterHours) cnt=cnt + 1;
      if (_signal.PipsAway <= SignalInvalidAfterPips) cnt=cnt+1;
      return cnt;
   }
   
   //--------------------------------------------------------------------
   int GetMaxSignalCount()
   {
      int cnt= _strategy.GetIndicatorCount();
      if (UseNewsFilter) cnt = cnt + 1;
      cnt = cnt + 1; // time filter
      cnt = cnt + 1; // signal age
      cnt = cnt + 1; // signal pips from price
      return cnt;
   }
   
   //--------------------------------------------------------------------
   void DrawHeader()
   {
      double maxX = (1 + GetMaxSignalCount() ) * 60 + 140;
      
      DrawRectBg(10, 35, (int)maxX, 20, clrGray);
      
      DrawText(1, 20, "Time", White);
      DrawText(1, 81, "Pair", White);
      
      int x = 140;
      for (int i=0; i < _strategy.GetIndicatorCount();++i)
      {
         CIndicator* indicator = _strategy.GetIndicator(i);
         DrawText(1,  x, indicator.Name, White);
         x += 60;
      }
      if (UseNewsFilter)
      {
         DrawText(1, x, "News",White);
         x += 60;
      }
      DrawText(1, x, "Time",White);
      x += 60;
      
      DrawText(1, x, "Age",White);
      x += 60;

      DrawText(1, x, "Pips",White);
      x += 60;
      
      DrawText(1, x, "Valid",White);
      x += 60;
   }
   
   //--------------------------------------------------------------------
   void Draw(int line)
   {
      if (_signal == NULL) return;
      int xpos = 140;
      DrawTextLine(line, 0,TimeToStr(TimeCurrent(), TIME_MINUTES), White);
      DrawTextLine(line, 1, _symbol, White, -30);
      
      color zigClr = clrGray;
      if (_signal.IsBuy  ) zigClr = Green;
      else if (_signal.IsSell ) zigClr = Red;
      
      for (int i=0; i < _strategy.GetIndicatorCount();++i)
      {
         CIndicator* indicator = _strategy.GetIndicator(i);
         
         color clr =  (indicator.IsValid ) ? zigClr : clrGray;
         DrawRect(line, xpos, clr,60 ); xpos+=60;
      }

      if (UseNewsFilter)
      {
         color newsColor = _allowedToTradeNews ? zigClr : clrGray;
         DrawRect(line, xpos, zigClr,60 ); xpos+=60;
      }   
      
      color timeColor = _allowedToTradeTimeFilter ? zigClr : clrGray;
      DrawRect(line, xpos, zigClr,60 ); xpos+=60;

      color ageColor = (_signal.Age <= SignalInvalidAfterHours )? zigClr : clrGray;
      DrawRect(line, xpos, ageColor,60 ); xpos+=60;
      
      color pipsColor = (_signal.PipsAway <= SignalInvalidAfterPips )? zigClr : clrGray;
      DrawRect(line, xpos, pipsColor,60 ); xpos+=60;

      color validColor = ( SignalCount() == GetMaxSignalCount() ) ? zigClr : clrGray;
      DrawRect(line, xpos, validColor, 60  );xpos+=60;


      if (validColor != clrGray)
      {
         if (zigClr == Green)  DrawText(line, xpos-42, "buy", White, 2);
         if (zigClr == Red) DrawText(line, xpos-42, "sell", White, 2);
      }
   }
   
   //--------------------------------------------------------------------
   void Trail()
   {
      _trailingStop.Trail();
   }
   
   //--------------------------------------------------------------------
   string GetSymbol()
   {
     return _symbol;
   }
   
   //--------------------------------------------------------------------
   double GetStoploss(int ticket)
   {
     return _trailingStop.GetStoploss(ticket);
   }
   
   //--------------------------------------------------------------------
   double GetRiskReward(int ticket)
   {
     return _trailingStop.GetRiskReward(ticket);
   }
      
   //--------------------------------------------------------------------
   void Refresh()
   {
     _signal = _strategy.Refresh();
     
      string      news = "";
      _allowedToTradeNews       = _newsFilter.GetNews(_symbol, news, _impact);  
      _allowedToTradeTimeFilter = _timeFilter.CanTrade();
      
      if ( !_signal.IsBuy && !_signal.IsSell ) return;
      if ( SignalCount() != GetMaxSignalCount() ) return;
      SendAlerts();
      CloseOppositeOrders();
      OpenNewOrder();
   }
   
   //--------------------------------------------------------------------
   void SendAlerts()
   {
      // send alerts enabled ?
      if (!sendAlerts) return;      
      if (_signal == NULL) return;
      // valid signal ?
      if ( SignalCount() != GetMaxSignalCount() ) return;
      
      if (_signal.IsBuy)
      {
         // send buy alert
         _utils.SendNotify(_symbol, _symbol + " BUY", emailAlerts,   _utils.GetTimeFrame(Period())+ " buy");
      }
      else if (_signal.IsSell)
      {
         // send sell alert
        _utils.SendNotify(_symbol, _symbol + " SELL", emailAlerts,   _utils.GetTimeFrame(Period())+ " sell");
      }
   }
   
   //--------------------------------------------------------------------
   void CloseOppositeOrders()
   {  
      if (_signal == NULL) return;
      
	  // is trading enabled ?
      if (!allowTrading) return;  

      // is market open ?
      if (!IsTesting() && !IsOptimization())
      {
        if (!MarketInfo(_symbol, MODE_TRADEALLOWED)) return;
      }
	  
	   // is spread on this pair ok ?
      if (!_orders.IsSpreadOk()) return;
     
      // do we have a valid signal ?
      if ( SignalCount() != GetMaxSignalCount() ) return;
      
      if (_signal.IsBuy)
      {  
		// if it is a buy signal, then close any sell orders
         _orders.CloseOrderByType(OP_SELL);
      }
      else if (_signal.IsSell)
      {
         // if it is a sell signal, then close any buy orders
         _orders.CloseOrderByType( OP_BUY);
      }
   }
   
   //--------------------------------------------------------------------
   void OpenNewOrder()
   {  
      if (_signal == NULL) return;

      // is trading enabled ?
      if (!allowTrading) return;  
	  
      // is market open ?
      if (!IsTesting() && !IsOptimization())
      {
        if (!MarketInfo(_symbol, MODE_TRADEALLOWED)) return;
      }
	  
	  // is spread on this pair ok ?
      if (!_orders.IsSpreadOk()) return;
	  	  
      // do we have a valid signal ?
      if ( SignalCount() != GetMaxSignalCount() ) return;

	  // do we have any trades running for this pair
      int  orderCount  = _orders.GetOrderCount();
      if (orderCount != 0) return; // yes, return
      
      // no trade running atm. Lets see if we are allowed to open a new one.

      // get last trade for this symbol
      COrder* order = _orders.GetLastClosedOrder();
      if (order != NULL)
      {
        bool lastTradeWasBuyOrder  = order.IsBuy;
        bool lastTradeWasSellOrder = order.IsSell;
        
        // is this a re-entry
        if ( (lastTradeWasBuyOrder  && _signal.IsBuy) ||
             (lastTradeWasSellOrder && _signal.IsSell) )
             {
                // yes, then check number of minutes elapsed since this last trade has closed
                double timeElapsed =(double)(TimeCurrent() - order.CloseTime);
                timeElapsed /= 60.0;
                delete order;

                int minsSinceLastTrade = (int)timeElapsed;

                // did enough time pass since last trade ?
                if (minsSinceLastTrade < minsBetween2TradesOnSamePair)
                {
                    // no, then return
                    return;
                }
            }
      }
      
      // did we reach the max nr of open orders ?
      if (_orders.CanOpenNewOrder() == false) 
	  {
		 // yes then don't open another trade             
		 return; 
	  }
       
      // ok, we are allowed to open a new order , so place order..
      if (_signal.IsBuy)
      {  
         // place buy order
         Print(_symbol, " -> place buy order");
         double slZigZag = _signal.StopLoss;
         double price    = _utils.AskPrice(_symbol);
         
         double orderSl  = price - _utils.PipsToPrice(_symbol, OrderHiddenSL);
         double sl       = orderSl;
         if (stopLossAtZigZagArrow)
         {
            sl = slZigZag;
            if (OrderHiddenSL > 0 && slZigZag < orderSl) sl = orderSl;
         }
         Print(_symbol," open buy trade @", DoubleToStr(price, 5), " sl:", DoubleToStr(sl, 5));
         int ticket = _orders.OpenBuyOrder(_orders.GetLotSize(sl, OP_BUY), 0, 0);
         if (ticket >= 0) _trailingStop.SetInitalStoploss(ticket, sl);
      }
      else if (_signal.IsSell)
      {
         // place sell order
         Print(_symbol, " -> place sell order");
         double slZigZag = _signal.StopLoss;
         double price    = _utils.BidPrice(_symbol);
         double orderSl  = price + _utils.PipsToPrice(_symbol, OrderHiddenSL);
         double sl       = orderSl;
         if (stopLossAtZigZagArrow ) 
         {
            sl = slZigZag;
            if (OrderHiddenSL > 0 && slZigZag > orderSl) sl = orderSl;
         }
         Print(_symbol," open sell trade @", DoubleToStr(price, 5), " sl:", DoubleToStr(sl, 5));
         int ticket = _orders.OpenSellOrder(_orders.GetLotSize(sl, OP_SELL), 0, 0);
         if (ticket >= 0) _trailingStop.SetInitalStoploss(ticket, sl);
      }
   }
   
   
//--------------------------------------------------------------------
void SetStoplossOnOpenOrder()
{
   if (!allowTrading) return;
   
   // loop through all open orders
   for (int i=0; i < OrdersTotal();++i)
   {
	  // select next order
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
		 // check if magic number matches
         if (OrderMagicNumber() == MagicNumberBuy || OrderMagicNumber() == MagicNumberSell)
         {
		        // check if order is for our symbol
            if (OrderSymbol() != _symbol) continue;
            
		   	    // ask strategy for the stoploss for this order

            double strategySL = _strategy.GetStopLossForOpenOrder();
            if (OrderType() == OP_BUY)
            {
               double orderSl  = OrderOpenPrice() - _utils.PipsToPrice(_symbol, OrderHiddenSL);
               
               if (stopLossAtZigZagArrow  && OrderHiddenSL > 0 && strategySL < orderSl)
               {
				      // set stoploss to OrderHiddenSL
                  Print(_symbol, " -> order ", OrderTicket()," set SL to @ ", DoubleToStr(orderSl, 5));
                  _trailingStop.SetInitalStoploss(OrderTicket(), orderSl);
               }
               else if (stopLossAtZigZagArrow && strategySL > 0)
               {
				      // set stoploss to zigzag
                  Print(_symbol, " -> order ", OrderTicket()," set SL to zigzag @ ", DoubleToStr(strategySL, 5));
                  _trailingStop.SetInitalStoploss(OrderTicket(), strategySL);
               }
               else
               {
				      // set stoploss to OrderHiddenSL
                  Print(_symbol, " -> order ", OrderTicket()," set SL to @ ", DoubleToStr(orderSl, 5));
                  _trailingStop.SetInitalStoploss(OrderTicket(), orderSl);
               }
            }
            else  if (OrderType() == OP_SELL)
            {
               double orderSl  = OrderOpenPrice() + _utils.PipsToPrice(_symbol, OrderHiddenSL);
               if (stopLossAtZigZagArrow && OrderHiddenSL > 0 && strategySL > orderSl)
               {
				      // set stoploss to OrderHiddenSL
                  Print(_symbol, " -> order ", OrderTicket()," set virtual SL to @ ", DoubleToStr(orderSl, 5));
                  _trailingStop.SetInitalStoploss(OrderTicket(), orderSl);
               }
               else if (stopLossAtZigZagArrow && strategySL > 0)
               {
				      // set stoploss to zigzag
                  Print(_symbol, " -> order " ,OrderTicket()," set virtual SL to zigzag @ ", DoubleToStr(strategySL, 5));
                  _trailingStop.SetInitalStoploss(OrderTicket(), strategySL);
               }
               else
               {
				      // set stoploss to OrderHiddenSL
                  Print(_symbol, " -> order ", OrderTicket()," set SL to @ ", DoubleToStr(orderSl, 5));
                  _trailingStop.SetInitalStoploss(OrderTicket(), orderSl);
               }
            }
         }
      }
   }
}
};
