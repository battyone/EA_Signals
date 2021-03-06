//+------------------------------------------------------------------+
//|                                          hp_oscillator v1.00.mq5 |
//| HP Oscillator v1.00                       Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 50
#property indicator_type1   DRAW_LINE
#property indicator_color1  DodgerBlue
#property indicator_width1 2
#property indicator_type2   DRAW_LINE
#property indicator_color2  Gold
#property indicator_style2  STYLE_DOT
#property indicator_width2 1
//--- input parameters
input int Inp1stPeriod=8; // Oscillator Period 
input int InpLambda=20;   // HP Lambda 
input int InpCalc_Period=200;//HP Calc Period 
input int InpRePaint_Period=10;// RePaint Period 

//---- will be used as indicator buffers
double OscBuffer[];
double SigBuffer[];
double MainBuffer[];
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=Inp1stPeriod+InpRePaint_Period*2;
//--- indicator buffers mapping
   SetIndexBuffer(0,MainBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,OscBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,SigBuffer,INDICATOR_CALCULATIONS);

   IndicatorSetInteger(INDICATOR_DIGITS,2);

//---
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---

   string short_name="HP Oscillator v1.00";

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
   
   for(i=first; i<rates_total-1 && !IsStopped(); i++)
     {
      int i1st=begin_pos+10;
      if(i<=i1st)continue;
      double dir=CalcUpDn(open,high,low,close,i);
      double v=100*dir;
      SigBuffer[i]=v *MathMax(_Point,(high[i]-low[i]));

      int i2nd=i1st+Inp1stPeriod;
      if(i<=i2nd) continue;
      double dmax1=0.0;
      double sig1=0.0;
      double dmax2=0.0;
      double sig2=0.0;

      for(int j=0;j<Inp1stPeriod;j++)
        {
         dmax1+=(high[i-j]-low[i-j]);
         sig1+=SigBuffer[i-j];
        }
      sig1/=Inp1stPeriod;
      dmax1/=Inp1stPeriod;

      OscBuffer[i]=sig1/MathMax(_Point,dmax1);


      int i3rd=i2nd+InpRePaint_Period+InpCalc_Period+1;
      if(i<=i3rd) continue;
      double result[];
      HPFilter(OscBuffer,result,InpLambda,i,InpCalc_Period);
      for(int j=0;j<InpRePaint_Period;j++) MainBuffer[i-j]=result[j];
     }
     OscBuffer[rates_total-1]=0;
     MainBuffer[rates_total-1]=0;
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcUpDn(const double  &o[],const double  &h[],const double  &l[],const double  &c[],const int i)
  {

   double up= MathMax(0,(c[i]-o[i])) + (c[i]-l[i]);
   double dn= MathMax(0,(o[i]-c[i])) + (h[i]-c[i]);
   double dir=(up/MathMax(0.0000001,(up+dn)));
   return dir;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HPFilter(double &aySource[],double &ayResult[],int Lambda,int i,int count)
  {
//---
   double Ak[],Bk[],Ck[],H1=0.0,H2=0.0,H3=0.0,H4=0.0,H5=0.0,HH1=0.0,HH2=0.0,HH3=0.0,HH5=0.0,HB,HC,Z;
   ArrayResize(ayResult,count);
   ArrayResize(Ak,count);
   ArrayResize(Bk,count);
   ArrayResize(Ck,count);
//---
   Ak[0]=1.0+Lambda;
   Bk[0]=-2.0*Lambda;
   Ck[0]=Lambda;
//---
   for(int Hx=1; Hx<count-2; Hx++)
     {
      Ak[Hx]=6.0*Lambda+1.0;
      Bk[Hx]=-4.0*Lambda;
      Ck[Hx]=Lambda;
     }
//---
   Ak[1]=5.0*Lambda+1;
   Ak[count-1]=1.0+Lambda;
   Ak[count-2]=5.0*Lambda+1.0;
   Bk[count-2]=-2.0*Lambda;
   Bk[count-1]=0.0;
   Ck[count-2]=0.0;
   Ck[count-1]=0.0;
//--- forward
   for(int Hx=0; Hx<count; Hx++)
     {
      Z=Ak[Hx]-H4*H1-HH5*HH2;
      HB=Bk[Hx];
      HH1=H1;
      H1=(HB-H4*H2)/Z;
      Bk[Hx]=H1;
      HC=Ck[Hx];
      HH2=H2;
      H2=HC/Z;
      Ck[Hx]=H2;
      Ak[Hx]=(aySource[i-Hx]-HH3*HH5-H3*H4)/Z;
      HH3=H3;
      H3=Ak[Hx];
      H4=HB-H5*HH1;
      HH5=H5;
      H5=HC;
     }
//--- backward 
   H2=0;
   H1=Ak[count-1];
   ayResult[count-1]=H1;

   for(int Hx=count-2; Hx>=0; Hx--)
     {
      ayResult[Hx]=Ak[Hx]-Bk[Hx]*H1-Ck[Hx]*H2;
      H2=H1;
      H1=ayResult[Hx];
     }

//---
  }
//+------------------------------------------------------------------+
