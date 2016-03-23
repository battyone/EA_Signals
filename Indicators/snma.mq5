//+------------------------------------------------------------------+
//|                                                        snma.mq5  |
//| snma                                      Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 1

#property indicator_type1         DRAW_COLOR_LINE
#property indicator_color1       clrRed,clrDodgerBlue
#property indicator_width1 2
input int InpNMAPeriod=40; // NMA Period
input int InpSmoothing=8; //  Smoothing
input double InpThreshold=50; // Shreshold
double Threshold=InpThreshold*_Point;
double NMA[];
double SNMA[];
double SNMA_CLR[];
double SIG[];

int min_rates_total=InpNMAPeriod+InpSmoothing+1;
// SuperSmoother Filter

double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpSmoothing );
double B1 = 2 * A1 * MathCos( SQ2 *M_PI / InpSmoothing );
double C2 = B1;
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,SNMA,INDICATOR_DATA);
   SetIndexBuffer(1,SNMA_CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,NMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SIG,INDICATOR_CALCULATIONS);

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
   else
     {
      for(i=0;i<first;i++)
        {
         NMA[i]=0;
         SNMA[i]=0;
        }

     }

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      double diff=0;
      double adif=0;
      for(int j=0;j<InpNMAPeriod;j++)
        {
         double mom=close[i-j]-close[(i-j)-1];
         diff+= MathAbs(mom);
         adif+=(mom) *(MathSqrt(j+1)-MathSqrt(j));
        }
      double ratio=(diff>0)? MathAbs(adif)/diff : 0;
      NMA[i]=NMA[i-1]+(ratio *(close[i]-NMA[i-1]));
      //---
      int i1st=begin_pos+3;
      if(i<=i1st)continue;
      SNMA[i]=C1 *(NMA[i]+NMA[i-1])/2+C2*SNMA[i-1]+C3*SNMA[i-2];
      int i2nd=i1st+1;
      if(i<=i2nd)continue;

      if((SNMA[i]-Threshold)>SIG[i-1])
         SIG[i]=SNMA[i];
      else if((SNMA[i]+Threshold)<SIG[i-1])
         SIG[i]=SNMA[i];
      else
         SIG[i]=SIG[i-1];

      int i3rd=i2nd+1;
      if(i<=i3rd)continue;

      if(SIG[i-1]<SIG[i])SNMA_CLR[i]=1;
      else if(SIG[i-1]>SIG[i])SNMA_CLR[i]=0;
      else SNMA_CLR[i]=SNMA_CLR[i-1];

     }
//----

//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
