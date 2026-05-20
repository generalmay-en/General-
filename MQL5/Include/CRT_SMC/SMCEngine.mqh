//+------------------------------------------------------------------+
//|                                                    SMCEngine.mqh |
//|                                  Copyright 2024, Trading Bot Dev |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Bot Dev"
#property link      "https://www.mql5.com"
#property strict

struct OB_Zone
{
   double high;
   double low;
   datetime time;
   bool mitigated;
   ENUM_TIMEFRAMES timeframe;
};

struct FVG_Zone
{
   double high;
   double low;
   datetime time;
   bool mitigated;
   ENUM_TIMEFRAMES timeframe;
};

class CSMCEngine
{
private:
   string m_symbol;
   OB_Zone m_ob_zones[];
   FVG_Zone m_fvg_zones[];

public:
   CSMCEngine(string symbol) : m_symbol(symbol) {}
   ~CSMCEngine() {}

   void UpdateZones()
   {
      FindOBs(PERIOD_H1);
      FindOBs(PERIOD_M15);
      FindFVGs(PERIOD_H1);
      FindFVGs(PERIOD_M15);
      CheckMitigation();
   }

   bool IsPriceInZone(double price, OB_Zone &out_ob, FVG_Zone &out_fvg)
   {
      for(int i = 0; i < ArraySize(m_ob_zones); i++)
      {
         if(!m_ob_zones[i].mitigated && price <= m_ob_zones[i].high && price >= m_ob_zones[i].low)
         {
            out_ob = m_ob_zones[i];
            return true;
         }
      }

      for(int i = 0; i < ArraySize(m_fvg_zones); i++)
      {
         if(!m_fvg_zones[i].mitigated && price <= m_fvg_zones[i].high && price >= m_fvg_zones[i].low)
         {
            out_fvg = m_fvg_zones[i];
            return true;
         }
      }

      return false;
   }

private:
   void FindOBs(ENUM_TIMEFRAMES tf)
   {
      MqlRates rates[];
      if(CopyRates(m_symbol, tf, 0, 50, rates) < 10) return;
      ArraySetAsSeries(rates, true);

      for(int i = 1; i < 48; i++)
      {
         // Bullish OB: Last bearish candle before bullish impulsive move
         if(rates[i+1].close < rates[i+1].open && rates[i].close > rates[i].open && (rates[i].close - rates[i].open) > (rates[i+1].open - rates[i+1].close) * 2)
         {
            AddOB(rates[i+1].high, rates[i+1].low, rates[i+1].time, tf);
         }
         // Bearish OB: Last bullish candle before bearish impulsive move
         if(rates[i+1].close > rates[i+1].open && rates[i].close < rates[i].open && (rates[i].open - rates[i].close) > (rates[i+1].close - rates[i+1].open) * 2)
         {
            AddOB(rates[i+1].high, rates[i+1].low, rates[i+1].time, tf);
         }
      }
   }

   void FindFVGs(ENUM_TIMEFRAMES tf)
   {
      MqlRates rates[];
      if(CopyRates(m_symbol, tf, 0, 50, rates) < 10) return;
      ArraySetAsSeries(rates, true);

      for(int i = 1; i < 48; i++)
      {
         // Bullish FVG
         if(rates[i+1].high < rates[i-1].low)
         {
            AddFVG(rates[i-1].low, rates[i+1].high, rates[i].time, tf);
         }
         // Bearish FVG
         if(rates[i+1].low > rates[i-1].high)
         {
            AddFVG(rates[i+1].low, rates[i-1].high, rates[i].time, tf);
         }
      }
   }

   void AddOB(double high, double low, datetime time, ENUM_TIMEFRAMES tf)
   {
      int size = ArraySize(m_ob_zones);
      for(int i=0; i<size; i++) if(m_ob_zones[i].time == time && m_ob_zones[i].timeframe == tf) return;

      ArrayResize(m_ob_zones, size + 1);
      m_ob_zones[size].high = high;
      m_ob_zones[size].low = low;
      m_ob_zones[size].time = time;
      m_ob_zones[size].mitigated = false;
      m_ob_zones[size].timeframe = tf;
   }

   void AddFVG(double high, double low, datetime time, ENUM_TIMEFRAMES tf)
   {
      int size = ArraySize(m_fvg_zones);
      for(int i=0; i<size; i++) if(m_fvg_zones[i].time == time && m_fvg_zones[i].timeframe == tf) return;

      ArrayResize(m_fvg_zones, size + 1);
      m_fvg_zones[size].high = high;
      m_fvg_zones[size].low = low;
      m_fvg_zones[size].time = time;
      m_fvg_zones[size].mitigated = false;
      m_fvg_zones[size].timeframe = tf;
   }

   void CheckMitigation()
   {
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);

      for(int i = 0; i < ArraySize(m_ob_zones); i++)
      {
         if(!m_ob_zones[i].mitigated)
         {
            if(bid <= m_ob_zones[i].high && ask >= m_ob_zones[i].low)
               m_ob_zones[i].mitigated = true;
         }
      }

      for(int i = 0; i < ArraySize(m_fvg_zones); i++)
      {
         if(!m_fvg_zones[i].mitigated)
         {
            if(bid <= m_fvg_zones[i].high && ask >= m_fvg_zones[i].low)
               m_fvg_zones[i].mitigated = true;
         }
      }
   }
};
