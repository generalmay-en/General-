# EURUSD CRT + SMC Trading Bot

A fully automated Expert Advisor (EA) for MetaTrader 5 (MT5) designed for the EURUSD pair. It combines Candle Range Theory (CRT) session sweeps with Smart Money Concepts (SMC) for high-probability institutional trading.

## Features

- **Modular Architecture**: 8 distinct modules for easy maintenance and optimization.
- **Market Structure Detection**: Daily and H4 bias classification (Bullish, Bearish, Ranging).
- **CRT Engine**: Detects H1 session range sweeps and confirms shifts on M15/M5.
- **SMC Engine**: Identifies Order Blocks (OB) and Fair Value Gaps (FVG) on H1 and M15.
- **Risk Management**: Automated position sizing, spread filtering, and daily drawdown protection.
- **Advanced Execution**: Partial close at TP1, move to Break-Even, and multi-target exits (TP2, TP3).
- **Observability**: On-chart dashboard, CSV trade logging, and mobile push notifications.

## Project Structure

- `MQL5/Experts/CRT_SMC/`: Contains the main EA executable (`EA_EURUSD_CRT_SMC.mq5`).
- `MQL5/Include/CRT_SMC/`: Contains the core logic library files (`.mqh`).

## Getting Started

1. Copy the `MQL5` folder into your MT5 Data Folder.
2. Compile `EA_EURUSD_CRT_SMC.mq5` in MetaEditor.
3. Attach the EA to a EURUSD chart.
4. Configure input parameters as needed.

## Disclaimer

Trading involves significant risk. This EA is provided for educational purposes. Always test on a demo account before live trading.
