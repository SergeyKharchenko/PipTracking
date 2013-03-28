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
extern bool      OpenTrades = true;

extern string    MagicNumber_Help = "Should be unique for each charts";
extern int       MagicNumber      = 1234;

extern string    StrategySettings = "------------------------------------------------";
extern bool      UseUpSide        = true;
extern bool      UseDownSide      = true;

extern int       PipStep          = 25;
extern double    LotSize          = 0.1;
extern double    ProfitPerLot     = 30;
extern int       TakeProfit       = 20;
extern double    LotExponent      = 1.5;
extern double    LotHedgeExponent = 2.5;
extern double    UnrealizedLoss   = 15;
extern double    CriticalLoss     = 50;

extern string    RestrictionSettings       = "------------------------------------------------";
extern int       InitialRestrictionPips    = 10;
extern int       HedgeRestrictionPips      = 10;

extern string    HedgeSettings         = "------------------------------------------------";
extern string    HedgeStopLoss_Help_1  = "0 - Moving Average";
extern string    HedgeStopLoss_Help_2  = "1 - Bollinger Bands Lowest";
extern string    HedgeStopLoss_Help_3  = "2 - Bollinger Bands Medium";
extern string    HedgeStopLoss_Help_4  = "3 - Bollinger Bands Highest";
extern int       UpHedgeStopLossLine   = 1;
extern int       DownHedgeStopLossLine = 3;
extern int       AdditionalHedgeStopLossPips = 5;
extern int       AdditionalHedgeReenterPips  = 8;

extern string    IndicatorSettings = "------------------------------------------------";
extern int       MAPeriod          = 14;
extern string    MAMethod_Help_1   = "0 - Simple moving average";
extern string    MAMethod_Help_2   = "1 - Exponential moving average";
extern string    MAMethod_Help_3   = "2 - Smoothed moving average";
extern string    MAMethod_Help_4   = "3 - Linear weighted moving average";
extern int       MAMethod          = 0;
extern int       MAShift           = 0;
extern int       BBPeriod          = 20;
extern int       BBDeviation       = 1;
extern int       BBShift           = 0;

extern string    MaAndBbIndicatorPrice_Help_1 = "0 - Close price";
extern string    MaAndBbIndicatorPrice_Help_2 = "1 - Open price";
extern string    MaAndBbIndicatorPrice_Help_3 = "2 - High price";
extern string    MaAndBbIndicatorPrice_Help_4 = "3 - Low price";
extern string    MaAndBbIndicatorPrice_Help_5 = "4 - Median price";
extern string    MaAndBbIndicatorPrice_Help_6 = "5 - Typical price";
extern string    MaAndBbIndicatorPrice_Help_7 = "6 - Weighted close price";
extern int       MAPrice           = 0;
extern int       BBPrice           = 0;

extern bool      UseOsMA     = true;
extern int       OsMAFastEMA = 12;
extern int       OsMASlowEMA = 26;
extern int       OsMASMA     = 9;
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
extern int       MATimeframe   = 0;
extern int       BBTimeframe   = 0;
extern int       OsMATimeframe = 0;
extern int       ACTimeframe   = 0;
                                
extern string    AdditionalSettings = "------------------------------------------------";                           
extern bool      ShowAlerts         = true;
extern bool      ShowComments       = true;
extern string    DisableEA_Help     = "If any error has occurred EA will close all positions and will be disable";
extern bool      DisableEA          = false;

// --> Global states
#define NONE    -1
#define SIMPLE   0
#define MULTIPLE 1
#define HEDGE    2
#define RESTRICTION_INITIAL  3
#define RESTRICTION_HEDGE 	  4
#define BREAK_EVEN        	  5


// --> Global sides
#define UP     0
#define DOWN   1
// 


// --> Global variables
int
   ticket,
   state[2],
   hedgeWasClosed[2],
   hedgeCapturedSl[2],
   magicSimple[2],
   magicMultiple[2],
   magicHedge[2],
   magicRestriction[2];
   
bool 
   work = true,
   isError = false,
   debug = false,
   preDebug = false;   
   
double
   startLot,
   startMoney[2];   
   
string 
   errorStr,
   saveFileName;        
    
datetime
   startSession[2];
    
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
	  AdditionalHedgeStopLossPips *= 10;
	  AdditionalHedgeReenterPips *= 10;
	  InitialRestrictionPips *= 10;
	  HedgeRestrictionPips *= 10;
   }

   if (MagicNumber <= 0) 
      ShowCriticalAlertAndStop("MagicNumber is invalid");      
   
   if (TakeProfit < 0) 
      ShowCriticalAlertAndStop("TakeProfit is invalid");    

   if (LotExponent < 1) 
		ShowCriticalAlertAndStop("LotExponent is invalid");
   
   if (LotHedgeExponent < 1) 
		ShowCriticalAlertAndStop("LotHedgeExponent is invalid");
   
   if (PipStep < 1) 
		ShowCriticalAlertAndStop("PipStep is invalid");
   
   if (UnrealizedLoss <= 0) 
		ShowCriticalAlertAndStop("UnrealizedLoss is invalid");
   
   if ((UpHedgeStopLossLine < 0) || (UpHedgeStopLossLine > 3)) 
		ShowCriticalAlertAndStop("UpHedgeStopLossLine is invalid");

   if ((DownHedgeStopLossLine < 0) || (DownHedgeStopLossLine > 3)) 
		ShowCriticalAlertAndStop("DownHedgeStopLossLine is invalid");
   
   if (MAPeriod < 1) 
		ShowCriticalAlertAndStop("MAPeriod is invalid");
   
   if (MAShift < 0) 
		ShowCriticalAlertAndStop("MAShift is invalid");
   
   if (BBPeriod < 1) 
		ShowCriticalAlertAndStop("BBPeriod is invalid");
   
   if (BBDeviation < 0) 
		ShowCriticalAlertAndStop("BBDeviation is invalid");
   
   if (BBShift < 0) 
		ShowCriticalAlertAndStop("BBShift is invalid");
   
   if (CriticalLoss <= 0) 
		ShowCriticalAlertAndStop("CriticalLoss is invalid");	
   
   if (OsMAFastEMA < 1) 
		ShowCriticalAlertAndStop("OsMAFastEMA is invalid");
   
   if (OsMASlowEMA < 1) 
		ShowCriticalAlertAndStop("OsMASlowEMA is invalid");
   
   if (OsMASMA < 1) 
		ShowCriticalAlertAndStop("OsMASMA is invalid");	
	
   if ((MAMethod < 0) || (MAMethod > 3)) 
		ShowCriticalAlertAndStop("MAMethod is invalid");
   
   if ((MAPrice < 0) || (MAPrice > 6)) 
		ShowCriticalAlertAndStop("MAPrice is invalid");
   
   if ((BBPrice < 0) || (BBPrice > 6)) 
		ShowCriticalAlertAndStop("BBPrice is invalid");
   
   if ((MATimeframe < 0) || (MATimeframe > 9)) 
		ShowCriticalAlertAndStop("MATimeframe is invalid");
   
   if ((BBTimeframe < 0) || (BBTimeframe > 9)) 
		ShowCriticalAlertAndStop("BBTimeframe is invalid");
   
   if ((OsMATimeframe < 0) || (OsMATimeframe > 9)) 
		ShowCriticalAlertAndStop("OsMATimeframe is invalid");
   
   if ((ACTimeframe < 0) || (ACTimeframe > 9)) 
		ShowCriticalAlertAndStop("ACTimeframe is invalid");
   
   if ((InitialRestrictionPips * Point) < (Ask - Bid)) 
		ShowCriticalAlertAndStop("InitialRestrictionPips is invalid");  
		
   if ((HedgeRestrictionPips * Point) < (Ask - Bid)) 
		ShowCriticalAlertAndStop("InitialRestrictionPips is invalid"); 		
		  
   
   double lot = NormalizeLots(LotSize, Symbol());

   if (lot != LotSize) 
		ShowCriticalAlertAndStop("lot is invalid");
   
   if (!work)   
      return;         
   
   if (MarketInfo(Symbol(), MODE_LOTSIZE) != 0)
      if (lot > (AccountFreeMargin() / MarketInfo(Symbol(), MODE_LOTSIZE))) {
         if (ShowAlerts) {
            Alert("This LotSize too big for your balance");
         }   
      }         
   
   isError = false;
   
   state[0]  = NONE;
   state[1] = NONE;
	
	ResetToDefault();   
   
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
		ResetToDefault();
		work = false;
		Alert("EA is blocking");
		return;
   } 
      
	bool isCriticalLossUp = IsCriticalLoss(UP);
	bool isCriticalLossDown = IsCriticalLoss(DOWN);
	if (isCriticalLossUp || isCriticalLossDown)
	{
		if (isCriticalLossUp)
			Alert("You have reached critical loss by Buy side");
		else
			Alert("You have reached critical loss by Sell side");
		isError = true;
		start();
		return;
	}    

	SaveSession();
	 
	if (GetOrdersCountBySide(UP) == 0)
		state[0] = NONE;        

	ProcessHedgeOrders(UP);
	 
	if (!ProcessBreakEven(UP))
	{   
		if (IsTakeProfitForSimpleState(UP))
			TryClose(magicSimple[0], OP_BUY);
			
		OpenOrders(UP);		
	}
	
	if (GetOrdersCountBySide(DOWN) == 0)
		state[1] = NONE;

	ProcessHedgeOrders(DOWN);

	if (!ProcessBreakEven(DOWN))
	{            
		if (IsTakeProfitForSimpleState(DOWN))
			TryClose(magicSimple[1], OP_SELL);

		OpenOrders(DOWN);
	}
   
   if (ShowComments)
      ShowStatistics();
		
   return (0);
}
//+------------------------------------------------------------------+


//=========================================================================================================
// Open order logic part
//=========================================================================================================

//+------------------------------------------------------------------+
void OpenOrders(int side)
{
	int newState = GetOpenState(side);
	if (newState == -1)
		return;		
	
	double lot = CalculateLotByState(side, newState);  
	if (lot == -1) 
		return;
		
	state[side] = newState;	
		
	color 
		sameOrderColor,
		oppositeOrderColor,
		orderColor;
		
	int 
		sameOrderType,
		oppositeOrderType,
		orderType,
		magic,
		sl = 0;
		
	double 
		sameOrderOpenPrice,
		oppositeOrderOpenPrice,
		orderOpenPrice;
		
	switch (side)
	{
		case UP: 
			sameOrderColor = Lime;
			oppositeOrderColor = Red;
			sameOrderType = OP_BUY;
			oppositeOrderType = OP_SELL;
			sameOrderOpenPrice = Ask;
			oppositeOrderOpenPrice = Bid;
			break;
		case DOWN: 
			sameOrderColor = Red;
			oppositeOrderColor = Lime;
			sameOrderType = OP_SELL;
			oppositeOrderType = OP_BUY;
			sameOrderOpenPrice = Bid;
			oppositeOrderOpenPrice = Ask;
			break;
	}
		
	if ((newState != HEDGE) && (newState != RESTRICTION_HEDGE))
	{
		orderType = sameOrderType;
		orderOpenPrice = sameOrderOpenPrice;
		orderColor = sameOrderColor;
	}
			
	switch (newState)
	{
		case SIMPLE: 		 
			startMoney[side] = AccountBalance();  
			startSession[side] = TimeCurrent();
			hedgeWasClosed[side] = -1;
			magic = magicSimple[side];
			break;
			
		case MULTIPLE: 
			magic = magicMultiple[side];
			break;
			
		case HEDGE:
		case RESTRICTION_HEDGE:
			if (lot == -1) 
				break;
			hedgeWasClosed[side] = 0;
			double slValue = GetHedgeSL(hedgeCapturedSl[side], AdditionalHedgeStopLossPips);
			sl = CastSLToPoints(slValue, oppositeOrderType);      
			magic = magicHedge[side];
			if (state[side] == RESTRICTION_HEDGE) 
				magic = magicRestriction[side]; 
			   

			orderType = oppositeOrderType;
			orderOpenPrice = oppositeOrderOpenPrice;
			orderColor = oppositeOrderColor;
			
			break;		

		case RESTRICTION_INITIAL:
		   if (side == DOWN)
		    debug = true;
			magic = magicRestriction[side];
			break; 
	}
	
	ticket = OpenOrderA(Symbol(), orderType, lot, orderOpenPrice, sl, 0, 100, NULL, magic, 5, 0, orderColor);  
	if (DisplayError(ticket))
		state[side] = NONE;	
	else
	{
	  if (state[side] == RESTRICTION_HEDGE)
	     Notify("Restriction hedge order has been opened with lots amount: " + DoubleToStr(lot, 2) + " by " + SideToString(side) + " side");
	  if (state[side] == RESTRICTION_INITIAL)
	     Notify("Restriction initial order has been opened with lots amount: " + DoubleToStr(lot, 2) + " by " + SideToString(side) + " side");
	}	
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int GetOpenState(int side)
{
	if (!OpenTrades)
		return (-1);
		
	if ((side == UP) && !UseUpSide)
	  return (-1);
	  
	if ((side == DOWN) && !UseDownSide)
	  return (-1);
		
   RefreshRates();
   
	if (IsOpenSimple(side))
		return (SIMPLE);
		
	if (IsOpenMultiple(side))
		return (MULTIPLE);	
	
	if (IsOpenFirstHedge(side))
		return (HEDGE);	
	
	if (IsInitialRestrictionOpen(side))
		return (RESTRICTION_INITIAL);		
	
	if (IsHedgeRestrictionOpen(side))
	   return (RESTRICTION_HEDGE);	
	
   return (-1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsOpenSimple(int side)
{
	return (GetOrdersCountBySide(side) == 0);
}	
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsOpenMultiple(int side)
{
	if (IsUnrealizedLoss(side))
		return (false);
	switch (side)
	{
		case UP:
			if (hedgeWasClosed[0] != -1)
				return (false);
				double lastOrderOpenPrice = MathMinBlocked(GetLastOrderOpenPrice(magicSimple[0], OP_BUY),
																		 GetLastOrderOpenPrice(magicMultiple[0], OP_BUY), -1);	
				if (((Ask + PipStep * Point) <= lastOrderOpenPrice) && (lastOrderOpenPrice != -1))
					return (true);  
			break;
		case DOWN:
			if (hedgeWasClosed[1] != -1)
				return (false);		
				lastOrderOpenPrice = MathMax(GetLastOrderOpenPrice(magicSimple[1], OP_SELL),
													  GetLastOrderOpenPrice(magicMultiple[1], OP_SELL));
				if ((Bid - PipStep * Point) >= lastOrderOpenPrice)
					return (true); 
			break;			
	}
	return (false);
}	
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsOpenFirstHedge(int side)
{
	if (!IsUnrealizedLoss(side))
		return (false);
	if (hedgeWasClosed[side] != -1)
		return (false);
	int hedgeSLMode = GetHedgeIndicatorLine(side);
	
	if ((hedgeSLMode != -1)  && IsIndicatorsAllowHedge(side))
	{
      hedgeCapturedSl[side] = hedgeSLMode;
		return (true);
	}
	return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsInitialRestrictionOpen(int side)
{		
	if (hedgeWasClosed[side] != 1)			
		return (false);
		
	switch (side)
	{
		case UP:
			double lastHedgeOpenPrice = GetLastHedgeClosePrice(magicHedge[0], OP_SELL, startSession[0]);
			if ((Ask > lastHedgeOpenPrice) && !IsLastRestrictionOrderSameType(UP, OP_BUY, startSession[0]) && IsIndicatorsAllowHedge(DOWN))
				return (true);
			break;
		case DOWN:	
			lastHedgeOpenPrice = GetLastHedgeClosePrice(magicHedge[1], OP_BUY, startSession[1]);
			if ((Bid < lastHedgeOpenPrice) && !IsLastRestrictionOrderSameType(DOWN, OP_SELL, startSession[1]) && IsIndicatorsAllowHedge(UP))
				return (true);  				
			break;			
	}
	return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsHedgeRestrictionOpen(int side)
{
	if (hedgeWasClosed[side] != 1)
		return (false);
		
	switch (side)
	{
		case UP:
			double lastHedgeOpenPrice = GetLastHedgeClosePrice(magicHedge[0], OP_SELL, startSession[0]);
			if ((Bid <= lastHedgeOpenPrice)
				 && (Bid <= GetHedgeSL(hedgeCapturedSl[0], -AdditionalHedgeReenterPips))
				 && IsIndicatorsAllowHedge(UP))
				return (true);
			break;
		case DOWN:
			lastHedgeOpenPrice = GetLastHedgeClosePrice(magicHedge[1], OP_BUY, startSession[1]);
			if ((Ask >= lastHedgeOpenPrice)
				 && (Ask >= GetHedgeSL(hedgeCapturedSl[1], AdditionalHedgeReenterPips))
				 && IsIndicatorsAllowHedge(DOWN))
				return (true);			
			break;			
	}
	return (false);
}
//+------------------------------------------------------------------+


//=========================================================================================================
// Logic part
//=========================================================================================================

//+------------------------------------------------------------------+
double CalculateLotByState(int side, int newState)
{
	double lots = startLot;
	
	int
		sameOrderType,
		hedgeOrderType;
	
	double 
		orderTargetPriceForInitial,
		orderTargetPriceForHedge;
		
   switch (side)
   {
      case UP:
         sameOrderType = OP_BUY;
         hedgeOrderType = OP_SELL;         
			orderTargetPriceForInitial = GetLastHedgeClosePrice(magicHedge[UP], OP_SELL, startSession[UP]) + InitialRestrictionPips*Point + (Ask - Bid);
			orderTargetPriceForHedge = GetLastHedgeClosePrice(magicHedge[UP], OP_SELL, startSession[UP]) - HedgeRestrictionPips*Point;
			break;
      case DOWN:
         sameOrderType = OP_SELL;
         hedgeOrderType = OP_BUY;
			orderTargetPriceForInitial = GetLastHedgeClosePrice(magicHedge[DOWN], OP_BUY, startSession[DOWN]) - InitialRestrictionPips*Point - (Ask - Bid);
			orderTargetPriceForHedge = GetLastHedgeClosePrice(magicHedge[DOWN], OP_BUY, startSession[DOWN]) + HedgeRestrictionPips*Point;
			break;
   } 		
	
	switch (newState) 
	{              
		case MULTIPLE:
			double lastOrderLots = MathMax(GetLastOrderLots(magicSimple[side], sameOrderType),
													 GetLastOrderLots(magicMultiple[side], sameOrderType));
			lots = lastOrderLots * LotExponent;
			break;          
		case HEDGE:
			lots = GetOrdersLotsBySide(side) * LotHedgeExponent;
			break;  
		case RESTRICTION_HEDGE:
			lots = GetRestrictionLots(side, hedgeOrderType, orderTargetPriceForHedge, ProfitPerLot);
			break;
		case RESTRICTION_INITIAL:
			lots = GetRestrictionLots(side, sameOrderType, orderTargetPriceForInitial, ProfitPerLot); 
			break;                                       
	}
	
	if (lots < 0) 
		return (-1);
	
   return (NormalizeLots(lots, Symbol())); 
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void ProcessHedgeOrders(int side)
{
	int orderType;
	switch (side)
	{
		case UP: 
			orderType = OP_SELL; 
			break;
		case DOWN: 
			orderType = OP_BUY; 
			break;
	}
	
	if ((state[side] == HEDGE) || (state[side] == RESTRICTION_HEDGE))
	{
		int hedgeOrderCount = GetOrdersCount(magicHedge[side], orderType);
		int hedgeRestrictionOrderCount = GetOrdersCount(magicRestriction[side], orderType);
		if ((hedgeOrderCount + hedgeRestrictionOrderCount) > 0)
		{
			if (hedgeOrderCount > 0)
				TrailingHedgeByIndicatorLine(magicHedge[side], orderType); 
			if (hedgeRestrictionOrderCount > 0)
			TrailingHedgeByIndicatorLine(magicRestriction[side], orderType); 
		}   
		else
		{
			hedgeWasClosed[side] = 1;
		}  
	}
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool ProcessBreakEven(int side)
{
	if ((state[side] == BREAK_EVEN) || IsBreakEven(side))
	{
		state[side] = BREAK_EVEN;
		GlobalTrailing(side);
		return (true);
	}
	return (false);
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
					
               if (GetOrdersCount(magicRestriction[0], OP_SELL) > 0)
               {
                  double restrictionPrice = GetLastHedgeClosePrice(magicHedge[0], OP_SELL, startSession[0]);
                  if (Ask <= (restrictionPrice - HedgeRestrictionPips*Point))
                  {
                     Notify("Break even by hedge restriction pips has been triggered by UP side");
                     return (true);
                  }   
               }
               
               if (GetOrdersCount(magicRestriction[0], OP_BUY) > 0)
               {
                  restrictionPrice = GetLastHedgeClosePrice(magicHedge[0], OP_SELL, startSession[0]);
                  if (Bid >= (restrictionPrice + InitialRestrictionPips*Point))
                  {
                     Notify("Break even by initial restriction pips has been triggered by UP side");
                     return (true);
                  } 
               }                 
               
               double 
                  previousProfit = GetHedgeProfitFromHistory(UP, startSession[0]),             
                  neededProfit = lots * ProfitPerLot,       
                  currentTotalProfit = currentProfit + previousProfit; 
            
               if (currentTotalProfit >= neededProfit)
               {
                  Notify("Break even by profit per lot has triggered by UP side");
                  return (true);
               } 
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
               if (GetOrdersCount(magicRestriction[1], OP_BUY) > 0)
               {
                  restrictionPrice = GetLastHedgeClosePrice(magicHedge[0], OP_BUY, startSession[1]);
                  if (Bid >= (restrictionPrice + HedgeRestrictionPips*Point))
                  {
                     Notify("Break even by hedge restriction pips has been triggered by DOWN side");
                     return (true);
                  } 
               }        
               
               if (GetOrdersCount(magicRestriction[1], OP_SELL) > 0)
               {
                  restrictionPrice = GetLastHedgeClosePrice(magicHedge[0], OP_BUY, startSession[1]);
                  if (Ask <= (restrictionPrice - InitialRestrictionPips*Point))
                  {
                     Notify("Break even by initial restriction pips has been triggered by DOWN side");
                     return (true);
                  } 
               }                
               
               previousProfit = GetHedgeProfitFromHistory(DOWN, startSession[1]);               
               neededProfit = lots * ProfitPerLot;         
               currentTotalProfit = currentProfit + previousProfit;
         
               if (currentTotalProfit >= neededProfit)
               {
                  Notify("Break even by profit per lot has triggered by UP side");
                  return (true);
               } 
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
            if ((OrderMagicNumber() != magicSimple[0]) 
                && (OrderMagicNumber() != magicMultiple[0])
                && (OrderMagicNumber() != magicHedge[0])
                && (OrderMagicNumber() != magicRestriction[0]))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicSimple[1]) 
                && (OrderMagicNumber() != magicMultiple[1])
                && (OrderMagicNumber() != magicHedge[1])
                && (OrderMagicNumber() != magicRestriction[1]))
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
   if (GetOrdersCountBySide(side) != 1)
      return (false);
      
   switch (side)
   {
      case UP:
         if (Bid >= (GetLastOrderOpenPrice(magicSimple[0], OP_BUY) + TakeProfit * Point))
         {
            Notify("Take profit point has been reached by UP side");
            return (true);
         } 
         break;
         
      case DOWN:
         if (Ask <= (GetLastOrderOpenPrice(magicSimple[1], OP_SELL) - TakeProfit * Point))
         {
            Notify("Take profit point has been reached by DOWN side");
            return (true);
         } 
         break;
   }      

   return (false);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsIndicatorsAllowHedge(int side)
{
   return (IsOsMAAllowHedge(side) && IsACAllowHedge(side));
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsOsMAAllowHedge(int side)
{
   if (!UseOsMA)
      return (true);

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
   if (!UseAC)
      return (true);

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
         double slValue = GetHedgeSL(DownHedgeStopLossLine, AdditionalHedgeReenterPips);                  
         if (slValue < (Ask + stopLevel))
         {
            for (int i = 3; i >= 1; i--)
            {
               slValue = GetHedgeSL(UpHedgeStopLossLine, AdditionalHedgeReenterPips);
               if (slValue > (Ask + stopLevel))
                  return (i);
            }
         }
         else
         {
            return (DownHedgeStopLossLine);
         }      
         break;
         
      case DOWN:
         slValue = GetHedgeSL(UpHedgeStopLossLine, -AdditionalHedgeReenterPips);
         if (slValue >= (Bid + stopLevel))
         {
            for (i = 1; i <= 3; i++)
            {
               slValue = GetHedgeSL(UpHedgeStopLossLine, -AdditionalHedgeReenterPips);
               if (slValue < (Bid - stopLevel))
                  return (i);
            }
         }
         else
         {
            return (UpHedgeStopLossLine);
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
                  break;
						
               RefreshRates();                       
               
               if (OrderType() == OP_BUY)
               {
                  double slValue = GetHedgeSL( hedgeCapturedSl[1], -AdditionalHedgeStopLossPips);                                    
                  int newSLpt = CastSLToPoints(slValue, OP_BUY);                                  
                  int checkedSLpt = CheckStop(newSLpt, 0);          
                  double newSL = NormalizeDouble(Ask - checkedSLpt * Point, Digits);                             
                  if (NormalizeDouble(newSL, Digits) != NormalizeDouble(OrderStopLoss(), Digits))
                     OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), Lime);  
               }

               if (OrderType() == OP_SELL)
               {                  
                  slValue = GetHedgeSL(hedgeCapturedSl[0], AdditionalHedgeStopLossPips);
                  newSLpt = CastSLToPoints(slValue, OP_SELL);
                  checkedSLpt = CheckStop(newSLpt, 0);                  
                  newSL = NormalizeDouble(Bid + checkedSLpt * Point, Digits);
                  if (NormalizeDouble(newSL, Digits) != NormalizeDouble(OrderStopLoss(), Digits))
                     OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), Lime);
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
         totalProfit += GetHedgeProfitFromHistory(UP, startSession[0]);
         break;
      case DOWN:
         totalProfit += GetHedgeProfitFromHistory(DOWN, startSession[1]);
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
         if (startMoney[0] == -1)
            loss = 0;     
         else
            loss = startMoney[0] * (percent / 100);
         break;
         
      case DOWN:
         if (startMoney[1] == -1)
            loss = 0;
         else
            loss = startMoney[1] * (percent / 100);         
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
   
   switch (mode == MODE_HISTORY)
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
               if (OrderType() != type) continue;                 
               if (OrderMagicNumber() != magic) continue; 
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
         count = GetOrdersCount(magicSimple[0], OP_BUY)
                 + GetOrdersCount(magicMultiple[0], OP_BUY)
                 + GetOrdersCount(magicHedge[0], OP_SELL)
                 + GetOrdersCount(magicRestriction[0], OP_SELL)
                 + GetOrdersCount(magicRestriction[0], OP_BUY);   
         break;   
      case DOWN:
         count = GetOrdersCount(magicSimple[1], OP_SELL)
                 + GetOrdersCount(magicMultiple[1], OP_SELL)
                 + GetOrdersCount(magicHedge[1], OP_BUY)
                 + GetOrdersCount(magicRestriction[1], OP_BUY)
                 + GetOrdersCount(magicRestriction[1], OP_SELL);   
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
            if ((OrderMagicNumber() != magicSimple[0]) 
                && (OrderMagicNumber() != magicMultiple[0])
                && (OrderMagicNumber() != magicHedge[0])
                && (OrderMagicNumber() != magicRestriction[0]))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicSimple[1]) 
                && (OrderMagicNumber() != magicMultiple[1])
                && (OrderMagicNumber() != magicHedge[1])
                && (OrderMagicNumber() != magicRestriction[1]))
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
            if ((OrderMagicNumber() != magicSimple[0]) 
                && (OrderMagicNumber() != magicMultiple[0])
                && (OrderMagicNumber() != magicHedge[0])
                && (OrderMagicNumber() != magicRestriction[0]))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicSimple[1]) 
                && (OrderMagicNumber() != magicMultiple[1])
                && (OrderMagicNumber() != magicHedge[1])
                && (OrderMagicNumber() != magicRestriction[1]))
               continue;   
         } 
         lots += OrderLots();
      }
   }
         
   return (lots);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetOrdersLots(int side, int type)
{
   double lots = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)  
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (OrderSymbol() != Symbol()) continue;
         if (OrderType() != type) continue;
         
         if (side == UP)
         {            
            if ((OrderMagicNumber() != magicSimple[0]) 
                && (OrderMagicNumber() != magicMultiple[0])
                && (OrderMagicNumber() != magicHedge[0])
                && (OrderMagicNumber() != magicRestriction[0]))
               continue;   
         }     
         if (side == DOWN)
         {
            if ((OrderMagicNumber() != magicSimple[1]) 
                && (OrderMagicNumber() != magicMultiple[1])
                && (OrderMagicNumber() != magicHedge[1])
                && (OrderMagicNumber() != magicRestriction[1]))
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
               if ((OrderMagicNumber() != magicHedge[0])
                   && (OrderMagicNumber() != magicRestriction[0]))
                  continue;
               if (OrderType() != OP_SELL)   
                  continue;
               break;
            case DOWN:
               if ((OrderMagicNumber() != magicHedge[1])
                   && (OrderMagicNumber() != magicRestriction[1]))
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
double GetLastHedgeClosePrice(int magic, int type, datetime time)
{
   int ticket = GetLastOrderTicket(magic, type, MODE_HISTORY);
	if (OrderSelect(ticket, SELECT_BY_TICKET)) 
		if (OrderOpenTime() > time)
			return (OrderClosePrice());
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
            if (OrderMagicNumber() != magicRestriction[0]) continue; 
            break;
         case DOWN:
            if (OrderMagicNumber() != magicRestriction[1]) continue; 
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
string SideToString(int side)
{
   switch (side)
   {
      case UP: return ("UP");
      case DOWN: return ("DOWN");
   }
   return ("");
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void ShowCriticalAlertAndStop(string alertText)
{
   Alert(alertText);
   work = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void ResetToDefault()
{
	startMoney[0] = -1;
	startMoney[1] = -1;
	startSession[0] = -1;
	startSession[1] = -1;       
	hedgeWasClosed[0] = -1;
	hedgeWasClosed[1] = -1;
	hedgeCapturedSl[0] = UpHedgeStopLossLine;
	hedgeCapturedSl[1] = DownHedgeStopLossLine;
	MATimeframe = TranslatePeriod(MATimeframe);
	BBTimeframe = TranslatePeriod(BBTimeframe);
	OsMATimeframe = TranslatePeriod(OsMATimeframe);
	ACTimeframe = TranslatePeriod(ACTimeframe);
	
   int magic = MagicNumber * 10;
   magicSimple[0] = magic;
   magicMultiple[0] = magic + 1;
   magicHedge[0] = magic + 2;
   magicRestriction[0] = magic + 3;
   magicSimple[1] = magic + 4;
   magicMultiple[1] = magic + 5;
   magicHedge[1] = magic + 6; 
   magicRestriction[1] = magic + 7;
   
   saveFileName = Symbol() + " " + MagicNumber + ".csv";	
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void LoadSession()
{
   int handle;
   handle = FileOpen(saveFileName, FILE_CSV | FILE_READ,';');   
   if(handle > 0)
   {
      state[0] = FileReadNumber(handle);
      startMoney[0] = FileReadNumber(handle);
      startSession[0] = FileReadNumber(handle);
      hedgeWasClosed[0] = FileReadNumber(handle);   
      hedgeCapturedSl[0] = FileReadNumber(handle); 
      
      state[1] = FileReadNumber(handle);
      startMoney[1] = FileReadNumber(handle);
      startSession[0] = FileReadNumber(handle);
      hedgeWasClosed[1] = FileReadNumber(handle); 
      hedgeCapturedSl[1] = FileReadNumber(handle); 
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
               state[0], startMoney[0], startSession[0], hedgeWasClosed[0], hedgeCapturedSl[0],
               state[1], startMoney[1], startSession[1], hedgeWasClosed[1], hedgeCapturedSl[1]);
      FileClose(handle);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetRestrictionLots(int side, int orderType, double targetPrice, double perLot)
{
   double pipsDistance = 0;
   double currentLots = 0;
   
   switch (orderType)
   {
      case OP_BUY:
         pipsDistance = (targetPrice - Ask) / Point;
         switch (side)
         {
            case UP:
               currentLots = GetOrdersLots(UP, OP_BUY) - GetOrdersLots(UP, OP_SELL);
               break;
            case DOWN:
               currentLots = GetOrdersLots(UP, OP_SELL) - GetOrdersLots(UP, OP_BUY);
               break;
         }
         break;
      case OP_SELL:
         pipsDistance = (Bid - targetPrice) / Point;
         switch (side)
         {
            case UP:
               currentLots = GetOrdersLots(DOWN, OP_BUY) - GetOrdersLots(DOWN, OP_SELL);
               break;
            case DOWN:
               currentLots = GetOrdersLots(DOWN, OP_SELL) - GetOrdersLots(DOWN, OP_BUY);
               break;
         }
         break;         
   } 
   
   if (pipsDistance <= 0)
      return (-1);
   
   int moneyForOnePoint;
   switch (Digits)
   {
      case 5: moneyForOnePoint = 1; break;
      case 4: moneyForOnePoint = 10; break;
      case 3: moneyForOnePoint = 100; break;
   }   
   
   double currentProfit = GetOrdersProfitBySide(side) + GetHedgeProfitFromHistory(side, startSession[side]); 
   double tickSize = currentLots * moneyForOnePoint;
   double distaceSize = tickSize * pipsDistance;
   double targetProfit = GetOrdersLotsBySide(side) * perLot;
   double targetProfitWithLoss = targetProfit - currentProfit;
   double missingMoney = distaceSize - targetProfitWithLoss;
           
   if (missingMoney < 0)
   {
      missingMoney *= -1;
      double lotsAmount = missingMoney / (moneyForOnePoint * pipsDistance); 
      return (lotsAmount);
   }
   return (-1);
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
   TryClose(magicSimple[0], OP_BUY);
   TryClose(magicMultiple[1], OP_BUY);
   TryClose(magicHedge[0], OP_SELL);
   
   TryClose(magicSimple[1], OP_SELL);
   TryClose(magicMultiple[1], OP_SELL);
   TryClose(magicHedge[1], OP_BUY);  
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
      switch (state[0])
      {
         case SIMPLE:
            upSideComment = "     Target take profit: " + DoubleToStr(GetLastOrderOpenPrice(magicSimple[0], OP_BUY) + TakeProfit * Point, Digits) + "\n";
            double targetUnresizedLoss = startMoney[0] - GetTargetLossByPercent(UP, UnrealizedLoss);
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
            targetUnresizedLoss = startMoney[0] - GetTargetLossByPercent(UP, UnrealizedLoss);
            upSideComment = upSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\n";                                         
            break;   
            
         case HEDGE:             
         case RESTRICTION_HEDGE:    
         case RESTRICTION_INITIAL: 
            double currentProfit = GetOrdersProfitBySide(UP); 
            double previousProfit = GetHedgeProfitFromHistory(UP, startSession[0]);                 
            currentTotalProfitUp = currentProfit + previousProfit;
                                       
            upSideComment = "     Live profit: " + DoubleToStr(currentProfit, 2) + " $\n"; 
            upSideComment = upSideComment + "     Balance of previous hedge orders: " + DoubleToStr(previousProfit, 2) + " $\n";                 
            upSideComment = upSideComment + "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(UP) * ProfitPerLot, 2) + " $\n";                 
            upSideComment = upSideComment + "     Stop loss uses: " + StopLossModeToString(hedgeCapturedSl[0]) + "\n";
         
            bool isHedgeOrderExist = GetOrdersCount(magicHedge[0], OP_SELL) != 0;
            if ((hedgeWasClosed[0] == 1) && !isHedgeOrderExist)
            {
               upSideComment = upSideComment + "     Hedge previous price: " + DoubleToStr(GetLastHedgeClosePrice(magicHedge[0], OP_SELL, startSession[0]), Digits) + "\n";                                        
               upSideComment = upSideComment + "     Hedge indicator price: " + DoubleToStr(GetHedgeSL(hedgeCapturedSl[0], -AdditionalHedgeReenterPips), Digits) + "\n";                            
            }   
            if (isHedgeOrderExist)
               upSideComment = upSideComment + "     Hedge stop loss: " + DoubleToStr(GetLastHedgeOrderStopLoss(magicHedge[0], OP_SELL), Digits) + "\n";                                                                                        
               
            double lotsRestriction = -1;   
            if (state[0] == RESTRICTION_HEDGE) 
            {
               lotsRestriction = GetLastOrderLots(magicRestriction[0], OP_SELL);
               if (lotsRestriction != -1)
               {
                  upSideComment = upSideComment + "     Restriction hedge lots: " + DoubleToStr(lotsRestriction, 2) + "\n";  
                  double restrictionPrice = GetLastHedgeClosePrice(magicHedge[0], OP_SELL, startSession[0]);
                  double restrictionTargerPrice = restrictionPrice - HedgeRestrictionPips*Point;
                  upSideComment = upSideComment + "     Restriction targer price for Ask: " + DoubleToStr(restrictionTargerPrice, Digits) + "\n";  
               }   
            }   
            if (state[0] == RESTRICTION_INITIAL)   
            {
               lotsRestriction = GetLastOrderLots(magicRestriction[0], OP_BUY);
               if (lotsRestriction != -1)
               {   
                  upSideComment = upSideComment + "     Restriction initial lots: " + DoubleToStr(lotsRestriction, 2) + "\n";  
                  restrictionPrice = GetLastHedgeClosePrice(magicHedge[0], OP_SELL, startSession[0]);
                  restrictionTargerPrice = restrictionPrice + InitialRestrictionPips*Point;
                  upSideComment = upSideComment + "     Restriction targer price for Bid: " + DoubleToStr(restrictionTargerPrice, Digits) + "\n";                 
               }   
            }   
            break;   
      }
      double targetCriticalLoss = startMoney[0] - GetTargetLossByPercent(UP, CriticalLoss);
      upSideComment = upSideComment + "     Target critical loss: " + DoubleToStr(targetCriticalLoss, 2) + "\n";        


      string downSideComment;
      
      double currentTotalProfitDown;      
      switch (state[1])
      {
         case SIMPLE:
            downSideComment = "     Target take profit: " + DoubleToStr(GetLastOrderOpenPrice(magicSimple[1], OP_SELL) - TakeProfit * Point, Digits) + "\n";
            targetUnresizedLoss = startMoney[1] - GetTargetLossByPercent(DOWN, UnrealizedLoss);
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
            targetUnresizedLoss = startMoney[1] - GetTargetLossByPercent(DOWN, UnrealizedLoss);
            downSideComment = downSideComment + "     Target unrealized loss: " + DoubleToStr(targetUnresizedLoss, 2) + "\n";                  
            break;                 
         case HEDGE:           
         case RESTRICTION_HEDGE:  
         case RESTRICTION_INITIAL: 
            currentProfit = GetOrdersProfitBySide(DOWN);              
            previousProfit = GetHedgeProfitFromHistory(DOWN, startSession[1]);               
            currentTotalProfitDown = currentProfit + previousProfit;                                                          
                                  
            downSideComment = "     Live profit: " + DoubleToStr(currentProfit, 2) + " $\n";                       
            downSideComment = downSideComment + "     Balance of previous hedge orders: " + DoubleToStr(previousProfit, 2) + " $\n";                
            downSideComment = downSideComment + "     Target break even trigger: " + DoubleToStr(GetOrdersLotsBySide(DOWN) * ProfitPerLot, 2) + " $\n";                                     
            downSideComment = downSideComment + "     Stop loss uses: " + StopLossModeToString(hedgeCapturedSl[1]) + "\n";
         
            isHedgeOrderExist = GetOrdersCount(magicHedge[1], OP_BUY) != 0;
            if ((hedgeWasClosed[1] == 1) && !isHedgeOrderExist)
            {                                       
               downSideComment = downSideComment + "     Hedge previous price: " + DoubleToStr(GetLastHedgeClosePrice(magicHedge[1], OP_BUY, startSession[1]), Digits) + "\n";
               downSideComment = downSideComment + "     Hedge indicator price: " + DoubleToStr(GetHedgeSL(hedgeCapturedSl[1], AdditionalHedgeReenterPips), Digits) + "\n";
            }   
            if (isHedgeOrderExist)
               downSideComment = downSideComment + "     Hedge stop loss: " + DoubleToStr(GetLastHedgeOrderStopLoss(magicHedge[1], OP_BUY), Digits) + "\n";                     
               
            lotsRestriction = -1;   
            if (state[1] == RESTRICTION_HEDGE)   
            {
               lotsRestriction = GetLastOrderLots(magicRestriction[1], OP_BUY);            
               if (lotsRestriction != -1)
               {
                  downSideComment = downSideComment + "     Restriction hedge lots: " + DoubleToStr(lotsRestriction, 2) + "\n";                                      
                  restrictionPrice = GetLastHedgeClosePrice(magicHedge[0], OP_BUY, startSession[1]);
                  restrictionTargerPrice = restrictionPrice + HedgeRestrictionPips*Point;
                  downSideComment = downSideComment + "     Restriction targer price for Bid: " + DoubleToStr(restrictionTargerPrice, Digits) + "\n";                                              
               }   
            }   
            if (state[1] == RESTRICTION_INITIAL) 
            {
               lotsRestriction = GetLastOrderLots(magicRestriction[1], OP_SELL);
               if (lotsRestriction != -1)
               {
                  downSideComment = downSideComment + "     Restriction initial lots: " + DoubleToStr(lotsRestriction, 2) + "\n";  
                  restrictionPrice = GetLastHedgeClosePrice(magicHedge[0], OP_BUY, startSession[1]);
                  restrictionTargerPrice = restrictionPrice - InitialRestrictionPips*Point;
                  downSideComment = downSideComment + "     Restriction targer price for Bid: " + DoubleToStr(restrictionTargerPrice, Digits) + "\n";                                                      
               }   
            }                 
            break;   
      }   
      
      targetCriticalLoss = startMoney[1] - GetTargetLossByPercent(DOWN, CriticalLoss);
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
           "     Account balance at the session start: " + DoubleToStr(startMoney[0], 2) + "\n" +
           "     Lots: " + DoubleToStr(GetOrdersLotsBySide(UP), 2) + "\n" +
           "     Current total profit: " + DoubleToStr(currentTotalProfitUp, 2) + " $\n" +
           upSideComment +
           "=========================\n" +
           "Down side\n" +
           "     Account balance at the session start: " + DoubleToStr(startMoney[1], 2) + "\n" +
           "     Lots: " + DoubleToStr(GetOrdersLotsBySide(DOWN), 2) + "\n" +
           "     Current total profit: " + DoubleToStr(currentTotalProfitDown, 2) + " $\n" +              
           downSideComment;
   }
   
   Comment(comment); 
   while(debug);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void Notify(string text)
{
   if (ShowAlerts)
      Alert(text);
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



