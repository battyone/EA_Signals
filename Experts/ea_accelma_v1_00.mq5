//+------------------------------------------------------------------+
//|                                             ea_accelma_v1_00.mq5 |
//| ea_accelma v1.00                          Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <ExpertAdvisor.mqh>

input string description1="1.-------------------------------";
input double Risk=0.1; // Risk
input int    SL        = 4000; // Stop Loss distance
input int    TP        = 4000; // Take Profit distance
input int    HourStart =   7; // Hour of trade start
input int    HourEnd   =  20; // Hour of trade end
input string description2="2.-------------------------------";
input double MA_K=0.5; // Ma K
input int    MA_Period=20;// Ma period  
input int    MA_Smoothing=14;// Ma Smoothing  

//---
class CMyEA : public CExpertAdvisor
  {
protected:
   double            m_risk;          // size of risk
   int               m_sl;            // Stop Loss
   int               m_tp;            // Take Profit
   int               m_hourStart;     // Hour of trade start
   int               m_hourEnd;       // Hour of trade end
   int               m_ma_handle;  // MA Handle
   double            m_ma_k;  // MA K
   int               m_ma_period;  // MA period
   int               m_ma_smoothing;  // MA Smoothing

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
   IndicatorRelease(m_ma_handle);
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
   m_ma_k=MA_K;
   m_ma_period=MA_Period;
   m_ma_smoothing=MA_Smoothing;

//---
   m_ma_handle=iCustom(NULL,m_tf,"Accel_MA_v1_02",m_ma_k,m_ma_period,m_ma_smoothing);
   if(m_ma_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit
   
   m_bInit=true; return(true);                         // "trade allowed"
  }
//------------------------------------------------------------------	Main
bool CMyEA::Main() // main function
  {
   if(!CExpertAdvisor::Main()) return(false); // call function of parent class

   static CIsNewBar NB;
   if(!NB.IsNewBar(m_smb,m_tf))return (true);

// check each direction

   double MA[3];

   if(CopyBuffer(m_ma_handle,1,1,3,MA)!=3)
     { Print("CopyBuffer Ma - no data"); return(WRONG_VALUE); }


// OPEN BUY
   if(MA[1]==0)
   {
       ClosePosition(ORDER_TYPE_SELL);
       OpenPosition(ORDER_TYPE_BUY);
   }   
   
// OPEN SELL
   if(MA[1]==2)
   {
       ClosePosition(ORDER_TYPE_BUY);
       OpenPosition(ORDER_TYPE_SELL);
   }   

   
   return(true);
  }
//------------------------------------------------------------------	OpenPos
void CMyEA::OpenPosition(long dir)
  {
   if(PositionSelect(m_smb)) return;
/*
   if(!CheckTime(StringToTime(IntegerToString(m_hourStart)+":00"),
      StringToTime(IntegerToString(m_hourEnd)+":00"))) return;
*/
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
