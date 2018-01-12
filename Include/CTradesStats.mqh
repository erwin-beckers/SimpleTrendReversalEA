
class CTradeStats
{
private:
   int     _today;
   int     _prevOrdersTotal;
   int     _magicNumberBuy;
   int     _magicNumberSell;
   
public:
   int     TotalCount;              // # of open orders for this chart / ea
   int     BuyOrders;               // # of open buy orders for this chart / ea
   int     SellOrders;              // # of open sell orders for this chart / ea
   
   double  TotalProfit;             // total profit of all open orders for this chart / ea
   double  TotalProfitPips;         // total profit of all open orders for this chart / ea
   double  TotalProfitOfSellOrders; // total profit of all sell open orders for this chart / ea
   double  TotalProfitOfBuyOrders;  // total profit of all buy open orders for this chart / ea
   
   int     OrdersWon;               // Total # of orders won by this ea on this chart            
   int     OrdersLost;              // Total # of orders won by this ea on this chart       
   double  WinPercentage;           // percentage of orders won;     
   double  AllTimeProfit;           // all profit made by this ea on this chart            
   double  ProfitToday;             // profit made by this ea on this chart today
   double  ProfitYesterday;         // profit made by this ea on this chart yesterday
   
   double  AllTimeProfitPips;       // all profit made by this ea on this chart in pips          
   double  ProfitTodayPips;         // profit made by this ea on this chart today in pips
   double  ProfitYesterdayPips;     // profit made by this ea on this chart yesterday in pips
   double  ProfitFactor;            // profit factor
   double  ExpectedPayOff;          // expected payoff / trade   
   double  TotalLotsTraded;         // total nr of lots traded
   int     TotalTrades;             // total nr of trades traded
   double  AverageLotsPerTrade;     // average lot size / trade   
   int     GlobalOrderCount;        // # open orders for this account
   double  GlobalProfit;            // total profit of all open orders on this account
   double  HighestBuyPrice;
   double  LowestBuyPrice;
   double  HighestSellPrice;
   double  LowestSellPrice;
   
   CTradeStats(int magicNumberBuy, int magicNumberSell)
   {
      _magicNumberBuy  = magicNumberBuy;
      _magicNumberSell = magicNumberSell;
      _prevOrdersTotal = 0;
      _today=0;
      Refresh();
      RefreshHistory();
   }
   
   //------------------------------------------------------------------------------------
   //  Refresh statistics of all closed trades
   //------------------------------------------------------------------------------------
    void RefreshHistory()
    {      
      // get history
      AllTimeProfit              = 0;
      AllTimeProfitPips          = 0;
      OrdersWon                  = 0;
      OrdersLost                 = 0;     
      ProfitToday                = 0;
      ProfitTodayPips            = 0;
      ProfitYesterday            = 0;
      ProfitYesterdayPips        = 0; 
      WinPercentage              = 0;
      ProfitFactor               = 0;
      ExpectedPayOff             = 0;
      TotalLotsTraded            = 0;
      AverageLotsPerTrade        = 0;
      TotalTrades                = 0;
      double totalAmountWon      = 0;
      double totalAmountLost     = 0; 
      datetime now               = TimeCurrent();
      datetime yesterday         = TimeCurrent() - 60 * 60 * 24;
      
      if (IsTesting() || IsOptimization()) return;      
      
      for (int i=0; i < OrdersHistoryTotal(); ++i)
      {
        if(OrderSelect(i, SELECT_BY_POS,MODE_HISTORY))
        {
            if (OrderMagicNumber() == _magicNumberBuy || OrderMagicNumber() == _magicNumberSell)
            {
               double digits   = MarketInfo(OrderSymbol(), MODE_DIGITS);
               double points   = MarketInfo(OrderSymbol(), MODE_POINT);
               double mult = 1.0;
               if (digits == 3 || digits == 5) mult = 10.0;

               TotalTrades = TotalTrades+1;
               TotalLotsTraded += OrderLots();
               double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();
               AllTimeProfit += orderProfit;
               double pips=0;
               if (OrderType() == OP_BUY)
               {     
                  pips = ( OrderClosePrice() - OrderOpenPrice()) ;
               }
               else
               {
                  pips = ( OrderOpenPrice() - OrderClosePrice());
               }

               if (pips != 0)
               {
                  pips /= mult;
                  pips /= points;
               }
               AllTimeProfitPips += pips;
               
               if (orderProfit > 0) 
               {
                  OrdersWon++;
                  totalAmountWon += orderProfit;
               }
               if (orderProfit < 0) 
               {
                  OrdersLost++;
                  totalAmountLost += orderProfit;
               }
               
               datetime orderTime = OrderCloseTime();
               
               if ( TimeDay(orderTime)   == TimeDay(now) &&
                    TimeMonth(orderTime) == TimeMonth(now) &&
                    TimeYear(orderTime)  == TimeYear(now) )
               { 
                  ProfitToday     += orderProfit;
                  ProfitTodayPips += pips;
               }
               
               if ( TimeDay(orderTime)   == TimeDay(yesterday) &&
                    TimeMonth(orderTime) == TimeMonth(yesterday) &&
                    TimeYear(orderTime)  == TimeYear(yesterday) )
               { 
                  ProfitYesterday     += orderProfit;
                  ProfitYesterdayPips += pips;
               }
            }
        }
      }
      if (OrdersWon + OrdersLost != 0)
      {
         double won =(double)OrdersWon;
         double lost=(double)OrdersLost;
         WinPercentage =  (won / (won + lost) ) * 100.0;
      }
      
      if (totalAmountLost !=0)
      {
         ProfitFactor = MathAbs( totalAmountWon / totalAmountLost);
      }
      
      if (TotalTrades > 0)
      {
         double dTrades=TotalTrades;
         ExpectedPayOff = AllTimeProfit / dTrades;
         AverageLotsPerTrade = TotalLotsTraded /  dTrades;
      }
   }
   
   
   //------------------------------------------------------------------------------------
   //  Refresh statistics of all open trades
   //------------------------------------------------------------------------------------
   void Refresh()
   {
      // refresh history when new day arrives
      if ( (TimeDay( TimeCurrent()) != _today) || ( OrdersTotal() != _prevOrdersTotal))
      {
        _today           = TimeDay( TimeCurrent());
        _prevOrdersTotal = OrdersTotal();
        RefreshHistory(); 
      }
   
      GlobalOrderCount = 0;
      GlobalProfit     = 0;
      TotalCount = 0;
      SellOrders = 0;
      BuyOrders  = 0;
      TotalProfit= 0;
	  TotalProfitPips = 0;
      TotalProfitOfSellOrders = 0;
      TotalProfitOfBuyOrders  = 0;
      HighestBuyPrice  = 0;
      LowestBuyPrice   = 999999;
      HighestSellPrice = 0;
      LowestSellPrice  = 999999;
      
      for (int i=0; i < OrdersTotal(); ++i)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();
            GlobalOrderCount++;
            GlobalProfit += orderProfit;
            double price = OrderOpenPrice();
            if (OrderMagicNumber() == _magicNumberBuy || OrderMagicNumber() == _magicNumberSell)
            {
				TotalProfit += orderProfit;
				TotalCount++;
			   
				double pips     = 0;
				double priceBid = MarketInfo(OrderSymbol(), MODE_BID);
				double priceAsk = MarketInfo(OrderSymbol(), MODE_ASK);
				double points   = MarketInfo(OrderSymbol(), MODE_POINT);
				double digits   = MarketInfo(OrderSymbol(), MODE_DIGITS);
				int orderType   = OrderType();
				double mult = 1.0;
				if (digits == 3 || digits == 5) mult = 10.0;
               
				if (IsBuy(orderType)) 
				{
					BuyOrders++;
					TotalProfitOfBuyOrders += orderProfit;
					HighestBuyPrice = MathMax(HighestBuyPrice, price);
					LowestBuyPrice  = MathMin(LowestBuyPrice, price);
					pips		    = ( priceBid - OrderOpenPrice());
				}
				else
				{
					SellOrders=SellOrders+1;
					TotalProfitOfSellOrders += orderProfit;
					HighestSellPrice = MathMax(HighestSellPrice, price);
					LowestSellPrice  = MathMin(LowestSellPrice, price);
					pips			 = ( OrderOpenPrice() - priceAsk);
				}
				if (pips != 0)
				{
					pips /= mult;
					pips /= points;
					TotalProfitPips += pips;
				}
            }
         }
      }
   }
   
private:
   bool IsBuy(int orderType)
   {
      return (orderType  == OP_BUY ||  orderType== OP_BUYLIMIT || orderType== OP_BUYSTOP);
   }   
};