//+------------------------------------------------------------------+
//|                                                   CInfoPanel.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                              www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "www.erwinbeckers.nl"
#property strict

#include  <CGui.mqh>;

class CInfoPanel
{
private:
   IDrawable* _drawables[];
   int        _size;
   double     _yPos;
   double     _xPos;
   CPanel*    _panel;
   
public:
   CInfoPanel(int width, int height)
   {
      _size = 0;
      _yPos = 0;
      _xPos =50;
      _panel = new CPanel();
      _panel.Width  = width;
      _panel.Height = height;      
      Add(_panel, 0, 50);
   }
   
   ~CInfoPanel()
   {
      for (int i=0; i < _size;++i)
      {
         delete _drawables[i];
      }
   }
   
   void SetPosition(double x, double y)
   {
      _xPos=x;
      _yPos=y;
      _panel.SetPosition(CORNER_LEFT_UPPER,x,y);
      _panel.Update();
   }
   
   void Add(IDrawable* drawable, double xoff, double yoff)
   {  
      ArrayResize(_drawables, _size + 1);
      _drawables[_size] = drawable;
      _size++;
      drawable.SetPosition(_panel.Corner, xoff+_xPos, yoff + _yPos);
      _yPos+=(yoff + 12);
   }
   
   void Update()
   {
      for (int i=0; i < _size;++i)
      {
         _drawables[i].Update();
      }
   }    
};