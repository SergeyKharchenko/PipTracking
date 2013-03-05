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
extern int       StopLoss          = 0;

extern string    HedjeStopLoss_Help_1 = "0 - Moving Average";
extern string    HedjeStopLoss_Help_2 = "1 - Bollinger Bands Lowest";
extern string    HedjeStopLoss_Help_3 = "2 - Bollinger Bands Medium";
extern string    HedjeStopLoss_Help_4 = "3 - Bollinger Bands Highest";
extern int       UpHedjeStopLoss      = 1;
extern int       DownHedjeStopLoss    = 3;
extern int       AdditionalSLPips     = 5;
extern int       AdditionalHedjeReenterPips = 8;

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
extern double    OsMAHedjeValue   = 0.001;

extern bool      UseAC        = true;
extern double    ACHedjeValue = 0.003;

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

extern string    LotSettings         = "------------------------------------------------";
extern double    LotSize             = 0.1;
extern double    LotExponent         = 1.5;
extern double    LotHedjeExponent    = 2.5;

extern string    StrategySettings  = "------------------------------------------------";
extern int       PipStep           = 25;
extern double    UnrealizedLoss    = 15;

extern string    MagicNymberSettings = "------------------------------------------------";
extern string    MagicNumber_Help    = "Should be unique for all charts";
extern int       MagicNumber         = 1234;
                                
extern string    SupportSettings = "------------------------------------------------";                           
extern bool      ShowAlerts      = true;
extern bool      ShowComments    = true;
extern string    DisableEA_Help  = "If any error has occurred EA will close all positions and will be disable";
extern bool      DisableEA       = false;

// --> Global states
#define NONE       -1
#define SIMPLE      0
#define MULTIPLE    1
#define HEDJE       2
#define BREAK_EVEN  3
// 
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
   hedjeWasClosedUp,
   hedjeWasClosedDown,
   hedjeCapturedSLUp,
   hedjeCapturedSLDown,
   magicUpSimple,
   magicUpMultiple,
   magicUpHedje,
   magicDownSimple,
   magicDownMultiple,
   magicDownHedje;
   
bool 
   work = true,
   isError = false,
   debug = false,
   preDebug = false;   
   
double
   lot,
   startLot,
   startMoneyBuy,
   startMoneySell;   
   
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

   if (MagicNumber < 0) 
   {
      if (ShowAlerts)
         Alert("MagicNumber is invalid");
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
	  AdditionalHedjeReenterPips *= 10;
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
   startSessionUp = -1;
   startSessionDown = -1;       
   hedjeWasClosedUp = 0;
   hedjeWasClosedDown = 0;
   hedjeCapturedSLUp = UpHedjeStopLoss;
   hedjeCapturedSLDown = DownHedjeStopLoss;
   MATimeframe = TranslatePeriod(MATimeframe);
   BBTimeframe = TranslatePeriod(BBTimeframe);
   OsMATimeframe = TranslatePeriod(OsMATimeframe);
   ACTimeframe = TranslatePeriod(ACTimeframe);
   
   int magic = MagicNumber * 10;
   magicUpSimple = magic;
   magicUpMultiple = magic + 1;
   magicUpHedje = magic + 2;
   magicDownSimple = magic + 3;
   magicDownMultiple = magic + 4;
   magicDownHedje = magic + 5; 
   
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

void LoadSession()
{
   int handle;
   handle = FileOpen(saveFileName, FILE_CSV | FILE_READ,';');   
   if(handle > 0)
   {
      stateUp = FileReadNumber(handle);
      startMoneyBuy = FileReadNumber(handle);
      startSessionUp = FileReadNumber(handle);
      hedjeWasClosedUp = FileReadNumber(handle);   
      hedjeCapturedSLUp = FileReadNumber(handle); 
      
      stateDown = FileReadNumber(handle);
      startMoneySell = FileReadNumber(handle);
      startSessionUp = FileReadNumber(handle);
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
               stateUp, startMoneyBuy, startSessionUp, hedjeWasClosedUp, hedjeCapturedSLUp,
               stateDown, startMoneySell, startSessionDown, hedjeWasClosedDown, hedjeCapturedSLDown);
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
      startSessionUp = -1;
      startSessionDown = -1;       
      hedjeWasClosedUp = 0;
      hedjeWasClosedDown = 0;
      hedjeCapturedSLUp = UpHedjeStopLoss;
      hedjeCapturedSLDown = DownHedjeStopLoss;
   }   
   else
   {
      SaveSession();
      
      // --> Buy    
      if (GetOrdersCountBySide(UP) == 0)
         stateUp = NONE;        

      if (stateUp == HEDJE)
      {
         if (GetOrdersCount(magicUpHedje, OP_SELL) > 0)
         {
            TrailingHedjeByIndicatorLine(magicUpHedje, OP_SELL); 
         }   
         else
         {
            hedjeWasClosedUp = 1;
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
                  lot = CalculateLotByState(OP_BUY, stateUp);
                  switch (stateUp)
                  {              
                     case SIMPLE: 
                        startMoneyBuy = AccountBalance();  
                        startSessionUp = TimeCurrent();
                        hedjeWasClosedUp = 0;
                        ticket = OpenOrderA(Symbol(), OP_BUY, startLot, Ask, sl, 0, 100, NULL, magicUpSimple, 5, 0, Lime);  
                        if (DisplayError(ticket))
                           stateUp = NONE;
                        break;

                     case MULTIPLE:
                        ticket = OpenOrderA(Symbol(), OP_BUY, lot, Ask, sl, 0, 100, NULL, magicUpMultiple, 5, 0, Lime);  
                        if (DisplayError(ticket))
                           stateUp = NONE;
                        break;

                     case HEDJE:
                        double slValue = GetHedjeSL(hedjeCapturedSLUp, AdditionalSLPips);
                        slOp = CastSLToPoints(slValue, OP_SELL);                     
                        ticket = OpenOrderA(Symbol(), OP_SELL, lot, Bid, slOp, 0, 100, NULL, magicUpHedje, 5, 0, Red);  
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

      if (stateDown == HEDJE)
      {
         if (GetOrdersCount(magicDownHedje, OP_BUY) > 0)
         {
            TrailingHedjeByIndicatorLine(magicDownHedje, OP_BUY); 
         }   
         else
         {
            hedjeWasClosedDown = 1;
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
                  lot = CalculateLotByState(OP_SELL, stateDown);
                  switch (stateDown)
                  {              
                     case SIMPLE: 
                        startMoneySell = AccountBalance();  
                        startSessionDown = TimeCurrent();
                        hedjeWasClosedDown = 0;
                        ticket = OpenOrderA(Symbol(), OP_SELL, startLot, Bid, sl, 0, 100, NULL, magicDownSimple, 5, 0, Red);  
                        if (DisplayError(ticket))
                           stateDown = NONE;
                        break;

                     case MULTIPLE:
                        ticket = OpenOrderA(Symbol(), OP_SELL, lot, Bid, sl, 0, 100, NULL, magicDownMultiple, 5, 0, Red);  
                        if (DisplayError(ticket))
                           stateDown = NONE;
                        break;

                     case HEDJE:
                        slValue = GetHedjeSL(hedjeCapturedSLDown, -AdditionalSLPips);
                        slOp = CastSLToPoints(slValue, OP_BUY);                     
                        ticket = OpenOrderA(Symbol(), OP_BUY, lot, Ask, slOp, 0, 100, NULL, magicDownHedje, 5, 0, Lime);  
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
   string comment = "\r\nPipTracking\r\n\r\nAccount balance: " + DoubleToStr(AccountBalance(), 2) + "\r\n";
   if (isError)
   {
      comment = comment + errorStr + "\r\n"; 
   }
   else
   {
      double currentTotalProfitUp;
      
      string upSideComment;
      switch (stateUp)
      {
         case SIMPLE:
            upSideComment = "     Target take profit: " + DoubleToStr(GetLastOrderOpenPrice(magicUpSimple, OP_BUY) + TakeProfit * Point, Digits) + "\r\n";
            double targetUnresizedLoss = startMoneyBuy - GetUnrealizedLoss(UP);
            upSideComment = upSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\r\n";
            currentTotalProfitUp = GetOrdersProfitBySide(UP);
            break;
         case BREAK_EVEN:   
            upSideComment = "     In Break even\r\n";      
            currentTotalProfitUp = GetOrdersProfitBySide(UP);
            break;
         case MULTIPLE:
            currentTotalProfitUp = GetOrdersProfitBySide(UP);                                            
            upSideComment = "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(UP) * ProfitPerLot, 2) + " $\r\n";
            targetUnresizedLoss = startMoneyBuy - GetUnrealizedLoss(UP);
            upSideComment = upSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\r\n";                                         
            break;   
            
         case HEDJE:             
            double currentProfit = GetOrdersProfitBySide(UP); 
            double previousProfit = GetHedjeProfitFromHistory(magicUpHedje, OP_SELL, startSessionUp);                 
            currentTotalProfitUp = currentProfit + previousProfit;
                                       
            upSideComment = "     Live profit: " + DoubleToStr(currentProfit, 2) + " $\r\n"; 
            upSideComment = upSideComment + "     Balance of previous hedje orders: " + DoubleToStr(previousProfit, 2) + " $\r\n";                 
            upSideComment = upSideComment + "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(UP) * ProfitPerLot, 2) + " $\r\n";                 
            upSideComment = upSideComment + "     Stop loss uses: " + StopLossModeToString(hedjeCapturedSLUp) + "\r\n";
         
            bool isHedjeOrderExist = IsHedjeOrderExist(magicUpHedje, OP_SELL);
            if ((hedjeWasClosedUp == 1) && !isHedjeOrderExist)
            {
               upSideComment = upSideComment + "     Hedje previous price: " + DoubleToStr(GetLastHedjeOpenPrice(magicUpHedje, OP_SELL, startSessionUp), Digits) + "\r\n";                                        
               upSideComment = upSideComment + "     Hedje indicator price: " + DoubleToStr(GetHedjeSL(hedjeCapturedSLUp, -AdditionalHedjeReenterPips), Digits) + "\r\n";                            
            }   
            if (isHedjeOrderExist)
               upSideComment = upSideComment + "     Hedje stop loss: " + DoubleToStr(GetLastHedjeOrderStopLoss(magicUpHedje, OP_SELL), Digits) + "\r\n";                                                                                        
            break;   
      }

      double currentTotalProfitDown;
      string downSideComment;
      switch (stateDown)
      {
         case SIMPLE:
            downSideComment = "     Target take profit: " + DoubleToStr(GetLastOrderOpenPrice(magicDownSimple, OP_SELL) - TakeProfit * Point, Digits) + "\r\n";
            targetUnresizedLoss = startMoneySell - GetUnrealizedLoss(DOWN);
            downSideComment = downSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\r\n";               
            currentTotalProfitDown = GetOrdersProfitBySide(DOWN);
            break;
         case BREAK_EVEN:   
            downSideComment = "     In Break even\r\n";
            currentTotalProfitDown = GetOrdersProfitBySide(DOWN);
            break;
         case MULTIPLE:
            currentTotalProfitDown = GetOrdersProfitBySide(DOWN);
            downSideComment = "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(DOWN) * ProfitPerLot, 2) + " $\r\n";
            targetUnresizedLoss = startMoneySell - GetUnrealizedLoss(DOWN);
            downSideComment = downSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\r\n";                  
            break;                 
         case HEDJE:           
            currentProfit = GetOrdersProfitBySide(DOWN);              
            previousProfit = GetHedjeProfitFromHistory(magicDownHedje, OP_BUY, startSessionDown);               
            currentTotalProfitDown = currentProfit + previousProfit;                                                          
                                  
            downSideComment = "     Live profit: " + DoubleToStr(currentProfit, 2) + " $\r\n";                       
            downSideComment = downSideComment + "     Balance of previous hedje orders: " + DoubleToStr(previousProfit, 2) + " $\r\n";                
            downSideComment = downSideComment + "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(DOWN) * ProfitPerLot, 2) + " $\r\n";                                     
            downSideComment = downSideComment + "     Stop loss uses: " + StopLossModeToString(hedjeCapturedSLDown) + "\r\n";
         
            isHedjeOrderExist = IsHedjeOrderExist(magicDownHedje, OP_BUY);
            if ((hedjeWasClosedDown == 1) && !isHedjeOrderExist)
            {                                       
               downSideComment = downSideComment + "     Hedje previous price: " + DoubleToStr(GetLastHedjeOpenPrice(magicDownHedje, OP_BUY, startSessionDown), Digits) + "\r\n";
               downSideComment = downSideComment + "     Hedje indicator price: " + DoubleToStr(GetHedjeSL(hedjeCapturedSLDown, AdditionalHedjeReenterPips), Digits) + "\r\n";
            }   
            if (isHedjeOrderExist)
               downSideComment = downSideComment + "     Hedje stop loss: " + DoubleToStr(GetLastHedjeOrderStopLoss(magicDownHedje, OP_BUY), Digits) + "\r\n";                  
         
               
            break;   
      }   
      
      comment = comment + 
           "Moving Avarage uses timeframe: " + PeriodToString(MATimeframe) + "\r\n" +
           "Bollinger Bands uses timeframe: " + PeriodToString(BBTimeframe) + "\r\n";
           
      if (UseOsMA)
         comment = comment + "OsMA uses timeframe: " + PeriodToString(OsMATimeframe) + "\r\n";
      if (UseAC)
         comment = comment + "AC uses timeframe: " + PeriodToString(ACTimeframe) + "\r\n";         
           
      comment = comment + 
           "---------------------------------------------------------\r\n" +
           "Buy\r\n" +
           "     Account balance at the session start: " + DoubleToStr(startMoneyBuy, 2) + "\r\n" +
           "     Lots: " + DoubleToStr(GetOrdersLotsBySide(UP), 2) + "\r\n" +
           "     Current total profit: " + DoubleToStr(currentTotalProfitUp, 2) + " $\r\n" +
           upSideComment +
           "=========================\r\n" +
           "Sell\r\n" +
           "     Account balance at the session start: " + DoubleToStr(startMoneySell, 2) + "\r\n" +
           "     Lots: " + DoubleToStr(GetOrdersLotsBySide(DOWN), 2) + "\r\n" +
           "     Current total profit: " + DoubleToStr(currentTotalProfitDown, 2) + " $\r\n" +              
           downSideComment;
   }
   
   Comment(comment); 
   //while(debug);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsIndicatorsAllowHedje(int side)
{
   return ((IsOsMAAllowHedje(side) || !UseOsMA)
           && (IsACAllowHedje(side) || !UseAC));
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsOsMAAllowHedje(int side)
{
   double osma = iOsMA(Symbol(), OsMATimeframe, OsMAFastEMA, OsMASlowEMA, OsMASMA, OsMAPrice, 0);
   switch (side)
   {
      case UP:
         return (osma <= -OsMAHedjeValue);
      case DOWN:
         return (osma >= OsMAHedjeValue);         
   }
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsACAllowHedje(int side)
{
   double ac = iAC(Symbol(), ACTimeframe, 0);
   switch (side)
   {
      case UP:
         return (ac <= -ACHedjeValue);
      case DOWN:
         return (ac >= ACHedjeValue);         
   }
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void CloseAllOrders()
{
   TryClose(magicUpSimple, OP_BUY);
   TryClose(magicUpMultiple, OP_BUY);
   TryClose(magicUpHedje, OP_SELL);
   
   TryClose(magicDownSimple, OP_SELL);
   TryClose(magicDownMultiple, OP_SELL);
   TryClose(magicDownHedje, OP_BUY);  
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
double GetHedjeSL(int hedjeStopLoss, int additionalPips)
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
     
   iValue += additionalPips * Point;
   return (iValue);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetHedjeProfitFromHistory(int magic, int type, datetime time)
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
double GetLastHedjeOpenPrice(int magic, int type, datetime time)
{
   for (int i = OrdersHistoryTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if (OrderSymbol() != Symbol()) continue;
         if (OrderMagicNumber() != magic) continue;                           
         if (OrderType() != type) continue;
         if ((OrderOpenTime() < time) || (time == -1)) continue;
         return (OrderOpenPrice());
      }
   }

   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void TrailingHedjeByIndicatorLine(int magic, int type, int attempts = 5)
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
                  double slValue = GetHedjeSL( hedjeCapturedSLDown, -AdditionalSLPips);                                    
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
                  slValue = GetHedjeSL(hedjeCapturedSLUp, AdditionalSLPips);
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
                && (OrderMagicNumber() != magicUpHedje))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicDownSimple) 
                && (OrderMagicNumber() != magicDownMultiple)
                && (OrderMagicNumber() != magicDownHedje))
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
double CalculateLotByState(int type, int state)
{
   switch (type)
   {
      case OP_BUY:
         switch (state)
         {
            case HEDJE:
               return (NormalizeLots(GetOrdersLotsBySide(UP) * LotHedjeExponent, Symbol()));              
            case MULTIPLE:
               double lastOrderLots = MathMax(GetLastOrderLots(magicUpSimple, OP_BUY),
                                              GetLastOrderLots(magicUpMultiple, OP_BUY));
               return (NormalizeLots(lastOrderLots * LotExponent, Symbol()));  
         }
      case OP_SELL:
         switch (state)
         {
            case HEDJE:
               return (NormalizeLots(GetOrdersLotsBySide(DOWN) * LotHedjeExponent, Symbol()));             
            case MULTIPLE:
               lastOrderLots = MathMax(GetLastOrderLots(magicDownSimple, OP_SELL),
                                       GetLastOrderLots(magicDownMultiple, OP_SELL));            
               return (NormalizeLots(lastOrderLots * LotExponent, Symbol()));
         }
   }   
   return (startLot); 
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
                 + GetOrdersCount(magicUpHedje, OP_SELL);   
         break;   
      case DOWN:
         count = GetOrdersCount(magicDownSimple, OP_SELL)
                 + GetOrdersCount(magicDownMultiple, OP_SELL)
                 + GetOrdersCount(magicDownHedje, OP_BUY);   
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
   int ticket = GetLastOrderTicket(magic, type, MODE_TRADES);

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
                && (OrderMagicNumber() != magicUpHedje))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicDownSimple) 
                && (OrderMagicNumber() != magicDownMultiple)
                && (OrderMagicNumber() != magicDownHedje))
               continue;   
         }                                   
         profit += OrderProfit();
      }
   }
         
   return (profit);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsUnrealizedLoss(int side)
{
   double loss = GetUnrealizedLoss(side);
   loss *= -1;
   if (GetOrdersProfitBySide(side) <= loss)
      return (true);
      
   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetUnrealizedLoss(int side)
{
   double loss = 0; 
   switch (side)
   {
      case UP:
         if (startMoneyBuy == -1)
            loss = 0;     
         else
            loss = startMoneyBuy * (UnrealizedLoss / 100);
         break;
         
      case DOWN:
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
                && (OrderMagicNumber() != magicUpHedje))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicDownSimple) 
                && (OrderMagicNumber() != magicDownMultiple)
                && (OrderMagicNumber() != magicDownHedje))
               continue;   
         } 
         lots += OrderLots();
      }
   }
         
   return (lots);
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
int IsOpen(int side)
{
   RefreshRates();
   switch (side)
   {
      case UP:            
         if (GetOrdersCount(magicUpHedje, OP_SELL) == 0)   // No hedje order
         {            
            if (GetOrdersCountBySide(UP) == 0)
               return (SIMPLE);      
               
            if (!hedjeWasClosedUp)  // First hedje
            {
               if (IsUnrealizedLoss(UP))
               {
                  int hedjeSLMode = GetHedjeMode(UP);
                  if ((hedjeSLMode != -1) 
                      && IsIndicatorsAllowHedje(UP))
                  {
                     hedjeCapturedSLUp = hedjeSLMode;
                     return (HEDJE);
                  }
               }     
               else
               {   
                  double lastOrderOpenPrice = MathMin(GetLastOrderOpenPrice(magicUpSimple, OP_BUY),
                                                      GetLastOrderOpenPrice(magicUpMultiple, OP_BUY));
                  if ((Ask + PipStep * Point) <= lastOrderOpenPrice)
                     return (MULTIPLE);      
               }                 
            }
            else  // Not first hedje
            {
               double lastHedjeOpenPrice = GetLastHedjeOpenPrice(magicUpHedje, OP_SELL, startSessionUp);
               if ((Bid < lastHedjeOpenPrice)
                   && (Bid < GetHedjeSL(hedjeCapturedSLUp, -AdditionalHedjeReenterPips))
                   && IsIndicatorsAllowHedje(UP))
                  return (HEDJE);
            }
         }
         break;
         
      case DOWN:        
         if (GetOrdersCount(magicDownHedje, OP_BUY) == 0)   // No hedje order
         {
            if (GetOrdersCountBySide(DOWN) == 0)
               return (SIMPLE);
         
            if (!hedjeWasClosedDown)  // First hedje
            {
               if (IsUnrealizedLoss(DOWN))
               {                                   
                  hedjeSLMode = GetHedjeMode(DOWN);                   
                  if ((hedjeSLMode != -1)                  
                      && IsIndicatorsAllowHedje(DOWN))
                  {
                     hedjeCapturedSLDown = hedjeSLMode;
                     return (HEDJE);
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
            else  // Not first hedje
            {                            
               lastHedjeOpenPrice = GetLastHedjeOpenPrice(magicDownHedje, OP_BUY, startSessionUp);
               if ((Ask > lastHedjeOpenPrice)
                   && (Ask > GetHedjeSL(hedjeCapturedSLDown, AdditionalHedjeReenterPips))
                   && IsIndicatorsAllowHedje(DOWN))
                     return (HEDJE);
            }
         }
         break;         
   }


   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int GetHedjeMode(int side)
{
   double
      stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

   switch (side)
   {        
      case UP:
         double slValue = GetHedjeSL(DownHedjeStopLoss, AdditionalHedjeReenterPips);                  
         if (slValue < (Ask + stopLevel))
         {
            for (int i = 3; i >= 1; i--)
            {
               slValue = GetHedjeSL(UpHedjeStopLoss, AdditionalHedjeReenterPips);
               if (slValue > (Ask + stopLevel))
                  return (i);
            }
         }
         else
         {
            return (DownHedjeStopLoss);
         }      
         break;
         
      case DOWN:
         slValue = GetHedjeSL(UpHedjeStopLoss, -AdditionalHedjeReenterPips);
         if ((slValue >= (Bid + stopLevel)) || ())
         {
            for (i = 1; i <= 3; i++)
            {
               slValue = GetHedjeSL(UpHedjeStopLoss, -AdditionalHedjeReenterPips);
               if (slValue < (Bid - stopLevel))
                  return (i);
            }
         }
         else
         {
            return (UpHedjeStopLoss);
         }
         break;         
   }
   return (-1);
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
               double 
                  previousProfit = GetHedjeProfitFromHistory(magicUpHedje, OP_SELL, startSessionUp),             
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
               previousProfit = GetHedjeProfitFromHistory(magicDownHedje, OP_BUY, startSessionDown);               
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



