//+------------------------------------------------------------------+
//|                                                   RSI_Lines.mq5  |
//| RSI_Lines                                 Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <MovingAverages.mqh>
#property indicator_separate_window
const double PI=3.14159265359;
double SQ2=sqrt(2);

#property indicator_levelcolor Silver

#property indicator_buffers 10
#property indicator_plots 6

#property indicator_type1         DRAW_LINE
#property indicator_color1        clrRed
#property indicator_width1 1

#property indicator_type2         DRAW_LINE
#property indicator_color2        clrDodgerBlue
#property indicator_width2 1

#property indicator_type3         DRAW_LINE 
#property indicator_color3        clrSilver
#property indicator_width3 1
#property indicator_style3        STYLE_DOT

#property indicator_type4         DRAW_ARROW
#property indicator_color4        clrRed
#property indicator_width4 1

#property indicator_type5         DRAW_ARROW
#property indicator_color5        clrLimeGreen
#property indicator_width5 1

#property indicator_type6         DRAW_LINE 
#property indicator_color6        clrLightSeaGreen
#property indicator_width6 2


input int InpCalcPeriod=120; // CalcPeriod
input int InpRSIPeriod=25; // RSIPeriod
input int InpPivotSize=5; // PivotSize
input int InpSmoothing=20; // Smoothing

double R1[];
double R2[];
double S1[];
double S2[];

double BTM[];
double TOP[];
double MAIN[];
double OSC[];
double POS[];
double NEG[];
int WinNo=ChartWindowFind();
int min_rates_total=InpRSIPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- 
//---
   int i=0;
   SetIndexBuffer(i++,R1,INDICATOR_DATA);
   SetIndexBuffer(i++,S1,INDICATOR_DATA);
   SetIndexBuffer(i++,OSC,INDICATOR_DATA);
   SetIndexBuffer(i++,TOP,INDICATOR_DATA);
   SetIndexBuffer(i++,BTM,INDICATOR_DATA);
   SetIndexBuffer(i++,MAIN,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i,POS,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(i++,PLOT_EMPTY_VALUE,0);
   SetIndexBuffer(i,NEG,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(i++,PLOT_EMPTY_VALUE,0);
   SetIndexBuffer(i++,R2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,S2,INDICATOR_CALCULATIONS);

///  --- 
//--- digits
   IndicatorSetInteger(INDICATOR_DIGITS,2);
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

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      double diff;
      double pos=0;
      double neg=0;
      if(i==begin_pos)
        {
         for(int j=0;j<InpRSIPeriod;j++)
           {
            diff=close[i-j]-close[i-j-1];
            if(diff==0)continue;
            if(diff>0) pos+=diff;
            if(diff<0) neg-=diff;
           }

         POS[i]=pos/InpRSIPeriod;
         NEG[i]=neg/InpRSIPeriod;
         continue;
        }
      diff=close[i]-close[i-1];
      if(diff>0) pos+=diff;
      if(diff<0) neg-=diff;
      //---
      POS[i]=(POS[i-1]*(InpRSIPeriod-1) + pos)/InpRSIPeriod;
      NEG[i]=(NEG[i-1]*(InpRSIPeriod-1) + neg)/InpRSIPeriod;
      //---
      if(NEG[i]!=0.0 && NEG[i]!=EMPTY_VALUE) OSC[i]=50-50/(1+POS[i]/NEG[i]);
      else  if(POS[i]!=0.0) OSC[i]=100.0;
      else  OSC[i]=50.0;
      //---

      int i1st=begin_pos+2;
      if(i<=i1st)continue;

      double a1,b1,c2,c3,c1;

      // SuperSmoother Filter
      a1 = MathExp( -SQ2  * PI / InpSmoothing );
      b1 = 2 * a1 * MathCos( SQ2 *PI / InpSmoothing );
      c2 = b1;
      c3 = -a1 * a1;
      c1 = 1 - c2 - c3;
      MAIN[i]=c1 *(OSC[i]+OSC[i-1])/2+c2*MAIN[i-1]+c3*MAIN[i-2];


      int i2nd=i1st+InpPivotSize+3;
      if(i<=i2nd)continue;
      double dmax=OSC[ArrayMaximum(OSC,i-(InpPivotSize+2),InpPivotSize)];
      double dmin=OSC[ArrayMinimum(OSC,i-(InpPivotSize+2),InpPivotSize)];

      TOP[i]=EMPTY_VALUE;
      BTM[i]=EMPTY_VALUE;
      if(nd(OSC[i-2],1)>=nd(dmax,1) && nd(OSC[i-2],1)>nd(OSC[i-1],1))TOP[i-2]=nd(OSC[i-2],1);
      if(nd(OSC[i-2],1)<=nd(dmin,1) && nd(OSC[i-2],1)<nd(OSC[i-1],1))BTM[i-2]=nd(OSC[i-2],1);

      int i3rd=i2nd+InpCalcPeriod;
      if(i<=i3rd)continue;
      double res=TOP[i-2];
      double sup=BTM[i-2];
      int i_top1=i-2;
      int i_btm1=i-2;
      int i_top2=0;
      int i_btm2=0;
      if(res!=EMPTY_VALUE || sup!=EMPTY_VALUE)
        {
         bool res_break = (res!=EMPTY_VALUE) ? false: true;
         bool sup_break = (sup!=EMPTY_VALUE) ? false: true;
         for(int j=3;j<InpCalcPeriod;j++)
           {
            if(!res_break && TOP[i-j]!=EMPTY_VALUE && res<=TOP[i-j])
              {
               i_top2=i-j;
               res_break=true;
              }
            if(!sup_break && BTM[i-j]!=EMPTY_VALUE && sup>=BTM[i-j])
              {
               i_btm2=i-j;
               sup_break=true;
              }
            if(res_break && sup_break)break;
           }
        }
      R1[i]=EMPTY_VALUE;
      S1[i]=EMPTY_VALUE;
      if(i_top2>0)
        {
         double x = double(i_top1 - i_top2);
         double y = (res-TOP[i_top2])/x;
         for(int t=-2;t<=x;t++)
           {
            int tt=i_top1-t;
            R1[tt]= res-(y*t);
           }
         ObjectDelete(0,"R"+IntegerToString(1));
         ObjectCreate(0,"R"+IntegerToString(1),OBJ_TREND,WinNo,time[i_top1],TOP[i_top1],time[i_top2],TOP[i_top2]);
         ObjectSetInteger(0,"R"+IntegerToString(1),OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0,"R"+IntegerToString(1),OBJPROP_WIDTH,1);
         ObjectSetInteger(0,"R"+IntegerToString(1),OBJPROP_RAY_LEFT,true);

        }
      if(i_btm2>0)
        {
         double x = double((i_btm1-i_btm2));
         double y = (sup-BTM[i_btm2])/x;
         for(int t=-2;t<=x;t++)
           {
            int tt=i_btm1-t;
            S1[tt]= sup-(y*t);
           }
         ObjectDelete(0,"S"+IntegerToString(1));
         ObjectCreate(0,"S"+IntegerToString(1),OBJ_TREND,WinNo,time[i_btm1],BTM[i_btm1],time[i_btm2],BTM[i_btm2]);
         ObjectSetInteger(0,"S"+IntegerToString(1),OBJPROP_COLOR,clrDodgerBlue);
         ObjectSetInteger(0,"S"+IntegerToString(1),OBJPROP_WIDTH,1);
         ObjectSetInteger(0,"S"+IntegerToString(1),OBJPROP_RAY_LEFT,true);

        }

      if(i_btm2>0 && i_top2>0)ChartRedraw();
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
double nd(const double x,const int n)
  {
   return(NormalizeDouble(x,n));
  }
//+------------------------------------------------------------------+
