//+------------------------------------------------------------------+
//|                                              MarketStructure.mqh |
//|                                  Copyright 2024, Trading Bot Dev |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Bot Dev"
#property link      "https://www.mql5.com"
#property strict

enum ENUM_MARKET_BIAS
{
   BIAS_BULL,
   BIAS_BEAR,
   BIAS_RANGE
};

struct MarketStructureInfo
{
   ENUM_MARKET_BIAS htf_bias;
   double last_swing_high;
   double last_swing_low;
   bool bos_detected;
   bool choch_detected;
};

class CMarketStructure
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf_daily;
   ENUM_TIMEFRAMES   m_tf_h4;

   double            m_last_h4_high;
   double            m_last_h4_low;
   double            m_last_daily_high;
   double            m_last_daily_low;

public:
   CMarketStructure(string symbol) : m_symbol(symbol), m_tf_daily(PERIOD_D1), m_tf_h4(PERIOD_H4) {}
   ~CMarketStructure() {}

   MarketStructureInfo UpdateBias()
   {
      MarketStructureInfo info;
      info.htf_bias = BIAS_RANGE;

      double daily_highs[], daily_lows[], daily_closes[];
      double h4_highs[], h4_lows[], h4_closes[];

      CopyHigh(m_symbol, m_tf_daily, 0, 20, daily_highs);
      CopyLow(m_symbol, m_tf_daily, 0, 20, daily_lows);
      CopyClose(m_symbol, m_tf_daily, 0, 20, daily_closes);

      CopyHigh(m_symbol, m_tf_h4, 0, 50, h4_highs);
      CopyLow(m_symbol, m_tf_h4, 0, 50, h4_lows);
      CopyClose(m_symbol, m_tf_h4, 0, 50, h4_closes);

      ArraySetAsSeries(daily_highs, true);
      ArraySetAsSeries(daily_lows, true);
      ArraySetAsSeries(daily_closes, true);
      ArraySetAsSeries(h4_highs, true);
      ArraySetAsSeries(h4_lows, true);
      ArraySetAsSeries(h4_closes, true);

      // Simplified Swing Logic for this version
      m_last_h4_high = FindSwingHigh(h4_highs, 5);
      m_last_h4_low = FindSwingLow(h4_lows, 5);

      info.last_swing_high = m_last_h4_high;
      info.last_swing_low = m_last_h4_low;

      // Determine Bias
      if(h4_closes[1] > m_last_h4_high) info.bos_detected = true;
      if(h4_closes[1] < m_last_h4_low)  info.bos_detected = true;

      // Logic for BULL: HH and HL
      // Logic for BEAR: LH and LL

      if(h4_highs[1] > h4_highs[2] && h4_lows[1] > h4_lows[2])
         info.htf_bias = BIAS_BULL;
      else if(h4_highs[1] < h4_highs[2] && h4_lows[1] < h4_lows[2])
         info.htf_bias = BIAS_BEAR;
      else
         info.htf_bias = BIAS_RANGE;

      return info;
   }

private:
   double FindSwingHigh(const double &highs[], int lookback)
   {
      for(int i = 1; i < lookback; i++)
      {
         if(highs[i] > highs[i-1] && highs[i] > highs[i+1]) return highs[i];
      }
      return highs[1];
   }

   double FindSwingLow(const double &lows[], int lookback)
   {
      for(int i = 1; i < lookback; i++)
      {
         if(lows[i] < lows[i-1] && lows[i] < lows[i+1]) return lows[i];
      }
      return lows[1];
   }
};
