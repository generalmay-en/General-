//+------------------------------------------------------------------+
//|                                                  Confluence.mqh |
//|                                  Copyright 2024, Trading Bot Dev |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Bot Dev"
#property link      "https://www.mql5.com"
#property strict

#include "MarketStructure.mqh"
#include "CRTEngine.mqh"
#include "SMCEngine.mqh"

struct ConfluenceResult
{
   bool trade_valid;
   string rejection_reason;
   double entry_price;
   double sl_price;
   double tp1;
   double tp2;
   double tp3;
};

class CConfluence
{
private:
   string m_symbol;
   int m_sl_buffer_pips;

public:
   CConfluence(string symbol, int sl_buffer) : m_symbol(symbol), m_sl_buffer_pips(sl_buffer) {}
   ~CConfluence() {}

   ConfluenceResult ValidateSetup(MarketStructureInfo &structure, CRTSignal &signal, CSMCEngine &smc, double range_size)
   {
      ConfluenceResult result;
      result.trade_valid = false;
      result.rejection_reason = "";

      // 1. Session Check (Simplified here, usually checked in OnTick)
      if(!IsSessionKillzone())
      {
         result.rejection_reason = "Outside session killzone";
         return result;
      }

      // 2. HTF Bias Match
      if(signal.direction == SIGNAL_BUY && structure.htf_bias != BIAS_BULL)
      {
         result.rejection_reason = "Bias mismatch (Not Bullish)";
         return result;
      }
      if(signal.direction == SIGNAL_SELL && structure.htf_bias != BIAS_BEAR)
      {
         result.rejection_reason = "Bias mismatch (Not Bearish)";
         return result;
      }

      // 3. CRT Signal Validity
      if(!signal.is_valid || signal.quality == SWEEP_INVALID)
      {
         result.rejection_reason = "Invalid CRT signal or sweep quality";
         return result;
      }

      // 4. SMC Zone Alignment
      OB_Zone ob;
      FVG_Zone fvg;
      double current_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      if(!smc.IsPriceInZone(current_price, ob, fvg))
      {
         result.rejection_reason = "Price not in OB or FVG zone";
         return result;
      }

      // 5. Setup confirmed
      result.trade_valid = true;
      result.entry_price = current_price;

      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

      if(signal.direction == SIGNAL_BUY)
      {
         result.sl_price = signal.sweep_level - (m_sl_buffer_pips * 10 * point);
         result.tp1 = result.entry_price + range_size * 0.5;
         result.tp2 = result.entry_price + range_size * 1.0;
         result.tp3 = ob.high > 0 ? ob.high : result.tp2 + range_size;
      }
      else
      {
         result.sl_price = signal.sweep_level + (m_sl_buffer_pips * 10 * point);
         result.tp1 = result.entry_price - range_size * 0.5;
         result.tp2 = result.entry_price - range_size * 1.0;
         result.tp3 = ob.low > 0 ? ob.low : result.tp2 - range_size;
      }

      return result;
   }

private:
   bool IsSessionKillzone()
   {
      MqlDateTime dt;
      TimeCurrent(dt);

      // London: 08:00 - 10:00 UTC
      // NY: 13:00 - 15:00 UTC
      if((dt.hour >= 8 && dt.hour < 10) || (dt.hour >= 13 && dt.hour < 15)) return true;

      return false;
   }
};
