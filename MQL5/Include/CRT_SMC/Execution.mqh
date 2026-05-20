//+------------------------------------------------------------------+
//|                                                    Execution.mqh |
//|                                  Copyright 2024, Trading Bot Dev |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Bot Dev"
#property link      "https://www.mql5.com"
#property strict

#include <Trade\Trade.mqh>
#include "Confluence.mqh"

class CExecution
{
private:
   CTrade m_trade;
   int    m_magic;
   string m_symbol;

public:
   CExecution(string symbol, int magic) : m_symbol(symbol), m_magic(magic)
   {
      m_trade.SetExpertMagicNumber(m_magic);
   }

   ~CExecution() {}

   bool ExecuteTrade(const ConfluenceResult &setup, double lot_size, ENUM_SIGNAL_DIRECTION dir)
   {
      bool success = false;
      double tp = (setup.tp3 > 0) ? setup.tp3 : setup.tp2;

      if(dir == SIGNAL_BUY)
      {
         success = m_trade.Buy(lot_size, m_symbol, setup.entry_price, setup.sl_price, tp, "CRT_SMC Buy");
      }
      else if(dir == SIGNAL_SELL)
      {
         success = m_trade.Sell(lot_size, m_symbol, setup.entry_price, setup.sl_price, tp, "CRT_SMC Sell");
      }

      return success;
   }

   void ManagePositions(double range_size)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionGetTicket(i) > 0 && PositionGetString(POSITION_SYMBOL) == m_symbol && PositionGetInteger(POSITION_MAGIC) == m_magic)
         {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
            double profit_pips = 0;

            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
               profit_pips = (current_price - open_price) / SymbolInfoDouble(m_symbol, SYMBOL_POINT) / 10.0;
            else
               profit_pips = (open_price - current_price) / SymbolInfoDouble(m_symbol, SYMBOL_POINT) / 10.0;

            // TP1: 50% of reference range -> Close 50% of position and set BE
            double tp1_pips = range_size * 0.5 / SymbolInfoDouble(m_symbol, SYMBOL_POINT) / 10.0;

            if(profit_pips >= tp1_pips && PositionGetDouble(POSITION_VOLUME) > SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN))
            {
               double close_volume = MathFloor(PositionGetDouble(POSITION_VOLUME) / 2.0 / SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP)) * SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
               if(close_volume > 0)
               {
                  m_trade.PositionClosePartial(ticket, close_volume);
                  m_trade.PositionModify(ticket, open_price, PositionGetDouble(POSITION_TP));
               }
            }
         }
      }
   }
};
