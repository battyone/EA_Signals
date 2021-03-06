//+------------------------------------------------------------------+
//|                                           LogicalStops_v1.01.mq5 |
//|                                           Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"

#include <MovingAverages.mqh>

#property indicator_chart_window

#property indicator_buffers 14
#property indicator_plots   4
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_type3   DRAW_COLOR_ARROW
#property indicator_type4   DRAW_COLOR_ARROW

#property indicator_color1 clrRed
#property indicator_width1 1

#property indicator_color2 clrDodgerBlue
#property indicator_width2 1

#property indicator_color3  clrNONE,clrRed,clrGold,clrDodgerBlue,clrGreen
#property indicator_width3  1

#property indicator_color4  clrNONE,clrRed,clrGold,clrDodgerBlue,clrGreen
#property indicator_width4  1





input int InpStopSizePoint=100;    // Stop Size Point
input int InpChannelPeriod=2;     // Channel Period

input bool InpShowArrow=false;    // Show Arrow
double StopSize=InpStopSizePoint*_Point;

int InpMaPeriod=12;         // Ma Period
int HiLoPeriod=4;
double MaBuffer[];
double SpreadBuffer[];
double UpChBuffer[];
double DnChBuffer[];

double HighBuffer[];
double LowBuffer[];
double UpperBuffer[];
double LowerBuffer[];
double HSignBuffer[];
double LSignBuffer[];
double HColorBuffer[];
double LColorBuffer[];
double InSideUpBuffer[];
double InSideDnBuffer[];
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   min_rates_total=HiLoPeriod+InpMaPeriod;
//--- indicator buffers mapping
   SetIndexBuffer(0,UpChBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DnChBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,HSignBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,HColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,LSignBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,LColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,HighBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,LowBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,MaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SpreadBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,UpperBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,LowerBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,InSideUpBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,InSideDnBuffer,INDICATOR_CALCULATIONS);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(12,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(13,PLOT_EMPTY_VALUE,0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);

   string short_name="Logical Stops";
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

//---7
   int i,first,begin_pos;
   begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total-1 && !IsStopped(); i++)
     {
      UpChBuffer[i]=0;
      DnChBuffer[i]=0;

      //MaBuffer[i]=SimpleMA(i,InpMaPeriod,close);
      double avg=0;
      for(int j=0;j<InpMaPeriod;j++) avg+=MathAbs(open[i-j]-close[i-j]);
      SpreadBuffer[i]=avg/InpMaPeriod;

      int i1st=begin_pos+InpMaPeriod+HiLoPeriod;
      if(i<=i1st)continue;
      bool up_done=false;
      bool dn_done=false;

      int imax=ArrayMaximum(high,i-3,4);
      int imin=ArrayMinimum(low,i-3,4);
      if(imax==i || imin==i)
        {
         //Pin Bar
         int pinbar=chkPinBar(open[i],high[i],low[i],close[i],SpreadBuffer[i-1]);
         if(pinbar==1)
           {
            HighBuffer[i]=high[i];
            if(InpShowArrow)
              {
               HSignBuffer[i]=high[i];
               HColorBuffer[i]=1;
              }
            up_done=true;
           }
         if(pinbar==-1)
           {
            LowBuffer[i]=low[i];
            if(InpShowArrow)
              {
               LSignBuffer[i]=low[i];
               LColorBuffer[i]=1;
              }
            dn_done=true;
           }
        }
      if(!up_done && !dn_done)
        {
         int rev=chkReversal(open,high,low,close,i,SpreadBuffer[i],MaBuffer[i-1]);
         if(rev==1)
           {
            HighBuffer[i]=high[i];
            if(InpShowArrow)
              {
               HSignBuffer[i]=high[i];
               HColorBuffer[i]=2;
              }
            up_done=true;

           }
         else if(rev==-1)
           {
            LowBuffer[i]=low[i];
            if(InpShowArrow)
              {
               LSignBuffer[i]=low[i];
               LColorBuffer[i]=2;
              }
            dn_done=true;
           }
         else
           {
            double hi,lo;
            chkHiLo(hi,lo,high,low,close,i);
            if(hi>0)
              {
               HighBuffer[i]=hi;
               if(InpShowArrow)
                 {
                  HSignBuffer[i]=hi;
                  HColorBuffer[i]=3;
                 }
               up_done=true;

              }
            if(lo>0)
              {
               LowBuffer[i]=lo;
               if(InpShowArrow)
                 {
                  LSignBuffer[i]=lo;
                  LColorBuffer[i]=3;
                 }
               dn_done=true;
              }

           }
        }

      if(!dn_done)
        {
         if((close[i]-open[i])>SpreadBuffer[i-1]*3 && low[i-1]<low[i])
           {

            LowBuffer[i]=low[i];
            if(InpShowArrow)
              {
               LSignBuffer[i]=low[i];
               LColorBuffer[i]=3;
              }
            dn_done=true;
           }
        }

      if(!up_done)
        {
         if((open[i]-close[i])>SpreadBuffer[i-1]*3 && high[i-1]>high[i])
           {
            HighBuffer[i]=high[i];
            if(InpShowArrow)
              {
               HSignBuffer[i]=high[i];
               HColorBuffer[i]=3;
              }
            up_done=true;
           }
        }
      int brakeout=chkBrakeOut(high,low,close,i);

      if(!up_done || !dn_done)
        {
         // in side bar brake
         if(!dn_done && brakeout>=1)
           {
            int x=brakeout;
            double prev_h=InSideUpBuffer[i-1];
            double prev_l=InSideDnBuffer[i-1];
            LowBuffer[i]=(prev_h+prev_l)*0.5;
            if(InpShowArrow)
              {
               LSignBuffer[i]=LowBuffer[i];
               LColorBuffer[i]=3;
              }
            dn_done=true;

           }
         else if(!up_done && brakeout<=-1)
           {
            int x=MathAbs(brakeout);
            double prev_h=InSideUpBuffer[i-1];
            double prev_l=InSideDnBuffer[i-1];
            HighBuffer[i]=(prev_h+prev_l)*0.5;
            if(InpShowArrow)
              {
               HSignBuffer[i]=HighBuffer[i];
               HColorBuffer[i]=3;
              }
            up_done=true;

           }

        }

      if(!up_done || !dn_done)
        {
         if(chkInSide(high,low,i))
           {
            if(!up_done && (HighBuffer[i-1] >= HighBuffer[i] || HighBuffer[i-1]==0))
              {
               HighBuffer[i]=InSideUpBuffer[i];
               if(InpShowArrow)
                 {
                  HSignBuffer[i]=HighBuffer[i];
                  HColorBuffer[i]=4;
                 }
               up_done=true;
              }
            if(!dn_done && (LowBuffer[i-1]>=LowBuffer[i] || LowBuffer[i-1]==0))
              {
               LowBuffer[i]=InSideDnBuffer[i];
               if(InpShowArrow)
                 {
                  LSignBuffer[i]=LowBuffer[i];
                  LColorBuffer[i]=4;
                 }
               dn_done=true;
              }
           }
        }
      if(InSideUpBuffer[i]==0 && InSideUpBuffer[i-1]!=0 && brakeout==0)
        {
         InSideUpBuffer[i]=InSideUpBuffer[i-1];
         InSideDnBuffer[i]=InSideDnBuffer[i-1];
        }

      if(!dn_done)
        {
         LowBuffer[i]=LowBuffer[i-1];
        }

      if(!up_done)
        {
         HighBuffer[i]=HighBuffer[i-1];
        }

      int i2nd=i1st+InpChannelPeriod;
      if(i<=i2nd)continue;
      double dmax=-999999999;
      double dmin= 999999999;
      for(int j=0;j<InpChannelPeriod;j++)
        {
         if(dmax<HighBuffer[i-j] && HighBuffer[i-j]!=0)dmax=HighBuffer[i-j];
         if(dmin>LowBuffer[i-j] && LowBuffer[i-j]!=0)dmin=LowBuffer[i-j];
        }

      UpperBuffer[i]=(dmax==-999999999 || dmax==0)?UpperBuffer[i-1]:dmax;
      LowerBuffer[i]=(dmin==999999999||dmin==0)?LowerBuffer[i-1]:dmin;
//      if(UpperBuffer[i-1]>=UpperBuffer[i])UpChBuffer[i]=UpperBuffer[i];
//      if(LowerBuffer[i-1]<=LowerBuffer[i])DnChBuffer[i]=LowerBuffer[i];
      UpChBuffer[i]=UpperBuffer[i];
      DnChBuffer[i]=LowerBuffer[i];
     }
//---

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

int chkPinBar(double o,double h,double l,double c,double avgBody1)
  {
   double body=NormalizeDouble((h-l)*0.4,Digits());
   double spread=h-l;
   if(spread<avgBody1 * 3)return (0);

//--- Bearish Pin Bar
   double tail=h-MathMax(o,c);
   double not_tail=MathMax((spread-tail),_Point);
   if(tail/not_tail > 1.3 && o >c-body*0.1 && c <=(l + (h-l)*0.3)) return (1);
   if(tail/not_tail > 1.1 && (o-c)>body*0.5 && c <=(l + (h-l)*0.6)) return (1);
   if(tail/not_tail > 1.3 && MathMax(o,c) <=(l + (h-l)*0.6)) return (1);


//--- Bullish Pin Bar
   tail=MathMin(o,c)-l;
   not_tail=MathMax((spread-tail),_Point);
   if(tail/not_tail > 1.3 && o<c+body*0.1 && c >=(h - (h-l)*0.3)) return (-1);
   if(tail/not_tail > 1.1 && (c-o)>body*0.5 && c >=(h - (h-l)*0.6)) return (-1);
   if(tail/not_tail > 1.3 && MathMin(o,c) >=(h - (h-l)*0.6)) return (-1);

   return (0);
  }
//+------------------------------------------------------------------+
int chkReversal(const double &o[],const double &h[],const double &l[],const double &c[],const int i,double avgBody1,double ma2)
  {

   if(h[i-2]<MathMin(h[i],h[i-1]) && 
      o[i-1]<c[i-1] && 
      o[i]>c[i] && 
      MathMax(c[i-1]-o[i-1],o[i]-c[i])>avgBody1*2.5)
      return(1);

   if(l[i-2]>MathMax(l[i],l[i-1]) && 
      o[i-1]>c[i-1] && 
      o[i]<c[i] && 
      MathMax(c[i]-o[i],o[i-1]-c[i-1])>avgBody1*2.5)
      return(-1);

   if(o[i]>c[i] && 
      o[i]-c[i]>avgBody1*2.5)
      return(1);

   if(o[i]<c[i] && 
      c[i]-o[i]>avgBody1*2.5)
      return(-1);


   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chkInSide(const double &h[],const double &l[],const int i)
  {

   double prev2_h=MathMax(h[i-3],h[i-2]);
   double prev2_l=MathMin(l[i-3],l[i-2]);

   if((h[i-1]-l[i-1])>StopSize)
     {
      if(h[i]<h[i-1] && l[i]>l[i-1])
        {
         InSideUpBuffer[i]=h[i-1];
         InSideDnBuffer[i]=l[i-1];
         return true;
        }
     }
   else if((h[i-2]-l[i-2])>StopSize)
     {
      if(MathMax(h[i-1],h[i])<h[i-2] && 
         MathMin(l[i-1],l[i])>l[i-2])
        {
         InSideUpBuffer[i]=h[i-2];
         InSideDnBuffer[i]=l[i-2];
         return true;
        }
     }
   else if((prev2_h-prev2_l)>StopSize)
     {
      if(MathMax(h[i-1],h[i])<prev2_h && 
         MathMin(l[i-1],l[i])>prev2_l)
        {
         InSideUpBuffer[i]=prev2_h;
         InSideDnBuffer[i]=prev2_l;
         return true;
        }
     }
   return false;


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int chkBrakeOut(const double &h[],const double &l[],const double &c[],const int i)
  {
   return 0;
   double prev_h,prev_l;
   if(InSideUpBuffer[i-1]!=0 && InSideDnBuffer[i-1]!=0)
     {
      prev_h=InSideUpBuffer[i-1];
      prev_l=InSideDnBuffer[i-1];

      double mini=(prev_h-prev_l)*0.25;
      if(prev_l+mini<l[i] &&  prev_h+mini<c[i])return 1;
      if(prev_h-mini>h[i] &&  prev_l-mini>c[i])return -1;
     }

   if(InSideUpBuffer[i-2]!=0 && InSideDnBuffer[i-2]!=0)
     {
      prev_h=InSideUpBuffer[i-2];
      prev_l=InSideDnBuffer[i-2];

      double mini=(prev_h-prev_l)*0.25;
      if(prev_l-mini<l[i-1] && prev_l<c[i-1] && prev_l+mini<l[i] && prev_h+mini<c[i])return   2;
      if(prev_h+mini>h[i-1] && prev_h>c[i-1] && prev_h+mini>h[i] &&  prev_l-mini>c[i])return -2;
     }

   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void chkHiLo(double &upper,double &lower,const double &h[],const double &l[],const double &c[],const int i)
  {
   upper=0;
   lower=0;

   for(int j=1;j<=3;j++)
     {
      if(MathAbs(h[i]-h[i-j])<StopSize*0.2)
        {
         double hh=MathMax(h[i],h[i-j]);
         if((hh-c[i])>StopSize)upper=hh;
        }
      if(MathAbs(l[i]-l[i-j])<StopSize*0.2)
        {
         double ll=MathMin(l[i],l[i-j]);
         if((c[i]-ll)>StopSize)lower=ll;
        }
     }

   int cnt=0;
   int from_j=0;
   for(int j=0;j<InpMaPeriod;j++)
     {
      if(h[i-j]<h[i-j-1] && l[i-j]>l[i-j-1])continue;
      cnt++;
      if(cnt>=3)
        {
         from_j=j;
         break;
        }
     }
   if(from_j==0)return;
   int imax=ArrayMaximum(h,i-from_j,from_j+1);
   int imin=ArrayMinimum(l,i-from_j,from_j+1);

   if(upper==0 && (i-from_j)==imax && (h[imax]-c[i])>StopSize)
     {
      if((h[imax]-c[i])<StopSize*2)
         upper=h[imax];
      else if((h[i]-c[i])>StopSize)
         upper=h[i];
      else if((h[i-1]-c[i])>StopSize)
         upper=h[i-1];
      else
         upper=(h[imax]+c[i])*0.5;

     }
   if(lower==0 && (i-from_j)==imin && (c[i]-l[imin])>StopSize)
     {
      if((c[i]-l[imin])<StopSize*2)
         lower=l[imin];
      else if((c[i]-l[i])>StopSize)
         lower=l[i];
      else if((c[i]-l[i-1])>StopSize)
         lower=l[i-1];
      else
         lower=(l[imin]+c[i])*0.5;
     }
  }
//+------------------------------------------------------------------+
