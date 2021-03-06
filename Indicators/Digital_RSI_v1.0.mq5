//+------------------------------------------------------------------+
//|                                                  Digital RSI.mq5 |
//| Digital RSI                               Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <MovingAverages.mqh>
enum ENUM_MY_METHOD  
  {
   SMA     = 0,
   LWMA    = 1
  } ;
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level2       30.0
#property indicator_level1       70.0
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Red,Gray,DodgerBlue
#property indicator_width1 2
//--- input parameters
input int InpRSI_Period=14; // RSI Period 
input int InpSmoothing=7;// Smoothing Period 
input ENUM_MY_METHOD InpMethod=SMA; // MA Method
input double InpThreshold=4.0; // Threshold
//---- will be used as indicator buffers

double ColorBuffer[];
double RSIBuffer[];
double DigitBuffer[];
double SigBuffer[];
double SmoothBuffer[];
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=InpRSI_Period+InpSmoothing*2;
//--- indicator buffers mapping

   SetIndexBuffer(0,DigitBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,RSIBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SmoothBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SigBuffer,INDICATOR_CALCULATIONS);
//---
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---

   string short_name="Digital RSI v1.00";

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
      double sumP=0.0;
      double sumN=0.0;
      for(int j=0;j<InpRSI_Period;j++)
        {
         double diff=close[i-j]-close[i-j-1];
         sumP+=(diff>0?diff:0);
         sumN+=(diff<0?-diff:0);
        }
      sumP/=InpRSI_Period;
      sumN/=InpRSI_Period;

      if(sumN!=0.0)
         RSIBuffer[i]=100.0-(100.0/(1.0+sumP/sumN));
      else
         RSIBuffer[i]=(sumP!=0.0)?100.0:50.0;

      int i1st=begin_pos+InpSmoothing+1;
      if(i<=i1st)continue;
      if(InpMethod ==LWMA)
            SmoothBuffer[i]=LinearWeightedMA(i,InpSmoothing,RSIBuffer);
      else  
            SmoothBuffer[i]=SimpleMA(i,InpSmoothing,RSIBuffer);
      int i2nd=i1st+1;
      if(i<=i2nd) continue;
      if((DigitBuffer[i-1]+InpThreshold) < SmoothBuffer[i] )DigitBuffer[i]=SmoothBuffer[i];
      else if((DigitBuffer[i-1]-InpThreshold) > SmoothBuffer[i] )DigitBuffer[i]=SmoothBuffer[i];
      else DigitBuffer[i]=DigitBuffer[i-1];

      int i3rd=i2nd+1;
      if(i<=i3rd) continue;

      if(DigitBuffer[i-1]<DigitBuffer[i])   SigBuffer[i]=2;
      else if(DigitBuffer[i-1]>DigitBuffer[i])    SigBuffer[i]=0;
      else SigBuffer[i]=SigBuffer[i-1];
  
      ColorBuffer[i]=SigBuffer[i];
     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
