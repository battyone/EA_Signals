//+------------------------------------------------------------------+
//|                                                  Super_Trend.mq5 |
//|                   Copyright ｩ 2005, Jason Robinson (jnrtrading). | 
//|                                      http://www.jnrtrading.co.uk | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright ｩ 2005, Jason Robinson (jnrtrading)." 
#property link      "http://www.jnrtrading.co.uk" 
//---- 濵・・粢韋 竟蒻・
#property version   "1.00"
//---- ⅳ粲・竟蒻・ ・ⅲ濵粹黑 鶴淲
#property indicator_chart_window
//---- ・・粽 竟蒻・顥 碯・4
#property indicator_buffers 4 
//---- 頌・・鉋籵濵 糂裙・ 胙瑶顆褥・・・褊・
#property indicator_plots   4
//+----------------------------------------------+
//| ﾏ瑩瑟褪 ⅳ粲・竟蒻・               |
//+----------------------------------------------+
//---- ⅳ粲・竟蒻・ ・粨蒟 ・湜・
#property indicator_type1 DRAW_LINE
//---- ・・粢 鶴・竟蒻・ 頌・・鉋籵・褪 MediumSeaGreen
#property indicator_color1 clrMediumSeaGreen
//---- ・湜 竟蒻・ - ・・
#property indicator_style1 STYLE_SOLID
//---- ・竟・・湜・竟蒻・ 粹・2
#property indicator_width1 2
//---- ⅳ髜趺湜・・・肬琿・鵫 ・湜・
#property indicator_label1  "Super_Trend Up"
//+----------------------------------------------+
//| ﾏ瑩瑟褪 ⅳ粲・竟蒻・               |
//+----------------------------------------------+
//---- ⅳ粲・竟蒻・ ・粨蒟 ・湜・
#property indicator_type2 DRAW_LINE
//---- ・・粢 鶴・竟蒻・ 頌・・鉋籵・褪 Red
#property indicator_color2 clrRed
//---- ・湜 竟蒻・ - ・・
#property indicator_style2 STYLE_SOLID
//---- ・竟・・湜・竟蒻・ 粹・2
#property indicator_width2 2
//---- ⅳ髜趺湜・・・肬琿・鵫 ・湜・
#property indicator_label2  "Super_Trend Down"
//+----------------------------------------------+
//| ﾏ瑩瑟褪 ⅳ粲・磊裙・竟蒻・       |
//+----------------------------------------------+
//---- ⅳ粲・竟蒻・ 3 ・粨蒟 鈿璞・
#property indicator_type3   DRAW_ARROW
//---- ・・粢 褪・磊裨 ・湜・竟蒻・ 頌・・鉋籵・褪 MediumTurquoise
#property indicator_color3  clrMediumTurquoise
//---- ・湜 竟蒻・ 3 - 淲・褞鏆浯 ・鞣・
#property indicator_style3  STYLE_SOLID
//---- ・竟・・湜・竟蒻・ 3 粹・1
#property indicator_width3  1
//---- ⅳ髜趺湜・磊裨 ・・竟蒻・
#property indicator_label3  "Buy Super_Trend signal"
//+----------------------------------------------+
//| ﾏ瑩瑟褪 ⅳ粲・・葢褂・胛 竟蒻・    |
//+----------------------------------------------+
//---- ⅳ粲・竟蒻・ 4 ・粨蒟 鈿璞・
#property indicator_type4   DRAW_ARROW
//---- ・・粢 褪・・葢褂・・・湜・竟蒻・ 頌・・鉋籵・褪 DarkOrange
#property indicator_color4  clrDarkOrange
//---- ・湜 竟蒻・ 2 - 淲・褞鏆浯 ・鞣・
#property indicator_style4  STYLE_SOLID
//---- ・竟・・湜・竟蒻・ 4 粹・1
#property indicator_width4  1
//---- ⅳ髜趺湜・・葢褂・・・・竟蒻・
#property indicator_label4  "Sell Super_Trend signal"
//+----------------------------------------------+
//| ﾎ磅粱褊韃 ・瀨炅                          |
//+----------------------------------------------+
#define RESET 0                             // ・瀨炅・蓁 粽鈔 竟琿・・・淸・浯 ・褪 竟蒻・
#define UP_DOWN_SHIFT_CR  0
#define UP_DOWN_SHIFT_M1  3
#define UP_DOWN_SHIFT_M2  3
#define UP_DOWN_SHIFT_M3  4
#define UP_DOWN_SHIFT_M4  5
#define UP_DOWN_SHIFT_M5  5
#define UP_DOWN_SHIFT_M6  5
#define UP_DOWN_SHIFT_M10 6
#define UP_DOWN_SHIFT_M12 6
#define UP_DOWN_SHIFT_M15 7
#define UP_DOWN_SHIFT_M20 8
#define UP_DOWN_SHIFT_M30 9
#define UP_DOWN_SHIFT_H1  20
#define UP_DOWN_SHIFT_H2  27
#define UP_DOWN_SHIFT_H3  30
#define UP_DOWN_SHIFT_H4  35
#define UP_DOWN_SHIFT_H6  33
#define UP_DOWN_SHIFT_H8  35
#define UP_DOWN_SHIFT_H12 37
#define UP_DOWN_SHIFT_D1  40
#define UP_DOWN_SHIFT_W1  100
#define UP_DOWN_SHIFT_MN1 120
//+----------------------------------------------+
//| ﾂ蓖鐱 ・・・竟蒻・                 |
//+----------------------------------------------+
input int CCIPeriod=14; // ﾏ褞韶・竟蒻・ CCI 
input int Level=0;      // ﾓ粢犱 珮瑣鏆瑙・ CCI
input int Shift=0;      // ﾑ葢鞳 竟蒻・ ・ 胛鉋炅琿・・矜・
//+----------------------------------------------+
//---- 髜・粱褊韃 蒻浯・頷 ・鞣魵, ・・碯蔘・・
//---- 萵・淲鵁褌 頌・・鉋籵燾 ・・粢 竟蒻・顥 碯・
double TrendUp[],TrendDown[];
double SignUp[];
double SignDown[];
//----
double UpDownShift;
//---- 髜・粱褊韃 ・褊燾・・・澵顥 浯・ ⅳ褪・萵澵顥
int min_rates_total;
//---- 髜・粱褊韃 ・褊燾・・・澵顥 蓁 淸・・竟蒻・・
int CCI_Handle;
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int GetUpDownShift(ENUM_TIMEFRAMES Timeframe)
  {
//----
   switch(Timeframe)
     {
      case PERIOD_M1:     return(UP_DOWN_SHIFT_M1);
      case PERIOD_M2:     return(UP_DOWN_SHIFT_M2);
      case PERIOD_M3:     return(UP_DOWN_SHIFT_M3);
      case PERIOD_M4:     return(UP_DOWN_SHIFT_M4);
      case PERIOD_M5:     return(UP_DOWN_SHIFT_M5);
      case PERIOD_M6:     return(UP_DOWN_SHIFT_M6);
      case PERIOD_M10:     return(UP_DOWN_SHIFT_M10);
      case PERIOD_M12:     return(UP_DOWN_SHIFT_M12);
      case PERIOD_M15:     return(UP_DOWN_SHIFT_M15);
      case PERIOD_M20:     return(UP_DOWN_SHIFT_M20);
      case PERIOD_M30:     return(UP_DOWN_SHIFT_M30);
      case PERIOD_H1:     return(UP_DOWN_SHIFT_H1);
      case PERIOD_H2:     return(UP_DOWN_SHIFT_H2);
      case PERIOD_H3:     return(UP_DOWN_SHIFT_H3);
      case PERIOD_H4:     return(UP_DOWN_SHIFT_H4);
      case PERIOD_H6:     return(UP_DOWN_SHIFT_H6);
      case PERIOD_H8:     return(UP_DOWN_SHIFT_H8);
      case PERIOD_H12:     return(UP_DOWN_SHIFT_H12);
      case PERIOD_D1:     return(UP_DOWN_SHIFT_D1);
      case PERIOD_W1:     return(UP_DOWN_SHIFT_W1);
      case PERIOD_MN1:     return(UP_DOWN_SHIFT_MN1);
     }
//----
   return(UP_DOWN_SHIFT_CR);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- 竟頽鞨・鈞 ・・澵顥 浯・ ⅳ褪・萵澵顥
   min_rates_total=int(CCIPeriod)+1;
//---- ・・湜・淸・ 竟蒻・ CCI
   CCI_Handle=iCCI(NULL,0,CCIPeriod,PRICE_TYPICAL);
   if(CCI_Handle==INVALID_HANDLE)
     {
      Print(" ﾍ・琿ⅲ・・・ 淸・竟蒻・ CCI");
      return(INIT_FAILED);
     }
//---- 竟頽鞨・鈞 ・・澵鵫 蓁 粨聰 鈿璞褊韜     
   UpDownShift=GetUpDownShift(Period())*_Point;
//---- 竟頽鞨・鈞 ・・澵鵫 蓁 ・魲・韲褊・竟蒻・
   string shortname;
   StringConcatenate(shortname,"Super_Trend(",string(CCIPeriod),", ",string(Shift),")");
//---- 鈕瑙韃 韲褊・蓁 ⅳ髜趺湜 ・ⅳ蒟・濵・・蒡・・・粽 糂・鏆・・・蓴・鉤・
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- ⅰ蒟・湜・ⅲ ⅳ髜趺湜 鈿璞褊韜 竟蒻・
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- ・裘湜・蒻浯・魲・・鞣・ExtBuffer[] ・竟蒻・隆 碯・
   SetIndexBuffer(0,TrendUp,INDICATOR_DATA);
//---- ⅲ褥・湜・粨聰 竟蒻・ ・ 胛鉋炅琿・浯 Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- ⅲ褥・湜・粨聰 浯・ ⅳ褪・ⅳ粲・竟蒻・
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- 鈞・褪 浯 ⅳ粲・竟蒻・・・顥 鈿璞褊韜
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- 竟蒟・璋・ ・・炅魵 ・碯・ ・・・鴈・  
   ArraySetAsSeries(TrendUp,true);
//---- ・裘湜・蒻浯・魲・・鞣・ExtBuffer[] ・竟蒻・隆 碯・
   SetIndexBuffer(1,TrendDown,INDICATOR_DATA);
//---- ⅲ褥・湜・粨聰 竟蒻・ ・ 胛鉋炅琿・浯 Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- ⅲ褥・湜・粨聰 浯・ ⅳ褪・ⅳ粲・竟蒻・
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- 鈞・褪 浯 ⅳ粲・竟蒻・・・顥 鈿璞褊韜
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- 竟蒟・璋・ ・・炅魵 ・碯・ ・・・鴈・  
   ArraySetAsSeries(TrendDown,true);
//---- ・裘湜・蒻浯・魲・・鞣・SignUp [] ・竟蒻・隆 碯・
   SetIndexBuffer(2,SignUp,INDICATOR_DATA);
//---- ⅲ褥・湜・粨聰 竟蒻・ 1 ・ 胛鉋炅琿・浯 Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- ⅲ褥・湜・粨聰 浯・ ⅳ褪・ⅳ粲・竟蒻・ 1
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- 竟蒟・璋・ ・・炅魵 ・碯・ ・・・鴈・  
   ArraySetAsSeries(SignUp,true);
//---- 濵粲・鈿璞褊韜 竟蒻・, ・・淲 碯蔘・粨蒻・ 浯 胙瑶韭・
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
//---- ・鸙 蓁 竟蒻・
   PlotIndexSetInteger(2,PLOT_ARROW,108);
//---- ・裘湜・蒻浯・魲・・鞣・SignDown[] ・竟蒻・隆 碯・
   SetIndexBuffer(3,SignDown,INDICATOR_DATA);
//---- ⅲ褥・湜・粨聰 竟蒻・ 2 ・ 胛鉋炅琿・浯 Shift
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- ⅲ褥・湜・粨聰 浯・ ⅳ褪・ⅳ粲・竟蒻・ 2
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- 竟蒟・璋・ ・・炅魵 ・碯・ ・・・鴈・  
   ArraySetAsSeries(SignDown,true);
//---- 濵粲・鈿璞褊韜 竟蒻・, ・・淲 碯蔘・粨蒻・ 浯 胙瑶韭・
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
//---- ・鸙 蓁 竟蒻・
   PlotIndexSetInteger(3,PLOT_ARROW,108);
//--- 鈞粢褊韃 竟頽鞨・鈞・
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // ・・粽 頌・・矜・浯 ・・・
                const int prev_calculated,// ・・粽 頌・・矜・浯 ・裝鏸褌 ・
                const datetime &time[],
                const double &open[],
                const double& high[],     // 濵粽・・鞣 ・・韲魵 燾 蓁 褪・竟蒻・
                const double& low[],      // 濵粽・・鞣 ・湜・・・燾 蓁 褪・竟蒻・
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- ・魵褞・ ・・籵 矜・浯 蒡瑣ⅸ濵・蓁 褪・
   if(BarsCalculated(CCI_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//---- 髜・粱褊・ ・・・燾・・・澵顥 
   double CCI[],cciTrendNow,cciTrendPrevious;
   int limit,to_copy,bar;
//---- 竟蒟・璋・ ・・炅魵 ・・鞣瑾, ・・・鴈・ 
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(CCI,true);
//---- 褪 瑩粽胛 濵・ first 蓁 ・・・褪・矜・
   if(prev_calculated>rates_total || prev_calculated<=0) // ・魵褞・ 浯 ・隆 瑩・褪・竟蒻・
     {
      limit=rates_total-min_rates_total;                 // 瑩糺・濵・・蓁 褪・糂襄 矜・
     }
   else
     {
      limit=rates_total-prev_calculated;                 // 瑩糺・濵・・蓁 褪・濵糺・矜・
     }
//----
   to_copy=limit+2;
//----
   to_copy++;
//---- ・・褌 粹魵・・粨糲韃・ 萵澵鐱 ・・鞣 CCI[]
   if(CopyBuffer(CCI_Handle,0,0,to_copy,CCI)<=0) return(RESET);
//---- ⅲ濵粹鵫 ・ 褪・竟蒻・
   for(bar=limit; bar>0 && !IsStopped(); bar--)
     {
      SignUp[bar]=0.0;
      SignDown[bar]=0.0;
      SignUp[bar+1]=0.0;
      SignDown[bar+1]=0.0;
      //----
      cciTrendNow=CCI[bar]+70;
      cciTrendPrevious=CCI[bar+1]+70;
      //----
      if(cciTrendNow>=Level && cciTrendPrevious<Level) TrendUp[bar+1]=TrendDown[bar+1];
      if(cciTrendNow<=Level && cciTrendPrevious>Level) TrendDown[bar+1]=TrendUp[bar+1];
      //----
      if(cciTrendNow>Level)
        {
         TrendDown[bar]=0.0;
         TrendUp[bar]=low[bar]-UpDownShift;
         if(close[bar]<open[bar] && TrendDown[bar+1]!=TrendUp[bar+1]) TrendUp[bar]=TrendUp[bar+1];
         if(TrendUp[bar]<TrendUp[bar+1] && TrendDown[bar+1]!=TrendUp[bar+1]) TrendUp[bar]=TrendUp[bar+1];
         if(high[bar]<high[bar+1] && TrendDown[bar+1]!=TrendUp[bar+1]) TrendUp[bar]=TrendUp[bar+1];
        }
      //----
      if(cciTrendNow<Level)
        {
         TrendUp[bar]=0.0;
         TrendDown[bar]=high[bar]+UpDownShift;
         if(close[bar]>open[bar] && TrendUp[bar+1]!=TrendDown[bar+1]) TrendDown[bar]=TrendDown[bar+1];
         if(TrendDown[bar]>TrendDown[bar+1] && TrendDown[bar+1]!=TrendUp[bar+1]) TrendDown[bar]=TrendDown[bar+1];
         if(low[bar]>low[bar+1] && TrendUp[bar+1]!=TrendDown[bar+1]) TrendDown[bar]=TrendDown[bar+1];
        }
      //----
      if(TrendDown[bar+1]!=0.0 && TrendUp[bar]!=0.0) SignUp[bar+1]=TrendDown[bar+1];
      if(TrendUp[bar+1]!=0.0 && TrendDown[bar]!=0.0) SignDown[bar+1]=TrendUp[bar+1];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+