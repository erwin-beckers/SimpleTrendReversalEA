//+------------------------------------------------------------------+
//|                                     SimpleDailyTrendReversal.mq4 |
//|                                    Copyright 2017, Erwin Beckers |
//|                                              www.erwinbeckers.nl |
//
// # Donations are welcome !!
// Like what you see ? Feel free to donate to support further developments..
// BTC: 1J4npABsiQa2GkJu5q6RsjtCR1jxNvZdtu
// BCC: 1J4npABsiQa2GkJu5q6RsjtCR1jxNvZdtu
// LTC: LN4BCwQEUzULg3z6NpA5KQSvUftv3xG9xA
// ETH: 0xfa77e81d94b39b49f4b3dc7880c68ad57e6e7163
// NEO: ANQxQxFd4z5c7P3W1azK7zxvzRNY4dwbJg
//+------------------------------------------------------------------+
#property copyright "Copyright 2017-2018, Erwin Beckers"
#property link      "www.erwinbeckers.nl"
#property version   "1.25"
#property strict

string version = "1.25";
extern string      __chartTemplate              = " ------- Chart template ------------";
extern string      ChartTemplate                = "Trend Reversal Strategy PC.tpl";

#include <CPair.mqh>
#include <CTrailingStop.mqh>
#include <CGui.mqh>
#include <CInfoPanel.mqh>
#include <CTradesStats.mqh>
#include <CMrdFxStrategy.mqh>


CNewsFilter*     _newsFilter;  
CTradeStats*     _tradeStats;

CInfoPanel*      _infoPanel = NULL;
CLabel*          _labelTitle;
CLabelKeyValue*  _labelBalance;
CLabelKeyValue*  _labelEquity;
CLabelKeyValue*  _labelFreeMargin;
CLabelKeyValue*  _labelMargin;
CLabelKeyValue*  _labelGlobalOrders;
CLabelKeyValue*  _labelGlobalProfit;

CLine*           _line1;
CLabelKeyValue*  _labelOrders ;
CLabelKeyValue*  _labelOrdersBuySell;
CLabelKeyValue*  _labelProfitBuySell;
CLabelKeyValue*  _labelProfit;

CLine*           _line3;
CLabelKeyValue*  _labelTotalTrades;
CLabelKeyValue*  _labelOrdersWonLost;

CLine*           _line4;
CLabelKeyValue*  _labelProfitToday;
CLabelKeyValue*  _labelProfitYesterday;
CLabelKeyValue*  _labelProfitAllTime;
CLabelKeyValue*  _labelProfitFactor;
CLabelKeyValue*  _labelExpectedPayOff;

CLine*           _line5;
CLabelKeyValue*  _labelTotalLotsTraded;
CLabelKeyValue*  _labelAverageLotsPerTrade;

CPair* _pairs[];
int    _pairCount=0;

//--------------------------------------------------------------------
void Clear()
{ 
   bool deleted = false;
   do {
      deleted = false;
      for (int i = 0; i < ObjectsTotal(); ++i)
      {
         string name = ObjectName(0, i);
         if (StringSubstr(name, 0, 1) == "_")
         {
            ObjectDelete(0, name);
            deleted = true;
            break;
         }
      }
   } while (deleted); 
}

//--------------------------------------------------------------------
void SetupPanel()
{
   _infoPanel               = new CInfoPanel(380, 300);
   
   _labelTitle              = new CLabel();
   _labelBalance            = new CLabelKeyValue("Balance",150);
   _labelEquity             = new CLabelKeyValue("Equity",150);
   _labelFreeMargin         = new CLabelKeyValue("Free margin",150);
   _labelMargin             = new CLabelKeyValue("Margin",150);
   _labelGlobalOrders       = new CLabelKeyValue("Global Open Orders",150);
   _labelGlobalProfit       = new CLabelKeyValue("Global Profit/Loss",150);
   _line1                   = new CLine();
   _labelOrders             = new CLabelKeyValue("Open Orders",150);
   _labelOrdersBuySell      = new CLabelKeyValue("       buy/sell",150);
   _labelProfitBuySell      = new CLabelKeyValue("   P/L buy/sell",150);
   _labelProfit             = new CLabelKeyValue("Profit/Loss",150);
   
   _line3                   = new CLine();
   _labelTotalTrades        = new CLabelKeyValue("Trades",150);
   _labelOrdersWonLost      = new CLabelKeyValue("Won/Lost",150);
   
   _line4                   = new CLine();
   _labelProfitToday        = new CLabelKeyValue("Profit today",150);
   _labelProfitYesterday    = new CLabelKeyValue("Profit yesterday",150);
   _labelProfitAllTime      = new CLabelKeyValue("All time profit",150);
   _labelProfitFactor       = new CLabelKeyValue("Profit factor",150);
   _labelExpectedPayOff     = new CLabelKeyValue("Expected payoff",150);
   
   _line5                   = new CLine();
   _labelTotalLotsTraded    = new CLabelKeyValue("Total lots traded",150);
   _labelAverageLotsPerTrade= new CLabelKeyValue("Average lots/trade",150);

   _labelTitle.Text="--- Trend Reversal EA v"+version+" --- ";
   _labelTitle.FontSize = 10;   
   _line1.X = 0;
   _line1.Width = 380;
   _line3.X = 0;
   _line3.Width = 380;
   _line4.X = 0;
   _line4.Width = 380;
   _line5.X = 0;
   _line5.Width = 380;
   _infoPanel.SetPosition(840,20);
   _infoPanel.Add(_labelTitle, 70, 5);
   _infoPanel.Add(_labelBalance, 20, 10);
   _infoPanel.Add(_labelEquity, 20, 0);
   _infoPanel.Add(_labelFreeMargin, 20, 0);
   _infoPanel.Add(_labelMargin, 20, 0);
   _infoPanel.Add(_labelGlobalOrders, 20, 0);
   _infoPanel.Add(_labelGlobalProfit, 20, 0);
   _infoPanel.Add(_line1, 0, 5);
   _infoPanel.Add(_labelOrders, 20, -10);
   _infoPanel.Add(_labelOrdersBuySell, 20, 0);
   _infoPanel.Add(_labelProfitBuySell, 20, 0);
   _infoPanel.Add(_labelProfit, 20, 0);
   _infoPanel.Add(_line3, 0, 5);
   _infoPanel.Add(_labelTotalTrades, 20, -10);
   _infoPanel.Add(_labelOrdersWonLost, 20, 0);
   _infoPanel.Add(_line4, 0, 5);
   _infoPanel.Add(_labelProfitToday, 20, -10);
   _infoPanel.Add(_labelProfitYesterday, 20, 0);
   _infoPanel.Add(_labelProfitAllTime, 20, 0);
   _infoPanel.Add(_labelProfitFactor, 20, 0);
   _infoPanel.Add(_labelExpectedPayOff, 20, 0);
   _infoPanel.Add(_line5, 0, 5);
   _infoPanel.Add(_labelTotalLotsTraded, 20, -10);
   _infoPanel.Add(_labelAverageLotsPerTrade,20, 0);
   _infoPanel.Update();  
}

static int _line=0;


//--------------------------------------------------------------------
void OpenChart(string pair) 
{
   ulong chartId = ChartOpen(pair, Period());
   ChartApplyTemplate(chartId, ChartTemplate);
}


//--------------------------------------------------------------------
void Draw(int line, int column, string text, color clr, int xoff=0)
{
   string id="_l"+IntegerToString(line)+"c"+IntegerToString(column);
   double x= column==0 ?  20 : (column*70+35);
   if (_line ==0 && column > 0) x=x-10;
   ObjectCreate(0,id,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE, ((int)x)+xoff);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,_line*17+20);
   ObjectSetString(0,id,OBJPROP_TEXT,text);
   ObjectSetString(0,id,OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,id,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,id,OBJPROP_COLOR,clr);
}

//--------------------------------------------------------------------
void DrawWingDings(int line, int column, string text, color clr, int xoff=0)
{
   string id="_l"+IntegerToString(line)+"c"+IntegerToString(column);
   double x= column==0 ?  20 : (column*70+30);
   ObjectCreate(0,id,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE, ((int)x)+xoff );
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,_line*17+23);
   ObjectSetString(0,id,OBJPROP_TEXT,text);
   ObjectSetString(0,id,OBJPROP_FONT,"WingDings");
   ObjectSetInteger(0,id,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,id,OBJPROP_COLOR,clr);
}

//--------------------------------------------------------------------
void DrawRect(int line, int xPos,color clr, int width, int height=17)
{
   string id="_l"+IntegerToString(line)+"c"+IntegerToString(xPos); 
   ObjectCreate(0,id,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE, xPos);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,_line*17+22);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,clr);
   ObjectSetInteger(0,id,OBJPROP_XSIZE,  width);
   ObjectSetInteger(0,id,OBJPROP_YSIZE,  17);
   ObjectSetInteger(0,id, OBJPROP_BACK, true);
   ObjectSetInteger(0,id, OBJPROP_WIDTH,0);
}

//--------------------------------------------------------------------
void DrawText(int line, int xPos, string text, color clr)
{
   string id="_l"+IntegerToString(line)+"c"+IntegerToString(xPos);
   ObjectCreate(0,id,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE, xPos);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,_line*17+20);
   ObjectSetString(0,id,OBJPROP_TEXT,text);
   ObjectSetString(0,id,OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,id,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,id,OBJPROP_COLOR,clr);
}


//--------------------------------------------------------------------
void RefreshPairs()
{ 
   // refresh pairs
   for(int i = 0; i < _pairCount; ++i)
   {
     _pairs[i].Refresh();
   }   
}


//--------------------------------------------------------------------
void DrawPairs()
{
   if (IsTesting() || IsOptimization()) return;
   Clear();
   _line=0;
   
   Draw(_line, 0, "v"+version +" "+_utils.GetTimeFrame(Period())+ " Last update: " + TimeToStr(TimeCurrent()),White);
   _line=2;
   
   // draw pairs
   if (_pairCount > 0)
   {
      _pairs[0].DrawHeader();
      int maxSignals = _pairs[0].GetMaxSignalCount();
      
      for (int signals  = maxSignals; signals >= 1; signals--)
      {
         for(int idx = 0; idx < _pairCount; ++idx)
         {
            if (_pairs[idx].SignalCount() == signals)
            {
               _pairs[idx].Draw(_line);
               _line++;
            }
        }
      }
   }
}

//--------------------------------------------------------------------
void DrawOpenOrders()
{ 
   if (IsTesting() || IsOptimization()) return;
   _line++;
   Draw(_line, 0, "Opened", White);
   Draw(_line, 2, "Symbol", White);
   Draw(_line, 3, "Type", White);
   Draw(_line, 4, "Lots", White, 0);
   Draw(_line, 5, "Entry", White, 0);
   Draw(_line, 6, "S/L (pips)", White, 40);
   Draw(_line, 7, "Profit", White, 60);
   Draw(_line, 8, "Pips", White, 80);
   Draw(_line, 9, "R:R", White, 80);
   _line++;
   
   // show open orders
   for (int i = 0; i < OrdersTotal(); ++i)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if (OrderMagicNumber() == MagicNumberBuy || OrderMagicNumber() == MagicNumberSell)
         {
            string symbol   = OrderSymbol();
            double lots     = OrderLots();
            double profit   = OrderProfit() + OrderCommission() + OrderSwap();
            double priceBid = _utils.BidPrice(symbol);
            double priceAsk = _utils.AskPrice(symbol);
            double pips     = 0;
            double SL       = 0;
            double RR       = 0;

            for (int x=0; x < _pairCount;++x)
            {
               if (_pairs[x].GetSymbol() == symbol)
               {
                  SL = _pairs[x].GetStoploss( OrderTicket() );
                  RR = _pairs[x].GetRiskReward( OrderTicket() );
                  break;
               }
            }
            string arrow      = CharToString(233);
            color  arrowColor = Green;
            if (OrderType() == OP_BUY)
            {
               pips = ( priceBid - OrderOpenPrice());
               SL   = (SL - OrderOpenPrice() );
            }
            else
            {
               pips       = ( OrderOpenPrice() - priceAsk);
               arrow      = CharToString(234);
               arrowColor = Red;
               SL         = (OrderOpenPrice() - SL);
            }
            if (pips != 0)
            {
               pips =_utils.PriceToPips(symbol, pips);
            }
            if (SL != 0)
            {
               SL =_utils.PriceToPips(symbol, SL);
            }
            Draw(_line, 0, TimeToStr(OrderOpenTime()), White,0);
            Draw(_line, 2, OrderSymbol()  , White,0);
            DrawWingDings(_line,3, arrow  , arrowColor,0);
            Draw(_line, 4, DoubleToString(lots,4)  , White,0);
            Draw(_line, 5, DoubleToString(OrderOpenPrice(),5)  , White,0);
            Draw(_line, 6, DoubleToString(SL, 2), SL > 0 ? Green:Red, 40);
            Draw(_line, 7, DoubleToString(profit,2) , profit > 0 ? Green:Red,60);
            Draw(_line, 8, DoubleToString(pips,2) , pips > 0 ? Green:Red,80);
            Draw(_line, 9, DoubleToString(RR,2)+":1" , RR > 0 ? Green:Red,80);
            
            _line++;
         }
      }
   }
}

//--------------------------------------------------------------------
void UpdateTradeHistoryPanel()
{   
   if (IsTesting() || IsOptimization()) return;
   string currency = AccountCurrency();
   _labelBalance.Text    =  DoubleToString(AccountBalance(), 2) + " " + currency;
   _labelEquity.Text     =  DoubleToString(AccountEquity(), 2)  + " " + currency;
   _labelFreeMargin.Text =  DoubleToString(AccountFreeMargin(), 2) + " " + currency;
   _labelMargin.Text     =  DoubleToString(AccountMargin(), 2) + " " + currency;
   
   _labelGlobalProfit.Text  =  DoubleToString( _tradeStats.GlobalProfit, 2) +" " + currency;
   _labelGlobalProfit.Color =  _tradeStats.GlobalProfit >= 0 ? White:Red;
   _labelGlobalOrders.Text  =  IntegerToString(_tradeStats.GlobalOrderCount) ;
   
   _labelProfit.Text        =  DoubleToString( _tradeStats.TotalProfit,2) +" " + currency+ "  (" + DoubleToStr(_tradeStats.TotalProfitPips, 2) + " pips)" ;
   _labelProfit.Color       =  _tradeStats.TotalProfit >= 0 ? White:Red;
   _labelOrders.Text        =  IntegerToString(_tradeStats.TotalCount);
   _labelOrdersBuySell.Text = " buy:" + IntegerToString(_tradeStats.BuyOrders) + " / sell: " + IntegerToString(_tradeStats.SellOrders) ;
   _labelProfitBuySell.Text = DoubleToString(_tradeStats.TotalProfitOfBuyOrders, 2)  +" " + currency+ " / " + DoubleToString(_tradeStats.TotalProfitOfSellOrders, 2)  + " " + currency;
   
   _labelOrdersWonLost.Text  = IntegerToString(_tradeStats.OrdersWon) + " / " + IntegerToString(_tradeStats.OrdersLost) + " (" + DoubleToString(_tradeStats.WinPercentage, 2) + " % winrate)";
   _labelOrdersWonLost.Color = (_tradeStats.OrdersWon + _tradeStats.OrdersLost) >= 0 ? White:Red; 
   
   _labelTotalTrades.Text  = IntegerToString(_tradeStats.TotalTrades);
   _labelProfitToday.Text  = DoubleToStr(_tradeStats.ProfitToday, 2) + " " + currency+ "  (" + DoubleToStr(_tradeStats.ProfitTodayPips, 2) + " pips)" ;
   _labelProfitToday.Color = (_tradeStats.ProfitToday) >= 0 ? White:Red; 
   
   _labelProfitYesterday.Text  = DoubleToStr(_tradeStats.ProfitYesterday, 2) + " " + currency+ "  (" + DoubleToStr(_tradeStats.ProfitYesterdayPips, 2) + " pips)" ;
   _labelProfitYesterday.Color = (_tradeStats.ProfitYesterday) >= 0 ? White:Red; 
   
   _labelProfitAllTime.Text  = DoubleToStr(_tradeStats.AllTimeProfit, 2) + " " + currency+ "  (" + DoubleToStr(_tradeStats.AllTimeProfitPips, 2) + " pips)" ;
   _labelProfitAllTime.Color = (_tradeStats.AllTimeProfit) >= 0 ? White:Red; 
   
   _labelProfitFactor.Text   = DoubleToStr(_tradeStats.ProfitFactor, 2);    
   _labelExpectedPayOff.Text = DoubleToStr(_tradeStats.ExpectedPayOff, 2)+ " " + currency+ " / trade";
   
   _labelTotalLotsTraded.Text     = DoubleToStr(_tradeStats.TotalLotsTraded, 3) + " lots";
   _labelAverageLotsPerTrade.Text = DoubleToStr(_tradeStats.AverageLotsPerTrade, 3) + " lots";
   _infoPanel.Update();
}


//--------------------------------------------------------------------
int OnInit()
{
   Print("--- Simple Daily Trend Reversal ",version," --- ");
   
   ObjectsDeleteAll();
   Clear();
   _tradeStats   = new CTradeStats(MagicNumberBuy, MagicNumberSell);
   _newsFilter   = new CNewsFilter(); 
   _utils        = new CUtils();
   _line         = 0;
   _pairCount    = 0;
   
   // add currency pairs
   ArrayResize(_pairs, 100);
   
   if (IsTesting() || IsOptimization())
   {
      _pairs[0]  = new CPair(Symbol(), new CMrdFXStrategy(Symbol()), _newsFilter, _utils);
      _pairCount = 1;
   }
   else
   {
      string pairs[130];
      int pairCount =  StringSplit(TradePairs,StringGetCharacter(" ", 0), pairs);
      for (int i=0; i <  SymbolsTotal(true); ++i)
      {
         string symbol = SymbolName(i, true);
         for (int x=0; x < pairCount; ++x)
         {
            if (StringFind(symbol, pairs[x]) >= 0 )
            {
               _pairs[_pairCount] = new CPair(symbol, new CMrdFXStrategy(symbol), _newsFilter, _utils);
               _pairCount++;
               break;
            }
         }
      }
   }
   
   Print("  Found ",_pairCount," pairs");
   
   RefreshPairs();
   DrawPairs();
   
   if (allowTrading)
   {
     DrawOpenOrders();
     SetupPanel();
     UpdateTradeHistoryPanel();
   }
     
   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------
void OnDeinit(const int reason)
{
   Print("--- Simple Daily Trend Reversal deinit---");
   delete _utils;
   delete _tradeStats;
   delete _newsFilter;
   if (_infoPanel!=NULL) delete _infoPanel;
   _infoPanel=NULL;
   
   for (int i=0; i < _pairCount;++i)
   {
      delete _pairs[i];
   }
   _pairCount=0;
   ArrayFree(_pairs);
   
   ObjectsDeleteAll();
}

//--------------------------------------------------------------------
void OnTick()
{  
  static int lastMinute = -1;
  static int startLine  = 0;
  
  if (_pairCount <= 0)
  {
    Comment("No pairs found. Check your settings");
    return;
  }
  else
  {
    Comment("");
  }
  
   // refresh news
   _newsFilter.Check();
   _utils.Refresh();
   
   if (allowTrading)
   {
      // refresh trade history
      _tradeStats.Refresh();
      
      // trail S/L on open orders
      for (int i=0; i < _pairCount;++i)
      {
         _pairs[i].Trail();
      } 
   }
   
   // update dashboard once per minute
   int min = TimeMinute(TimeCurrent());
   if (min != lastMinute)
   {
      lastMinute = min;
      RefreshPairs();
      DrawPairs();
      startLine = _line;
   }
   
   
   // update trading panel
   if (allowTrading)
   {
     _line = startLine;
     DrawOpenOrders();
     UpdateTradeHistoryPanel();
   } 
}

//--------------------------------------------------------------------
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) 
{
   // did user click on the chart ?
   if (id == CHARTEVENT_OBJECT_CLICK)
   {
	  // and did he click on on of our objects
      if (StringSubstr(sparam, 0, 2) == "_l") 
      {
		// did user click on the name of a pair ?
		int len = StringLen(sparam);
		if (StringSubstr(sparam, len - 2, 2)=="c1" ||StringSubstr(sparam, len - 2, 2)=="c2")
		{
			// yes then open the chart for this pair
			OpenChart(ObjectDescription(sparam));
		}
      }
   }
}