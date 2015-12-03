//+------------------------------------------------------------------+
//|                                                 ACH_HM_MyCCI.mqh |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//|                                              Revision 2011.11.21 |
//+------------------------------------------------------------------+
#include "aCandlePatterns.mqh"
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals based on Hammer/Hanging Man                        |
//| confirmed by MyCCI                                               |
//| Type=SignalAdvanced                                              |
//| Name=CH_HM_MyCCI                                                 |
//| Class=CH_HM_MyCCI                                                |
//| Page=                                                            |
//| Parameter=ScaleFactor,double,2.25,ScaleFactor of StepChannel     |
//| Parameter=Smoothing,int,3,Smoothing of  StepChannel              |
//| Parameter=VolatilityPeriod,int,70,Volatility Period of StepChannel|
//| Parameter=PeriodCCI,int,35,Period of MyCCI                       |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_TYPICAL,Applied Price |
//| Parameter=PeriodMA,int,5, Period of MA                           |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| CH_HM_MyCCI Class.                                               |
//| Purpose: Trading signals class, based on                         |
//| the "hammer and hanging man"                                     |
//| Japanese Candlestick Patterns                                    |
//| with confirmation by MyCCI indicator                             |
//| Derived from CCandlePattern class.                               |
//+------------------------------------------------------------------+
class CH_HM_MyCCI : public CCandlePattern
  {
protected:
   CiCustom             m_CCI;            // object-CCI
   //--- adjusted parameters
   double m_scaleFactor; // the "step channel scale factor" paraemeter of the osillator
   int m_smoothing; // the "step channel smoothing period" paraemeter of the osillator
   int m_volatilityPeriod; // the "step channel volatility period" paraemeter of the osillator
   int               m_periodCCI;      // the "period of calculation" parameter of the oscillator
   ENUM_APPLIED_PRICE m_applied;       // the "prices series" parameter of the oscillator

public:
                     CH_HM_MyCCI();
   //--- methods of setting adjustable parameters
   void              ScaleFactor(double value)         { m_scaleFactor=value;         }
   void              Smoothing(int value)              { m_smoothing=value;           }
   void              VolatilityPeriod(int value)       { m_volatilityPeriod=value;    }
   
   void              PeriodCCI(int value)              { m_periodCCI=value;           }
   void              PeriodMA(int value)               { m_ma_period=value;           }
   void              Applied(ENUM_APPLIED_PRICE value) { m_applied=value;             }
   //--- method of verification of settings
   virtual bool      ValidationSettings();
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition();
   virtual int       ShortCondition();

protected:
   //--- method of initialization of the oscillator
   bool              InitCCI(CIndicators *indicators);
   //--- methods of getting data
   double            CCI(int ind) { return(m_CCI.GetData(0,ind));     }
  };
//+------------------------------------------------------------------+
//| Constructor CH_HM_CCI.                                           |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CH_HM_MyCCI::CH_HM_MyCCI()
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_HIGH+USE_SERIES_LOW;
//--- setting default values for the oscillator parameters
   m_periodCCI=14;
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//| INPUT:  no.                                                      |
//| OUTPUT: true-if settings are correct, false otherwise.           |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CH_HM_MyCCI::ValidationSettings()
  {
//--- validation settings of additional filters
   if(!CCandlePattern::ValidationSettings()) return(false);
//--- initial data checks
   if(m_periodCCI<=0)
     {
      printf(__FUNCTION__+": period of the CCI oscillator must be greater than 0");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//| INPUT:  indicators - pointer of indicator collection.            |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CH_HM_MyCCI::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL) return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CCandlePattern::InitIndicators(indicators)) return(false);
//--- create and initialize CCI oscillator
   if(!InitCCI(indicators)) return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize CCI oscillators.                                      |
//| INPUT:  indicators - pointer of indicator collection.            |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CH_HM_MyCCI::InitCCI(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL) return(false);
//--- add object to collection
   if(!indicators.Add(GetPointer(m_CCI)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
   MqlParam parameters[6];
//---
   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="CCI_on_StepChannel.ex5";
   parameters[1].type=TYPE_DOUBLE;
   parameters[1].double_value=m_scaleFactor;
   parameters[2].type=TYPE_INT;
   parameters[2].double_value=m_smoothing;
   parameters[3].type=TYPE_INT;
   parameters[3].double_value=m_volatilityPeriod;
   parameters[4].type=TYPE_INT;
   parameters[4].double_value=m_periodCCI;
   parameters[5].type=TYPE_INT;
   parameters[5].double_value=m_applied;
//--- initialize object

   if(!m_CCI.Create(m_symbol.Name(),m_period,IND_CUSTOM,6,parameters))/////maybe 0 instead of m_period
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//| INPUT:  no.                                                      |
//| OUTPUT: number of "votes" that price will grow.                  |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CH_HM_MyCCI::LongCondition()
  {
   int result=0;
   int idx   =StartIndex();
//--- check formation of Hammer and CCI<40
   if(CheckCandlestickPattern(CANDLE_PATTERN_HAMMER) && (CCI(1)<40))
      result=80;
//--- check conditions of short position closing
   if(((CCI(1)>30) && (CCI(2)<30)) || ((CCI(1)>70) && (CCI(2)<70)))
      result=40;
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//| INPUT:  no.                                                      |
//| OUTPUT: number of "votes" that price will fall.                  |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CH_HM_MyCCI::ShortCondition()
  {
   int result=0;
   int idx   =StartIndex();
//--- check formation of Hanging Man pattern and CCI>60     
   if(CheckCandlestickPattern(CANDLE_PATTERN_HANGING_MAN) && (CCI(1)>60))
      result=80;
//--- check conditions of long position closing
   if(((CCI(1)<70) && (CCI(2)>70)) || ((CCI(1)<30) && (CCI(2)>30)))
      result=40;
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
