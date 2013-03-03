//+---------------------------- ----------------------------------------+
//|                                                   TrendTracking.mq4 |
//|                                        Copyright 2012, Dawud Nelson |
//|                                 Dawud Nelson <dnelson212@yahoo.com> |
//|                                                                     |
//|                                  Programmed by AirBionicFX Software |
//|                                             http://airbionicfx.com/ |
//|    Programmer Sergey Kharchenko <sergey.kharchenko@airbionicfx.com> |
//+---------------------------------------------------------------------+
#property copyright "Copyright 2012, Dawud Nelson"

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>

//--- input parameters
extern string    OrderSettings     = "------------------------------------------------";
extern bool      OpenTrades        = true;
extern int       StopLoss          = 0;

extern string    HedjeStopLoss_Help_1 = "0 - Moving Average";
extern string    HedjeStopLoss_Help_2 = "1 - Bollinger Bands Lowest";
extern string    HedjeStopLoss_Help_3 = "2 - Bollinger Bands Medium";
extern string    HedjeStopLoss_Help_4 = "3 - Bollinger Bands Highest";
extern int       UpHedjeStopLoss      = 1;
extern int       DownHedjeStopLoss    = 3;
extern int       AdditionalSLPips        = 5;

extern string    IndicatorSettings = "------------------------------------------------";
extern int       MAPeriod          = 14;
extern string    IndicatorMAMethod_Help = "------------------------------------------------";
extern string    MAMethod_Help_1 = "0 - Simple moving average";
extern string    MAMethod_Help_2 = "1 - Exponential moving average";
extern string    MAMethod_Help_3 = "2 - Smoothed moving average";
extern string    MAMethod_Help_4 = "3 - Linear weighted moving average";
extern int       MAMethod          = 0;
extern int       MAShift           = 0;
extern int       BBPeriod          = 20;
extern int       BBDeviation       = 1;
extern int       BBShift           = 0;

extern string    IndicatorSettingsPrice_Help = "------------------------------------------------";
extern string    IndicatorPrice_Help_1 = "0 - Close price";
extern string    IndicatorPrice_Help_2 = "1 - Open price";
extern string    IndicatorPrice_Help_3 = "2 - High price";
extern string    IndicatorPrice_Help_4 = "3 - Low price";
extern string    IndicatorPrice_Help_5 = "4 - Median price";
extern string    IndicatorPrice_Help_6 = "5 - Typical price";
extern string    IndicatorPrice_Help_7 = "6 - Weighted close price";
extern int       MAPrice           = 0;
extern int       BBPrice           = 0;

extern string    IndicatorSettingsTimeframe_Help = "------------------------------------------------";
extern string    IndicatorTimeframe_Help_1  = "0 - Timeframe used on the chart";
extern string    IndicatorTimeframe_Help_2  = "1 - 1 minute";
extern string    IndicatorTimeframe_Help_3  = "2 - 5 minutes";
extern string    IndicatorTimeframe_Help_4  = "3 - 15 minutes";
extern string    IndicatorTimeframe_Help_5  = "4 - 30 minutes";
extern string    IndicatorTimeframe_Help_6  = "5 - 1 hour";
extern string    IndicatorTimeframe_Help_7  = "6 - 4 hours";
extern string    IndicatorTimeframe_Help_8  = "7 - Daily";
extern string    IndicatorTimeframe_Help_9  = "8 - Weekly";
extern string    IndicatorTimeframe_Help_10 = "9 - Monthly";
extern int       MATimeframe = 0;
extern int       BBTimeframe = 0;

extern int       TakeProfit         = 20;
extern double    ProfitPerLot       = 30;

extern string    LotSettings         = "------------------------------------------------";
extern double    LotSize             = 0.1;
extern double    LotExponent         = 1.5;
extern double    LotHedjeExponent = 2.5;

extern string    StrategySettings  = "------------------------------------------------";
extern int       PipStep           = 25;
extern double    UnrealizedLoss    = 15;

extern string    MagicNymberSettings = "------------------------------------------------";
extern string    MagicNumber_Help    = "Should be unique for all charts";
extern int       MagicNumberUp       = 1234;
extern int       MagicNumberDown     = 4321;
                                
extern string    SupportSettings = "------------------------------------------------";                           
extern bool      ShowAlerts      = true;
extern bool      ShowComments    = true;
extern string    DisableEA_Help  = "If any error has occurred EA will close all positions and will be disable";
extern bool      DisableEA       = false;

// --> Global states
#define NONE       -1
#define SIMPLE     0
#define MULTIPLE   1
#define OPPOSITE   2
#define BREAK_EVEN 3
// <-- Global states


// --> Global variables
int
   sl,
   slOp,
   ticket,
   stateUp,
   stateDown,
   hedjeWasClosedUp,
   hedjeWasClosedDown,
   hedjeCapturedSLUp,
   hedjeCapturedSLDown;
   
bool 
   work = true,
   isError = false;   
   
double
   lot,
   startLot,
   startMoneyBuy,
   startMoneySell;   
   
string 
   errorStr,
   saveFileName;        
    
datetime
   startSessionBuy,
   startSessionSell;
    
// <--
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----

   if (MagicNumberUp < 0) 
   {
      if (ShowAlerts)
         Alert("MagicNumberUp is invalid");
      work = false;
      return; 
   }     
   
   if (MagicNumberDown < 0) 
   {
      if (ShowAlerts)
         Alert("MagicNumberDown is invalid");
      work = false;
      return; 
   }      
    
   if (MagicNumberDown == MagicNumberUp) 
   {
      if (ShowAlerts)
         Alert("MagicNumberDown and MagicNumberUp can\'t be the same");
      work = false;
      return; 
   }                   
   
   if (StopLoss < 0) {
      if (ShowAlerts) {
         Alert("StopLoss is invalid");
      }   
      work = false;
      return; 
   }  
   
   if (TakeProfit < 0) {
      if (ShowAlerts) {
         Alert("TakeProfit is invalid");
      }   
      work = false;
      return; 
   }  

   if (LotExponent < 1) {
      if (ShowAlerts) {
         Alert("LotExponent is invalid");
      }   
      work = false;
      return; 
   }     
   
   if (LotHedjeExponent < 1) {
      if (ShowAlerts) {
         Alert("LotHedjeExponent is invalid");
      }   
      work = false;
      return; 
   }       
   
   if (PipStep < 1) {
      if (ShowAlerts) {
         Alert("PipStep is invalid");
      }   
      work = false;
      return; 
   }          
   
   if (UnrealizedLoss <= 0) {
      if (ShowAlerts) {
         Alert("UnrealizedLoss is invalid");
      }   
      work = false;
      return; 
   }     
   
   if ((UpHedjeStopLoss < 0) || (UpHedjeStopLoss > 3)) {
      if (ShowAlerts) {
         Alert("UpHedjeStopLoss is invalid");
      }   
      work = false;
      return; 
   }       

   if ((DownHedjeStopLoss < 0) || (DownHedjeStopLoss > 3)) {
      if (ShowAlerts) {
         Alert("DownHedjeStopLoss is invalid");
      }   
      work = false;
      return; 
   }       
   
   if (MAPeriod < 1) {
      if (ShowAlerts) {
         Alert("MAPeriod is invalid");
      }   
      work = false;
      return; 
   }      
   
   if (MAShift < 0) {
      if (ShowAlerts) {
         Alert("MAShift is invalid");
      }   
      work = false;
      return; 
   }                
   
   if (BBPeriod < 1) {
      if (ShowAlerts) {
         Alert("BBPeriod is invalid");
      }   
      work = false;
      return; 
   }     
   
   if (BBDeviation < 0) {
      if (ShowAlerts) {
         Alert("BBDeviation is invalid");
      }   
      work = false;
      return; 
   }               
   
   if (BBShift < 0) {
      if (ShowAlerts) {
         Alert("BBShift is invalid");
      }   
      work = false;
      return; 
   }           
   
   if ((MAMethod < 0) || (MAMethod > 3)) {
      if (ShowAlerts) {
         Alert("MAMethod is invalid");
      }   
      work = false;
      return; 
   }   
   
   if ((MAPrice < 0) || (MAPrice > 6)) {
      if (ShowAlerts) {
         Alert("MAPrice is invalid");
      }   
      work = false;
      return; 
   }   
   
   if ((BBPrice < 0) || (BBPrice > 6)) {
      if (ShowAlerts) {
         Alert("BBPrice is invalid");
      }   
      work = false;
      return; 
   }         
   
   if ((MATimeframe < 0) || (MATimeframe > 9)) {
      if (ShowAlerts) {
         Alert("MATimeframe is invalid");
      }   
      work = false;
      return; 
   }     
   
   if ((BBTimeframe < 0) || (BBTimeframe > 9)) {
      if (ShowAlerts) {
         Alert("BBTimeframe is invalid");
      }   
      work = false;
      return; 
   }        
   
   
   lot = NormalizeLots(LotSize, Symbol());

   if (lot != LotSize) {
      if (ShowAlerts) {
         Alert("Warning: This LotSize is invalid for this broker");
      }   
      work = false;
      return; 
   }
   
   startLot = lot;
   
   if (MarketInfo(Symbol(), MODE_LOTSIZE) != 0)
      if (lot > (AccountFreeMargin() / MarketInfo(Symbol(), MODE_LOTSIZE))) {
         if (ShowAlerts) {
            Alert("This LotSize too big for your balance");
         }   
      }   
      
   if ((Digits == 5) || (Digits == 3))
   {
	  sl = CheckStop(StopLoss * 10, 0); 
	  TakeProfit *= 10;
	  PipStep *= 10;	  
	  AdditionalSLPips *= 10;
   }
   else
   {
	  sl = CheckStop(StopLoss, 0);
   }
   
   isError = false;
   
   stateUp  = NONE;
   stateDown = NONE;
   
   startMoneyBuy = -1;
   startMoneySell = -1;
   startSessionBuy = -1;
   startSessionSell = -1;       
   hedjeWasClosedUp = 0;
   hedjeWasClosedDown = 0;
   hedjeCapturedSLUp = UpHedjeStopLoss;
   hedjeCapturedSLDown = DownHedjeStopLoss;
   MATimeframe = TranslatePeriod(MATimeframe);
   BBTimeframe = TranslatePeriod(BBTimeframe);
   
   
   saveFileName = Symbol() + " " + " " + MagicNumberUp + "-" + MagicNumberDown + ".csv";
   
   LoadSession();
   start();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   SaveSession();
   Comment("");  
//----
   return(0);
  }

void LoadSession()
{
   int handle;
   handle = FileOpen(saveFileName, FILE_CSV | FILE_READ,';');   
   if(handle > 0)
   {
      stateUp = FileReadNumber(handle);
      startMoneyBuy = FileReadNumber(handle);
      startSessionBuy = FileReadNumber(handle);
      hedjeWasClosedUp = FileReadNumber(handle);   
      hedjeCapturedSLUp = FileReadNumber(handle); 
      
      stateDown = FileReadNumber(handle);
      startMoneySell = FileReadNumber(handle);
      startSessionSell = FileReadNumber(handle);
      hedjeWasClosedDown = FileReadNumber(handle); 
      hedjeCapturedSLDown = FileReadNumber(handle); 
      FileClose(handle);
   }
}
  
void SaveSession()
{
   int handle;
   handle = FileOpen(saveFileName, FILE_CSV | FILE_WRITE,';');
   if(handle > 0)
   {
      FileWrite(handle, 
               stateUp, startMoneyBuy, startSessionBuy, hedjeWasClosedUp, hedjeCapturedSLUp,
               stateDown, startMoneySell, startSessionSell, hedjeWasClosedDown, hedjeCapturedSLDown);
      FileClose(handle);
   }
}
  
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   if (!IsExpertEnabled()) 
   { 
      if (ShowAlerts) 
         Alert("Expert advisors are disabled for running");
      return;
   }                
   
   if (!work) 
   {
      Comment("Reload EA with correct parameters.");
      return;
   }   
 
   if (isError)
   {
      CloseAllOrders();
      
      stateUp  = NONE;
      stateDown = NONE;   
      startMoneyBuy = -1;
      startMoneySell = -1;
      startSessionBuy = -1;
      startSessionSell = -1;       
      hedjeWasClosedUp = 0;
      hedjeWasClosedDown = 0;
      hedjeCapturedSLUp = UpHedjeStopLoss;
      hedjeCapturedSLDown = DownHedjeStopLoss;
   }   
   else
   {
      SaveSession();
      
      // --> Buy    
      if ((GetOrdersCount(MagicNumberUp, OP_BUY) + GetOrdersCount(MagicNumberUp, OP_SELL)) == 0)
         stateUp = NONE;

      if (stateUp == OPPOSITE)
      {
         if (GetOrdersCount(MagicNumberUp, OP_SELL) > 0)
         {
            TrailingByIndicator(MagicNumberUp, OP_SELL); 
            if (IsIndicatorClose(OP_SELL))
               TryClose(MagicNumberUp, OP_SELL);
         }   
         else
         {
            hedjeWasClosedUp = 1;
         }  
      }
       
      if (stateUp == BREAK_EVEN)  
      {
         Trailing(MagicNumberUp);
      }
      else   
      {     
         if (IsBreakEven(OP_BUY))
         {
            stateUp = BREAK_EVEN;    
            Trailing(MagicNumberUp);   
         }      
         else
         {   
            if (IsTakeProfit(OP_BUY))
            {
               TryClose(MagicNumberUp, OP_BUY);
            }
               
            if (OpenTrades)
            {
               int state = IsOpen(OP_BUY);
               if (state != -1)
               {
                  stateUp = state;
                  lot = CalcLot(OP_BUY, stateUp);
                  switch (stateUp)
                  {              
                     case SIMPLE: 
                        startMoneyBuy = AccountBalance();  
                        startSessionBuy = TimeCurrent();
                        hedjeWasClosedUp = 0;
                        ticket = OpenOrderA(Symbol(), OP_BUY, startLot, Ask, sl, 0, 100, NULL, MagicNumberUp, 5, 0, Lime);  
                        if (DisplayError(ticket))
                           stateUp = NONE;
                        break;

                     case MULTIPLE:
                        ticket = OpenOrderA(Symbol(), OP_BUY, lot, Ask, sl, 0, 100, NULL, MagicNumberUp, 5, 0, Lime);  
                        if (DisplayError(ticket))
                           stateUp = NONE;
                        break;

                     case OPPOSITE:
                        double slValue = GetHedjeSL(OP_SELL, hedjeCapturedSLUp, false);
                        slOp = CastSLToPoints(slValue, OP_SELL);                     
                        ticket = OpenOrderA(Symbol(), OP_SELL, lot, Bid, slOp, 0, 100, NULL, MagicNumberUp, 5, 0, Red);  
                        if (DisplayError(ticket))
                           stateUp = NONE;
                        break;
                  } 
               }
            }   
         }  
      }
      // <-- Buy
   
      // --> Sell    
      if ((GetOrdersCount(MagicNumberDown, OP_BUY) + GetOrdersCount(MagicNumberDown, OP_SELL)) == 0)
         stateDown = NONE;

      if (stateDown == OPPOSITE)
      {
         if (GetOrdersCount(MagicNumberDown, OP_BUY) > 0)
         {
            TrailingByIndicator(MagicNumberDown, OP_BUY);
            if (IsIndicatorClose(OP_BUY))
               TryClose(MagicNumberDown, OP_BUY);         
         }   
         else
         {
            hedjeWasClosedDown = 1;
         }  
      }   
   
      if (stateDown == BREAK_EVEN)   
      {
         Trailing(MagicNumberDown);  
      }
      else
      {
         if (IsBreakEven(OP_SELL))
         {
            stateDown = BREAK_EVEN;    
            Trailing(MagicNumberDown);     
            startSessionSell = -1;      
         }      
         else
         {            
            if (IsTakeProfit(OP_SELL))
            {
               TryClose(MagicNumberDown, OP_SELL);
            }      
      
            if (OpenTrades)
            {
               state = IsOpen(OP_SELL);
               if (state != -1)
               {
                  stateDown = state;
                  lot = CalcLot(OP_SELL, stateDown);
                  switch (stateDown)
                  {              
                     case SIMPLE: 
                        startMoneySell = AccountBalance();  
                        startSessionSell = TimeCurrent();
                        hedjeWasClosedDown = 0;
                        ticket = OpenOrderA(Symbol(), OP_SELL, startLot, Bid, sl, 0, 100, NULL, MagicNumberDown, 5, 0, Red);  
                        if (DisplayError(ticket))
                           stateDown = NONE;
                        break;

                     case MULTIPLE:
                        ticket = OpenOrderA(Symbol(), OP_SELL, lot, Bid, sl, 0, 100, NULL, MagicNumberDown, 5, 0, Red);  
                        if (DisplayError(ticket))
                           stateDown = NONE;
                        break;

                     case OPPOSITE:
                        slValue = GetHedjeSL(OP_BUY, hedjeCapturedSLDown, false);
                        slOp = CastSLToPoints(slValue, OP_BUY);                     
                        ticket = OpenOrderA(Symbol(), OP_BUY, lot, Ask, slOp, 0, 100, NULL, MagicNumberDown, 5, 0, Lime);  
                        if (DisplayError(ticket))
                           stateDown = NONE;
                        break;
                  } 
               }
            }   
         } 
      }  // <-- Sell  
          
   } // not isError
   
   if (ShowComments)
      ShowStatistics();
//----
   return(0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void ShowStatistics()
{
   string comment = "\r\nTrendTracking\r\n\r\nAccount balance: " + DoubleToStr(AccountBalance(), 2) + "\r\n";
   if (isError)
   {
      comment = comment + errorStr + "\r\n"; 
   }
   else
   {
      double currentTotalProfitBuy;
      
      string buyStr;
      switch (stateUp)
      {
         case SIMPLE:
            buyStr = "     Target take profit: " + DoubleToStr(GetLastOrderOpenPrice(MagicNumberUp, OP_BUY) + TakeProfit * Point, Digits) + "\r\n";
            double targetUnresizedLoss = startMoneyBuy - GetUnrealizedLoss(OP_BUY);
            buyStr = buyStr + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\r\n";
            currentTotalProfitBuy = GetOrdersProfit(MagicNumberUp);
            break;
         case BREAK_EVEN:   
            buyStr = "     In Break even\r\n";      
            currentTotalProfitBuy = GetOrdersProfit(MagicNumberUp);
            break;
         case MULTIPLE:
            currentTotalProfitBuy = GetOrdersProfit(MagicNumberUp);                                            
            buyStr = "     Target break even trigger: " + DoubleToStr(GetOrdersLots(MagicNumberUp) * ProfitPerLot, 2) + " $\r\n";
            targetUnresizedLoss = startMoneyBuy - GetUnrealizedLoss(OP_BUY);
            buyStr = buyStr + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\r\n";                                         
            break;   
            
         case OPPOSITE:             
            double previousProfit = GetHedjeProfit(MagicNumberUp, OP_SELL, startSessionBuy); 
            double currentProfit = GetOrdersProfit(MagicNumberUp);     
            currentTotalProfitBuy = currentProfit + previousProfit;
                                       
            buyStr = "     Live profit: " + DoubleToStr(currentProfit, 2) + " $\r\n"; 
            buyStr = buyStr + "     Balance of previous hedje orders: " + DoubleToStr(previousProfit, 2) + " $\r\n";                 
            buyStr = buyStr + "     Target break even trigger: " + DoubleToStr(GetOrdersLots(MagicNumberUp) * ProfitPerLot, 2) + " $\r\n";                 
            buyStr = buyStr + "     Stop loss use: " + StopLossModeToString(hedjeCapturedSLUp) + "\r\n";
         
            bool opposoteOrderExist = IsHedjeOrderExist(MagicNumberUp, OP_SELL);
            if ((hedjeWasClosedUp == 1) && !opposoteOrderExist)
               buyStr = buyStr + "     Hedje price: " + DoubleToStr(GetHedjeSL(OP_SELL, hedjeCapturedSLUp, true), Digits) + "\r\n";                
            if (opposoteOrderExist)
               buyStr = buyStr + "     Hedje stop loss: " + DoubleToStr(GetLastHedjeOrderStopLoss(MagicNumberUp, OP_SELL), Digits) + "\r\n";                                                                                        
            break;   
      }

      double currentTotalProfitSell;
      string sellStr;
      switch (stateDown)
      {
         case SIMPLE:
            sellStr = "     Target take profit: " + DoubleToStr(GetLastOrderOpenPrice(MagicNumberDown, OP_SELL) - TakeProfit * Point, Digits) + "\r\n";
            targetUnresizedLoss = startMoneySell - GetUnrealizedLoss(OP_SELL);
            sellStr = sellStr + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\r\n";               
            currentTotalProfitSell = GetOrdersProfit(MagicNumberDown);
            break;
         case BREAK_EVEN:   
            sellStr = "     In Break even\r\n";
            currentTotalProfitSell = GetOrdersProfit(MagicNumberDown);
            break;
         case MULTIPLE:
            currentTotalProfitSell = GetOrdersProfit(MagicNumberDown);
            sellStr = "     Target break even trigger: " + DoubleToStr(GetOrdersLots(MagicNumberDown) * ProfitPerLot, 2) + " $\r\n";
            targetUnresizedLoss = startMoneySell - GetUnrealizedLoss(OP_SELL);
            sellStr = sellStr + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\r\n";                  
            break;                 
         case OPPOSITE:           
            currentProfit = GetOrdersProfit(MagicNumberDown);              
            previousProfit = GetHedjeProfit(MagicNumberDown, OP_BUY, startSessionSell);               
            currentTotalProfitSell = currentProfit + previousProfit;                                                          
                                  
            sellStr = "     Live profit: " + DoubleToStr(currentProfit, 2) + " $\r\n";                       
            sellStr = sellStr + "     Balance of previous hedje orders: " + DoubleToStr(previousProfit, 2) + " $\r\n";                
            sellStr = sellStr + "     Target break even trigger: " + DoubleToStr(GetOrdersLots(MagicNumberDown) * ProfitPerLot, 2) + " $\r\n";                                     
            sellStr = sellStr + "     Stop loss use: " + StopLossModeToString(hedjeCapturedSLDown) + "\r\n";
         
            opposoteOrderExist = IsHedjeOrderExist(MagicNumberDown, OP_BUY);
            if ((hedjeWasClosedDown == 1) && !opposoteOrderExist)
               sellStr = sellStr + "     Hedje price: " + DoubleToStr(GetHedjeSL(OP_BUY, hedjeCapturedSLDown, true), Digits) + "\r\n";
            if (opposoteOrderExist)
               sellStr = sellStr + "     Hedje stop loss: " + DoubleToStr(GetLastHedjeOrderStopLoss(MagicNumberDown, OP_BUY), Digits) + "\r\n";                  
         
               
            break;   
      }   
      comment = comment + 
           "Moving Avarage use timeframe: " + PeriodToString(MATimeframe) + "\r\n" +
           "Bollinger Bands use timeframe: " + PeriodToString(BBTimeframe) + "\r\n" +
           "---------------------------------------------------------\r\n" +
           "Buy\r\n" +
           "     Account balance at the session start: " + DoubleToStr(startMoneyBuy, 2) + "\r\n" +
           "     Lots: " + DoubleToStr(GetOrdersLots(MagicNumberUp), 2) + "\r\n" +
           "     Current total profit: " + DoubleToStr(currentTotalProfitBuy, 2) + " $\r\n" +
           buyStr +
           "=========================\r\n" +
           "Sell\r\n" +
           "     Account balance at the session start: " + DoubleToStr(startMoneySell, 2) + "\r\n" +
           "     Lots: " + DoubleToStr(GetOrdersLots(MagicNumberDown), 2) + "\r\n" +
           "     Current total profit: " + DoubleToStr(currentTotalProfitSell, 2) + " $\r\n" +              
           sellStr;
   }
   
   Comment(comment); 
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void CloseAllOrders()
{
   TryClose(MagicNumberUp, OP_BUY);
   TryClose(MagicNumberUp, OP_SELL);
   TryClose(MagicNumberDown, OP_BUY);
   TryClose(MagicNumberDown, OP_SELL);

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
string StopLossModeToString(int mode)
{
   switch (mode)
   {
      case 0: return ("Moving Average");
      case 1: return ("Bollinger Bands Lowest");
      case 2: return ("Bollinger Bands Medium");
      case 3: return ("Bollinger Bands Highest");
   }
   return ("");
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
bool IsTakeProfit(int type)
{
   switch (type)
   {
      case OP_BUY:
         switch (GetOrdersCount(MagicNumberUp, OP_BUY))
         {
            case 0: return (false);
            case 1: 
               if (Ask >= (GetLastOrderOpenPrice(MagicNumberUp, OP_BUY) + TakeProfit * Point))
                  return (true);
               break;
         }
         break;
         
      case OP_SELL:
         switch (GetOrdersCount(MagicNumberDown, OP_SELL))         
         {
            case 0: return (false);
            case 1: 
               if (Bid <= (GetLastOrderOpenPrice(MagicNumberDown, OP_SELL) - TakeProfit * Point))
                  return (true);
               break;               
         }
         break;
   }      

   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
string PeriodToString(int period)
{
   switch (period)
   {
	   case PERIOD_M1 : return("1 minute");
	   case PERIOD_M5 : return("5 minutes");
	   case PERIOD_M15 : return("15 minutes");
	   case PERIOD_M30 : return("30 minutes");
	   case PERIOD_H1 : return("1 hour");
	   case PERIOD_H4 : return("4 hours");
	   case PERIOD_D1 : return("Daily");
	   case PERIOD_W1 : return("Weekly");
	   case PERIOD_MN1 : return("Monthly");
   }
   return ("");
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool TryClose(int magic, int type) 
{

   int ticket = GetLastOrderTicket(magic, type);
 
   if (OrderSelect(ticket, SELECT_BY_TICKET) && CheckOpen(ticket) == 1)
   {      
      int k = 0;
      while(k < 5)
      {
         RefreshRates();
         if (OrderClose(ticket, OrderLots(), OrderClosePrice(), 100)) 
         {


            return (true);
         }   
         k++;
      }             
   }


   return (false);
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
int CastSLToPoints(double slValue, int type)
{
   RefreshRates();
   int slPoints;
   switch (type)
   {
      case OP_BUY:
         slPoints = (Ask - slValue) / Point;
         break;
      case OP_SELL:
         slPoints = (slValue - Bid) / Point;
         break;         
   }
   if (slPoints <= 0)
      slPoints = -1;
      
   return (slPoints);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetHedjeSL(int type, int hedjeStopLoss, bool withAdditionalPips)
{
   double iValue;
   switch (hedjeStopLoss)
   {
      case 0:
         iValue = iMA(Symbol(), MATimeframe, MAPeriod, MAShift, MAMethod, MAPrice, 0);
         break;
      case 1:
         iValue = iBands(Symbol(), BBTimeframe, BBPeriod, BBDeviation, BBShift, BBPrice, MODE_LOWER, 0);
         break;
      case 2:
         double lowest = iBands(Symbol(), BBTimeframe, BBPeriod, BBDeviation, BBShift, BBPrice, MODE_LOWER, 0);
         double highest = iBands(Symbol(), BBTimeframe, BBPeriod, BBDeviation, BBShift, BBPrice, MODE_UPPER, 0);
         iValue = (highest + lowest) / 2;
         break;
      case 3:
         iValue = iBands(Symbol(), BBTimeframe, BBPeriod, BBDeviation, BBShift, BBPrice, MODE_UPPER, 0);
         break;                           
   }
   
   if (withAdditionalPips)   
      switch (type)
      {
         case OP_BUY:
            iValue += AdditionalSLPips * Point;
            break;
         case OP_SELL:
            iValue -= AdditionalSLPips * Point;
            break;         
      }  
   return (iValue);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetHedjeProfit(int magic, int type, datetime time)
{

   double profit = 0;
   for (int i = OrdersHistoryTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if (OrderSymbol() != Symbol()) continue;
         if (OrderMagicNumber() != magic) continue;                           
         if (OrderType() != type) continue;
         if ((OrderOpenTime() < time) || (time == -1)) continue;
         profit = profit + OrderProfit();
      }
   }

   return (profit);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void TrailingByIndicator(int magic, int type, int attempts = 5)
{

   for(int j = OrdersTotal() - 1; j >= 0; j--)
   {
      if (OrderSelect(j, SELECT_BY_POS))
      {
         if ((OrderMagicNumber() == magic) && (OrderSymbol() == Symbol()) && (OrderType() == type))
         {                                          
            for (int i = 0; i < attempts; i++)
            {                      

               if (CheckOpen(OrderTicket()) != 1)
               {
                  break;
               }
               RefreshRates();                       
               
               if (OrderType() == OP_BUY)
               {
                  double slValue = GetHedjeSL(OP_BUY, hedjeCapturedSLDown, false);                                    
                  int newSLpt = CastSLToPoints(slValue, OP_BUY);                                  
                  int checkedSLpt = CheckStop(newSLpt, 0);          
                  double newSL = NormalizeDouble(Ask - checkedSLpt * Point, Digits);                             
                  if (NormalizeDouble(newSL, Digits) != NormalizeDouble(OrderStopLoss(), Digits))
                  {
                     OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), Lime);
                  }
               }

               if (OrderType() == OP_SELL)
               {                  
                  slValue = GetHedjeSL(OP_SELL, hedjeCapturedSLUp, false);
                  newSLpt = CastSLToPoints(slValue, OP_SELL);
                  checkedSLpt = CheckStop(newSLpt, 0);                  
                  newSL = NormalizeDouble(Bid + checkedSLpt * Point, Digits);
                  if (NormalizeDouble(newSL, Digits) != NormalizeDouble(OrderStopLoss(), Digits))
                  {
                     OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), Lime);                                   
                  }                            
               }                              
            }                                    
         }
      }   
   }

}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
void Trailing(int magic, int attempts = 10)
{

   for(int j = OrdersTotal() - 1; j >= 0; j--)
   {
      if (OrderSelect(j, SELECT_BY_POS))
      {
         if ((OrderMagicNumber() == magic) && (OrderSymbol() == Symbol()))
         {                                          
            for (int i = 0; i < attempts; i++)
            {                     

                                                           
               if (CheckOpen(OrderTicket()) != 1)
                  break;
               RefreshRates();
                       
               
               int newSLpt = CheckStop(-1, 0);
               
               if (OrderType() == OP_BUY)
               {
                  double newSL = NormalizeDouble(Ask - newSLpt * Point, Digits);
                  if ((NormalizeDouble(newSL, Digits) > NormalizeDouble(OrderStopLoss(), Digits)) || (OrderStopLoss() < 0.000001))
                  {
                     OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), Lime);
                  }
               }

               if (OrderType() == OP_SELL)
               {
                  newSL = NormalizeDouble(Bid + newSLpt * Point, Digits);
                  if ((NormalizeDouble(newSL, Digits) < NormalizeDouble(OrderStopLoss(), Digits)) || (OrderStopLoss() < 0.000001))
                  {
                     OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), Lime);               
                  }                 
               }                              
            }                                    
         }
      }   
   }

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double CalcLot(int type, int state)
{
   switch (type)
   {
      case OP_BUY:
         if (state == OPPOSITE)
            return (NormalizeLots(GetOrdersLots(MagicNumberUp) * LotHedjeExponent, Symbol()));              
         return (NormalizeLots(GetLastOrderLots(MagicNumberUp, OP_BUY) * LotExponent, Symbol()));
         
      case OP_SELL:
         if (state == OPPOSITE)
            return (NormalizeLots(GetOrdersLots(MagicNumberDown) * LotHedjeExponent, Symbol()));
         return (NormalizeLots(GetLastOrderLots(MagicNumberDown, OP_SELL) * LotExponent, Symbol()));
   }   
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsIndicatorClose(int type)
{
   switch (type)
   {
      case OP_BUY:
         double hedjeSL = GetHedjeSL(OP_BUY, hedjeCapturedSLDown, false);
         if (hedjeSL >= Bid)
            return (true);
         break;
         
      case OP_SELL:
         hedjeSL = GetHedjeSL(OP_SELL, hedjeCapturedSLUp, false);
         if (hedjeSL <= Ask)
            return (true);         
         break;
   }   
   return (false);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int GetOrdersCount(int magic, int type)
{
   int count = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderType() != type) continue;
         if (OrderSymbol() != Symbol()) continue;
         if (OrderMagicNumber() != magic) continue;                           
         count++;
      }
   }
         
   return (count);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetLastOrderOpenPrice(int magic, int type)
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderType() != type) continue;
         if (OrderSymbol() != Symbol()) continue;
         if (OrderMagicNumber() != magic) continue;                           
         return (OrderOpenPrice());
      }
   }
         
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsHedjeOrderExist(int magic, int type)
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderType() != type) continue;
         if (OrderSymbol() != Symbol()) continue;
         if (OrderMagicNumber() != magic) continue;                           
         return (true);
      }
   }         
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetLastHedjeOrderStopLoss(int magic, int type, int mode = MODE_TRADES)
{
   int ticket = GetLastOrderTicket(magic, type, mode);

   switch (mode)
   {
      case MODE_TRADES:
         if (OrderSelect(ticket, SELECT_BY_TICKET))      
            return (OrderStopLoss());
         break;
      case MODE_HISTORY:
         if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY))      
            return (OrderStopLoss());
         break;         
   }
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetLastOrderLots(int magic, int type)
{
   int ticket = GetLastOrderTicket(magic, type);

   if (OrderSelect(ticket, SELECT_BY_TICKET))                        
      return (OrderLots());
         
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetOrdersProfit(int magic)
{
   double profit = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderSymbol() != Symbol()) continue;
         if (OrderMagicNumber() != magic) continue;                           
         profit += OrderProfit();
      }
   }
         
   return (profit);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsUnrealizedLoss(int magic, int type)
{
   double loss = GetUnrealizedLoss(type);
   loss *= -1;
   if (GetOrdersProfit(magic) <= loss)
      return (true);
      
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetUnrealizedLoss(int type)
{
   double loss = 0; 
   switch (type)
   {
      case OP_BUY:
         if (startMoneyBuy == -1)
            loss = 0;     
         else
            loss = startMoneyBuy * (UnrealizedLoss / 100);
         break;
         
      case OP_SELL:
         if (startMoneySell == -1)
            loss = 0;
         else
            loss = startMoneySell * (UnrealizedLoss / 100);         
         break;
   }   
   return (loss);
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
int GetLastOrderTicket(int magic, int type, int mode = MODE_TRADES)
{
   int orderOpenTime = 0;
   int ticket = 0;
   
   switch (mode)
   {
      case MODE_TRADES:
         for (int i = OrdersTotal() - 1; i >= 0; i--)  
         {
            if (OrderSelect(i, SELECT_BY_POS))
            {
               if (OrderSymbol() != Symbol()) continue;
               if (OrderMagicNumber() != magic) continue;                                
               if (OrderType() != type) continue;  
               if (orderOpenTime < OrderOpenTime())
               {
                  orderOpenTime = OrderOpenTime();
                  ticket = OrderTicket();
               }
            }
         }
         break;
      case MODE_HISTORY:
         for (i = OrdersHistoryTotal() - 1; i >= 0; i--)  
         {
            if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
            {
               if (OrderSymbol() != Symbol()) continue;
               if (OrderMagicNumber() != magic) continue;                                
               if (OrderType() != type) continue;  
               if (orderOpenTime < OrderOpenTime())
               {
                  orderOpenTime = OrderOpenTime();
                  ticket = OrderTicket();
               }
            }
         }
         break;         
   }


   return (ticket);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetOrdersLots(int magic)
{
   double lots = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderSymbol() != Symbol()) continue;
         if (OrderMagicNumber() != magic) continue;                                
         lots += OrderLots();
      }
   }
         
   return (lots);
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
int IsOpen(int type)
{
   RefreshRates();
   switch (type)
   {
      case OP_BUY:            
         if (GetOrdersCount(MagicNumberUp, OP_SELL) == 0)   // No hedje order
         {            
            if (GetOrdersCount(MagicNumberUp, OP_BUY) == 0)
               return (SIMPLE);      
               
            if (!hedjeWasClosedUp)  // First hedje
            {
               if (IsUnrealizedLoss(MagicNumberUp, OP_BUY))
               {
                  int hedjeSLMode = GetHedjeMode(OP_SELL);
                  if (hedjeSLMode != -1)
                  {
                     hedjeCapturedSLUp = hedjeSLMode;
                     return (OPPOSITE);
                  }
               }     
               else
               {                              
                  if ((Ask + PipStep * Point) <= GetLastOrderOpenPrice(MagicNumberUp, OP_BUY))
                     return (MULTIPLE);      
               }                 
            }
            else  // Not first hedje
            {
               if (GetHedjeSL(OP_SELL, hedjeCapturedSLUp, true) > Ask)
                  return (OPPOSITE);
            }
         }
         break;
         
      case OP_SELL:        
         if (GetOrdersCount(MagicNumberDown, OP_BUY) == 0)   // No hedje order
         {
            if (GetOrdersCount(MagicNumberDown, OP_SELL) == 0)
               return (SIMPLE);
         
            if (!hedjeWasClosedDown)  // First hedje
            {
               if (IsUnrealizedLoss(MagicNumberDown, OP_SELL))
               {
                  hedjeSLMode = GetHedjeMode(OP_BUY); 
                  if (hedjeSLMode != -1)
                  {
                     hedjeCapturedSLDown = hedjeSLMode;
                     return (OPPOSITE);
                  }
               }      
               else
               {               
                  if ((Bid - PipStep * Point) >= GetLastOrderOpenPrice(MagicNumberDown, OP_SELL))
                     return (MULTIPLE);   
               }                 
            }
            else  // Not first hedje
            {
               if (GetHedjeSL(OP_BUY, hedjeCapturedSLDown, true) < Bid)
                  return (OPPOSITE);
            }
         }
         break;         
   }


   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int GetHedjeMode(int type)
{
   double
      stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

   switch (type)
   {
      case OP_BUY:
         double slValue = GetHedjeSL(OP_BUY, UpHedjeStopLoss, false);
         if (slValue >= (Bid + stopLevel))
         {
            for (int i = 1; i <= 3; i++)
            {
               slValue = GetHedjeSL(OP_BUY, UpHedjeStopLoss, false);
               if (slValue < (Bid - stopLevel))
                  return (i);
            }
         }
         else
         {
            return (UpHedjeStopLoss);
         }
         break;
         
      case OP_SELL:
         slValue = GetHedjeSL(OP_SELL, DownHedjeStopLoss, false);
         if (slValue <= (Ask - stopLevel))
         {
            for (i = 3; i >= 1; i--)
            {
               slValue = GetHedjeSL(OP_SELL, UpHedjeStopLoss, false);
               if (slValue > (Ask + stopLevel))
                  return (i);
            }
         }
         else
         {
            return (DownHedjeStopLoss);
         }      
         break;
   }
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsBreakEven(int type)
{
   switch (type)
   {
      case OP_BUY:
         switch (GetOrdersCount(MagicNumberUp, OP_BUY))
         {
            case 0: 
            case 1: 
               return (false);               
            default:
               double lots = GetOrdersLots(MagicNumberUp);
               double previousProfit = GetHedjeProfit(MagicNumberUp, OP_SELL, startSessionBuy);               
               double neededProfit = lots * ProfitPerLot;                                      
               double currentProfit = GetOrdersProfit(MagicNumberUp); 
               double currentTotalProfit = currentProfit + previousProfit; 
               
               if (currentTotalProfit >= neededProfit)
                  return (true);
               
               break;
         }
         break;
         
      case OP_SELL:
         switch (GetOrdersCount(MagicNumberDown, OP_SELL))         
         {
            case 0: 
            case 1: 
               return (false);               
            default:
               lots = GetOrdersLots(MagicNumberDown);
               previousProfit = GetHedjeProfit(MagicNumberDown, OP_BUY, startSessionSell);               
               neededProfit = lots * ProfitPerLot;                                      
               currentProfit = GetOrdersProfit(MagicNumberDown); 
               currentTotalProfit = currentProfit + previousProfit;
               
               if (currentTotalProfit >= neededProfit)
                  return (true);
               
               break;   
         }
         break;
   }   


   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int TranslatePeriod(int period)
{
   switch(period)
   {
      case 1:
         return (PERIOD_M1);
      case 2:
         return (PERIOD_M5);
	  case 3:
         return (PERIOD_M15);
      case 4:
         return (PERIOD_M30);		 
      case 5:
         return (PERIOD_H1);
      case 6:
         return (PERIOD_H4);
	  case 7:
         return (PERIOD_D1);
      case 8:
         return (PERIOD_W1);	
      case 9:
         return (PERIOD_MN1);		 
      default:
         return (Period());
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int OpenOrderA(string symbol, int type, double lot, double price, int slPoints, int tpPoints, 
                  int slippage = 5, string comment = "", int magic = 42, int attempts = 5, datetime expiration = 0, color ooColor = CLR_NONE)
{
   bool
      isError = false;
   int 
      error,
      ticket;
   
   double
      sl,
      tp,      
      stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;
      
   RefreshRates();    

   // --> Check lot
   lot = NormalizeLots(lot, Symbol());
   switch (MarketInfo(Symbol(), MODE_LOTSTEP))
   {
      case 0.01: lot = NormalizeDouble(lot, 2); break;
      default: lot = NormalizeDouble(lot, 1);
   }
   // <--

   // --> Open order
   for (int i = 0; i < attempts; i++)
   {
   // --> Check price
      switch (type)
      {
         case OP_BUY:  price = Ask; break;
         case OP_SELL: price = Bid; break;
   
         case OP_BUYSTOP: 
         case OP_SELLLIMIT:
         {
            if ((price - Ask) < stopLevel)
            {
               price = Ask + stopLevel;
            }
            break;
         }
         case OP_BUYLIMIT: 
         case OP_SELLSTOP:
         {
            if ((Bid - price) < stopLevel)
            {
               price = Bid - stopLevel;
            }
            break;
         }      
      }
   
      price = NormalizeDouble(price, Digits);
      // <--      
   
       ticket = OrderSend(symbol, type, lot, price, slippage, 0, 0, comment, magic, expiration, ooColor);
       error = GetLastError();
       switch (error) 
       {
         case ERR_NO_RESULT:
         case ERR_COMMON_ERROR:
         case ERR_INVALID_PRICE:
         case ERR_PRICE_CHANGED:
         case ERR_TRADE_CONTEXT_BUSY:
         {
            isError = true;
            Sleep(500);
            continue;
         }
         default: isError = true;         
       }
    
       if (error == 0) 
       {
         isError = false;
         break;
       }
    
       if (isError) 
       {
         return (error * (-1));
       }
   }

   // -->  Check stops
   slPoints = CheckStop(slPoints, 0);   
   tpPoints = CheckStop(tpPoints);
   
   if ((slPoints == 0) && (tpPoints == 0))
   {
      return (ticket);
   }
   
   for (i = 0; i < 20; i++)
   {         
      RefreshRates();
      switch (type)
      {
         case OP_BUY:  
         {
            if (slPoints == 0) 
            {
               sl = 0;
            } 
            else
            {
               sl = NormalizeDouble(Ask - (slPoints + i) * Point, Digits);
            }
            if (tpPoints == 0) 
            {
               tp = 0;
            } 
            else
            {
               tp = NormalizeDouble(Ask + tpPoints * Point, Digits);
            }    
            break;     
         }   
         case OP_SELL:  
         {
            if (slPoints == 0) 
            {
               sl = 0;
            } 
            else
            {
               sl = NormalizeDouble(Bid + (slPoints + i) * Point, Digits);
            }
            if (tpPoints == 0) 
            {
               tp = 0;
            } 
            else
            {
               tp = NormalizeDouble(Bid - tpPoints * Point, Digits);
            }    
            break;     
         }        
         case OP_BUYLIMIT : 
         {
            if (slPoints == 0) 
            {
               sl = 0;
            } 
            else
            {
               sl = NormalizeDouble(price - slPoints * Point, Digits);
            }
            if (tpPoints == 0) 
            {
               tp = 0;
            } 
            else
            {
               tp = NormalizeDouble(price + tpPoints * Point, Digits);
            }    
            break;
         }   
         case OP_SELLLIMIT : 
         {
            if (slPoints == 0) 
            {
               sl = 0;
            } 
            else
            {
               sl = NormalizeDouble(Ask + slPoints * Point, Digits);
            }
            if (tpPoints == 0) 
            {
               tp = 0;
            } 
            else
            {
               tp = NormalizeDouble(Bid - tpPoints * Point, Digits);
            }    
            break;
         } 
         case OP_BUYSTOP : 
         {
            if (slPoints == 0) 
            {
               sl = 0;
            } 
            else
            {
               sl = NormalizeDouble(price - slPoints * Point, Digits);
            }
            if (tpPoints == 0) 
            {
               tp = 0;
            } 
            else
            {
               tp = NormalizeDouble(price + tpPoints * Point, Digits);
            }
               break;
         } 
         case OP_SELLSTOP : 
         {
            if (slPoints == 0) 
            {
               sl = 0;
            } 
            else
            {
               sl = NormalizeDouble(Ask + slPoints * Point, Digits);
            }
            if (tpPoints == 0) 
            {
               tp = 0;
            } 
            else
            {
               tp = NormalizeDouble(Bid - tpPoints * Point, Digits);
            }    
            break;
         }       
      }      
      // <--

      // --> Modify Order   

      if (OrderSelect(ticket, SELECT_BY_TICKET))
      {
         if (OrderModify(ticket, OrderOpenPrice(), sl, tp, expiration, ooColor))
         {
            return (ticket);
         }                
         else
         {                  
            error = GetLastError();
            switch (error) 
            {
               case ERR_NO_RESULT:
               case ERR_COMMON_ERROR:
               case ERR_INVALID_PRICE:
               case ERR_PRICE_CHANGED:
               case ERR_TRADE_CONTEXT_BUSY:
               case ERR_INVALID_STOPS:
               case ERR_INVALID_FUNCTION_PARAMVALUE:
               {
	              isError = true;
	              Sleep(500);
	              continue;
               }               
               default: isError = true;         
            }
         }
    
         if (error == 0) 
         {
           isError = false;
           break;
         }
    
         if (isError) 
         {
           return (error * (-1));
         }         
      }   
}
// <--
return (ticket);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool DisplayError(int DEerror)
{
   if (DEerror < 0) 
   {
      DEerror = MathAbs(DEerror); 
      switch (DEerror)
      {
         case ERR_NO_CONNECTION:
         case ERR_REQUOTE:
            return (true);
         default:
         if (ShowAlerts) 
            Alert("Error: " + ErrorDescription(DEerror));
            if (DisableEA)
            {
               isError = true;
               errorStr = "Error: " + ErrorDescription(DEerror);
            }
            return (true); 
      }
   }  
   return (false);  
}
//+------------------------------------------------------------------+

double NormalizeLots(double lots, string symbol)
{
   double lotStep = MarketInfo(symbol, MODE_LOTSTEP),
      maxLot = MarketInfo(symbol, MODE_MAXLOT),
      minLot = MarketInfo(symbol, MODE_MINLOT);  


   double lotDigits = 1;
   if (NormalizeDouble(lotStep, 2) == 0.01)
      lotDigits = 2;
   
   lots = NormalizeDouble(lots, lotDigits);
   
   double maxLotSize = AccountFreeMargin() / (MarketInfo(symbol, MODE_LOTSIZE) / AccountLeverage());
   
   if (maxLot > maxLotSize) maxLot = maxLotSize;    
   
   if (lots < minLot) lots = minLot;      
   if (lots < LotSize) lots = LotSize;      
   if (lots > maxLot) lots = maxLot; 
   
   return(lots);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int CheckStop(int Stop_pt, int stopType = 1)
{
   // 0 - SL
   // 1 - TP
   
   if (Stop_pt == 0) return (0);   
   double MinStopDist = MarketInfo(Symbol(), MODE_STOPLEVEL);
   int spread = MarketInfo(Symbol(), MODE_SPREAD);
   if (spread == 0)
   {
      spread = 1;
   }
         
   if (stopType == 0)
   {
      if (Stop_pt < (MinStopDist + spread)) Stop_pt = MinStopDist + spread;
   }   
   else
   {
      if (Stop_pt < MinStopDist) Stop_pt = MinStopDist;
   }
   return (Stop_pt);
}
//+------------------------------------------------------------------+ 

//+------------------------------------------------------------------+ 
int CheckOpen(int tick)
{
   // 1 - Open
   // 0 - Closed
   // -1 - ticket fail
   
   if(OrderSelect(tick, SELECT_BY_TICKET)) 
   {
      if(OrderCloseTime() == 0) return(1);
      return(0);
   }   
   return(-1);
}
//+------------------------------------------------------------------+ 



