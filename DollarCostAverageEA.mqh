//+------------------------------------------------------------------+
//|                                          DollarCostAverageEA.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"


#include "DollarCostAverageParams.mqh"

/*
Updates:
2024.05.22 - Update CDollarCostAverageEA to check for open trades before trying to modify takeProfit
2024.05.30 - ModifyTrades, ADDED newTakeProfit = RoundDownToMultiple(newTakeProfit, TICKSIZE);
*/

/*
TODO - TRE SA INVAT CUM SE FAC OPERATIILE CU  | % etc pe bits
TODO -  ModifyPosition la OnInit-> cand schimb timeframeurile
TODO - Sa vad cum merge pe marketClosed/MarketOpen pe un cont live cu debuggerul -> daca am aceleasi valori la TP/SL ce se intampla
*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDollarCostAverageEA: public CExpertAdvisor
{
private:
   CDollarCostAverageParams* _params;
   CTradeManager     _cTradeManager;
   STradesDetails    _sTradesDetails;
   CPositionInfo     _positionInfo;
   CCandleInfo       _candleInfo;

   double            _investedMoneyAmmount;
public:
   CDollarCostAverageEA(CDollarCostAverageParams& params)
   {
      _params = GetPointer(params);
      
      _candleInfo.SetSymbol(_params.GetSymbol());
      
      double tickSize = CSymbolInfo::GetTickSize(_params.GetSymbol());
      double point = CSymbolInfo::GetPoint(_params.GetSymbol());
      RefreshValues();
      if(_sTradesDetails.buyPositions > 0 && CSymbolInfo::IsSessionTrade(_params.GetSymbol()))
      {
         ModifyTrades();
      }
   }
   ~CDollarCostAverageEA() {}


public:
   virtual void      Main() override;
   //virtual void      OnTrade_() {};
protected:
   virtual void      OnReInit() override;

private:
   double            GetStepPoints();
   double            GetTakeProfitPoints();
   double            CalculateInvestedMoney();
   bool              OpenTrade();
   void              ModifyTrades();
   void              ManageTrades();
   double            GetLots();
   bool              CheckForOpen();
   void              RefreshValues()
   {
      CalculateInvestedMoney();
      CTradeUtils::CalculateTradesDetails(_sTradesDetails, _params.GetMagic(), _params.GetSymbol());
   }

};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              CDollarCostAverageEA::Main(void)
{
   if(!CSymbolInfo::IsSessionTrade(_params.GetSymbol()))
      return;

   if(_params.GetNewCandleTrade() && !_candleInfo.IsNewCandle())
      return;

   RefreshValues();
   ManageTrades();


   if(_params.GetDisplayInformation())
      Comment(StringFormat("              InvestedMoney: %s", DoubleToString(_investedMoneyAmmount, 2)));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDollarCostAverageEA::ManageTrades(void)
{
   if (_sTradesDetails.buyPositions == 0 || (_sTradesDetails.buyPositions > 0 && CheckForOpen()))
   {
      OpenTrade();
      RefreshValues();
      ModifyTrades();
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDollarCostAverageEA::CalculateInvestedMoney(void)
{
   double tradedMoneyAmmount = 0;

//contractSize / (1 / volumeStep)
   double contractFactor = CSymbolInfo::GetContractSize(_params.GetSymbol()) / (1 / CSymbolInfo::GetLotStep(_params.GetSymbol()));

   for(int index = PositionsTotal() - 1 ; index >= 0 && !IsStopped(); index--)
   {
      if(!_positionInfo.SelectByIndex(index))
         continue;
      if(_positionInfo.Magic() != _params.GetMagic() || _positionInfo.Symbol() != _params.GetSymbol())
         continue;

      double priceOpen = _positionInfo.PriceOpen();
      double volume = _positionInfo.Volume();
      double volumeStep = CSymbolInfo::GetLotStep(_positionInfo.Symbol());
      tradedMoneyAmmount = tradedMoneyAmmount + contractFactor * priceOpen * (volume / volumeStep);
   }
   _investedMoneyAmmount = tradedMoneyAmmount;
   return (tradedMoneyAmmount);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDollarCostAverageEA::ModifyTrades(void)
{
   int takeProfitPoint =  (int) MathRound(GetTakeProfitPoints());
   double newTakeProfit = CRiskService::AveragingTakeProfitForBatch((int)ORDER_TYPE_BUY, takeProfitPoint, _params.GetMagic(), _params.GetSymbol());

//newTakeProfit = NormalizeDouble(newTakeProfit, (int)CSymbolInfo::GetDigits(_params.GetSymbol()));
   newTakeProfit = CMath::RoundDownToMultiple(newTakeProfit, CSymbolInfo::GetTickSize(_params.GetSymbol()));

   _cTradeManager.ModifyMarketBatch(_params.GetMagic(), 0.0, newTakeProfit, _params.GetSymbol(), 0, LOGGER_PREFIX_ERROR, true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDollarCostAverageEA::GetTakeProfitPoints(void)
{
   if(_params.GetTakeProfitType() != ENUM_PERCENTAGE_PIPS)
      return _params.GetTakeProfitValue();

   double investedMoney = (_investedMoneyAmmount > 0)
                          ? _investedMoneyAmmount
                          : CalculateInvestedMoney();

   double profitCashTarget = investedMoney * _params.GetTakeProfitValue() / 100;

   double tpPoints = CRiskService::GetPointsRequiredByCashAndLots(_sTradesDetails.buyPositionsLots, profitCashTarget, _params.GetSymbol());
   return tpPoints;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDollarCostAverageEA::GetStepPoints(void)
{
   if(_params.GetStepType() != ENUM_PERCENTAGE_PIPS)
      return _params.GetStepValue();

   if(!_positionInfo.SelectByTicket(_sTradesDetails.lowestLevelBuyPosTicket))
   {
      //LOG_ERROR
      return DBL_MAX;
   }
   double step = _positionInfo.PriceOpen() *  (_params.GetStepValue() / 100) / CSymbolInfo::GetPoint(_params.GetSymbol());
   return step;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDollarCostAverageEA::GetLots(void)
{
   return CRiskService::GetVolumeBasedOnMartinGaleBatch(
             _sTradesDetails.buyPositions,
             _params.GetFactorValue(),
             _params.GetSymbol(),
             _params.GetLots(),
             ENUM_TYPE_MARTINGALE_MULTIPLICATION
          );
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDollarCostAverageEA::OpenTrade()
{
   double lots = GetLots();
   string comment = StringFormat("%s,#%d", IntegerToString(_params.GetMagic()), _sTradesDetails.buyPositions + 1);

   long ticket = _cTradeManager.Market((int)ORDER_TYPE_BUY, lots, 0, 0, comment, _params.GetSymbol(), _params.GetMagic());
   return (ticket > 0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDollarCostAverageEA::CheckForOpen()
{
   if(!_positionInfo.SelectByTicket(_sTradesDetails.lowestLevelBuyPosTicket))
      return false;

   double step = GetStepPoints();
   double distancePoints = (double) CTradeUtils::DistanceBetweenTwoPricesPoints(_positionInfo.PriceOpen(), CSymbolInfo::GetAsk(_params.GetSymbol()), _params.GetSymbol());

   return(distancePoints >= step);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDollarCostAverageEA::OnReInit(void)
{


}
//+------------------------------------------------------------------+
