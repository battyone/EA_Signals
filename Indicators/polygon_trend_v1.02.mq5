//+------------------------------------------------------------------+
//|                                                convex_v1.02.mq5  |
//| polygon_trend_v1.02                       Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.02"
#property indicator_chart_window


#property indicator_buffers 10
#property indicator_plots 5

#property indicator_type1         DRAW_LINE 
#property indicator_color1        clrAqua
#property indicator_width1 1
#property indicator_type2         DRAW_LINE 
#property indicator_color2        clrAqua
#property indicator_width2 1
#property indicator_type3         DRAW_LINE 
#property indicator_color3        clrAqua
#property indicator_width3 1
#property indicator_type4         DRAW_LINE 
#property indicator_color4        clrAqua
#property indicator_width4 1
#property indicator_type5         DRAW_LINE 
#property indicator_color5        clrAqua
#property indicator_width5 1
#property indicator_type6         DRAW_SECTION 
#property indicator_color6        clrRed
#property indicator_width6 1


input int InpConvexPeriod=40; //  Convex Hull Period
input int InpRegrPeriod=8;    //  Regression Period
input int Inp1stPeriod=5;   //  1st Period
input color Inp1stColor=clrGold; // 1st color
input int Inp2ndPeriod=40;   //  2nd Period
input color Inp2ndColor=clrRed; // 2nd color
input int Inp3rdPeriod=120;   //  2nd Period
input color Inp3rdColor=clrBlueViolet; // 2nd color
input int InpDisplayMode=1; // Display Mode( 1:show , 0:hide);
double R1[];
double S1[];
double OSC[];
double POS[];
double NEG[];
double CX[];
double CY[];
double LA[];
double LB[];
double LN1[];
double LN2[];
double LN3[];
double LN4[];
double LN5[];
double CNT[];

int WinNo=ChartWindowFind();
int min_rates_total=InpConvexPeriod+MathMax(Inp2ndPeriod,Inp1stPeriod);
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0,WinNo);

//--- 
if(InpDisplayMode==0)
{
  PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
  PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
  PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
  PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE);
  PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_NONE);
}
else
{
  PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
  PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
  PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
  PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_LINE);
  PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_LINE);
}

//---
   SetIndexBuffer(0,LN1,INDICATOR_DATA);
   SetIndexBuffer(1,LN2,INDICATOR_DATA);
   SetIndexBuffer(2,LN3,INDICATOR_DATA);
   SetIndexBuffer(3,LN4,INDICATOR_DATA);
   SetIndexBuffer(4,LN5,INDICATOR_DATA);
   SetIndexBuffer(5,CNT,INDICATOR_DATA);
   SetIndexBuffer(6,CX,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,CY,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,LA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,LB,INDICATOR_CALCULATIONS);
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

      if(i<rates_total-201)ObjectsDeleteAll(0,WinNo);

      CNT[i]=EMPTY_VALUE;
      CX[i]=EMPTY_VALUE;
      CY[i]=EMPTY_VALUE;
      LA[i]=EMPTY_VALUE;
      LB[i]=EMPTY_VALUE;
      LN1[i]=EMPTY_VALUE;
      LN2[i]=EMPTY_VALUE;
      LN3[i]=EMPTY_VALUE;
      LN4[i]=EMPTY_VALUE;
      LN5[i]=EMPTY_VALUE;

      int i1st=begin_pos+InpConvexPeriod*2;
      if(i<=i1st)continue;

      double up_vertex[][2];
      ArrayResize(up_vertex,0,InpConvexPeriod);
      double lo_vertex[][2];
      ArrayResize(lo_vertex,0,InpConvexPeriod);
      int i_vtx_up=0;
      int i_vtx_lo=0;
      for(int j=0;j<InpConvexPeriod;j++)
        {
         int ii=i-(InpConvexPeriod-1)+j;
         if(j==0)
           {
            ArrayResize(up_vertex,i_vtx_up+1,InpConvexPeriod);
            up_vertex[i_vtx_up][0] = ii;
            up_vertex[i_vtx_up][1] = low[ii];
            i_vtx_up++;

            ArrayResize(lo_vertex,i_vtx_lo+1,InpConvexPeriod);
            lo_vertex[i_vtx_lo][0] = ii;
            lo_vertex[i_vtx_lo][1] = high[ii];
            i_vtx_lo++;
           }
         ArrayResize(lo_vertex,i_vtx_lo+1,InpConvexPeriod);
         lo_vertex[i_vtx_lo][0] = ii;
         lo_vertex[i_vtx_lo][1] = low[ii];
         i_vtx_lo++;
         ArrayResize(up_vertex,i_vtx_up+1,InpConvexPeriod);
         up_vertex[i_vtx_up][0] = ii;
         up_vertex[i_vtx_up][1] = high[ii];
         i_vtx_up++;

        }

      calc_convex(R1,S1,up_vertex,lo_vertex,i);

      int i2nd=i1st+MathMax(MathMax(Inp1stPeriod,Inp2ndPeriod),Inp3rdPeriod)*2;
      if(i<=i2nd)continue;
      ObjectsDeleteAll(0,WinNo);
      calc_trend(i,Inp1stPeriod,time,1,Inp1stColor,true);
      calc_trend(i,Inp2ndPeriod,time,2,Inp2ndColor,false);
      calc_trend(i,Inp3rdPeriod,time,3,Inp3rdColor,false);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
void calc_trend(const int i,const int len,const datetime  &time[],const int no,const color clr,const bool mode)
  {
   double x=0;
   double y=0;
   double a=0;
   int a_count=0;
   int ifrom=0;
   int cnt=0;
   for(int j=0;j<len;j++)
     {
      if(CX[i-j]!=EMPTY_VALUE && LA[i-j]!=EMPTY_VALUE)
        {
           a+=LA[i-j];
           ifrom=i-j;
           a_count++;
        }
     }
   if(a_count==0)return;
   a/=a_count;
   x=i-(CX[ifrom]);
   y=a*x+(CY[ifrom]);

   CNT[int(CX[ifrom])]=CY[ifrom];
   if(mode)
   {
      if(LN1[i-3]==EMPTY_VALUE) set_line(LN1,a,y,i,4);
      else if(LN2[i-3]==EMPTY_VALUE)  set_line(LN2,a,y,i,4);
      else if(LN3[i-3]==EMPTY_VALUE)  set_line(LN3,a,y,i,4);
      else if(LN4[i-3]==EMPTY_VALUE)  set_line(LN4,a,y,i,4);
      else if(LN5[i-3]==EMPTY_VALUE)  set_line(LN5,a,y,i,4);
   }   
   double span=int(x);
   double from_x=i-span;
   double from_y= y-a*span;
   drawTrend(no,clr,int(from_x),from_y,i,y,time);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void set_line(double &LN[],const double a,const double y,const int i,const int len)
  {
   LN[i-len]=EMPTY_VALUE;
   for(int j=0;j<len;j++)
     {
      LN[i-j]=y-(a*j);
     }

  }
//+------------------------------------------------------------------+
void calc_convex(double  &R[],double &S[],double  &up_vertex[][2],double  &lo_vertex[][2],const int i)
  {
   double upper[][2];
   double lower[][2];
   int up_sz=0;
   int lo_sz=0;
   if(CX[i]!=EMPTY_VALUE)return;
//---
   convex_hull(upper,up_vertex,int(ArraySize(up_vertex)*0.5),1);
   convex_hull(lower,lo_vertex,int(ArraySize(lo_vertex)*0.5),-1);
   up_sz=int(ArraySize(upper)*0.5);
   lo_sz=int(ArraySize(lower)*0.5);


   double mx,my;
   calc_centroid(mx,my,upper,lower);
   if(mx<i)
     {
      CY[i]=my;
      CX[i]=mx;
      double a,b;
      regression(a,b,CX,CY,i-InpRegrPeriod-1,i);
      LA[i]=a;
      LB[i]=b;
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
   for(int j=0;j<up_sz;j++)
     {
      ArrayResize(vertices,n+1,sz);
      vertices[n][0]=upper[j][0];
      vertices[n][1]=upper[j][1];
      n++;
     }

   for(int j=lo_sz-1;j>=0;j--)
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
//|                                                                  |
//+------------------------------------------------------------------+
void regression(double  &a,double  &b,const double &x[],const double &y[],const int from,const int to)
  {
   int temp_sz=to-from;
   double temp[][2];
   ArrayResize(temp,temp_sz+1);
   int n=0;
   for(int k=from;k<=to;k++)
     {
      if(x[k]==EMPTY_VALUE)continue;
      if(y[k]==EMPTY_VALUE)continue;
      temp[n][0]=x[k];
      temp[n][1]=y[k];
      n++;
     }
   _regression(a,b,temp,n);
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
//|                                                                  |
//+------------------------------------------------------------------+
void convex_hull(double  &convex[][2],const double &points[][2],const int len,const int dir)
  {

   int k=0;
   if(len<=2)return;
   double temp[][2];

   ArrayResize(temp,k,len);
   for(int i=0;i<len;i++)
     {
      while(k>=2 && 
            (cross(temp[k-2][0],temp[k-2][1],
            temp[k-1][0],temp[k-1][1],
            points[i][0],points[i][1])*dir)>=0)
        {
         k--;
        }
      if(points[i][0]!=EMPTY_VALUE)
        {
         ArrayResize(temp,k+1,len);
         temp[k][0]= points[i][0];
         temp[k][1]= points[i][1];
         k++;
        }
     }
   ArrayCopy(convex,temp,0,2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double cross(const double ox,double oy,
             const double ax,double ay,
             const double bx,double by)
  {
   return ((ax - ox) * (by - oy) - (ay - oy) * (bx - ox));
  }
//+------------------------------------------------------------------+
void drawTrend(const int no,const color clr,const int x0,const double y0,const int x1,const double y1,const datetime &time[])
  {
   ObjectCreate(0,"Trend"+StringFormat("%d",no),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
   ObjectSetInteger(0,"Trend"+StringFormat("%d",no),OBJPROP_COLOR,clr);
   ObjectSetInteger(0,"Trend"+StringFormat("%d",no),OBJPROP_WIDTH,2);
   ObjectSetInteger(0,"Trend"+StringFormat("%d",no),OBJPROP_RAY_RIGHT,true);
  }
//+------------------------------------------------------------------+
