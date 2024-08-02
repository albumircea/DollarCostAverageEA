//+------------------------------------------------------------------+
//|                                        DollarCostAverageMain.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


#include "DollarCostAverageEA.mqh"
LOGGER_DEFINE_FILENAME("DollarCostAverage");
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
BEGIN_INPUT(CDollarCostAverageParams)
INPUT(int, Magic, 1); // Magic Number
INPUT(ENUM_PERCENTAGE_OR_FIXED_PIPS, StepType, ENUM_PERCENTAGE_PIPS);//Step Type
INPUT(double, StepValue, 5); //Step Value
INPUT(ENUM_PERCENTAGE_OR_FIXED_PIPS, TakeProfitType, ENUM_PERCENTAGE_PIPS); //Take Profit Type
INPUT(double, TakeProfitValue, 5); //Take Profit Value
INPUT(double, Lots, 0.0); //Start Lots (0.0 = Min Volume)
INPUT(double, FactorValue, 1.0); // Multiplier Factor
INPUT(bool, NewCandleTrade, false);
INPUT(bool, DisplayInformation, false); // Show Invested Money
END_INPUT
//+------------------------------------------------------------------+
DECLARE_EA(CDollarCostAverageEA, true, "DollarCostAverage");
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
