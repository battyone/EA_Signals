//+------------------------------------------------------------------+
//|                                                       RegrMa.mq5 |
//|                                           Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_chart_window

#property indicator_buffers 3
#property indicator_plots   1

#property indicator_type1 DRAW_COLOR_LINE
#property indicator_type2 DRAW_LINE

#property indicator_color1 clrRed,clrGray,clrDodgerBlue
#property indicator_width1 3

#property indicator_color2 clrSilver
#property indicator_width2 1
#property indicator_color3 clrGold
#property indicator_width3 1

input  ENUM_MA_METHOD InpMaMethod=MODE_EMA; // Ma Method 
input int InpMaPeriod=20;       // Ma Period
input int InpCalcBarCount=20;   // Calc Bar Count 
input int InpDegree=3;  // Degree

input int InpShift=0; // shift
double RegrBuffer[];
double MaBuffer[];
double ColorBuffer[];
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   min_rates_total=InpMaPeriod+InpCalcBarCount+1;
//--- indicator buffers mapping
   SetIndexBuffer(0,RegrBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,MaBuffer,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);

   string short_name="Moving Average Regr";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---

//---
   int i,first,begin_pos;
   begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      double prev_price=0;
      if(InpMaMethod==MODE_EMA || InpMaMethod==MODE_SMMA)
         prev_price=(MaBuffer[i-1]!=EMPTY_VALUE) ? MaBuffer[i-1]: price[i-1];

      switch(InpMaMethod)
        {
         //---
         case MODE_SMA: MaBuffer[i]=SimpleMA(i,InpMaPeriod,price); break;
         case MODE_EMA: MaBuffer[i]=ExponentialMA(i,InpMaPeriod,prev_price,price); break;
         case MODE_LWMA: MaBuffer[i]=LinearWeightedMA(i,InpMaPeriod,price); break;
         case MODE_SMMA: MaBuffer[i]=SmoothedMA(i,InpMaPeriod,prev_price,price);  break;
         default: MaBuffer[i]=SimpleMA(i,InpMaPeriod,price); break;
         //---
        }
      int i1st=begin_pos+InpCalcBarCount*2+InpShift;
      if(i<=i1st)continue;
      //---
      double slope=calcRegression(InpDegree,MaBuffer,i,InpCalcBarCount,InpShift);
      if( slope>0)ColorBuffer[i]=2;
      else if( slope<0)ColorBuffer[i]=0;
      else ColorBuffer[i]=1;

     }
//---

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

double calcRegression(int degree,const double  &arr[],const int pos,const int sz,const int shift)
  {

   if(degree<1) degree=1;
   if(degree>61) degree=61;



   double qq,mm,tt;
   int ii,jj,kk,ll,nn;
   double ai[][65],b[],c[],x[],y[],sx[];


//---- memory distribution for variables' arrays 
   ArrayResize(ai,degree+2);
   ArrayResize(b,degree+2);
   ArrayResize(c,degree+2);
   ArrayResize(x,degree+2);
   ArrayResize(y,degree+2);
   ArrayResize(sx,2*(degree+3));

   int p=sz;
   int mi;

   nn=degree+1;
//---- sx
   sx[1]=sz+1;
   for(mi=1;mi<=nn*2-2;mi++)
     {
      double sum=0;
      for(int j=0;j<=sz;j++)
        {
         sum+=MathPow(j,mi);
        }
      sx[mi+1]=sum;
     }

//---- syx 
   for(mi=1;mi<=nn;mi++)
     {
      double sum=0.00000;
      for(int j=0;j<=sz;j++)
        {

         if(mi==1) sum+=arr[pos-j];
         else      sum+=arr[pos-j]*MathPow(j,mi-1);
        }
      b[mi]=sum;
     }


///---- Matrix 
   for(jj=1;jj<=nn;jj++)
      for(ii=1; ii<=nn; ii++)
        {
         kk=ii+jj-1;
         ai[ii][jj]=sx[kk];
        }

//---- Gauss 
   for(kk=1; kk<=nn-1; kk++)
     {
      ll=0;
      mm=0;

      for(ii=kk; ii<=nn; ii++)
         if(MathAbs(ai[ii][kk])>mm)
           {
            mm=MathAbs(ai[ii][kk]);
            ll=ii;
           }
      if(ll==0) return(0);   

      if(ll!=kk)
        {
         for(jj=1; jj<=nn; jj++)
           {
            tt=ai[kk][jj];
            ai[kk][jj]=ai[ll][jj];
            ai[ll][jj]=tt;
           }

         tt=b[kk];
         b[kk]=b[ll];
         b[ll]=tt;
        }

      for(ii=kk+1;ii<=nn;ii++)
        {
         qq=ai[ii][kk]/ai[kk][kk];

         for(jj=1;jj<=nn;jj++)
           {
            if(jj==kk) ai[ii][jj]=0;
            else       ai[ii][jj]=ai[ii][jj]-qq*ai[kk][jj];
           }

         b[ii]=b[ii]-qq*b[kk];
        }
     }

   x[nn]=b[nn]/ai[nn][nn];

   for(ii=nn-1;ii>=1;ii--)
     {
      tt=0;
      for(jj=1;jj<=nn-ii;jj++)
        {
         tt=tt+ai[ii][ii+jj]*x[ii+jj];
         x[ii]=(1/ai[ii][ii])*(b[ii]-tt);
        }
     }
//----
   double slope=0;
   for(int j=0;j<=0;j++)
     {
      double sum=0;
      for(kk=1;kk<=degree;kk++) sum+=x[kk+1]*MathPow(j,kk);
      RegrBuffer[pos-j]=x[1]+sum;
     }

   return RegrBuffer[pos-InpShift]-RegrBuffer[pos-InpShift-1];
  }
//+------------------------------------------------------------------+
