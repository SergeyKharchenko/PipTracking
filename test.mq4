//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
#property show_inputs


//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>


extern int BalancePips = 100;
extern int $PerLot = 100;
extern string Side_Help = "0 - But; 1 - Sell";
extern int Side = 0;


int start()
{
   if ((Digits == 5) || (Digits == 3))
   {
      BalancePips *= 10;
   }
   
   if ((BalancePips * Point) < (Ask - Bid))
   {
      Alert("Too small BalancePips");
      return;
   }   

   switch (Side)
   {
      case OP_BUY:
         double lots = GetBalanceLotsAmount(Side, Bid + BalancePips*Point, $PerLot);
         Alert ("You should buy " + DoubleToStr(lots, 2) + " lots ");             
         break;      
      case OP_SELL:
         lots = GetBalanceLotsAmount(Side, Ask - BalancePips*Point, $PerLot);
         Alert ("You should sell " + DoubleToStr(lots, 2) + " lots ");             
         break;
   }   
   return(0);
}
//+------------------------------------------------------------------+

double GetBalanceLotsAmount(int side, double targetPrice, double perLot)
{
   double priceDistance = 0;
   switch (side)
   {
      case OP_BUY:
         priceDistance = targetPrice - Ask;
         break;
      case OP_SELL:
         priceDistance = Bid - targetPrice;
         break;         
   } 
   
	double lotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
	double profitFromOneLot = lotSize * priceDistance;	
	double targetProfit = GetOrdersLots() * perLot;
	double currentProfit = GetTotalProfit(side, targetPrice);
	double lotsAmount = (targetProfit - currentProfit) / profitFromOneLot;
	return (lotsAmount);
}

double GetTotalProfit(int side, double targetPrice)
{
   double profit = 0;
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS))
         continue;
      double spread = 0;   
      switch (side)
      {
         case OP_BUY:
            if (OrderType() == OP_SELL)
               spread = Ask - Bid;
            break;
         case OP_SELL:
            if (OrderType() == OP_BUY)
               spread = Bid - Ask;
            break;            
      }
      
      profit += GetOrderProfitInCurrency(OrderTicket(), targetPrice + spread);      
   }
   
   return (profit);
}

double GetOrderProfitInCurrency(int ticket, double targetPrice)
{
   if (!OrderSelect(ticket, SELECT_BY_TICKET))
      return (0);
   double orderLots = OrderLots();   
   double lotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
   double lotCost = orderLots * lotSize;
   int orderType = OrderType();
   double orderOpenPrice = OrderOpenPrice();
   double priceDiff;
   switch (orderType)
   {
      case OP_BUY:
         priceDiff = targetPrice - orderOpenPrice;
         break;      
      case OP_SELL:
         priceDiff = orderOpenPrice - targetPrice;
         break;
   }
   
   double orderProfit = lotCost * priceDiff;
   
   return(orderProfit);
}

double GetOrdersLots()
{
   double lots = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderSymbol() != Symbol()) 
            continue;  
         lots += OrderLots();
      }
   }
         
   return (lots);
}