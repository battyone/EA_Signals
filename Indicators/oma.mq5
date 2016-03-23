//+------------------------------------------------------------------+
//|                                                         oma.mq5  |
//| oma                                       Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots 1

#property indicator_type1         DRAW_COLOR_LINE
#property indicator_color1       clrRed,clrDodgerBlue
#property indicator_width1 2
input int InpLength=125; // Length
input double InpSpeed=8.0; // Speed
input bool   InpAdaptive=true; // use Adaptive

input double InpThreshold=50; // Shreshold
double Threshold=InpThreshold*_Point;

double OMA[];
double E1[];
double E2[];
double E3[];
double E4[];
double E5[];
double E6[];
double OMA_CLR[];
double SIG[];

// setting for adaptive
double MinPeriod = InpLength/2.0;
double MaxPeriod = MinPeriod*5.0;
int    EndPeriod = (int)MathCeil(MaxPeriod);

int min_rates_total=EndPeriod+1;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,OMA,INDICATOR_DATA);
   SetIndexBuffer(1,OMA_CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,SIG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,E1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,E2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,E3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,E4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,E5,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,E6,INDICATOR_CALCULATIONS);

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
         OMA[i]=0;
         E1[i]=0;
         E2[i]=0;
         E3[i]=0;
         E4[i]=0;
         E5[i]=0;
         E6[i]=0;
        }

     }

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      //---
      double period=(double)InpLength;
      if(InpAdaptive)
        {
         double signal    = MathAbs((close[i]-close[i-EndPeriod]));
         double noise     = 0.00000000001;
         for(int j=1; j<EndPeriod; j++)noise=noise+MathAbs(close[i]-close[i-j]);
         period=((signal/noise)*(MaxPeriod-MinPeriod))+MinPeriod;
        }
      //--- 
      double e1=E1[i-1];
      double e2=E2[i-1];
      double e3=E3[i-1];
      double e4=E4[i-1];
      double e5=E5[i-1];
      double e6=E6[i-1];

      double alpha=(20+InpSpeed)/(1.0+InpSpeed+period);
      //--- v1 
      E1[i] = E1[i-1] + alpha*(close[i]- E1[i-1]);
      E2[i] = E2[i-1] + alpha*(E1[i]   - E2[i-1]);
      double v1=1.5*E1[i]-0.5*E2[i];

      //--- v2
      E3[i] = E3[i-1] + alpha*(v1    - E3[i-1]);
      E4[i] = E4[i-1] + alpha*(E3[i] - E4[i-1]);
      double v2=1.5*E3[i]-0.5*E4[i];

      //--- v3
      E5[i] = E5[i-1] + alpha*(v2    -E5[i-1]);
      E6[i] = E6[i-1] + alpha*(E5[i] -E6[i-1]);
      double v3=1.5*E5[i]-0.5*E6[i];
      OMA[i]=v3;

      //---
      int i1st=begin_pos+3;
      if(i<=i1st)continue;

      if((OMA[i]-Threshold)>SIG[i-1])
         SIG[i]=OMA[i];
      else if((OMA[i]+Threshold)<SIG[i-1])
         SIG[i]=OMA[i];
      else
         SIG[i]=SIG[i-1];

      int i2nd=i1st+1;
      if(i<=i2nd)continue;

      if(SIG[i-1]<SIG[i])OMA_CLR[i]=1;
      else if(SIG[i-1]>SIG[i])OMA_CLR[i]=0;
      else OMA_CLR[i]=OMA_CLR[i-1];

     }
//----

//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
