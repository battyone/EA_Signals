//+------------------------------------------------------------------+
//|                                               Swing Strength.mq5 |
//| Swing Strength v1.02                      Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.02"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   3

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Red,Gray,DodgerBlue
#property indicator_type2   DRAW_FILLING
#property indicator_color2  DarkSlateGray
#property indicator_width1 2
//--- input parameters
input int Inp1stPeriod=7; // 1st Period 
input int Inp2ndPeriod=21;// 2nd Period 
input int InpSMoothing=2;// Smoothing Period 
double InpThreshold=0.1;// Threshold Level


int InpThresholdPeriod=100;// ThreshHold Period 
int InpAtrPeriod=10;
//---- will be used as indicator buffers
double UpBuffer[];
double DnBuffer[];
double UpperLvBuffer[];
double LowerLvBuffer[];
double MainBuffer[];
double SmoothBuffer[];
double ColorBuffer[];
double SigBuffer[];
double SlowBuffer[];
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=Inp1stPeriod+Inp2ndPeriod;
//--- indicator buffers mapping

   SetIndexBuffer(0,SmoothBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,UpperLvBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,LowerLvBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,SlowBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,SigBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,MainBuffer,INDICATOR_CALCULATIONS);
//---
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---

   string short_name="Swing Strength v1.00";

   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//---
   return(INIT_SUCCEEDED);
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
   if(rates_total<=min_rates_total)
      return(0);
//---

//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      int i1st=begin_pos+10;
      if(i<=i1st)continue;
      double maH=(high[i-2] +close[i-2] + high[i-1] +close[i-1])/4;
      double maL=( low[i-2] +close[i-2] +  low[i-1] +close[i-1])/4;
      //---
      double dup=MathMax(0,   (  (high[i] + close[i])/2  - maL)  );
      double ddn=MathMax(0,   (maH -(low[i]+close[i ])/2      )  );      
      if((dup+ddn)==0)
         SigBuffer[i] =0;
      else
         SigBuffer[i] = (dup-ddn)*MathAbs((dup-ddn)/(dup+ddn));
      
      int i2nd=i1st+MathMax(Inp1stPeriod,Inp2ndPeriod);
      if(i<=i2nd) continue;
      double sig1=0.0;
      double sig2=0.0;
      for(int j=0; j<Inp1stPeriod; j++) sig1+=SigBuffer[i-j];
      for(int j=0; j<Inp2ndPeriod; j++) sig2+=SigBuffer[i-j];
      sig1/=Inp1stPeriod;
      sig2/=Inp2ndPeriod;
      MainBuffer[i]=(sig1+sig2)/2;
      int i3rd=i2nd+InpSMoothing*3;
      if(i<=i3rd) continue;

      double avg2=0;
      for(int j=0;j<InpSMoothing;j++) 
        {
        int ii=i-j;
        double avg1=0;
        for(int k=0;k<InpSMoothing;k++)
          {
           int iii=ii-k;
           double avg0=0;
           for(int l=0;l<InpSMoothing;l++) avg0+=MainBuffer[iii-l];
           avg1 += avg0/InpSMoothing;
          }              
        avg2 += avg1/InpSMoothing;
        }
        
      SmoothBuffer[i]=avg2/InpSMoothing;  

      int i4th=i3rd+InpThresholdPeriod+5;
      if(i<=i4th) continue;
      double stddev=0;
      for(int j=0;j<InpThresholdPeriod;j++)
         stddev+=MathPow(0-MainBuffer[i-j],2);
      //---
      stddev=MathSqrt(stddev/(InpThresholdPeriod));
      UpperLvBuffer[i]=stddev*InpThreshold;
      LowerLvBuffer[i]=-stddev*InpThreshold;

      int i5th=i4th+InpAtrPeriod+InpAtrPeriod*7+5;
      if(i<=i5th)continue;
      double atr=0;
      for(int j=0;j<InpAtrPeriod*7;j++)
         {
            double atr1=0;
            for(int k=0;k<InpAtrPeriod;k++)
               atr1+=MathAbs(SmoothBuffer[(i-j)-k]-SmoothBuffer[(i-j)-k-1]);
            
            atr+=atr1/InpAtrPeriod;
         }
      atr/= InpAtrPeriod*7;  
      double th=atr*0.8;
      //---
  
      double sign=1;
      double ma=(SmoothBuffer[i-1]+SmoothBuffer[i-2]+SmoothBuffer[i-3])/3;
      //---
      if(SmoothBuffer[i]<=ma+th && SmoothBuffer[i]>=ma-th)sign=1;
      else if( SmoothBuffer[i]>ma)sign=2;
      else if( SmoothBuffer[i]<ma)sign=0;      
      ColorBuffer[i]=sign;

     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
