//+------------------------------------------------------------------+
//|                                               ea_super_trend.mq5 |
//| ea_super_trend v1.00                      Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <ExpertAdvisor.mqh>

input string description1="1.-------------------------------";
input double Risk=0.1; // Risk
input int    SL        = 1000; // Stop Loss distance
input int    TP        = 4000; // Take Profit distance
input int    HourStart =   7; // Hour of trade start
input int    HourEnd   =  20; // Hour of trade end

input string description2="2.-------------------------------";
input int SpTrend_Period=40;                           // Super Trend CCI Period 
input int SpTrend_Level=0;                                // Super Trend CCI Level

input string description3="3.-------------------------------";
input ENUM_MA_METHOD    Trend_Method=MODE_LWMA;    
input ENUM_TIMEFRAMES   Trend_TimeFrame=PERIOD_H1; // Trend Time Frame
input int    Trend_Period=26; // Trend period

input string description4="4.-------------------------------";//
input int    Trail_Size    =  380; // Trailing Stop Size
input int    Trail_Period  =  2;   // Trailing Stop Period
input int    Trail_Minimum    =  200; // Trailing Stop Minimum Size
input int    Trail_Maximum    =  500; // Trailing Stop Maximum Size
//---
class CMyEA : public CExpertAdvisor
  {
protected:
   double            m_risk;          // size of risk
   int               m_sl;            // Stop Loss
   int               m_tp;            // Take Profit
   int               m_ts;            // Trailing Stop
   int               m_hourStart;     // Hour of trade start
   int               m_hourEnd;       // Hour of trade end

   int               m_trend_handle;  // Trend Handle

   ENUM_MA_METHOD    m_trend_method;  // Trend MaMethod
   ENUM_TIMEFRAMES   m_trend_tf;      // Trend Timeframe
   int               m_trend_period;  // Trend period
   int               m_sp_trend_period;
   int               m_sp_trend_level;
   int               m_sp_trend_handle;   // Super Trend Handle

   int               m_trail_handle;
   int               m_trail_size;
   int               m_trail_period;
   int               m_trail_minimum;
   int               m_trail_maximum;

public:
   void              CMyEA();
   void             ~CMyEA();
   virtual bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
   virtual bool      Main();                              // main function
   virtual void      OpenPosition(long dir);              // open position on signal
   virtual void      ClosePosition(long dir);             // close position on signal
  };
//------------------------------------------------------------------	CMyEA
void CMyEA::CMyEA(void) { }
//------------------------------------------------------------------	~CMyEA
void CMyEA::~CMyEA(void)
  {
   IndicatorRelease(m_trend_handle);
   IndicatorRelease(m_trail_handle);
   IndicatorRelease(m_sp_trend_handle);
  }
//------------------------------------------------------------------	Init
bool CMyEA::Init(string smb,ENUM_TIMEFRAMES tf)
  {
   if(!CExpertAdvisor::Init(0,smb,tf)) return(false);  // initialize parent class
                                                       // copy parameters
   m_risk=Risk;
   m_tp=TP;
   m_sl=SL;
   m_hourStart=HourStart;
   m_hourEnd=HourEnd;

//---
   m_sp_trend_period=SpTrend_Period;
   m_sp_trend_level=SpTrend_Level;

   m_trend_period=Trend_Period;
   m_trend_tf=Trend_TimeFrame;
   m_trend_method=Trend_Method;
//---
   m_trail_size=Trail_Size;
   m_trail_period=Trail_Period;
   m_trail_minimum=Trail_Minimum;
   m_trail_maximum=Trail_Maximum;
//---

   m_trend_handle=iCustom(m_smb,m_trend_tf,"TrendMa",m_trend_period,m_trend_method);
   if(m_trend_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_sp_trend_handle=iCustom(m_smb,m_tf,"Super_Trend",m_sp_trend_period,m_sp_trend_level,0);
   if(m_sp_trend_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

  
   m_trail_handle=iCustom(m_smb,m_tf,"LogicalStops",m_trail_size,m_trail_period);
   if(m_trail_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_bInit=true; return(true);                         // "trade allowed"
  }
//------------------------------------------------------------------	Main
bool CMyEA::Main() // main function
  {
   if(!CExpertAdvisor::Main()) return(false); // call function of parent class

   if(Bars(m_smb,m_trend_tf)<=m_trend_period*2) return(false); // if there are insufficient number of bars
   static CIsNewBar NB;
   if(!NB.IsNewBar(m_smb,m_tf))return (true);

// check each direction

   MqlRates rt[2];
   if(CopyRates(m_smb,m_tf,1,2,rt)!=2)
     { Print("CopyRates ",m_smb," history is not loaded"); return(WRONG_VALUE); }

   double TREND[2];
   double SPT_BUY[2];
   double SPT_SELL[2];
   double SPT_UP[2];
   double SPT_DN[2];
   double TRAIL_UP[2];
   double TRAIL_DN[2];
   if(CopyBuffer(m_trend_handle,1,1,2,TREND)!=2)
     { Print("CopyBuffer Trend - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_sp_trend_handle,0,1,2,SPT_UP)!=2)
     { Print("CopyBuffer Super Trend - no data"); return(WRONG_VALUE); }
   if(CopyBuffer(m_sp_trend_handle,1,1,2,SPT_DN)!=2)
     { Print("CopyBuffer Super Trend - no data"); return(WRONG_VALUE); }
   if(CopyBuffer(m_sp_trend_handle,2,1,2,SPT_BUY)!=2)
     { Print("CopyBuffer Super Trend - no data"); return(WRONG_VALUE); }
   if(CopyBuffer(m_sp_trend_handle,3,1,2,SPT_SELL)!=2)
   
     { Print("CopyBuffer Super Trend - no data"); return(WRONG_VALUE); }
   if(CopyBuffer(m_trail_handle,0,1,2,TRAIL_UP)!=2)
     { Print("CopyBuffer LogicalStops - no data"); return(WRONG_VALUE); }
   if(CopyBuffer(m_trail_handle,1,1,2,TRAIL_DN)!=2)
     { Print("CopyBuffer LogicalStops - no data"); return(WRONG_VALUE); }

// OPEN BUY
   if( TREND[1]==2 && SPT_BUY[0]>0 && SPT_BUY[0]!=EMPTY_VALUE && SPT_UP[1]>0 && SPT_UP[1]!=EMPTY_VALUE )       
        OpenPosition(ORDER_TYPE_BUY);               

   if(TREND[1]==0 && SPT_DN[1]>0 && SPT_DN[1]!=EMPTY_VALUE  ) ClosePosition(ORDER_TYPE_BUY);
   CheckTrailingStopLong(TRAIL_DN[1],rt[1].low,m_trail_minimum,m_trail_maximum);

// DOWN TREND
   if( TREND[1]==0 && SPT_SELL[0]>0 && SPT_SELL[0]!=EMPTY_VALUE && SPT_DN[1]>0 && SPT_DN[1]!=EMPTY_VALUE )       
      OpenPosition(ORDER_TYPE_SELL);               

// CLOSE SELL
   if(TREND[1]==2 && SPT_UP[1]>0 && SPT_UP[1]!=EMPTY_VALUE  ) ClosePosition(ORDER_TYPE_SELL);

   CheckTrailingStopShort(TRAIL_UP[1],rt[1].high,m_trail_minimum,m_trail_maximum);


   return(true);
  }
//------------------------------------------------------------------	OpenPos
void CMyEA::OpenPosition(long dir)
  {
   if(PositionSelect(m_smb)) return;
   if(!CheckTime(StringToTime(IntegerToString(m_hourStart)+":00"),
      StringToTime(IntegerToString(m_hourEnd)+":00"))) return;
   double lot=CountLotByRisk(m_sl,m_risk,0);
   if(lot<=0) return;
   DealOpen(dir,lot,m_sl,m_tp);
  }
//------------------------------------------------------------------	ClosePos
void CMyEA::ClosePosition(long dir)
  {
   if(!PositionSelect(m_smb)) return;
   if(dir!=PositionGetInteger(POSITION_TYPE)) return;
   m_trade.PositionClose(m_smb,1);
  }


CMyEA ea; // class instance
//------------------------------------------------------------------	OnInit
int OnInit()
  {
   ea.Init(Symbol(),Period()); // initialize expert

                               // initialization example
// ea.Init(Symbol(), PERIOD_M5); // for fixed timeframe
// ea.Init("USDJPY", PERIOD_H2); // for fixed symbol and timeframe

   return(0);
  }
//------------------------------------------------------------------	OnDeinit
void OnDeinit(const int reason) { }
//------------------------------------------------------------------	OnTick
void OnTick()
  {
   ea.Main(); // process incoming tick
  }
//+------------------------------------------------------------------+
