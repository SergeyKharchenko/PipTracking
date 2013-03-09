//+---------------------------- ----------------------------------------+
//|                                                     PipTracking.mq4 |
//|                                        Copyright 2013, Dawud Nelson |
//|                                 Dawud Nelson <dnelson212@yahoo.com> |
//|                                                                     |
//|                                  Programmed by AirBionicFX Software |
//|                                             http://airbionicfx.com/ |
//|    Programmer Sergey Kharchenko <sergey.kharchenko@airbionicfx.com> |
//+---------------------------------------------------------------------+
#property copyright "Copyright 2013, Dawud Nelson"

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>

//--- input parameters
extern string    OrderSettings     = "------------------------------------------------";
extern bool      OpenTrades        = true;

extern string    HedgeStopLoss_Help_1 = "0 - Moving Average";
extern string    HedgeStopLoss_Help_2 = "1 - Bollinger Bands Lowest";
extern string    HedgeStopLoss_Help_3 = "2 - Bollinger Bands Medium";
extern string    HedgeStopLoss_Help_4 = "3 - Bollinger Bands Highest";
extern int       UpHedgeStopLoss      = 1;
extern int       DownHedgeStopLoss    = 3;
extern int       AdditionalSLPips     = 5;
extern int       AdditionalHedgeReenterPips = 8;

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

extern bool      UseOsMA     = true;
extern int       OsMAFastEMA = 12;
extern int       OsMASlowEMA = 9;
extern int       OsMASMA     = 26;
extern string    OsMAPrice_Help_1 = "0 - Close price";
extern string    OsMAPrice_Help_2 = "1 - Open price";
extern string    OsMAPrice_Help_3 = "2 - High price";
extern string    OsMAPrice_Help_4 = "3 - Low price";
extern string    OsMAPrice_Help_5 = "4 - Median price, (high+low)/2";
extern string    OsMAPrice_Help_6 = "5 - Typical price, (high+low+close)/3";
extern string    OsMAPrice_Help_7 = "6 - Weighted close price, (high+low+close+close)/4";
extern int       OsMAPrice        = 0;
extern double    OsMAHedgeValue   = 0.0001;

extern bool      UseAC        = true;
extern double    ACHedgeValue = 0.0001;

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
extern int       MATimeframe    = 0;
extern int       BBTimeframe    = 0;
extern int       OsMATimeframe  = 0;

extern int       ACTimeframe  = 0;

extern int       TakeProfit         = 20;
extern double    ProfitPerLot       = 30;
extern int       InitialRestrictionPips = 60;
extern int       HedgeRestrictionPips   = 60;
extern bool      UpRestrictionUse   = true;
extern bool      DownRestrictionUse = true;

extern string    LotSettings         = "------------------------------------------------";
extern double    LotSize             = 0.1;
extern double    LotExponent         = 1.5;
extern double    LotHedgeExponent    = 2.5;

extern string    StrategySettings  = "------------------------------------------------";
extern int       PipStep           = 25;
extern double    UnrealizedLoss    = 15;
extern double    CriticalLoss      = 50;

extern string    MagicNymberSettings = "------------------------------------------------";
extern string    MagicNumber_Help    = "Should be unique for all charts";
extern int       MagicNumber         = 1234;
                                
extern string    SupportSettings = "------------------------------------------------";                           
extern bool      ShowAlerts      = true;
extern bool      ShowComments    = true;
extern string    DisableEA_Help  = "If any error has occurred EA will close all positions and will be disable";
extern bool      DisableEA       = false;

// --> Global states
#define NONE        -1
#define SIMPLE       0
#define MULTIPLE     1
#define HEDGE        2
#define RESTRICTION_BUY  3
#define RESTRICTION_SELL 4
#define BREAK_EVEN       5


// --> Global sides
#define UP     0
#define DOWN   1
// 


// --> Global variables
int
   sl,
   slOp,
   ticket,
   stateUp,
   stateDown,
   hedgeWasClosedUp,
   hedgeWasClosedDown,
   hedgeCapturedSLUp,
   hedgeCapturedSLDown,
   magicUpSimple,
   magicUpMultiple,
   magicUpHedge,
   magicUpRestriction,
   magicDownSimple,
   magicDownMultiple,
   magicDownHedge,
   magicDownRestriction;
   
bool 
   work = true,
   isError = false,
   debug = false,
   preDebug = false;   
   
double
   lot,
   startLot,
   startMoneyUp,
   startMoneyDown;   
   
string 
   errorStr,
   saveFileName;        
    
datetime
   startSessionUp,
   startSessionDown;
    
// <--
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
//----
   if ((Digits == 5) || (Digits == 3))
   {
	  TakeProfit *= 10;
	  PipStep *= 10;	  
	  AdditionalSLPips *= 10;
	  AdditionalHedgeReenterPips *= 10;
	  InitialRestrictionPips *= 10;
	  HedgeRestrictionPips *= 10;
   }

   if (MagicNumber <= 0) 
   {
      if (ShowAlerts)
         Alert("MagicNumber is invalid");
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
   
   if (LotHedgeExponent < 1) {
      if (ShowAlerts) {
         Alert("LotHedgeExponent is invalid");
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
   
   if ((UpHedgeStopLoss < 0) || (UpHedgeStopLoss > 3)) {
      if (ShowAlerts) {
         Alert("UpHedgeStopLoss is invalid");
      }   
      work = false;
      return; 
   }       

   if ((DownHedgeStopLoss < 0) || (DownHedgeStopLoss > 3)) {
      if (ShowAlerts) {
         Alert("DownHedgeStopLoss is invalid");
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
   
   if (OsMAFastEMA < 1) {
      if (ShowAlerts) {
         Alert("OsMAFastEMA is invalid");
      }   
      work = false;
      return; 
   }    
   
   if (OsMASlowEMA < 1) {
      if (ShowAlerts) {
         Alert("OsMASlowEMA is invalid");
      }   
      work = false;
      return; 
   }    
   
   if (OsMASMA < 1) {
      if (ShowAlerts) {
         Alert("OsMASMA is invalid");
      }   
      work = false;
      return; 
   }     
   
   if ((OsMATimeframe < 0) || (OsMATimeframe > 9)) {
      if (ShowAlerts) {
         Alert("OsMA is invalid");
      }   
      work = false;
      return; 
   }   
   
   if ((ACTimeframe < 0) || (ACTimeframe > 9)) {
      if (ShowAlerts) {
         Alert("ACTimeframe is invalid");
      }   
      work = false;
      return; 
   }  
   
   if (CriticalLoss <= 0) {
      if (ShowAlerts) {
         Alert("CriticalLoss is invalid");
      }   
      work = false;
      return; 
   }    
   
   if ((InitialRestrictionPips * Point) < (Ask - Bid)) {
      if (ShowAlerts) {
         Alert("InitialRestrictionPips should be more than spread");
      }   
      work = false;
      return; 
   }    
   
   if ((HedgeRestrictionPips * Point) < (Ask - Bid)) {
      if (ShowAlerts) {
         Alert("HedgeRestrictionPips should be more than spread");
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
   
   isError = false;
   
   stateUp  = NONE;
   stateDown = NONE;
   
   startMoneyUp = -1;
   startMoneyDown = -1;
   startSessionUp = -1;
   startSessionDown = -1;       
   hedgeWasClosedUp = -1;
   hedgeWasClosedDown = -1;
   hedgeCapturedSLUp = UpHedgeStopLoss;
   hedgeCapturedSLDown = DownHedgeStopLoss;
   MATimeframe = TranslatePeriod(MATimeframe);
   BBTimeframe = TranslatePeriod(BBTimeframe);
   OsMATimeframe = TranslatePeriod(OsMATimeframe);
   ACTimeframe = TranslatePeriod(ACTimeframe);
   
   int magic = MagicNumber * 10;
   magicUpSimple = magic;
   magicUpMultiple = magic + 1;
   magicUpHedge = magic + 2;
   magicUpRestriction = magic + 3;
   magicDownSimple = magic + 4;
   magicDownMultiple = magic + 5;
   magicDownHedge = magic + 6; 
   magicDownRestriction = magic + 7;
   
   saveFileName = Symbol() + " " + MagicNumber + ".csv";
   
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
      startMoneyUp = -1;
      startMoneyDown = -1;
      startSessionUp = -1;
      startSessionDown = -1;       
      hedgeWasClosedUp = -1;
      hedgeWasClosedDown = -1;
      hedgeCapturedSLUp = UpHedgeStopLoss;
      hedgeCapturedSLDown = DownHedgeStopLoss;
   }   
   else
   {
      if (IsCriticalLoss(UP))
      {
         Alert("You have reached critical loss by Buy side");
         isError = true;
         start();
         return;
      }
      
      if (IsCriticalLoss(DOWN))
      {
         Alert("You have reached critical loss by Sell side");
         isError = true;
         start();
         return;
      }      
   
      SaveSession();
      
      // --> Buy    
      if (GetOrdersCountBySide(UP) == 0)
         stateUp = NONE;        

      if ((stateUp == HEDGE) || (stateUp == RESTRICTION_SELL))
      {
         if ((GetOrdersCount(magicUpHedge, OP_SELL) > 0) || (GetOrdersCount(magicUpRestriction, OP_SELL) > 0))
         {
            TrailingHedgeByIndicatorLine(magicUpHedge, OP_SELL); 
            TrailingHedgeByIndicatorLine(magicUpRestriction, OP_SELL); 
         }   
         else
         {
            hedgeWasClosedUp = 1;
         }  
      }
       
      if (stateUp == BREAK_EVEN)  
      {
         GlobalTrailing(UP);
      }
      else   
      {     
         if (IsBreakEven(UP))
         {
            stateUp = BREAK_EVEN;    
            GlobalTrailing(UP);   
         }      
         else
         {   
            if (IsTakeProfitForSimpleState(UP))
               TryClose(magicUpSimple, OP_BUY);
               
            if (OpenTrades)
            {
               int state = IsOpen(UP);
               if (state != -1)
               {
                  stateUp = state;
                  lot = CalculateLotByState(UP, stateUp);                 
                  
                  switch (stateUp)
                  {              
                     case SIMPLE: 
                        startMoneyUp = AccountBalance();  
                        startSessionUp = TimeCurrent();
                        hedgeWasClosedUp = -1;
                        ticket = OpenOrderA(Symbol(), OP_BUY, startLot, Ask, sl, 0, 100, NULL, magicUpSimple, 5, 0, Lime);  
                        if (DisplayError(ticket))
                           stateUp = NONE;
                        break;

                     case MULTIPLE:
                        ticket = OpenOrderA(Symbol(), OP_BUY, lot, Ask, sl, 0, 100, NULL, magicUpMultiple, 5, 0, Lime);  
                        if (DisplayError(ticket))
                           stateUp = NONE;
                        break;

                     case HEDGE:
                     case RESTRICTION_SELL:
                        if (lot == -1) 
                           break;
                        hedgeWasClosedUp = 0;
                        double slValue = GetHedgeSL(hedgeCapturedSLUp, AdditionalSLPips);
                        slOp = CastSLToPoints(slValue, OP_SELL);      
                        int magicHedge = magicUpHedge;
                        if (stateUp == RESTRICTION_SELL)
                           magicHedge = magicUpRestriction;                                 
                                                            
                        ticket = OpenOrderA(Symbol(), OP_SELL, lot, Bid, slOp, 0, 100, NULL, magicHedge, 5, 0, Red);  
                        if (DisplayError(ticket))
                           stateUp = NONE;
                        break;   
                        
                     case RESTRICTION_BUY:
                        if (lot == -1) 
                           break;
                        ticket = OpenOrderA(Symbol(), OP_BUY, lot, Ask, sl, 0, 100, NULL, magicUpRestriction, 5, 0, Lime);  
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
      if (GetOrdersCountBySide(DOWN) == 0)
         stateDown = NONE;

      if (stateDown == HEDGE)
      {
         if ((GetOrdersCount(magicDownHedge, OP_BUY) > 0) || (GetOrdersCount(magicDownRestriction, OP_BUY) > 0))
         {
            TrailingHedgeByIndicatorLine(magicDownHedge, OP_BUY); 
            TrailingHedgeByIndicatorLine(magicDownRestriction, OP_BUY); 
         }   
         else
         {
            hedgeWasClosedDown = 1;
         }  
      }   
   
      if (stateDown == BREAK_EVEN)   
      {
         GlobalTrailing(DOWN);  
      }
      else
      {
         if (IsBreakEven(DOWN))
         {
            stateDown = BREAK_EVEN; 
            GlobalTrailing(DOWN);     
            startSessionDown = -1;      
         }      
         else
         {            
            if (IsTakeProfitForSimpleState(DOWN))
               TryClose(magicDownSimple, OP_SELL);
      
            if (OpenTrades)
            {
               state = IsOpen(DOWN);
               if (state != -1)
               {
                  stateDown = state;
                  lot = CalculateLotByState(DOWN, stateDown);
                  switch (stateDown)
                  {              
                     case SIMPLE: 
                        startMoneyDown = AccountBalance();  
                        startSessionDown = TimeCurrent();
                        hedgeWasClosedDown = -1;
                        ticket = OpenOrderA(Symbol(), OP_SELL, startLot, Bid, sl, 0, 100, NULL, magicDownSimple, 5, 0, Red);  
                        if (DisplayError(ticket))
                           stateDown = NONE;
                        break;

                     case MULTIPLE:
                        ticket = OpenOrderA(Symbol(), OP_SELL, lot, Bid, sl, 0, 100, NULL, magicDownMultiple, 5, 0, Red);  
                        if (DisplayError(ticket))
                           stateDown = NONE;
                        break;

                     case HEDGE:
                     case RESTRICTION_BUY:
                        if (lot == -1) 
                           break;                     
                        hedgeWasClosedDown = 0;
                        slValue = GetHedgeSL(hedgeCapturedSLDown, -AdditionalSLPips);
                        slOp = CastSLToPoints(slValue, OP_BUY);     
                        magicHedge = magicDownHedge;
                        if (stateUp == RESTRICTION_SELL)
                           magicHedge = magicDownRestriction;                                         
                        ticket = OpenOrderA(Symbol(), OP_BUY, lot, Ask, slOp, 0, 100, NULL, magicHedge, 5, 0, Lime);  
                        if (DisplayError(ticket))
                           stateDown = NONE; 
                        break;
                        
                     case RESTRICTION_SELL:
                        if (lot == -1) 
                           break;                        
                        ticket = OpenOrderA(Symbol(), OP_SELL, lot, Bid, sl, 0, 100, NULL, magicDownRestriction, 5, 0, Red);  
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


//=========================================================================================================
// Open order logic part
//=========================================================================================================

//+------------------------------------------------------------------+
int IsOpen(int side)
{
   RefreshRates();
   switch (side)
   {
      case UP:            
         if ((GetOrdersCount(magicUpHedge, OP_SELL) == 0) && (GetOrdersCount(magicUpRestriction, OP_SELL) == 0))   // No Hedge order
         {            
            if (GetOrdersCountBySide(UP) == 0)
               return (SIMPLE);      
               
            if (hedgeWasClosedUp == -1)  // First hedge
            {
               if (IsUnrealizedLoss(UP))
               {
                  int hedgeSLMode = GetHedgeIndicatorLine(UP);
                  if ((hedgeSLMode != -1) 
                      && IsIndicatorsAllowHedge(UP))
                  {
                     hedgeCapturedSLUp = hedgeSLMode;
                     return (HEDGE);
                  }
               }     
               else
               {   
                  double lastOrderOpenPrice = MathMinBlocked(GetLastOrderOpenPrice(magicUpSimple, OP_BUY),
                                                             GetLastOrderOpenPrice(magicUpMultiple, OP_BUY), -1);                                                        
                                                      
                  if (((Ask + PipStep * Point) <= lastOrderOpenPrice) && (lastOrderOpenPrice != -1))
                     return (MULTIPLE);      
               }                 
            }
            else  // Not first hedge
            {               
               double simpleOrderOpenPrice = GetLastOrderOpenPrice(magicUpSimple, OP_BUY);
               if ((Ask > simpleOrderOpenPrice) && !IsLastRestrictionOrderSameType(UP, OP_BUY, startSessionUp))
                  return (RESTRICTION_BUY);
                                   
            
               bool isOpen = false;
               double lastHedgeOpenPrice = GetLastHedgeOpenPrice(magicUpHedge, OP_SELL, startSessionUp);
               if ((Bid < lastHedgeOpenPrice)
                   && (Bid < GetHedgeSL(hedgeCapturedSLUp, -AdditionalHedgeReenterPips))
                   && IsIndicatorsAllowHedge(UP))
                  isOpen = true;  
               
               if (isOpen)                  
                  if (!hedgeWasClosedUp || !UpRestrictionUse)
                     return (HEDGE);
                  else
                     return (RESTRICTION_SELL);
            }
         }
         break;
         
      case DOWN:        
         if ((GetOrdersCount(magicDownHedge, OP_BUY) == 0) && (GetOrdersCount(magicDownRestriction, OP_BUY) == 0))  // No hedge order
         {
            if (GetOrdersCountBySide(DOWN) == 0)
               return (SIMPLE);
         
            if (hedgeWasClosedDown == -1)  // First hedge
            {
               if (IsUnrealizedLoss(DOWN))
               {                                   
                  hedgeSLMode = GetHedgeIndicatorLine(DOWN);                   
                  if ((hedgeSLMode != -1)                  
                      && IsIndicatorsAllowHedge(DOWN))
                  {
                     hedgeCapturedSLDown = hedgeSLMode;
                     return (HEDGE);
                  }
               }      
               else
               {               
                  lastOrderOpenPrice = MathMax(GetLastOrderOpenPrice(magicDownSimple, OP_SELL),
                                               GetLastOrderOpenPrice(magicDownMultiple, OP_SELL));
                  if ((Bid - PipStep * Point) >= lastOrderOpenPrice)
                     return (MULTIPLE);   
               }                 
            }
            else  // Not first hedge
            {                
               simpleOrderOpenPrice = GetLastOrderOpenPrice(magicDownSimple, OP_SELL);
               if ((Bid < simpleOrderOpenPrice) && !IsLastRestrictionOrderSameType(DOWN, OP_SELL, startSessionDown))
                  return (RESTRICTION_SELL);  
            
               isOpen = false;
               lastHedgeOpenPrice = GetLastHedgeOpenPrice(magicDownHedge, OP_BUY, startSessionDown);
               if ((Ask > lastHedgeOpenPrice)
                   && (Ask > GetHedgeSL(hedgeCapturedSLDown, AdditionalHedgeReenterPips))
                   && IsIndicatorsAllowHedge(DOWN))
                     isOpen = true;
                     
               if (isOpen)                  
                  if (!hedgeWasClosedUp || !DownRestrictionUse)
                     return (HEDGE);
                  else
                     return (RESTRICTION_BUY);                     
            }
         }
         break;         
   }
   return (-1);
}
//+------------------------------------------------------------------+


//=========================================================================================================
// Logic part
//=========================================================================================================

//+------------------------------------------------------------------+
double CalculateLotByState(int side, int state)
{
   switch (side)
   {
      case UP:
         switch (state)
         {              
            case MULTIPLE:
               double lastOrderLots = MathMax(GetLastOrderLots(magicUpSimple, OP_BUY),
                                              GetLastOrderLots(magicUpMultiple, OP_BUY));
               return (NormalizeLots(lastOrderLots * LotExponent, Symbol()));           
            case HEDGE:
               return (NormalizeLots(GetOrdersLotsBySide(UP) * LotHedgeExponent, Symbol()));  
            case RESTRICTION_SELL:
               double lots = GetRestrictionLots(side, OP_SELL, Ask - HedgeRestrictionPips*Point, ProfitPerLot);
               if (lots < 0) return (-1);
               return (NormalizeLots(lots, Symbol()));    
            case RESTRICTION_BUY:
               lots = GetRestrictionLots(side, OP_BUY, Bid + InitialRestrictionPips*Point, ProfitPerLot);
               if (lots < 0) return (-1);
               return (NormalizeLots(lots, Symbol()));                                                  
         }
      case DOWN:
         switch (state)
         {           
            case MULTIPLE:
               lastOrderLots = MathMax(GetLastOrderLots(magicDownSimple, OP_SELL),
                                       GetLastOrderLots(magicDownMultiple, OP_SELL));            
               return (NormalizeLots(lastOrderLots * LotExponent, Symbol()));
            case HEDGE:
               return (NormalizeLots(GetOrdersLotsBySide(DOWN) * LotHedgeExponent, Symbol()));
            case RESTRICTION_BUY:
               lots = GetRestrictionLots(side, OP_BUY, Bid + HedgeRestrictionPips*Point, ProfitPerLot);
               if (lots < 0) return (-1);
               return (NormalizeLots(lots, Symbol())); 
            case RESTRICTION_SELL:
               lots = GetRestrictionLots(side, OP_SELL, Ask - InitialRestrictionPips*Point, ProfitPerLot);    
               if (lots < 0) return (-1);        
               return (NormalizeLots(lots, Symbol()));                                               
         }
   }   
   return (startLot); 
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsBreakEven(int side)
{
   double
      lots = GetOrdersLotsBySide(side),
      currentProfit = GetOrdersProfitBySide(side);
      
   switch (side)
   {
      case UP:
         switch (GetOrdersCountBySide(UP))
         {
            case 0: 
            case 1: 
               return (false);               
            default:
					
               if (GetOrdersCount(magicUpRestriction, OP_SELL) > 0)
               {
                  double balanceOrderOpenPrice = GetLastOrderOpenPrice(magicUpRestriction, OP_SELL);
                  if (Bid >= (balanceOrderOpenPrice + HedgeRestrictionPips*Point))
                     return (true);
               }
               
               if (GetOrdersCount(magicUpRestriction, OP_BUY) > 0)
               {
                  balanceOrderOpenPrice = GetLastOrderOpenPrice(magicUpRestriction, OP_BUY);
                  if (Ask <= (balanceOrderOpenPrice - HedgeRestrictionPips*Point))
                     return (true);
               }                 
               
               double 
                  previousProfit = GetHedgeProfitFromHistory(UP, startSessionUp),             
                  neededProfit = lots * ProfitPerLot,       
                  currentTotalProfit = currentProfit + previousProfit; 
            
               if (currentTotalProfit >= neededProfit)
                  return (true);
               break;
         }
         break;
         
      case DOWN:
         switch (GetOrdersCountBySide(DOWN))         
         {
            case 0: 
            case 1: 
               return (false);               
            default:
               if (GetOrdersCount(magicDownRestriction, OP_BUY) > 0)
               {
                  balanceOrderOpenPrice = GetLastOrderOpenPrice(magicDownRestriction, OP_BUY);
                  if (Bid >= (balanceOrderOpenPrice + HedgeRestrictionPips*Point))
                     return (true);
               }        
               
               if (GetOrdersCount(magicDownRestriction, OP_SELL) > 0)
               {
                  balanceOrderOpenPrice = GetLastOrderOpenPrice(magicDownRestriction, OP_SELL);
                  if (Ask <= (balanceOrderOpenPrice - InitialRestrictionPips*Point))
                     return (true);
               }                
               
               previousProfit = GetHedgeProfitFromHistory(DOWN, startSessionDown);               
               neededProfit = lots * ProfitPerLot;         
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
void GlobalTrailing(int side, int attempts = 10)
{
   for(int j = OrdersTotal() - 1; j >= 0; j--)
   {
      if (OrderSelect(j, SELECT_BY_POS))
      {
         if (OrderSymbol() != Symbol())
            continue;      
         if (side == UP)
         {
            if ((OrderMagicNumber() != magicUpSimple) 
                && (OrderMagicNumber() != magicUpMultiple)
                && (OrderMagicNumber() != magicUpHedge)
                && (OrderMagicNumber() != magicUpRestriction))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicDownSimple) 
                && (OrderMagicNumber() != magicDownMultiple)
                && (OrderMagicNumber() != magicDownHedge)
                && (OrderMagicNumber() != magicDownRestriction))
               continue;   
         }             
         
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
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsTakeProfitForSimpleState(int side)
{
   switch (side)
   {
      case UP:
         switch (GetOrdersCount(magicUpSimple, OP_BUY))
         {
            case 0: return (false);
            case 1: 
               if (Bid >= (GetLastOrderOpenPrice(magicUpSimple, OP_BUY) + TakeProfit * Point))
                  return (true);
               break;
         }
         break;
         
      case DOWN:
         switch (GetOrdersCount(magicDownSimple, OP_SELL))         
         {
            case 0: return (false);
            case 1: 
               if (Ask <= (GetLastOrderOpenPrice(magicDownSimple, OP_SELL) - TakeProfit * Point))
                  return (true);
               break;               
         }
         break;
   }      

   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsIndicatorsAllowHedge(int side)
{
   return ((IsOsMAAllowHedge(side) || !UseOsMA)
           && (IsACAllowHedge(side) || !UseAC));
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsOsMAAllowHedge(int side)
{
   double osma = iOsMA(Symbol(), OsMATimeframe, OsMAFastEMA, OsMASlowEMA, OsMASMA, OsMAPrice, 0);
   switch (side)
   {
      case UP:
         return (osma <= -OsMAHedgeValue);
      case DOWN:
         return (osma >= OsMAHedgeValue);         
   }
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsACAllowHedge(int side)
{
   double ac = iAC(Symbol(), ACTimeframe, 0);
   switch (side)
   {
      case UP:
         return (ac <= -ACHedgeValue);
      case DOWN:
         return (ac >= ACHedgeValue);         
   }
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int GetHedgeIndicatorLine(int side)
{
   double
      stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

   switch (side)
   {        
      case UP:
         double slValue = GetHedgeSL(DownHedgeStopLoss, AdditionalHedgeReenterPips);                  
         if (slValue < (Ask + stopLevel))
         {
            for (int i = 3; i >= 1; i--)
            {
               slValue = GetHedgeSL(UpHedgeStopLoss, AdditionalHedgeReenterPips);
               if (slValue > (Ask + stopLevel))
                  return (i);
            }
         }
         else
         {
            return (DownHedgeStopLoss);
         }      
         break;
         
      case DOWN:
         slValue = GetHedgeSL(UpHedgeStopLoss, -AdditionalHedgeReenterPips);
         if (slValue >= (Bid + stopLevel))
         {
            for (i = 1; i <= 3; i++)
            {
               slValue = GetHedgeSL(UpHedgeStopLoss, -AdditionalHedgeReenterPips);
               if (slValue < (Bid - stopLevel))
                  return (i);
            }
         }
         else
         {
            return (UpHedgeStopLoss);
         }
         break;         
   }
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetHedgeSL(int hedgeStopLoss, int additionalPips)
{
   double iValue;
   switch (hedgeStopLoss)
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
     
   iValue += additionalPips * Point;
   return (iValue);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void TrailingHedgeByIndicatorLine(int magic, int type, int attempts = 5)
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
                  double slValue = GetHedgeSL( hedgeCapturedSLDown, -AdditionalSLPips);                                    
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
                  slValue = GetHedgeSL(hedgeCapturedSLUp, AdditionalSLPips);
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
bool IsUnrealizedLoss(int side)
{
   double loss = GetTargetLossByPercent(side, UnrealizedLoss);
   loss *= -1;
   if (GetOrdersProfitBySide(side) <= loss)
      return (true);
      
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsCriticalLoss(int side)
{
   double loss = GetTargetLossByPercent(side, CriticalLoss);
   loss *= -1;
   
   double totalProfit = 0;
   switch (side)
   {
      case UP:
         totalProfit += GetHedgeProfitFromHistory(UP, startSessionUp);
         break;
      case DOWN:
         totalProfit += GetHedgeProfitFromHistory(DOWN, startSessionDown);
         break;  
   }
   totalProfit += GetOrdersProfitBySide(side);
   
   if ((MathAbs(totalProfit) < Point) || (MathAbs(loss) < Point))
      return (false);
   
   if (totalProfit <= loss)
      return (true);
      
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetTargetLossByPercent(int side, double percent)
{
   double loss = 0; 
   switch (side)
   {
      case UP:
         if (startMoneyUp == -1)
            loss = 0;     
         else
            loss = startMoneyUp * (percent / 100);
         break;
         
      case DOWN:
         if (startMoneyDown == -1)
            loss = 0;
         else
            loss = startMoneyDown * (percent / 100);         
         break;
   }   
   return (loss);
}
//+------------------------------------------------------------------+


//=========================================================================================================
// Find orders part
//=========================================================================================================

//+------------------------------------------------------------------+
int GetLastOrderTicket(int magic, int type, int mode)
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
int GetOrdersCountBySide(int side)
{
   int count = 0;
   switch (side)
   {
      case UP:
         count = GetOrdersCount(magicUpSimple, OP_BUY)
                 + GetOrdersCount(magicUpMultiple, OP_BUY)
                 + GetOrdersCount(magicUpHedge, OP_SELL)
                 + GetOrdersCount(magicUpRestriction, OP_SELL)
                 + GetOrdersCount(magicUpRestriction, OP_BUY);   
         break;   
      case DOWN:
         count = GetOrdersCount(magicDownSimple, OP_SELL)
                 + GetOrdersCount(magicDownMultiple, OP_SELL)
                 + GetOrdersCount(magicDownHedge, OP_BUY)
                 + GetOrdersCount(magicDownRestriction, OP_BUY)
                 + GetOrdersCount(magicDownRestriction, OP_SELL);   
         break;                     
   }
   
   return (count);            
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
double GetOrdersProfitBySide(int side)
{
   double profit = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderSymbol() != Symbol()) continue; 
         if (side == UP)
         {
            if ((OrderMagicNumber() != magicUpSimple) 
                && (OrderMagicNumber() != magicUpMultiple)
                && (OrderMagicNumber() != magicUpHedge)
                && (OrderMagicNumber() != magicUpRestriction))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicDownSimple) 
                && (OrderMagicNumber() != magicDownMultiple)
                && (OrderMagicNumber() != magicDownHedge)
                && (OrderMagicNumber() != magicDownRestriction))
               continue;   
         }                                   
         profit += OrderProfit();
      }
   }
         
   return (profit);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetOrdersLotsBySide(int side)
{
   double lots = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderSymbol() != Symbol()) continue;
         if (side == UP)
         {            
            if ((OrderMagicNumber() != magicUpSimple) 
                && (OrderMagicNumber() != magicUpMultiple)
                && (OrderMagicNumber() != magicUpHedge)
                && (OrderMagicNumber() != magicUpRestriction))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicDownSimple) 
                && (OrderMagicNumber() != magicDownMultiple)
                && (OrderMagicNumber() != magicDownHedge)
                && (OrderMagicNumber() != magicDownRestriction))
               continue;   
         } 
         lots += OrderLots();
      }
   }
         
   return (lots);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetHedgeProfitFromHistory(int side, datetime time)
{
   double profit = 0;      
   
   for (int i = OrdersHistoryTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if (OrderSymbol() != Symbol()) continue;
         switch (side)  
         {
            case UP:
               if ((OrderMagicNumber() != magicUpHedge)
                   && (OrderMagicNumber() != magicUpRestriction))
                  continue;
               if (OrderType() != OP_SELL)   
                  continue;
               break;
            case DOWN:
               if ((OrderMagicNumber() != magicDownHedge)
                   && (OrderMagicNumber() != magicDownRestriction))
                  continue;
               if (OrderType() != OP_BUY)   
                  continue;
               break;               
         }
         if ((OrderOpenTime() < time) || (time == -1)) continue;
         profit = profit + OrderProfit();
      }
   }

   return (profit);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetLastHedgeOpenPrice(int magic, int type, datetime time)
{
   int ticket = GetLastOrderTicket(magic, type, MODE_HISTORY);
	if (OrderSelect(ticket, SELECT_BY_TICKET)) 
		if (OrderOpenTime() > time)
			return (OrderOpenPrice());
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetLastOrderOpenPrice(int magic, int type)
{    
   int ticket = GetLastOrderTicket(magic, type, MODE_TRADES);
	if (OrderSelect(ticket, SELECT_BY_TICKET))      
		return (OrderOpenPrice());
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetLastHedgeOrderStopLoss(int magic, int type)
{
   int ticket = GetLastOrderTicket(magic, type, MODE_TRADES);
	if (OrderSelect(ticket, SELECT_BY_TICKET))      
		return (OrderStopLoss());
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetLastOrderLots(int magic, int type)
{
   int ticket = GetLastOrderTicket(magic, type, MODE_TRADES);
   if (OrderSelect(ticket, SELECT_BY_TICKET))                        
      return (OrderLots());
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsLastRestrictionOrderSameType(int side, int orderType, datetime time)
{	
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS))
         continue;
			
      switch (side)
      {
         case UP:
            if (OrderMagicNumber() != magicUpRestriction) continue; 
            break;
         case DOWN:
            if (OrderMagicNumber() != magicDownRestriction) continue; 
            break;         
      }
                                   
      if ((OrderOpenTime() < time) || (time == -1)) continue;
      return (OrderType() == orderType);
   }
   return (false);
} 
//+------------------------------------------------------------------+ 


//=========================================================================================================
// Support part
//=========================================================================================================

//+------------------------------------------------------------------+
void LoadSession()
{
   int handle;
   handle = FileOpen(saveFileName, FILE_CSV | FILE_READ,';');   
   if(handle > 0)
   {
      stateUp = FileReadNumber(handle);
      startMoneyUp = FileReadNumber(handle);
      startSessionUp = FileReadNumber(handle);
      hedgeWasClosedUp = FileReadNumber(handle);   
      hedgeCapturedSLUp = FileReadNumber(handle); 
      
      stateDown = FileReadNumber(handle);
      startMoneyDown = FileReadNumber(handle);
      startSessionUp = FileReadNumber(handle);
      hedgeWasClosedDown = FileReadNumber(handle); 
      hedgeCapturedSLDown = FileReadNumber(handle); 
      FileClose(handle);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void SaveSession()
{
   int handle;
   handle = FileOpen(saveFileName, FILE_CSV | FILE_WRITE,';');
   if(handle > 0)
   {
      FileWrite(handle, 
               stateUp, startMoneyUp, startSessionUp, hedgeWasClosedUp, hedgeCapturedSLUp,
               stateDown, startMoneyDown, startSessionDown, hedgeWasClosedDown, hedgeCapturedSLDown);
      FileClose(handle);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetRestrictionLots(int side, int orderType, double targetPrice, double perLot)
{
   double priceDistance = 0;
   switch (orderType)
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
	double targetProfit = GetOrdersLotsBySide(side) * perLot;
	double currentProfitOnExit = GetTotalProfitForRestriction(side, targetPrice);
	double lotsAmount = (targetProfit - currentProfitOnExit) / profitFromOneLot;	
	return (lotsAmount);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetTotalProfitForRestriction(int side, double targetPrice)
{
   double profit = 0;
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS))
         continue;
         
      if (OrderSymbol() != Symbol()) continue;
      if (side == UP)
      {            
         if ((OrderMagicNumber() != magicUpSimple) 
             && (OrderMagicNumber() != magicUpMultiple)
             && (OrderMagicNumber() != magicUpHedge)
             && (OrderMagicNumber() != magicUpRestriction))
            continue;   
      }     
      if (side == DOWN)
      {
         if ((OrderMagicNumber() != magicDownSimple) 
             && (OrderMagicNumber() != magicDownMultiple)
             && (OrderMagicNumber() != magicDownHedge)
             && (OrderMagicNumber() != magicDownRestriction))
            continue;   
      }          
         
      double spread = 0;   
      switch (side)
      {
         case UP:
            if (OrderType() == OP_SELL)
               spread = Ask - Bid;
            break;
         case DOWN:
            if (OrderType() == OP_BUY)
               spread = Bid - Ask;
            break;            
      }
      
      profit += GetOrderTargetProfitInCurrency(OrderTicket(), targetPrice + spread);      
   }
   
   return (profit);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetOrderTargetProfitInCurrency(int ticket, double targetPrice)
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
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double MathMinBlocked(double x, double y, double blocked)
{
   double value = MathMin(x, y);
   if (value != blocked)
      return (value);
   if (x != blocked)   
      return (x);
   if (y != blocked)   
      return (y);
   return (blocked);   
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
void CloseAllOrders()
{
   TryClose(magicUpSimple, OP_BUY);
   TryClose(magicUpMultiple, OP_BUY);
   TryClose(magicUpHedge, OP_SELL);
   
   TryClose(magicDownSimple, OP_SELL);
   TryClose(magicDownMultiple, OP_SELL);
   TryClose(magicDownHedge, OP_BUY);  
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool TryClose(int magic, int type) 
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {      
         if (OrderMagicNumber() != magic)
            continue;
            
         int k = 0;
         while(k < 5)
         {
            RefreshRates();
            if (OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 100)) 
            {
               return (true);
            }   
            k++;
         }             
      }
   }
   return (false);
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


//=========================================================================================================
// Statistics part
//=========================================================================================================

//+------------------------------------------------------------------+
void ShowStatistics()
{
   string comment = "\nPipTracking\n\nAccount balance: " + DoubleToStr(AccountBalance(), 2) + "\n";
   if (isError)
   {
      comment = comment + errorStr + "\n"; 
   }
   else
   {
      string upSideComment;
   
      double currentTotalProfitUp;            
      switch (stateUp)
      {
         case SIMPLE:
            upSideComment = "     Target take profit: " + DoubleToStr(GetLastOrderOpenPrice(magicUpSimple, OP_BUY) + TakeProfit * Point, Digits) + "\n";
            double targetUnresizedLoss = startMoneyUp - GetTargetLossByPercent(UP, UnrealizedLoss);
            upSideComment = upSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\n";
            currentTotalProfitUp = GetOrdersProfitBySide(UP);
            break;
         case BREAK_EVEN:   
            upSideComment = "     In Break even\n";      
            currentTotalProfitUp = GetOrdersProfitBySide(UP);
            break;
         case MULTIPLE:
            currentTotalProfitUp = GetOrdersProfitBySide(UP);                                            
            upSideComment = "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(UP) * ProfitPerLot, 2) + " $\n";
            targetUnresizedLoss = startMoneyUp - GetTargetLossByPercent(UP, UnrealizedLoss);
            upSideComment = upSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\n";                                         
            break;   
            
         case HEDGE:             
         case RESTRICTION_SELL:    
         case RESTRICTION_BUY: 
            double currentProfit = GetOrdersProfitBySide(UP); 
            double previousProfit = GetHedgeProfitFromHistory(UP, startSessionUp);                 
            currentTotalProfitUp = currentProfit + previousProfit;
                                       
            upSideComment = "     Live profit: " + DoubleToStr(currentProfit, 2) + " $\n"; 
            upSideComment = upSideComment + "     Balance of previous hedge orders: " + DoubleToStr(previousProfit, 2) + " $\n";                 
            upSideComment = upSideComment + "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(UP) * ProfitPerLot, 2) + " $\n";                 
            upSideComment = upSideComment + "     Stop loss uses: " + StopLossModeToString(hedgeCapturedSLUp) + "\n";
         
            bool isHedgeOrderExist = GetOrdersCount(magicUpHedge, OP_SELL) != 0;
            if ((hedgeWasClosedUp == 1) && !isHedgeOrderExist)
            {
               upSideComment = upSideComment + "     Hedge previous price: " + DoubleToStr(GetLastHedgeOpenPrice(magicUpHedge, OP_SELL, startSessionUp), Digits) + "\n";                                        
               upSideComment = upSideComment + "     Hedge indicator price: " + DoubleToStr(GetHedgeSL(hedgeCapturedSLUp, -AdditionalHedgeReenterPips), Digits) + "\n";                            
            }   
            if (isHedgeOrderExist)
               upSideComment = upSideComment + "     Hedge stop loss: " + DoubleToStr(GetLastHedgeOrderStopLoss(magicUpHedge, OP_SELL), Digits) + "\n";                                                                                        
               
            double lotsBalance = -1;   
            if (stateUp == RESTRICTION_SELL) 
               lotsBalance = GetLastOrderLots(magicUpRestriction, OP_SELL);
            if (stateUp == RESTRICTION_BUY)   
               lotsBalance = GetLastOrderLots(magicUpRestriction, OP_BUY);
            if (lotsBalance != -1)
               upSideComment = upSideComment + "     Restriction lots: " + DoubleToStr(lotsBalance, 2) + "\n";
            break;   
      }
      double targetCriticalLoss = startMoneyUp - GetTargetLossByPercent(UP, CriticalLoss);
      upSideComment = upSideComment + "     Target critical loss: " + DoubleToStr(targetCriticalLoss, 2) + "\n";        


      string downSideComment;
      
      double currentTotalProfitDown;      
      switch (stateDown)
      {
         case SIMPLE:
            downSideComment = "     Target take profit: " + DoubleToStr(GetLastOrderOpenPrice(magicDownSimple, OP_SELL) - TakeProfit * Point, Digits) + "\n";
            targetUnresizedLoss = startMoneyDown - GetTargetLossByPercent(DOWN, UnrealizedLoss);
            downSideComment = downSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\n";               
            currentTotalProfitDown = GetOrdersProfitBySide(DOWN);
            break;
         case BREAK_EVEN:   
            downSideComment = "     In Break even\n";
            currentTotalProfitDown = GetOrdersProfitBySide(DOWN);
            break;
         case MULTIPLE:
            currentTotalProfitDown = GetOrdersProfitBySide(DOWN);
            downSideComment = "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(DOWN) * ProfitPerLot, 2) + " $\n";
            targetUnresizedLoss = startMoneyDown - GetTargetLossByPercent(DOWN, UnrealizedLoss);
            downSideComment = downSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\n";                  
            break;                 
         case HEDGE:           
         case RESTRICTION_BUY:  
         case RESTRICTION_SELL: 
            currentProfit = GetOrdersProfitBySide(DOWN);              
            previousProfit = GetHedgeProfitFromHistory(DOWN, startSessionDown);               
            currentTotalProfitDown = currentProfit + previousProfit;                                                          
                                  
            downSideComment = "     Live profit: " + DoubleToStr(currentProfit, 2) + " $\n";                       
            downSideComment = downSideComment + "     Balance of previous hedge orders: " + DoubleToStr(previousProfit, 2) + " $\n";                
            downSideComment = downSideComment + "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(DOWN) * ProfitPerLot, 2) + " $\n";                                     
            downSideComment = downSideComment + "     Stop loss uses: " + StopLossModeToString(hedgeCapturedSLDown) + "\n";
         
            isHedgeOrderExist = GetOrdersCount(magicDownHedge, OP_BUY) != 0;
            if ((hedgeWasClosedDown == 1) && !isHedgeOrderExist)
            {                                       
               downSideComment = downSideComment + "     Hedge previous price: " + DoubleToStr(GetLastHedgeOpenPrice(magicDownHedge, OP_BUY, startSessionDown), Digits) + "\n";
               downSideComment = downSideComment + "     Hedge indicator price: " + DoubleToStr(GetHedgeSL(hedgeCapturedSLDown, AdditionalHedgeReenterPips), Digits) + "\n";
            }   
            if (isHedgeOrderExist)
               downSideComment = downSideComment + "     Hedge stop loss: " + DoubleToStr(GetLastHedgeOrderStopLoss(magicDownHedge, OP_BUY), Digits) + "\n";                     
               
            lotsBalance = -1;   
            if (stateDown == RESTRICTION_BUY)   
               lotsBalance = GetLastOrderLots(magicDownRestriction, OP_BUY);            
            if (stateDown == RESTRICTION_SELL) 
               lotsBalance = GetLastOrderLots(magicDownRestriction, OP_SELL);
            if (lotsBalance != -1)
               downSideComment = downSideComment + "     Restriction lots: " + DoubleToStr(lotsBalance, 2) + "\n";               
            break;   
      }   
      
      targetCriticalLoss = startMoneyDown - GetTargetLossByPercent(DOWN, CriticalLoss);
      downSideComment = downSideComment + "     Target critical loss: " + DoubleToStr(targetCriticalLoss, 2) + "\n";        
      
      comment = comment + 
           "Moving Avarage uses timeframe: " + PeriodToString(MATimeframe) + "\n" +
           "Bollinger Bands uses timeframe: " + PeriodToString(BBTimeframe) + "\n";
           
      if (UseOsMA)
         comment = comment + "OsMA uses timeframe: " + PeriodToString(OsMATimeframe) + "\n";
      if (UseAC)
         comment = comment + "AC uses timeframe: " + PeriodToString(ACTimeframe) + "\n";         
           
      comment = comment + 
           "---------------------------------------------------------\n" +
           "Up side\n" +
           "     Account balance at the session start: " + DoubleToStr(startMoneyUp, 2) + "\n" +
           "     Lots: " + DoubleToStr(GetOrdersLotsBySide(UP), 2) + "\n" +
           "     Current total profit: " + DoubleToStr(currentTotalProfitUp, 2) + " $\n" +
           upSideComment +
           "=========================\n" +
           "Down side\n" +
           "     Account balance at the session start: " + DoubleToStr(startMoneyDown, 2) + "\n" +
           "     Lots: " + DoubleToStr(GetOrdersLotsBySide(DOWN), 2) + "\n" +
           "     Current total profit: " + DoubleToStr(currentTotalProfitDown, 2) + " $\n" +              
           downSideComment;
   }
   
   Comment(comment); 
   while(debug);
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



