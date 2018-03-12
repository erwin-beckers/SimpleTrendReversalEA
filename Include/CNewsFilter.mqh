//+------------------------------------------------------------------+
//|                                                  CNewsFilter.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                              www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "www.erwinbeckers.nl"
#property strict


#include <CDownloadFile.mqh>;

// needs FFC to be installed (and working)
extern string     __news__                         = "--- FFCal News Filter --- ";
extern bool       UseNewsFilter                    =  true; 
extern int        MinsBeforeNews                   =  30;   
extern int        MinsAfterNews                    =  30;   
extern bool 	   IncludeHigh 		               = true;
extern bool 	   IncludeMedium 		               = true;
extern bool 	   IncludeLow 			               = false;
extern int		   OffsetHoursGMT                   = 0; 
extern bool       CloseProfitableTradesBeforeNews  = false;   
 

enum NEWS_IMPACT
{
   IMPACT_NONE   = 0,
   IMPACT_HIGH   = 1,
   IMPACT_MEDIUM = 2,
   IMPACT_LOW    = 3
};

class CNewsEvent
{
public:
   string      Title;
   string      Country;
   datetime    DateTime;
   NEWS_IMPACT Impact;
      
   string GetImpact()
   {
      if (Impact == IMPACT_HIGH) return "High ";
      if (Impact == IMPACT_MEDIUM) return "Medium ";
      if (Impact == IMPACT_LOW) return "Low ";
      return "";
   }
};

class CNewsFilter
{
private:
   CNewsEvent* _newsEvents[];
   int         _maxEvents;
   datetime    _lastDownloaded;
   datetime    _lastDownloadRetry;
   
   string MakeDateTime(string strDate, string strTime)
   {
   	// Print("Converting Forex Factory Time into Metatrader time..."); //added by MN
   	// Converts forexfactory time & date into yyyy.mm.dd hh:mm	
   	int n1stDash = StringFind(strDate, "-");
   	int n2ndDash = StringFind(strDate, "-", n1stDash+1);
   
   	string strMonth = StringSubstr(strDate, 0, 2);
   	string strDay = StringSubstr(strDate, 3, 2);
   	string strYear = StringSubstr(strDate, 6, 4); 
   //	strYear = "20" + strYear;
   	
   	int nTimeColonPos = StringFind(strTime, ":");
   	string strHour = StringSubstr(strTime, 0, nTimeColonPos);
   	string strMinute = StringSubstr(strTime, nTimeColonPos+1, 2);
   	string strAM_PM = StringSubstr(strTime, StringLen(strTime)-2);
   
   	int nHour24 = StrToInteger(strHour);
   	if ((strAM_PM == "pm" || strAM_PM == "PM") && nHour24 != 12)
   	{
   		nHour24 += 12;
   	}
   	if ((strAM_PM == "am" || strAM_PM == "AM") && nHour24 == 12)
   	{
   		nHour24 = 0;
   	}
    	string strHourPad = "";
   	if (nHour24 < 10) 
   		strHourPad = "0";
   
   	//Print("Date compare:"+strDate+" "+strTime+" - "+StringConcatenate(strYear, ".", strMonth, ".", strDay, " ", strHourPad, nHour24, ":", strMinute));
   
   	return(StringConcatenate(strYear, ".", strMonth, ".", strDay, " ", strHourPad, nHour24, ":", strMinute));
   	
   }
   
   datetime TimeGMTFIX() 
   {
      return(TimeGMT()+(OffsetHoursGMT * 3600));
   }
   
public: 
   //--------------------------------------------------------------------
   CNewsFilter()
   {
      _maxEvents      = 0;
      _lastDownloaded = 0;
      _lastDownloadRetry =0;
      ArrayResize(_newsEvents, 500);
   }
   
   //--------------------------------------------------------------------
   ~CNewsFilter()
   {  
      for (int i=0; i < _maxEvents;++i)
         delete _newsEvents[i];
      _maxEvents=0;
   }
   
   //--------------------------------------------------------------------
   void DownloadNews()
   {
   	if (!IsConnected())
   	{
   	   // no internet connection
   	   return;
   	}
   	
   	// download news once every 24 hrs
   	double timeSpanMins = (double)(TimeCurrent() - _lastDownloaded);
   	timeSpanMins /= 60.0;   	
   	if (_maxEvents == 0 || timeSpanMins >= (60*24) )
		{
		   // only try to load news once in every 5 mins
		   timeSpanMins = (double)(TimeCurrent() - _lastDownloadRetry);
   	   timeSpanMins /= 60.0;
   	   if (timeSpanMins < 5) 
   	   {
   	      return;
   	   }
   	   _lastDownloadRetry = TimeCurrent();
		
		   //Print("-- downloading news --");
		   string url= "http://www.forexfactory.com/ffcal_week_this.xml";
		   string news="";
		   
		   CDownloadFile* downloader = new CDownloadFile();
			bool result = downloader.GrabWeb(url, news);
			delete downloader;
			
			int end = StringFind(news, "</weeklyevents>", 0);
			if (end <= 0)
			{
				Print("-- unable to download news --");
				return ;
			}
			else
			{
		      //Print("-- news downloaded--");
				// set global to time of last update
				_lastDownloaded = TimeCurrent();
				Parse(news);
			}
		}
   }
   
   //--------------------------------------------------------------------
   void Parse(string news)
   {
      //Print("Parsing news");
      for (int i=0; i < _maxEvents;++i)
         delete _newsEvents[i];
      _maxEvents=0;
      
   	int      BoEvent = 0;
    int      end=0;
    string 	sTags[7] = { "<title>", "<country>", "<date>", "<time>", "<impact>", "<forecast>", "<previous>" };
    string 	eTags[7] = { "</title>", "</country>", "</date>", "</time>", "</impact>", "</forecast>", "</previous>" };
   	while (true)
   	{
   		BoEvent = StringFind(news, "<event>", BoEvent);
   		if (BoEvent == -1) break;
   			
   		BoEvent += 7;	
   		int next = StringFind(news, "</event>", BoEvent);
   		if (next == -1) break;
   	
   		string myEvent = StringSubstr(news, BoEvent, next - BoEvent);
   		BoEvent = next;
   		
   		string newsData[7];
   		int  begin = 0;
   		for (int i=0; i < 7; i++)
   		{
   		   newsData[i] = "";
   			next = StringFind(myEvent, sTags[i], begin);
   			
   			// Within this event, if tag not found, then it must be missing; skip it
   			if (next == -1) continue;
   			else
   			{
   				// We must have found the sTag okay...
   				begin = next + StringLen(sTags[i]);			// Advance past the start tag
   				end   = StringFind(myEvent, eTags[i], begin);	// Find start of end tag
   				if (end > begin && end != -1)
   				{
   					// Get data between start and end tag
   					newsData[i]= StringSubstr(myEvent, begin, end - begin);
   					if (StringSubstr(newsData[i],0,9)=="<![CDATA[")
   				   {
   					   newsData[i]=StringSubstr(newsData[i],9,StringLen(newsData[i])-12);
   				   }
   				}
   			}
   		}// for (i=0; i < 7)
   		
   		bool impactOk=false;
   		NEWS_IMPACT impact = IMPACT_NONE;
   		if (IncludeHigh && StringFind(newsData[4], "High") >= 0) 
   		{
   		   impact = IMPACT_HIGH;
   		}
   		else if (IncludeMedium && StringFind(newsData[4], "Medium")  >=0)
   		{
   		   impact = IMPACT_MEDIUM;
   		}
   		else if (IncludeLow && StringFind(newsData[4],"Low") >=0)
   		{
   		   impact = IMPACT_LOW;
   		}
   		
   		if (impact != IMPACT_NONE)
   		{
   		   datetime dateTime = StrToTime(MakeDateTime(newsData[2], newsData[3]));
   		   double mins =(double)( TimeGMTFIX() - dateTime);
   		   mins /= 60.0;
   		   if ( mins <= MinsAfterNews)
   		   {
      		   CNewsEvent* event = new CNewsEvent();
         		event.Title    = newsData[0];
         		event.Country  = newsData[1];
         		event.DateTime = dateTime;
         		event.Impact   = impact;
         		
         		_newsEvents[_maxEvents++] = event;
         	}
      	}
		}
      //Print("News parsed, found ", _maxEvents," upcoming news events");
   }
   
   //--------------------------------------------------------------------
   void Check()
   {
      if(IsTesting() || IsOptimization() || !UseNewsFilter) 
      {
         return;
      }
      DownloadNews();
   }
   
   //--------------------------------------------------------------------
   bool GetNews(string symbol, string& news, NEWS_IMPACT& newsImpact)
   {
      if (UseNewsFilter==false || IsOptimization() || IsTesting() )
      {
         news = "";
         return true;
      }
      
      double minMinutes = 999999;
      bool canTrade     = true;
      newsImpact        = IMPACT_NONE;
      
      for (int i=0; i < _maxEvents;++i)
      {
         CNewsEvent* event = _newsEvents[i];
         int pos = StringFind(symbol, event.Country);
         if (pos >= 0) 
         {
            double mins = (double)( TimeGMTFIX() - event.DateTime);
            mins /= 60.0;
            if (MathAbs(mins) < minMinutes)
            {
               news = "";
               minMinutes = mins;
               if (mins < 0)
               {
                  // event still needs to happen
                  if (MathAbs(mins) <= MinsBeforeNews)
                  {
                     // news is about to happen, disable trading
                     news = "in "+ IntegerToString(MathAbs((int)mins)) + " mins";
                     canTrade = false;
                     newsImpact = event.Impact;
                  } 
                  else if (MathAbs(mins) < 180)
                  {
                     // only show news within the next 3 hours
                     canTrade   = true;
                     newsImpact = event.Impact;
                     news="in "+ IntegerToString(MathAbs((int)mins))+" mins";
                  }
                  else 
                  {
                     // news is more then 3 hours away
                     canTrade   = true;
                     news       = "";
                     newsImpact = IMPACT_NONE;
                  }
               }
               else 
               {
                  // event already happend
                  if (MathAbs(mins) <= MinsAfterNews)
                  {  
                     // event just happend, disable trading
                     canTrade   = false;
                     newsImpact = event.Impact;
                     news=" "+ IntegerToString(MathAbs((int)mins))+" ago";
                  }
                  else
                  {
                     // event happend long ago
                     newsImpact = IMPACT_NONE;
                     canTrade   = true;
                     news       = "";
                  }
               }
            }
         }
      }
      return canTrade;
   }
};