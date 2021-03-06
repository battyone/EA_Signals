//+------------------------------------------------------------------+
//|                                               Accel_Ma_V1_00.mq5 |
//| Accel Moving Average v1.00                Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 4
#property indicator_plots   1
#property indicator_chart_window

#property indicator_type1 DRAW_LINE
#property indicator_color1 clrMagenta
#property indicator_width1 2


//--- input parameters

input double InpK=0.5; // K
input int InpPeriod=20; // Period
input int InpSmoothing=1; //  Smoothing

double alpha=MathMax(0.001,MathMin(1,InpK));

//---- will be used as indicator buffers
double AMA[];
double SAMA[];
double MAIN[];
double MOM[];
double VOLAT[];
double Accel[];
// SuperSmoother Filter
double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpSmoothing );
double B1 = 2 * A1 * MathCos( SQ2 *M_PI / InpSmoothing );
double C2 = B1;
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;

//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=2;
//--- indicator buffers mapping

//--- indicator buffers
   SetIndexBuffer(0,SAMA,INDICATOR_DATA);
   SetIndexBuffer(1,AMA,INDICATOR_DATA);
   SetIndexBuffer(2,MOM,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,VOLAT,INDICATOR_CALCULATIONS);
//---
 ArrayResize(Accel,InpPeriod);
 for(int j=0;j<InpPeriod;j++) Accel[j]=pow(alpha,MathLog(j+1));
//---
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
         SAMA[i]=close[i];
         AMA[i]=close[i];
         MOM[i]=close[i]-close[i-1];
         VOLAT[i]=fabs(close[i]-close[i-1]);
         //---
         int i1st=begin_pos+InpPeriod;
         if(i<=i1st)continue;
         //---
         double dsum=0.0000000001;
         double volat=0.0000000001;
         double b=0;
         double dmax=0;
         double dmin=0;
         for(int j=0;j<InpPeriod;j++){
          volat+=VOLAT[i-j];
          dsum+=MOM[i-j]*Accel[j];
          if(dsum>dmax)dmax=dsum;
          if(dsum<dmin)dmin=dsum;
          
         }
         double accel=(dmax-dmin)/volat;
         //---
         int i2nd=i1st+2;
         if(i<=i2nd)continue;
         
         AMA[i] = accel*(close[i]-AMA[i-1])+AMA[i-1];
         //--- 
         
         //---
         SAMA[i]=C1*AMA[i]+C2*SAMA[i-1]+C3*SAMA[i-2];
     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
