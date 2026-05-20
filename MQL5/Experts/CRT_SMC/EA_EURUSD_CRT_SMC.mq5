//+------------------------------------------------------------------+
//|                                         EA_EURUSD_CRT_SMC.mq5    |
//|                                  Copyright 2024, Trading Bot Dev |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Bot Dev"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Include Modules
#include <CRT_SMC\MarketStructure.mqh>
#include <CRT_SMC\CRTEngine.mqh>
#include <CRT_SMC\SMCEngine.mqh>
#include <CRT_SMC\Confluence.mqh>
#include <CRT_SMC\RiskManager.mqh>
#include <CRT_SMC\Execution.mqh>
#include <CRT_SMC\Logger.mqh>

// Input Parameters
input double RiskPercent = 1.0;          // Risk percentage per trade
input int    MaxSpreadPoints = 20;       // Max spread in points
input double MaxDailyLossPct = 3.0;      // Max daily loss percentage
input int    SL_BufferPips = 4;          // SL buffer beyond sweep wicks
input bool   UseTP3 = true;              // Extend runner to HTF zones
input bool   LondonSession = true;       // Enable London Killzone
input bool   NYSession = true;           // Enable NY Killzone
input bool   EnablePushAlerts = true;    // Send mobile push alerts
input int    MagicNumber = 202501;       // EA Magic Number

// Global Objects
CMarketStructure *market_structure;
CCRTEngine       *crt_engine;
CSMCEngine       *smc_engine;
CConfluence      *confluence;
CRiskManager     *risk_manager;
CExecution       *execution;
CLogger          *logger;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(Symbol() != "EURUSD")
   {
      Print("This EA is designed for EURUSD only.");
      return INIT_FAILED;
   }

   market_structure = new CMarketStructure(_Symbol);
   crt_engine       = new CCRTEngine(_Symbol);
   smc_engine       = new CSMCEngine(_Symbol);
   confluence       = new CConfluence(_Symbol, SL_BufferPips);
   risk_manager     = new CRiskManager(RiskPercent, MaxSpreadPoints, MaxDailyLossPct);
   execution        = new CExecution(_Symbol, MagicNumber);
   logger           = new CLogger();

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   delete market_structure;
   delete crt_engine;
   delete smc_engine;
   delete confluence;
   delete risk_manager;
   delete execution;
   delete logger;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Update Market Data
   MarketStructureInfo structure = market_structure.UpdateBias();
   smc_engine.UpdateZones();

   // 2. Discover Signals
   CRTSignal signal = crt_engine.ScanForSignal();

   // 3. Update Dashboard
   logger.UpdateDashboard(structure, signal);

   // 4. Validate Confluence
   ConfluenceResult setup = confluence.ValidateSetup(structure, signal, *smc_engine, crt_engine.GetRangeSize());

   if(setup.trade_valid)
   {
      // 5. Risk Management
      if(risk_manager.IsRiskApproved(_Symbol))
      {
         double sl_distance = MathAbs(setup.entry_price - setup.sl_price) / _Point / 10.0;
         double lot_size = risk_manager.CalculateLotSize(_Symbol, sl_distance);

         if(lot_size > 0)
         {
            // 6. Execution
            if(execution.ExecuteTrade(setup, lot_size, signal.direction))
            {
               string type_str = (signal.direction == SIGNAL_BUY) ? "BUY" : "SELL";
               logger.LogTrade(TimeCurrent(), _Symbol, type_str, setup.entry_price, setup.sl_price, setup.tp2, "OPEN");
               if(EnablePushAlerts) logger.SendAlert("Trade Opened: " + type_str + " on " + _Symbol);
            }
         }
      }
   }

   // 7. Active Trade Management
   execution.ManagePositions(crt_engine.GetRangeSize());
}
