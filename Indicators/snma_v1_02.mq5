//+------------------------------------------------------------------+
//|                                                  snma_v1_02.mq5  |
//| snma v1.02                                Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.02"
#property indicator_chart_window

#property indicator_buffers 10
#property indicator_plots 1


#property indicator_type1     DRAW_COLOR_LINE 
#property indicator_color1    clrRed,clrPink,clrWhiteSmoke,clrSkyBlue,clrDodgerBlue
#property indicator_width1 3

input int InpNMAPeriod=40; // NMA Period
input int InpSmoothing=42; //  Smoothing
input int InpTemaPeriod=5;    //  Tema Period
input double InpThreshold=2; //  Threshold
double Threshold= InpThreshold*_Point;


double  tema_alpha=2.0/(1.0+InpTemaPeriod);

double NMA[];
double SNMA[];
double SNMA_CLR[];
double EMA1[];
double EMA2[];
double EMA3[];
double TEMA[];
double TR[];
double ATR[];
double SATR[];
// SuperSmoother Filter
double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpSmoothing );
double B1 = 2 * A1 * MathCos( SQ2 *M_PI / InpSmoothing );
double C2 = B1;
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;


int min_rates_total=InpNMAPeriod+1;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   int i=0;
   SetIndexBuffer(i++,SNMA,INDICATOR_DATA);
   SetIndexBuffer(i++,SNMA_CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,TEMA,INDICATOR_DATA);
   SetIndexBuffer(i++,SATR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,ATR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,NMA,INDICATOR_CALCULATIONS);
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
      EMA1[i]=close[i];
      EMA2[i]=close[i];
      EMA3[i]=close[i];
      TEMA[i]=close[i];
      NMA[i]=0;
      SNMA[i]=0;
      //---
      

      if(i<=begin_pos+1)continue;
      EMA1[i]=EMA1[i-1]+tema_alpha*(close[i]-EMA1[i-1]);
      EMA2[i]=EMA2[i-1]+tema_alpha*(EMA1[i]-EMA2[i-1]);
      EMA3[i]= EMA3[i-1]+tema_alpha*(EMA2[i]-EMA3[i-1]);
      TEMA[i]=(3.0*EMA1[i]-3.0*EMA2[i]+EMA3[i]);



      int i1st=begin_pos+10;
      if(i<=i1st)continue;

      //--- NMA
      double diff=0;
      double adif=0;
      for(int j=0;j<InpNMAPeriod;j++)
        {
         double mom=TEMA[i-j]-TEMA[(i-j)-1];
         diff+= MathAbs(mom);
         adif+=(mom) *(MathSqrt(j+1)-MathSqrt(j));
        }
      double ratio=(diff>0)? MathAbs(adif)/diff : 0;
      NMA[i]=NMA[i-1]+(ratio *(TEMA[i]-NMA[i-1]));
      int i2nd=i1st+3;
      if(i<=i2nd)continue;
      SNMA[i]=C1*NMA[i]+C2*SNMA[i-1]+C3*SNMA[i-2];

      //---
      int i3rd=i2nd+2;
      if(i<=i3rd)continue;
      //---
      double slope=SNMA[i]-((SNMA[i-2]+SNMA[i-1])/2);
      //---
      if(slope>Threshold*4 )SNMA_CLR[i]=4;
      else if(slope > Threshold && slope <= Threshold*4 )SNMA_CLR[i]=3;
      else if(slope > -Threshold && slope < Threshold )SNMA_CLR[i]=2;
      else if(slope < -Threshold && slope >= -Threshold*4 )SNMA_CLR[i]=1;
      else if(slope < -Threshold*4)SNMA_CLR[i]=0;
    
      //---

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double atan2(double y,double x)
  {
   double a;
   if(fabs(x)>fabs(y))
      a=atan(y/x);
   else
     {
      a=atan(x/y); // pi/4 <= a <= pi/4
      if(a<0.)
         a=-1.*M_PI_2-a; //a is negative, so we're adding
      else
         a=M_PI_2-a;
     }
   if(x<0.)
     {
      if(y<0.)
         a=a-M_PI;
      else
         a=a+M_PI;
     }
   return a;
  }
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
double nd(const double x,const int n)
  {
   return(NormalizeDouble(x,n));
  }
//+------------------------------------------------------------------+
