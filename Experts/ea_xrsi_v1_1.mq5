//+------------------------------------------------------------------+
//|                                                 ea_xrsi_v_01.mq5 |
//| ea_xrsi v1.01                             Copyright 2015, fxborg |
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
input int RSI_Period=40;      // XRSI Period 
input int RSI_TemaPeriod=42;   // XRSI TemaPeriod  
input int RSI_Threshold=5;    // XRSI Threshold  
input double RSI_EntryLevel=45;//  XRSI Entry Level

input string description3="3.-------------------------------";//
input int    MA_Period=40; // Ma period
input int    MA_Smoothing=42;// Ma Smoothing  
input int MA_TemaPeriod=5;// Ma TemaPeriod
input double MA_Threshold=5;// Ma Threshold  
input string description4="3.-------------------------------";//
/*
input ENUM_TIMEFRAMES   Trend_TimeFrame=PERIOD_H1; // Trend Time Frame
input int    Trend_Period=43; // Trend period
input int    Trend_Smoothing=15;// Trend Smoothing  
input int    Trend_TemaPeriod=5;// Trend TemaPeriod
input double Trend_Threshold=10;// Trend Threshold
*/
input string description5="4.-------------------------------";//
input int    Trail_Period=2;   // Trailing Stop Period
input int    Trail_Minimum=160; // Trailing Stop Minimum Size
input int    Trail_Size=220; // Trailing Stop Size
input int    Trail_Maximum=400; // Trailing Stop Maximum Size
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
   int               m_ma_handle;  // MA Handle
   int               m_rsi_handle;   // Swing Strength  Handle

   int               m_ma_period;  // MA period
   int               m_ma_smoothing;  // MA Smoothing
   double            m_ma_threshold;  // MA threshold
   int               m_ma_tema_period; //MA Tema period

   ENUM_TIMEFRAMES   m_trend_tf;      // Trend Timeframe
   int               m_trend_period;  // Trend period
   int               m_trend_smoothing;  // Trend Smoothing
   double            m_trend_threshold;  // Trend threshold
   int               m_trend_tema_period; //Trend Tema period

   int               m_rsi_period;      // RSI period
   int               m_rsi_tema_period;  // RSI Smoothing
   int               m_rsi_threshold;  // RSI Threshold
   double            m_rsi_long_level;
   double            m_rsi_long_bottom;
   double            m_rsi_short_level;
   double            m_rsi_short_top;

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
   IndicatorRelease(m_rsi_handle);
   IndicatorRelease(m_ma_handle);
  }
//------------------------------------------------------------------	Init
bool CMyEA::Init(string smb,ENUM_TIMEFRAMES tf)
  {
   if(!CExpertAdvisor::Init(0,smb,tf)) return(false);  // initialize parent class
                                                       // copy parameters
   if(Trail_Minimum>=Trail_Size)return (false);
   if(Trail_Size>=Trail_Maximum)return (false);
   m_risk=Risk;
   m_tp=TP;
   m_sl=SL;
   m_hourStart=HourStart;
   m_hourEnd=HourEnd;

//---
   m_rsi_period=RSI_Period;
   m_rsi_tema_period=RSI_TemaPeriod;
   m_rsi_threshold=RSI_Threshold;
   m_rsi_long_level=RSI_EntryLevel;
   m_rsi_short_level= 100-RSI_EntryLevel;

//---
   m_ma_period=MA_Period;
   m_ma_smoothing=MA_Smoothing;
   m_ma_tema_period=MA_TemaPeriod;
   m_ma_threshold=MA_Threshold;
//---
/*
   m_trend_tf=Trend_TimeFrame;
   m_trend_period=Trend_Period;
   m_trend_smoothing=Trend_Smoothing;
   m_trend_tema_period=Trend_TemaPeriod;
   m_trend_threshold=Trend_Threshold;
*/
//---
   m_trail_size=Trail_Size;
   m_trail_period=Trail_Period;
   m_trail_minimum=Trail_Minimum;
   m_trail_maximum=Trail_Maximum;
//---
//   m_trend_handle=iCustom(NULL,m_trend_tf,"snma_v1_02",m_trend_period,m_trend_smoothing,m_trend_tema_period,m_trend_threshold);
//   if(m_trend_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_ma_handle=iCustom(NULL,m_tf,"snma_v1_02",m_ma_period,m_ma_smoothing,m_ma_tema_period,m_ma_threshold);
   if(m_ma_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_rsi_handle=iCustom(NULL,m_tf,"XRSI_v1_01",m_rsi_period,m_rsi_tema_period,m_rsi_threshold);
   if(m_rsi_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_trail_handle=iCustom(NULL,m_tf,"LogicalStops",m_trail_size,m_trail_period);
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

   MqlRates rt[3];
   if(CopyRates(m_smb,m_tf,1,3,rt)!=3)
     { Print("CopyRates ",m_smb," history is not loaded"); return(WRONG_VALUE); }

   double TREND[2];
   double MA[2];
   double OSC[3];
   double OSC_SIG[2];
   double TRAIL_UP[2];
   double TRAIL_DN[2];
//   if(CopyBuffer(m_trend_handle,1,1,2,TREND)!=2)
//     { Print("CopyBuffer Trend - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_ma_handle,1,1,2,MA)!=2)
     { Print("CopyBuffer Ma - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_rsi_handle,0,1,3,OSC)!=3)
     { Print("CopyBuffer Signal - no data"); return(WRONG_VALUE); }
   if(CopyBuffer(m_rsi_handle,1,1,2,OSC_SIG)!=2)
     { Print("CopyBuffer Signal - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_trail_handle,0,1,2,TRAIL_UP)!=2)
     { Print("CopyBuffer LogicalStops - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_trail_handle,1,1,2,TRAIL_DN)!=2)
     { Print("CopyBuffer LogicalStops - no data"); return(WRONG_VALUE); }

// OPEN BUY
   if( (MA[1]==1 || MA[1]==2) && OSC_SIG[1]==2 && OSC[1]<m_rsi_long_level) OpenPosition(ORDER_TYPE_BUY);

// CLOSE BUY
   if(MA[1]<=1 && OSC_SIG[1]==0) ClosePosition(ORDER_TYPE_BUY);
   CheckTrailingStopLong(TRAIL_DN[1],rt[1].low,m_trail_minimum,m_trail_maximum);

// OPEN SELL
   if((MA[1]==3 || MA[1]==2) && OSC_SIG[1]==0 && OSC[1]>m_rsi_short_level ) OpenPosition(ORDER_TYPE_SELL);

// CLOSE SELL
   if(MA[1]>=3 && OSC_SIG[1]==2 ) ClosePosition(ORDER_TYPE_SELL);

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
