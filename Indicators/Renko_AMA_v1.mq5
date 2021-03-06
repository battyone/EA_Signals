//+------------------------------------------------------------------+
//|                                                   renko_ama.mq5  |
//| Renko Adaptive Moving Avarage             Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 6
#property indicator_plots 1


#property indicator_type1         DRAW_LINE
#property indicator_color1        clrMagenta
#property indicator_width1 2

#property indicator_type2         DRAW_COLOR_HISTOGRAM2
#property indicator_color2        clrRed,clrDodgerBlue
#property indicator_width2 6


input double InpBoxSize=500; // Box size (in Points)
input int InpBoxCount=5; // Box count
input int InpMaxPeriod=1000; // Max Period
double BoxSize=InpBoxSize*_Point;

double RENKO_H[];
double RENKO_L[];
double RENKO_CLR[];

double RENKO_UP[];
double RENKO_DN[];
double MAIN[];

int min_rates_total=2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- 
//---
   int i=0;
   SetIndexBuffer(i++,MAIN,INDICATOR_DATA);

   SetIndexBuffer(i++,RENKO_H,INDICATOR_DATA);
   SetIndexBuffer(i++,RENKO_L,INDICATOR_DATA);
   SetIndexBuffer(i++,RENKO_CLR,INDICATOR_COLOR_INDEX);

   SetIndexBuffer(i++,RENKO_UP,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,RENKO_DN,INDICATOR_CALCULATIONS);
///  --- 
//--- digits
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
      MAIN[i]=close[i];
      RENKO_DN[i]=0;
      RENKO_UP[i]=0;
      RENKO_H[i]=0;
      RENKO_L[i]=0;
      RENKO_CLR[i]=0;
      if(i==begin_pos)
        {
         RENKO_DN[i]=int(close[i]/BoxSize)*BoxSize;
         RENKO_UP[i]=RENKO_DN[i]+BoxSize;
         RENKO_H[i]=RENKO_UP[i]+BoxSize;
         RENKO_L[i]=RENKO_DN[i];
        }
      if(i==begin_pos)continue;
      //---
      if(close[i]>RENKO_UP[i-1]+BoxSize)
        {
         RENKO_UP[i] = RENKO_UP[i-1]+ BoxSize * int((close[i]-RENKO_UP[i-1])/BoxSize);
         RENKO_DN[i] = RENKO_UP[i] - BoxSize;
         RENKO_H[i]=RENKO_UP[i]+BoxSize;
         RENKO_L[i]=MathMin(RENKO_H[i-1],RENKO_H[i]-BoxSize*2);
         RENKO_CLR[i]=1;
        }
      else if(close[i]<RENKO_DN[i-1]-BoxSize)
        {
         RENKO_DN[i] = RENKO_DN[i-1]- BoxSize * int((RENKO_DN[i-1]-close[i])/BoxSize);
         RENKO_UP[i] = RENKO_DN[i]+BoxSize;
         RENKO_L[i]=RENKO_DN[i]-BoxSize;
         RENKO_H[i]=MathMax(RENKO_L[i-1],RENKO_L[i]+BoxSize*2);
         RENKO_CLR[i]=0;

        }
      else
        {
         RENKO_UP[i]=RENKO_UP[i-1];
         RENKO_DN[i]=RENKO_DN[i-1];
         RENKO_CLR[i]=RENKO_CLR[i-1];
         double b_sz=RENKO_H[i-1]-RENKO_L[i-1];
         if(b_sz==BoxSize*2)
         {
            RENKO_H[i]=RENKO_H[i-1];
            RENKO_L[i]=RENKO_L[i-1];
         }
         else
         {
            if(RENKO_UP[i-1]>RENKO_UP[i-2])
            {
             RENKO_H[i]=RENKO_H[i-1];
             RENKO_L[i]=RENKO_H[i]-BoxSize*2;
            }
            else
            {
             RENKO_L[i]=RENKO_L[i-1];
             RENKO_H[i]=RENKO_L[i]+BoxSize*2;
            }
         }
        }
        
        
      //---
      int i1st=begin_pos+2+InpMaxPeriod;
      if(i<=i1st)continue;
      //--
      int cnt=0;
      int back=1;
      double buf[];
      ArrayResize(buf,0,InpBoxCount);
      double avg=0;
      int sz=0;
      for(int j=0;j<InpMaxPeriod;j++)
        {
         if(RENKO_UP[i-j]==RENKO_UP[i-j-1] )continue;
         cnt++;
         back=j+1;
         //---
         if(InpBoxCount<cnt)break;
        }
       double dmax=close[ArrayMaximum(close,i-(back-1),back)];
       double dmin=close[ArrayMinimum(close,i-(back-1),back)];
       double volat = 0.0000000001+(dmax-dmin)/BoxSize;
       double fact= (back/volat)*InpBoxCount;
       double a=2.0/(fact+1.0);
       MAIN[i]=close[i] * a + MAIN[i-1] * (1 - a);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
