//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                  Copyright 2024, Trading Bot Dev |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Bot Dev"
#property link      "https://www.mql5.com"
#property strict

class CRiskManager
{
private:
   double m_risk_percent;
   int    m_max_spread_points;
   double m_max_daily_loss_pct;
   double m_initial_balance;

public:
   CRiskManager(double risk_pct, int max_spread, double max_daily_loss) :
      m_risk_percent(risk_pct),
      m_max_spread_points(max_spread),
      m_max_daily_loss_pct(max_daily_loss)
   {
      m_initial_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   }

   ~CRiskManager() {}

   double CalculateLotSize(string symbol, double sl_distance_pips)
   {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

      if(sl_distance_pips <= 0 || tick_value <= 0) return 0;

      double risk_amount = balance * (m_risk_percent / 100.0);
      double sl_points = sl_distance_pips * (0.0001 / point); // Assuming 5 digit broker

      double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double lot_size = risk_amount / (sl_distance_pips * 10.0 * tick_value); // Rough estimation

      // More precise calculation
      double money_per_lot = (sl_distance_pips * 10 * point) / tick_size * tick_value;
      if (money_per_lot > 0) lot_size = risk_amount / money_per_lot;

      double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

      lot_size = MathFloor(lot_size / lot_step) * lot_step;

      if(lot_size < min_lot) lot_size = 0;
      if(lot_size > max_lot) lot_size = max_lot;

      return lot_size;
   }

   bool IsRiskApproved(string symbol)
   {
      // Check Daily Drawdown
      double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double daily_loss = (m_initial_balance - current_balance) / m_initial_balance * 100.0;

      if(daily_loss >= m_max_daily_loss_pct) return false;

      // Check Spread
      long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      if(spread > m_max_spread_points) return false;

      // Check for active trades
      if(PositionsTotal() > 0)
      {
          for(int i=0; i<PositionsTotal(); i++)
          {
              if(PositionGetSymbol(i) == symbol) return false;
          }
      }

      return true;
   }

   void ResetDailyBalance()
   {
       m_initial_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   }
};
