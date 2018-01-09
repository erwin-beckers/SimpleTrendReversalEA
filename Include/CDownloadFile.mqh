//+------------------------------------------------------------------+
//|                                                CDownloadFIle.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                              www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "www.erwinbeckers.nl"
#property strict


#import "wininet.dll"

#define INTERNET_FLAG_PRAGMA_NOCACHE    0x00000100 // Forces the request to be resolved by the origin server, even if a cached copy exists on the proxy.
#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000 // Does not add the returned entity to the cache. 
#define INTERNET_FLAG_RELOAD            0x80000000 // Forces a download of the requested file, object, or directory listing from the origin server, not from the cache.

int InternetOpenA(
	uchar & sAgent[],
	int		lAccessType,
	uchar & sProxyName[],
	uchar & sProxyBypass[],
	int 	lFlags=0
);

int InternetOpenUrlA(
	int 	hInternetSession,
	uchar & sUrl[], 
	uchar & sHeaders[],
	int 	lHeadersLength=0,
	int 	lFlags=0,
	int 	lContext=0 
);

int InternetReadFile(
	int 	hFile,
	uchar & sBuffer[],
	int 	lNumBytesToRead,
	int& 	lNumberOfBytesRead[]
);

int InternetCloseHandle(
	int 	hInet
);
#import

class CDownloadFile
{
private:
   bool _winInetDebug;
   int _hSession_IEType;
   int _hSession_Direct;
   int _Internet_Open_Type_Preconfig;
   int _Internet_Open_Type_Direct;
   int _Internet_Open_Type_Proxy;
   int _Buffer_LEN;

   
   int InternetOpenAFIX(
   	string 	sAgent,
   	int		lAccessType,
   	string 	sProxyName="",
   	string 	sProxyBypass="",
   	int 	lFlags=0
   )
   {
      uchar sAgentFIX[], sProxyNameFIX[], sProxyBypassFIX[];
      StringToCharArray(sAgent, sAgentFIX);
      StringToCharArray(sProxyName, sProxyNameFIX);
      StringToCharArray(sProxyBypass, sProxyBypassFIX);
      return(InternetOpenA(sAgentFIX,lAccessType,sProxyNameFIX,sProxyBypassFIX,lFlags));
   }
   
   int InternetOpenUrlAFIX(
   	int 	hInternetSession,
   	string 	sUrl, 
   	string 	sHeaders="",
   	int 	lHeadersLength=0,
   	int 	lFlags=0,
   	int 	lContext=0 
   )
   {
      uchar sUrlFIX[], sHeadersFIX[];
      StringToCharArray(sUrl, sUrlFIX);
      StringToCharArray(sHeaders, sHeadersFIX);
      return(InternetOpenUrlA(hInternetSession,sUrlFIX,sHeadersFIX,lHeadersLength,lFlags,lContext));
   }
   
   int InternetReadFileFIX(
   	int 	hFile,
   	string 	&sBuffer,
   	int 	lNumBytesToRead,
   	int& 	lNumberOfBytesRead[]
   )
   {
      uchar sBufferFIX[];
      ArrayResize(sBufferFIX,lNumBytesToRead);
      int result=InternetReadFile(hFile,sBufferFIX,lNumBytesToRead,lNumberOfBytesRead);
      sBuffer=CharArrayToString(sBufferFIX);
      return(result);
   }
   
   int hSession(bool Direct)
   {
   	string InternetAgent;
   	if (_hSession_IEType == 0)
   	{
   		InternetAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";
   		_hSession_IEType = InternetOpenAFIX(InternetAgent, _Internet_Open_Type_Preconfig, "0", "0", 0);
   		_hSession_Direct = InternetOpenAFIX(InternetAgent, _Internet_Open_Type_Direct, "0", "0", 0);
         //Print("Could not open sessions via InternetOpenA");
   	}
   	if (Direct) 
   	{ 
   		return (_hSession_Direct); 
   	}
   	else 
   	{
   		return(_hSession_IEType); 
   	}
   }

public:
   CDownloadFile()
   {
      _winInetDebug = false;
      _Internet_Open_Type_Preconfig = 0;
      _Internet_Open_Type_Direct = 1;
      _Internet_Open_Type_Proxy = 3;
      _Buffer_LEN = 80;
   }
   
   bool GrabWeb(string strUrl, string& strWebPage)
   {
   	int 	   lReturn[]	= {1};
   	string 	sBuffer		= "                                                                                                                                                                                                                                                               ";	// 255 spaces
   	int 	   bytes;
   	
   	int hInternet = InternetOpenUrlAFIX(hSession(FALSE), strUrl, "0", 0, (int)( INTERNET_FLAG_NO_CACHE_WRITE |INTERNET_FLAG_PRAGMA_NOCACHE |INTERNET_FLAG_RELOAD), 0);
   								
   	if (_winInetDebug) Print("hInternet: " + IntegerToString(hInternet));  
   	if (hInternet == 0) return(false);
   
   	int iResult = InternetReadFileFIX(hInternet, sBuffer, _Buffer_LEN, lReturn);
   	
   	if (_winInetDebug) Print("iResult: " + IntegerToString(iResult));
   	if (_winInetDebug) Print("lReturn: " + IntegerToString(lReturn[0]));
   	if (_winInetDebug) Print("iResult: " + IntegerToString(iResult));
   	if (_winInetDebug) Print("sBuffer: " + sBuffer);
   	if (iResult == 0) return(false);
   	
   	bytes = lReturn[0];
   	strWebPage = StringSubstr(sBuffer, 0, lReturn[0]);
   	
   	// If there's more data then keep reading it into the buffer
   	while (lReturn[0] != 0)
   	{
   		iResult = InternetReadFileFIX(hInternet, sBuffer, _Buffer_LEN, lReturn);
   		if (lReturn[0]==0) break;
   		bytes = bytes + lReturn[0];
   		strWebPage = strWebPage + StringSubstr(sBuffer, 0, lReturn[0]);
   	}
   
      if (_winInetDebug) {	Print("Closing URL web connection"); }
   
   	iResult = InternetCloseHandle(hInternet);
   	if (iResult == 0) return(false);
   	return(true);
   }
};
