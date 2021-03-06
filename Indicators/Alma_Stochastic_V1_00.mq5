//+------------------------------------------------------------------+
//|                                        Alma_Stochastic_v1_00.mq5 |
//| ALMA by Arnaud Legoux / Dimitris Kouzis-Loukas / Anthony Cascino |
//|                                             www.arnaudlegoux.com | 
//| Alma Stochastic v1.00                    Written BY 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 10
#property indicator_plots   1
#property indicator_separate_window

#property indicator_minimum -0
#property indicator_maximum 100

#property indicator_level1 75
#property indicator_level2 25

#property indicator_type1         DRAW_COLOR_LINE
#property indicator_color1       clrDodgerBlue ,clrSilver,clrRed
#property indicator_width1 2


//--- input parameters
input int InpKPeriod=8;  // K period
input int InpSlowing=3;  // Slowing
input int InpThreshold=5; //Threshold
input int InpLength      =     9;       //Window Size  
input double InpSigma    =   6.0;       //Sigma parameter 
input double InpOffset   =  0.85;       //Offset of Gaussian distribution (0...1)

                                        // alpha
double Alpha=2.0/(1.0+InpKPeriod);

//---- will be used as indicator buffers
double OSC[];
double SOSC[];

double HI[];
double LO[];
double POS[];
double RANGE[];

double MAIN[];
double MA[];
double SIG[];
double MOM[];
double VOLAT[];
double Accel[];

//---- declaration of global variables

double W[];
int min_rates_total=InpKPeriod+1;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point

//--- indicator buffers mapping
   SetIndexBuffer(0,MAIN,INDICATOR_DATA);
   SetIndexBuffer(1,SIG,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,SOSC,INDICATOR_DATA);
   SetIndexBuffer(3,MA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,HI,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,LO,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,MOM,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,POS,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,RANGE,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,OSC,INDICATOR_CALCULATIONS);
//---
   ArrayResize(W,InpLength);
   double m = MathFloor(InpOffset*(InpLength - 1));
   double s = InpLength/InpSigma;
   double wSum=0;
   for(int i=0;i<InpLength;i++)
     {
      W[i] = MathExp(-((i-m)*(i-m))/(2*s*s));
      wSum+= W[i];
     }
   for(int i=0;i<InpLength;i++) W[i]=W[i]/wSum;
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
      MAIN[i]=50;
      OSC[i]=50;
      HI[i]=high[ArrayMaximum(high,i-(InpKPeriod-1),InpKPeriod)];
      LO[i]=low[ArrayMinimum(low,i-(InpKPeriod-1),InpKPeriod)];


      int i1st=begin_pos+InpSlowing;
      if(i<=i1st)continue;
      double sumlow=0.0;
      double sumhigh=0.0;
      for(int k=(i-InpSlowing+1);k<=i;k++)
        {
         sumlow +=(close[k]-LO[k]);
         sumhigh+=(HI[k]-LO[k]);
        }
      POS[i]=sumlow;
      RANGE[i]=sumhigh;

      OSC[i]=(RANGE[i]==0)?50 :(100 *(POS[i]/RANGE[i]));
      //---

      int i2nd=i1st+InpLength+1;
      if(i<=i2nd)continue;

      double dsum=0.0;
      for(int j=0; j<InpLength; j++)
        {
         int jj=(InpLength - 1) - j;
         dsum += OSC[i-jj] * W[j];
        }
      SOSC[i]=dsum;

      int i3rd=i2nd+5;

      if(i<=i3rd) continue;

      if((MAIN[i-1]+InpThreshold)<SOSC[i])MAIN[i]=SOSC[i];
      else if((MAIN[i-1]-InpThreshold)>SOSC[i])MAIN[i]=SOSC[i];
      else MAIN[i]=MAIN[i-1];

      //---
      if(i<=i3rd+1) continue;
      //---
      if(MAIN[i]>MAIN[i-1])SIG[i]=0;
      else if(MAIN[i]<MAIN[i-1])SIG[i]=2;
      else SIG[i]=SIG[i-1];

     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
