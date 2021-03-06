//+------------------------------------------------------------------+
//|                                            RSI_convex_v1.01.mq5  |
//| RSI_convex                                Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"
#property indicator_separate_window

#property indicator_levelcolor Silver

#property indicator_buffers 12
#property indicator_plots 5

#property indicator_type1         DRAW_SECTION
#property indicator_color1        clrRed
#property indicator_width1 2

#property indicator_type2         DRAW_SECTION
#property indicator_color2        clrDodgerBlue
#property indicator_width2 2

#property indicator_type3         DRAW_LINE 
#property indicator_color3        clrSilver
#property indicator_width3 1
#property indicator_style3        STYLE_DOT

#property indicator_type4         DRAW_SECTION
#property indicator_color4        clrRed
#property indicator_width4 1

#property indicator_type5         DRAW_SECTION
#property indicator_color5        clrLimeGreen
#property indicator_width5 1



input int Inp1stPeriod=50; // 1st Period
input int Inp2ndPeriod=200; // 2nd Period

input int InpRSIPeriod=25; // RSIPeriod
input int InpPivotSize=5; // PivotSize

double R1[];
double R2[];
double S1[];
double S2[];

double BTM[];
double TOP[];
double MAIN[];
double OSC[];
double NOSC[];
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
   SetIndexBuffer(i++,R2,INDICATOR_DATA);
   SetIndexBuffer(i++,S2,INDICATOR_DATA);
   SetIndexBuffer(i++,OSC,INDICATOR_DATA);
   SetIndexBuffer(i++,R1,INDICATOR_DATA);
   SetIndexBuffer(i++,S1,INDICATOR_DATA);
   SetIndexBuffer(i++,TOP,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,BTM,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i,POS,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(i++,PLOT_EMPTY_VALUE,0);
   SetIndexBuffer(i,NEG,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(i++,PLOT_EMPTY_VALUE,0);
   SetIndexBuffer(i++,NOSC,INDICATOR_CALCULATIONS);

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
      // normalize

      int i1st=begin_pos+2;
      if(i<=i1st)continue;

      S1[i]=EMPTY_VALUE;
      R1[i]=EMPTY_VALUE;
      S2[i]=EMPTY_VALUE;
      R2[i]=EMPTY_VALUE;

      int i2nd=i1st+InpPivotSize+3;
      if(i<=i2nd)continue;
      double dmax=OSC[ArrayMaximum(OSC,i-(InpPivotSize+2),InpPivotSize)];
      double dmin=OSC[ArrayMinimum(OSC,i-(InpPivotSize+2),InpPivotSize)];

      TOP[i]=EMPTY_VALUE;
      BTM[i]=EMPTY_VALUE;
      if(nd(OSC[i-2],1)>=nd(dmax,1))TOP[i-2]=nd(OSC[i-2],1);
      if(nd(OSC[i-2],1)<=nd(dmin,1))BTM[i-2]=nd(OSC[i-2],1);

      int i3rd=i2nd+Inp1stPeriod+1;
      if(i<=i3rd)continue;

      calc_convex(R1,S1,TOP,BTM,nd(OSC[i-1],1),i,Inp1stPeriod);
      int i4th=i3rd+Inp2ndPeriod+1;
      if(i<=i4th)continue;
      calc_convex(R2,S2,R1,S1,EMPTY_VALUE,i,Inp2ndPeriod);

      int i_top1=0;
      int i_top2=0;
      int i_top3=0;
      int i_btm1=0;
      int i_btm2=0;
      int i_btm3=0;

      ObjectDelete(0,"R"+IntegerToString(1));
      ObjectDelete(0,"R"+IntegerToString(2));
      ObjectDelete(0,"S"+IntegerToString(1));
      ObjectDelete(0,"S"+IntegerToString(2));

      for(int j=0;j<Inp2ndPeriod;j++)
        {
         if(i_top3==0 &&  R2[i-j]!=EMPTY_VALUE)
           {
            i_top3=i_top2;
            i_top2=i_top1;
            i_top1=i-j;
           }
         if(i_btm3==0 &&  S2[i-j]!=EMPTY_VALUE)
           {
            i_btm3=i_btm2;
            i_btm2=i_btm1;
            i_btm1=i-j;
           }

         if(i_top3>0 && i_btm3>0)break;
        }

      if(i_top2>0)
        {
         ObjectCreate(0,"R"+IntegerToString(1),OBJ_TREND,WinNo,time[i_top1],R2[i_top1],time[i_top2],R2[i_top2]);
         ObjectSetInteger(0,"R"+IntegerToString(1),OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0,"R"+IntegerToString(1),OBJPROP_WIDTH,2);
         ObjectSetInteger(0,"R"+IntegerToString(1),OBJPROP_RAY_RIGHT,true);

        }
      if(i_top3>0)
        {
         ObjectCreate(0,"R"+IntegerToString(2),OBJ_TREND,WinNo,time[i_top2],R2[i_top2],time[i_top3],R2[i_top3]);
         ObjectSetInteger(0,"R"+IntegerToString(2),OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0,"R"+IntegerToString(2),OBJPROP_WIDTH,2);
         ObjectSetInteger(0,"R"+IntegerToString(2),OBJPROP_RAY_RIGHT,true);
        }
      if(i_btm2>0)
        {
         ObjectCreate(0,"S"+IntegerToString(1),OBJ_TREND,WinNo,time[i_btm1],S2[i_btm1],time[i_btm2],S2[i_btm2]);
         ObjectSetInteger(0,"S"+IntegerToString(1),OBJPROP_COLOR,clrDodgerBlue);
         ObjectSetInteger(0,"S"+IntegerToString(1),OBJPROP_WIDTH,2);
         ObjectSetInteger(0,"S"+IntegerToString(1),OBJPROP_RAY_RIGHT,true);

        }
      if(i_btm3>0)
        {
         ObjectCreate(0,"S"+IntegerToString(2),OBJ_TREND,WinNo,time[i_btm2],S2[i_btm2],time[i_btm3],S2[i_btm3]);
         ObjectSetInteger(0,"S"+IntegerToString(2),OBJPROP_COLOR,clrDodgerBlue);
         ObjectSetInteger(0,"S"+IntegerToString(2),OBJPROP_WIDTH,2);
         ObjectSetInteger(0,"S"+IntegerToString(2),OBJPROP_RAY_RIGHT,true);

        }


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
//|
//+------------------------------------------------------------------+
void convex_hull(double  &hull[][2],const double &points[][2],const int len,const int dir)
  {
   if(len<=2)return;
   ArrayResize(hull,len);
   int k=0;
   for(int i=0;i<len;i++)
     {
      while(k>=2 && 
            (cross(hull[k-2][0],hull[k-2][1],
            hull[k-1][0],hull[k-1][1],
            points[i][0],points[i][1])*dir)>=0)
        {
         k--;
        }

      hull[k][0]= points[i][0];
      hull[k][1]= points[i][1];
      k++;
     }
   ArrayResize(hull,k);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double cross(const double ox,double oy,
             const double ax,double ay,
             const double bx,double by)
  {
   return nd(((ax - ox) * (by - oy) - (ay - oy) * (bx - ox)),1);
  }
//+------------------------------------------------------------------+
void calc_convex(double & R[],double &S[],const double &TP[],const double &BM[],const double new_val, const int i,const int period )
{
      double tops[][2];
      double btms[][2];
      ArrayResize(tops,period);
      ArrayResize(btms,period);
      int i_top=0;
      int i_btm=0;
      if(new_val!=EMPTY_VALUE)
        {
        i_top=1;
        i_btm=1;
         tops[0][1]=0;
         tops[0][1]=new_val;
         btms[0][1]=0;
         btms[0][1]=new_val;
        } 
      for(int j=i_top;j<period;j++)
        {
         if(TP[i-j-1]!=EMPTY_VALUE)
           {
            tops[i_top][0]=j+1;
            tops[i_top][1]=TP[i-j-1];
            i_top++;
           }
         if(BM[i-j-1]!=EMPTY_VALUE)
           {
            btms[i_btm][0]=j+1;
            btms[i_btm][1]=BM[i-j-1];
            i_btm++;
           }
        }

      double lower[][2];
      double upper[][2];
      convex_hull(upper,tops,i_top,1);
      int usz=int(ArraySize(upper)*0.5);

      for(int j=1;j<usz-2;j++)
        {
         int t=(int)upper[j][0];
         R[i-t]=upper[j][1];
        }
      convex_hull(lower,btms,i_btm,-1);
      int lsz=int(ArraySize(lower)*0.5);
      for(int j=1;j<lsz-2;j++)
        {
         int t=(int)lower[j][0];
         S[i-t]=lower[j][1];
        }
        
}