//+------------------------------------------------------------------+
//|                                                        SATR.mq5  |
//| SATR                                      Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 6
#property indicator_plots 1


#property indicator_type1     DRAW_LINE 
#property indicator_color1    clrGold
#property indicator_width1 2

input int InpTemaPeriod=100;    //  Tema Period
input int InpAtrPeriod=100;    //  ATR Period

double  tema_alpha = 2.0 /(1.0 + InpTemaPeriod);
int MinPeriod=int((InpAtrPeriod+0.5)*2);
int MaxPeriod=MinPeriod*5;

double EMA1[];
double EMA2[];
double EMA3[];
double EMA1b[];
double EMA2b[];
double EMA3b[];
double TEMA[];
double TR[];
double ATR[];

int min_rates_total=5;  
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   int i=0;
   SetIndexBuffer(i++,ATR,INDICATOR_DATA);
   SetIndexBuffer(i++,TEMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,TR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA3,INDICATOR_CALCULATIONS);
 
///  --- 
//--- digits
//   IndicatorSetInteger(INDICATOR_DIGITS,1);
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int i,first;
   if(rates_total<=min_rates_total) return(0);
//---
   int begin_pos=min_rates_total;

//---
   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;
//--- preliminary calculations
//---
   
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      //---     
      ATR[i]=0;
      //---
      
      TR[i]=(MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]));
      //TR[i]=MathAbs(close[i]-close[i-1]);
      
      if(i<=begin_pos+1)continue;
      EMA1[i] = EMA1[i-1]+tema_alpha*(TR[i]-EMA1[i-1]);     
      if(i<=begin_pos+2)continue;
      EMA2[i] = EMA2[i-1]+tema_alpha*(EMA1[i]-EMA2[i-1]);     
      if(i<=begin_pos+3)continue;
      EMA3[i] = EMA3[i-1]+tema_alpha*(EMA2[i]-EMA3[i-1]);     
      TEMA[i]=(3.0*EMA1[i] - 3.0*EMA2[i] + EMA3[i]);
      


      int i1st=begin_pos+4+InpAtrPeriod;
      if(i<=i1st)continue;
      if(i==i1st+1)
         {
         double atr=0;
         for(int j=0;j<InpAtrPeriod;j++) atr+=TEMA[i-j];
         ATR[i] = atr/InpAtrPeriod;
         }
      else
      {    
         ATR[i] = ATR[i-1]+ (TEMA[i]-TEMA[i-InpAtrPeriod])/InpAtrPeriod;
      }
      
     
    }
     

//--- return value of prev_calculated for next call
   return(rates_total);
  }
