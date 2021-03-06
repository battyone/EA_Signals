//+------------------------------------------------------------------+
//|                                            RSI_convex_v1.04.mq5  |
//| RSI_convex_v1.0.4                         Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.04"
#property indicator_separate_window

#property indicator_levelcolor Silver

#property indicator_buffers 12
#property indicator_plots 3

#property indicator_type1         DRAW_LINE 
#property indicator_color1        clrSilver
#property indicator_width1 1
#property indicator_style1        STYLE_DOT

#property indicator_type2         DRAW_LINE
#property indicator_color2        clrRed
#property indicator_width2 2

#property indicator_type3         DRAW_LINE
#property indicator_color3        clrLimeGreen
#property indicator_width3 2

input int InpRSIPeriod=40; // RSIPeriod
input int InpMinSize=10; //    Minimum Period
input int InpCalcPeriod=50; // Calc Period
input double InpThreshold=0.5; // MaxDistance

double R1[];
double S1[];
double OSC[];
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
   SetIndexBuffer(i++,OSC,INDICATOR_DATA);
   SetIndexBuffer(i++,R1,INDICATOR_DATA);
   SetIndexBuffer(i++,S1,INDICATOR_DATA);
   SetIndexBuffer(i,POS,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(i++,PLOT_EMPTY_VALUE,0);
   SetIndexBuffer(i,NEG,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(i++,PLOT_EMPTY_VALUE,0);

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
      S1[i]=EMPTY_VALUE;
      R1[i]=EMPTY_VALUE;
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
      if(NEG[i]!=0.0 && NEG[i]!=EMPTY_VALUE) OSC[i]=100-100/(1+POS[i]/NEG[i]);
      else  if(POS[i]!=0.0) OSC[i]=100.0;
      else  OSC[i]=50.0;
      // normalize
      int i1st=InpCalcPeriod+1;
      if(i<=i1st)continue;
      calc_convex(R1,S1,OSC,i,i-InpCalcPeriod,time);

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
   int k=0;
   ArrayResize(hull,k,len);
   if(len<=2)return;

   for(int i=k;i<len;i++)
     {
      while(k>=2 && 
            (cross(hull[k-2][0],hull[k-2][1],
            hull[k-1][0],hull[k-1][1],
            points[i][0],points[i][1])*dir)>=0)
        {
         k--;
        }
      if(points[i][0]!=EMPTY_VALUE)
        {
         ArrayResize(hull,k+1,len);
         hull[k][0]= points[i][0];
         hull[k][1]= points[i][1];
         k++;
        }
     }

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
void calc_convex(double  &R[],double &S[],const double &SRC[],const int i,const int period,const datetime &time[])
  {
   double vertex[][2];
   ArrayResize(vertex,0,period);
   int i_vtx=0;
   double upper[][2];
   double lower[][2];
   int up_sz=0;
   int lo_sz=0;
   for(int j=period;j<=i;j++)
     {
      if(R[j]!=EMPTY_VALUE || S[j]!=EMPTY_VALUE)continue;
      if(SRC[j]!=EMPTY_VALUE)
        {
         if((up_sz+lo_sz)>InpMinSize && (i_vtx>0 && i-vertex[0][0]>0))
           {
            double a,b,dev;
            regression(a,b,dev,SRC,int(vertex[0][0]),i-2);
            double mx,my;
            calc_centroid(mx,my,upper,lower);
            if((up_sz+lo_sz)>period || MathAbs((mx*a+b)-my)>InpThreshold)
              {
               for(int k=1;k<up_sz;k++)
                 {
                  int t1=(int)upper[k-1][0];
                  int t2=(int)upper[k][0];

                  double y1 = upper[k-1][1];
                  double y2 = upper[k][1];
                  double yy=(y2-y1)/(t2-t1);
                  for(int kk=t1;kk<=t2;kk++)
                     R[kk]=y1+yy*(kk-t1);
                 }

               for(int k=1;k<lo_sz;k++)
                 {
                  int t1=(int)lower[k-1][0];
                  int t2=(int)lower[k][0];

                  double y1 = lower[k-1][1];
                  double y2 = lower[k][1];
                  double yy=(y2-y1)/(t2-t1);
                  for(int kk=t1;kk<=t2;kk++)
                     S[kk]=y1+yy*(kk-t1);
                 }

               double temp[1][2];
               temp[0][0]=vertex[i_vtx-1][0];
               temp[0][1]=vertex[i_vtx-1][1];
               ArrayResize(vertex,1,period);
               vertex[0][0]=temp[0][0];
               vertex[0][1]=temp[0][1];
               i_vtx=1;
              }
           }
        }
      ArrayResize(vertex,i_vtx+1,period);
      vertex[i_vtx][0] = j;
      vertex[i_vtx][1] = SRC[j];
      i_vtx++;
      convex_hull(upper,vertex,i_vtx,-1);
      convex_hull(lower,vertex,i_vtx,1);
      up_sz=int(ArraySize(upper)*0.5);
      lo_sz=int(ArraySize(lower)*0.5);
     }

   ObjectsDeleteAll(0,WinNo);
   for(int k=1;k<up_sz;k++)
     {
      int t1=(int)upper[k-1][0];
      int t2=(int)upper[k][0];
      double y1 = upper[k-1][1];
      double y2 = upper[k][1];
      drawR(k,t1,y1,t2,y2,time);

     }
   for(int k=1;k<lo_sz;k++)
     {
      int t1=(int)lower[k-1][0];
      int t2=(int)lower[k][0];
      double y1 = lower[k-1][1];
      double y2 = lower[k][1];
      drawS(k,t1,y1,t2,y2,time);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool check_distance(double  &vertex[][2],const int x,const double y,const double limit)
  {
   int sz=int(ArraySize(vertex)/2);
   double dmin=0;
   for(int j=0;j<sz;j++)
     {
      double dst=distance(vertex[j][0],vertex[j][1],x,y);
      if(dmin==0 || dmin>dst) dmin=dst;
     }
   return(dmin<=limit);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double distance(const double ax,const double ay,const double  bx,const double by)
  {
   double dx = ax-bx;
   double dy = ay-by;
   return MathSqrt((dx * dx) + (dy * dy));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void regression(double  &a,double  &b,double &dev,const double &data[],const int from,const int to)
  {

   int temp_sz=to-from;
   double temp[][2];
   ArrayResize(temp,temp_sz+1);
   int n=0;
   for(int k=from;k<=to;k++)
     {
      temp[n][0]=k;
      temp[n][1]=data[k];
      n++;
     }
   _regression(a,b,temp,n);
   dev=0;
   for(int i=0; i<n; i++)
      dev+=MathPow((temp[i][0]*a+b)-temp[i][1],2);
   dev=MathSqrt(dev/n);
  }
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
void _regression(double  &a,double  &b,const double &data[][2],const int cnt)
  {

   if(cnt==0)
     {
      a=EMPTY_VALUE;
      b=EMPTY_VALUE;
      return;
     }
//--- 
   double sumy=0.0; double sumx=0.0;
   double sumxy=0.0; double sumx2=0.0;

//--- 
   for(int n=0; n<cnt; n++)
     {
      //---
      sumx+=data[n][0];
      sumx2+= data[n][0]*data[n][0];
      sumy += data[n][1];
      sumxy+= data[n][0]*data[n][1];

     }
//---
   double c=sumx2-sumx*sumx/cnt;
   if(c==0.0)
     {
      a=0.0;
      b=sumy/cnt;
     }
   else
     {
      a=(sumxy-sumx*sumy/cnt)/c;
      b=(sumy-sumx*a)/cnt;
     }
  }
//+------------------------------------------------------------------+

void calc_centroid(double  &x,double  &y,const double  &upper[][2],const double  &lower[][2])
  {
   double vertices[][2];
   int up_sz=int(ArraySize(upper)*0.5);
   int lo_sz=int(ArraySize(lower)*0.5);
   int sz=up_sz+lo_sz;
   ArrayResize(vertices,0,sz);

   int n=0;
   for(int j=0;j<up_sz-1;j++)
     {
      ArrayResize(vertices,n+1,sz);
      vertices[n][0]=upper[j][0];
      vertices[n][1]=upper[j][1];
      n++;
     }
   for(int j=lo_sz-1;j>=1;j--)
     {
      ArrayResize(vertices,n+1,sz);
      vertices[n][0]=lower[j][0];
      vertices[n][1]=lower[j][1];
      n++;
     }

   int v_cnt=n;
   y=0;
   x=0;
   double signedArea=0.0;
   double x0 = 0.0; // Current vertex X
   double y0 = 0.0; // Current vertex Y
   double x1 = 0.0; // Next vertex X
   double y1 = 0.0; // Next vertex Y
   double a = 0.0;  // Partial signed area

                    // For all vertices
   int i=0;
   for(i=0; i<v_cnt-1; i++)
     {
      x0 = vertices[i][0];
      y0 = vertices[i][1];
      if(i==v_cnt-2)
        {
         x1 = vertices[0][0];
         y1 = vertices[0][1];
        }
      else
        {
         x1 = vertices[i+1][0];
         y1 = vertices[i+1][1];
        }
      a=x0*y1-x1*y0;
      signedArea+=a;
      x += (x0 + x1)*a;
      y += (y0 + y1)*a;
     }
   if(signedArea!=0.0)
     {
      signedArea*=0.5;
      x /= (6.0*signedArea);
      y /= (6.0*signedArea);
     }

  }
//+------------------------------------------------------------------+
void drawR(const int n,const int x0,const double y0,const int x1,const double y1,const datetime &time[])
  {
   ObjectCreate(0,"R"+IntegerToString(n),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
   ObjectSetInteger(0,"R"+IntegerToString(n),OBJPROP_COLOR,clrRed);
   ObjectSetInteger(0,"R"+IntegerToString(n),OBJPROP_WIDTH,2);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawS(const int n,const int x0,const double y0,const int x1,const double y1,const datetime &time[])
  {
   ObjectCreate(0,"S"+IntegerToString(n),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
   ObjectSetInteger(0,"S"+IntegerToString(n),OBJPROP_COLOR,clrLimeGreen);
   ObjectSetInteger(0,"S"+IntegerToString(n),OBJPROP_WIDTH,2);

  }
//+------------------------------------------------------------------+
