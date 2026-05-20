//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                                  Copyright 2024, Trading Bot Dev |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Bot Dev"
#property link      "https://www.mql5.com"
#property strict

#include "MarketStructure.mqh"
#include "CRTEngine.mqh"

class CLogger
{
private:
   int m_log_handle;
   string m_filename;

public:
   CLogger() : m_filename("trades_log.csv")
   {
      m_log_handle = FileOpen(m_filename, FILE_WRITE | FILE_CSV | FILE_ANSI);
      if(m_log_handle != INVALID_HANDLE)
      {
         FileWrite(m_log_handle, "Time", "Symbol", "Type", "Entry", "SL", "TP", "Status");
      }
   }

   ~CLogger()
   {
      if(m_log_handle != INVALID_HANDLE) FileClose(m_log_handle);
   }

   void LogTrade(datetime time, string symbol, string type, double entry, double sl, double tp, string status)
   {
      if(m_log_handle == INVALID_HANDLE)
         m_log_handle = FileOpen(m_filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI);

      if(m_log_handle != INVALID_HANDLE)
      {
         FileSeek(m_log_handle, 0, SEEK_END);
         FileWrite(m_log_handle, TimeToString(time), symbol, type, DoubleToString(entry, 5), DoubleToString(sl, 5), DoubleToString(tp, 5), status);
         FileFlush(m_log_handle);
      }
   }

   void UpdateDashboard(MarketStructureInfo &structure, CRTSignal &signal)
   {
      string text = "--- EURUSD CRT+SMC Dashboard ---\n";
      text += "HTF Bias: " + EnumToString(structure.htf_bias) + "\n";
      text += "Last Swing High: " + DoubleToString(structure.last_swing_high, 5) + "\n";
      text += "Last Swing Low: " + DoubleToString(structure.last_swing_low, 5) + "\n";
      text += "CRT Signal: " + EnumToString(signal.direction) + " (" + EnumToString(signal.quality) + ")\n";
      text += "--------------------------------";

      Comment(text);
   }

   void SendAlert(string message)
   {
      Print(message);
      SendNotification(message);
   }
};
