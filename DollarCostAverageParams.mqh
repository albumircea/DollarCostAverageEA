//+------------------------------------------------------------------+
//|                                      DollarCostAverageParams.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Mircea/_profitpoint/Base/ExpertBase.mqh>
#include <Mircea/_profitpoint/Trade/TradeManager.mqh>
#include <Mircea/RiskManagement/RiskService.mqh>
#include <Mircea/_profitpoint/Mql/CandleInfo.mqh>
#include <Mircea/RiskManagement/RiskService.mqh>
#include <Mircea/RiskManagement/EquityStopService.mqh>
#include <Mircea/ExpertAdvisors/Hedge/HedgeCandles.mqh>


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDollarCostAverageParams : public CAppParams
{
                     ObjectAttrProtected(int, Magic);
                     ObjectAttrProtected(ENUM_PERCENTAGE_OR_FIXED_PIPS, StepType);
                     ObjectAttrProtected(double, StepValue);
                     ObjectAttrProtected(ENUM_PERCENTAGE_OR_FIXED_PIPS, TakeProfitType);
                     ObjectAttrProtected(double, TakeProfitValue);
                     //ObjectAttrProtected(double, Lots);
                     ObjectAttrProtected(ENUM_RISK_TYPE, RiskType);
                     ObjectAttrProtected(double, RiskAmmount);
                     ObjectAttrProtected(double, FactorValue);
                     ObjectAttrProtected(string, Symbol);
                     ObjectAttrProtected(bool, NewCandleTrade);
                     ObjectAttrProtected(bool, DisplayInformation);

public:
                     CDollarCostAverageParams(const string symbol = NULL)
   {
      mSymbol = (CString::IsEmptyOrNull(symbol)) ? ::Symbol() : symbol;
   }
                    ~CDollarCostAverageParams() {}

   bool              Check() override
   {
      if(!CTradeUtils::IsTradingAllowed())
         return false;

      if(mMagic <= 0)
      {
         Alert("Magic Number cannot be negative");
         return false;
      }

      if(mFactorValue == 0)
      {
         Alert("Factor cannot be zero");
         return false;
      }

      if(CString::IsEmptyOrNull(mSymbol))
      {
         mSymbol = Symbol();
      }

      string message = NULL;
//      mLots = (mLots != 0.0) ? mLots : CSymbolInfo::GetMinLot(mSymbol);
//
//      if(!CTradeUtils::IsLotsValid(mLots, mSymbol, message))
//      {
//         Alert(message);
//         return false;
//      }

      return true;
   }
};
//+------------------------------------------------------------------+
