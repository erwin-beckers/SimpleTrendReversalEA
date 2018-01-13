//+------------------------------------------------------------------+
//|                                                        CMBFX.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                              www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "www.erwinbeckers.nl"
#property strict


// inputs for MBFX
extern string     __mbfx               = " ------- MBFX settings ------------";
extern int        Len                  = 7;
extern double     Filter               = 0.0;


//--------------------------------------------------------------------
class CMBFX
{
private:
   double            _mbfxYellow[];
   double            _mbfxGreen[];
   double            _mbfxRed[];

public:
   //--------------------------------------------------------------------
   CMBFX()
   {
      ArrayResize(_mbfxGreen , 500+5, 0);
      ArrayResize(_mbfxRed   , 500+5, 0);
      ArrayResize(_mbfxYellow, 500+5, 0);
   }
   
   //--------------------------------------------------------------------
   bool IsGreen(int bar)
   {
      if (bar <0 || bar >= 500) return false;
      return (_mbfxGreen[bar] != EMPTY_VALUE);
   }
   
   //--------------------------------------------------------------------
   double GreenValue(int bar)
   {
      if (bar <0 || bar >= 500) return EMPTY_VALUE;
      return _mbfxGreen[bar];
   }
   
   //--------------------------------------------------------------------
   double RedValue(int bar)
   {
      if (bar <0 || bar >= 500) return EMPTY_VALUE;
      return _mbfxRed[bar];
   }
   
   //--------------------------------------------------------------------
   void Refresh(string symbol)
   {
      ArrayInitialize(_mbfxYellow, 0);
      ArrayInitialize(_mbfxGreen, 0);
      ArrayInitialize(_mbfxRed, 0);
      double ld_0=0;
      double ld_8=0;
      double ld_16=0;
      double ld_24=0;
      double ld_32=0;
      double ld_40=0;
      double ld_48=0;
      double ld_56=0;
      double ld_64=0;
      double ld_72=0;
      double ld_80=0;
      double ld_88=0;
      double ld_96=0;
      double ld_104=0;
      double ld_112=0;
      double ld_120=0;
      double ld_128=0;
      double ld_136=0;
      double ld_144=0;
      double ld_152=0;
      double ld_160=0;
      double ld_168=0;
      double ld_176=0;
      double ld_184=0;
      double ld_192=0;
      double ld_200=0;
      double ld_208=0;
      int barLimit = 500 - Len - 1;
      for (int bar = barLimit; bar >= 0; bar--) 
      {
         if (ld_8 == 0.0) 
         {
            ld_8 = 1.0;
            ld_16 = 0.0;
            if (Len - 1 >= 5) ld_0 = Len - 1.0;
            else ld_0 = 5.0;
            ld_80 = 100.0 * ((iHigh(symbol, 0, bar) + iLow(symbol, 0, bar) + iClose(symbol, 0, bar)) / 3.0);
            ld_96 = 3.0 / (Len + 2.0);
            ld_104 = 1.0 - ld_96;
         } 
         else 
         {
            if (ld_0 <= ld_8) ld_8 = ld_0 + 1.0;
            else ld_8 += 1.0;
            ld_88 = ld_80;
            ld_80 = 100.0 * ((iHigh(symbol, 0, bar) + iLow(symbol, 0, bar) + iClose(symbol, 0, bar)) / 3.0);
            ld_32 = ld_80 - ld_88;
            ld_112 = ld_104 * ld_112 + ld_96 * ld_32;
            ld_120 = ld_96 * ld_112 + ld_104 * ld_120;
            ld_40 = 1.5 * ld_112 - ld_120 / 2.0;
            ld_128 = ld_104 * ld_128 + ld_96 * ld_40;
            ld_208 = ld_96 * ld_128 + ld_104 * ld_208;
            ld_48 = 1.5 * ld_128 - ld_208 / 2.0;
            ld_136 = ld_104 * ld_136 + ld_96 * ld_48;
            ld_152 = ld_96 * ld_136 + ld_104 * ld_152;
            ld_56 = 1.5 * ld_136 - ld_152 / 2.0;
            ld_160 = ld_104 * ld_160 + ld_96 * MathAbs(ld_32);
            ld_168 = ld_96 * ld_160 + ld_104 * ld_168;
            ld_64 = 1.5 * ld_160 - ld_168 / 2.0;
            ld_176 = ld_104 * ld_176 + ld_96 * ld_64;
            ld_184 = ld_96 * ld_176 + ld_104 * ld_184;
            ld_144 = 1.5 * ld_176 - ld_184 / 2.0;
            ld_192 = ld_104 * ld_192 + ld_96 * ld_144;
            ld_200 = ld_96 * ld_192 + ld_104 * ld_200;
            ld_72 = 1.5 * ld_192 - ld_200 / 2.0;
            if (ld_0 >= ld_8 && ld_80 != ld_88) ld_16 = 1.0;
            if (ld_0 == ld_8 && ld_16 == 0.0) ld_8 = 0.0;
         }
         if (ld_0 < ld_8 && ld_72 > 0.0000000001) 
         {
            ld_24 = 50.0 * (ld_56 / ld_72 + 1.0);
            if (ld_24 > 100.0) ld_24 = 100.0;
            if (ld_24 < 0.0) ld_24 = 0.0;
         } 
         else ld_24 = 50.0;
         
         _mbfxYellow[bar] = ld_24;
         _mbfxGreen[bar]  = ld_24;
         _mbfxRed[bar]    = ld_24;
         if (_mbfxYellow[bar] > _mbfxYellow[bar + 1] - Filter) _mbfxRed[bar] = EMPTY_VALUE;
         else 
         {
            if (_mbfxYellow[bar] < _mbfxYellow[bar + 1] + Filter) _mbfxGreen[bar] = EMPTY_VALUE;
            else 
            {
               if (_mbfxYellow[bar] == _mbfxYellow[bar + 1] + Filter) 
               {
                  _mbfxGreen[bar] = EMPTY_VALUE;
                  _mbfxRed[bar] = EMPTY_VALUE;
               }
            }
         }
      }
   }
};