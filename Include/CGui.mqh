//+------------------------------------------------------------------+
//|                                                         CGui.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict


static int guiId=0;

interface IDrawable
{
   void SetPosition(ENUM_BASE_CORNER corner, double x, double y);
   void Update();
};

class CPanel: public IDrawable
{
private:
   string _id;
   
public:  
   double           X;
   double           Y;
   double           Width;
   double           Height;
   color            Color;
   color            BorderColor;
   ENUM_BASE_CORNER Corner;
   
   CPanel()
   {  
      _id="pnl"+IntegerToString(guiId);
      guiId++;
      
      X = Y = 0;
      Width = Height = 100;
      Color = 0x3a3027;
      BorderColor = 0xc2c236;
      Corner=CORNER_LEFT_UPPER;
      
      ObjectCreate(_id, OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSet(_id, OBJPROP_CORNER, Corner);
      ObjectSet(_id, OBJPROP_BGCOLOR, Color);
      ObjectSet(_id, OBJPROP_BACK, true);
      ObjectSet(_id, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSet(_id, OBJPROP_WIDTH, 2);
      ObjectSet(_id, OBJPROP_BACK, true);
      ObjectSet(_id, OBJPROP_COLOR, BorderColor); 

   }
   
   ~CPanel()
   {
     ObjectDelete(_id);
   }
   
   void SetPosition(ENUM_BASE_CORNER corner, double x, double y)
   {
      X = x;
      Y = y;
      ObjectSet(_id, OBJPROP_CORNER, corner);
      ObjectSet(_id, OBJPROP_XDISTANCE, X);
      ObjectSet(_id, OBJPROP_YDISTANCE, Y);
      ObjectSet(_id, OBJPROP_XSIZE, Width);
      ObjectSet(_id, OBJPROP_YSIZE, Height);
   }
   
   void Update()
   {
   }
};



class CLabel: public IDrawable
{
private:
   string _id;
   
public:
   double X;
   double Y;
   string Text;
   string Font;
   int    FontSize;
   color  Color;
   
   CLabel()
   {
      _id = "lbl"+IntegerToString(guiId);
      guiId++;
      X=Y=0;
      Font="Courier New";
      FontSize=8;
      Color=White;
      
     ObjectCreate(_id, OBJ_LABEL, 0, 0, 0);
     ObjectSet(_id, OBJPROP_BACK, false);
   }
   
   ~CLabel()
   {
     ObjectDelete(_id);
   }
   
   void SetPosition(ENUM_BASE_CORNER corner, double x, double y)
   {
      X = x;
      Y = y;
      ObjectSet(_id, OBJPROP_CORNER, corner);
      ObjectSet(_id, OBJPROP_XDISTANCE, X);
      ObjectSet(_id, OBJPROP_YDISTANCE, Y);
   }
   
   void Update()
   {
     ObjectSetText(_id, Text, FontSize, Font, Color);
   }
};


class CLabelKeyValue : public IDrawable
{
  private:
    CLabel* _labelDesc;
    CLabel* _labelVal;
    double _offset;
  public:
    color   Color;
    string  Text;
    
    CLabelKeyValue(string description, double offset)
    {
      Color=White;
      _offset=offset;
      _labelDesc = new CLabel();
      _labelVal  = new CLabel();
      _labelDesc.Text= description;
    }
    
   ~CLabelKeyValue()
   {
     delete _labelDesc;
     delete _labelVal;
   }
    
   void SetPosition(ENUM_BASE_CORNER corner, double x, double y)
   {
      _labelDesc.SetPosition(corner,x,y);
      _labelVal.SetPosition(corner,x+_offset,y);
   }
   
    void Update()
    {
      _labelVal.Color = Color;
      _labelVal.Text  = Text;
      _labelDesc.Update();
      _labelVal.Update();
    }
};


class CLine: public IDrawable
{    
private:
   string _id;
   
public:  
   double           X;
   double           Y;
   double           Width;
   double           Height;
   color            BorderColor; 
   
   CLine()
   {  
      _id="line"+IntegerToString(guiId);
      guiId++;
      
      X = Y = 0;
      Width = 100;
      Height = 1;
      BorderColor = 0xc2c236;
      
      ObjectCreate(_id,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSet(_id, OBJPROP_BACK, false);
      ObjectSet(_id, OBJPROP_WIDTH, 0);
      ObjectSet(_id, OBJPROP_BACK, false);
      ObjectSet(_id, OBJPROP_BGCOLOR, BorderColor);

   }
   
   ~ CLine()
   {
     ObjectDelete(_id);
   }
   
   void SetPosition(ENUM_BASE_CORNER corner, double x, double y)
   {
      ObjectSet(_id, OBJPROP_CORNER, corner);
      ObjectSet(_id, OBJPROP_XDISTANCE, x);
      ObjectSet(_id, OBJPROP_YDISTANCE, y);
   }
   
   void Update()
   {
      ObjectSet(_id, OBJPROP_XSIZE, Width);
      ObjectSet(_id, OBJPROP_YSIZE, 1);
   }
};