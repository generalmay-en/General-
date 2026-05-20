//+------------------------------------------------------------------+
//|                                                    CRTEngine.mqh |
//|                                  Copyright 2024, Trading Bot Dev |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Bot Dev"
#property link      "https://www.mql5.com"
#property strict

#include "MarketStructure.mqh"

enum ENUM_SWEEP_QUALITY
{
   SWEEP_CLEAN,
   SWEEP_PARTIAL,
   SWEEP_INVALID
};

enum ENUM_SIGNAL_DIRECTION
{
   SIGNAL_BUY,
   SIGNAL_SELL,
   SIGNAL_NONE
};

struct CRTSignal
{
   ENUM_SIGNAL_DIRECTION direction;
   double sweep_level;
   double mss_level;
   ENUM_SWEEP_QUALITY quality;
   bool is_valid;
};

class CCRTEngine
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf_h1;
   ENUM_TIMEFRAMES   m_tf_m15;
   ENUM_TIMEFRAMES   m_tf_m5;

   double            m_range_high;
   double            m_range_low;
   datetime          m_range_time;

public:
   CCRTEngine(string symbol) : m_symbol(symbol), m_tf_h1(PERIOD_H1), m_tf_m15(PERIOD_M15), m_tf_m5(PERIOD_M5)
   {
      m_range_high = 0;
      m_range_low = 0;
      m_range_time = 0;
   }

   ~CCRTEngine() {}

   double GetRangeSize() { return MathAbs(m_range_high - m_range_low); }

   CRTSignal ScanForSignal()
   {
      CRTSignal signal;
      signal.direction = SIGNAL_NONE;
      signal.is_valid = false;
      signal.quality = SWEEP_INVALID;

      // 1. Isolate reference range (H1 candle at session open)
      UpdateReferenceRange();

      if(m_range_high == 0 || m_range_low == 0) return signal;

      // 2. Detect Sweep
      double m15_highs[], m15_lows[], m15_closes[];
      CopyHigh(m_symbol, m_tf_m15, 0, 10, m15_highs);
      CopyLow(m_symbol, m_tf_m15, 0, 10, m15_lows);
      CopyClose(m_symbol, m_tf_m15, 0, 10, m15_closes);

      ArraySetAsSeries(m15_highs, true);
      ArraySetAsSeries(m15_lows, true);
      ArraySetAsSeries(m15_closes, true);

      bool sweep_high = false;
      bool sweep_low = false;

      // Check for sweep high
      if(m15_highs[1] > m_range_high && m15_closes[1] < m_range_high)
      {
         sweep_high = true;
         signal.sweep_level = m15_highs[1];
         signal.quality = SWEEP_CLEAN;
      }

      // Check for sweep low
      if(m15_lows[1] < m_range_low && m15_closes[1] > m_range_low)
      {
         sweep_low = true;
         signal.sweep_level = m15_lows[1];
         signal.quality = SWEEP_CLEAN;
      }

      if(sweep_high && sweep_low) return signal; // Double sweep invalidates

      if(sweep_high) signal.direction = SIGNAL_SELL;
      if(sweep_low)  signal.direction = SIGNAL_BUY;

      if(signal.direction != SIGNAL_NONE)
      {
         // 3. Confirm MSS on M15 or CHoCH on M5
         if(ConfirmMSS(signal.direction))
         {
            signal.is_valid = true;
         }
      }

      return signal;
   }

private:
   void UpdateReferenceRange()
   {
      MqlDateTime dt;
      TimeCurrent(dt);

      // London Open 08:00 UTC
      // Simplified: Find the H1 candle for the current day at 08:00
      datetime session_start = StringToTime(IntegerToString(dt.year) + "." + IntegerToString(dt.mon) + "." + IntegerToString(dt.day) + " 08:00");

      if(session_start > TimeCurrent()) return;

      MqlRates rates[];
      if(CopyRates(m_symbol, m_tf_h1, session_start, 1, rates) > 0)
      {
         m_range_high = rates[0].high;
         m_range_low = rates[0].low;
         m_range_time = rates[0].time;
      }
   }

   bool ConfirmMSS(ENUM_SIGNAL_DIRECTION dir)
   {
      double m15_closes[];
      CopyClose(m_symbol, m_tf_m15, 0, 5, m15_closes);
      ArraySetAsSeries(m15_closes, true);

      // Simple MSS logic: Close above/below previous local structure
      if(dir == SIGNAL_BUY && m15_closes[0] > m15_closes[1]) return true;
      if(dir == SIGNAL_SELL && m15_closes[0] < m15_closes[1]) return true;

      return false;
   }
};
