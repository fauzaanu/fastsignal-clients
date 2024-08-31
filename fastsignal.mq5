#property strict
#include <Trade\Trade.mqh>
#include <JAson.mqh>

// Input parameter for base URL
input string BaseURL = "https://example.com";

// Structure to hold trade information
struct TradeInfo {
   string asset;
   double entryLow;
   double entryHigh;
   double sl;
   double tp1;
   double tp2;
   double tp3;
};

// Function to fetch and parse JSON data
TradeInfo FetchTradeInfo() {
   string url = BaseURL + "/next";
   char post[];
   char result[];
   string resultHeaders;
   
   int res = WebRequest("GET", url, NULL, NULL, 5000, post, 0, result, resultHeaders);
   
   if(res == -1) {
      Print("Error in WebRequest. Error code: ", GetLastError());
      return TradeInfo();
   }
   
   string resultString = CharArrayToString(result);
   
   CJAVal json;
   if(!json.Deserialize(resultString)) {
      Print("Failed to parse JSON");
      return TradeInfo();
   }
   
   TradeInfo info;
   info.asset = json["asset"].ToStr();
   
   string entryRange = json["entry_range"].ToStr();
   string entryPrices[];
   StringSplit(entryRange, '-', entryPrices);
   info.entryLow = StringToDouble(entryPrices[0]);
   info.entryHigh = StringToDouble(entryPrices[1]);
   
   info.sl = json["sl"].ToDbl();
   info.tp1 = json["tp1"].ToDbl();
   info.tp2 = json["tp2"].ToDbl();
   info.tp3 = json["tp3"].ToDbl();
   
   return info;
}

// Function to execute trade
void ExecuteTrade(TradeInfo &info) {
   CTrade trade;
   double currentPrice = SymbolInfoDouble(info.asset, SYMBOL_ASK);
   
   if(currentPrice >= info.entryLow && currentPrice <= info.entryHigh) {
      if(trade.Buy(0.1, info.asset, currentPrice, info.sl, info.tp1)) {
         Print("Trade executed successfully. Ticket: ", trade.ResultOrder());
         
         // Modify order to add TP2 and TP3 if they exist
         if(info.tp2 > 0) {
            trade.PositionModify(trade.ResultOrder(), info.sl, info.tp2);
         }
         if(info.tp3 > 0) {
            if(trade.Buy(0.1, info.asset, currentPrice, info.sl, info.tp3)) {
               Print("Additional trade for TP3 executed. Ticket: ", trade.ResultOrder());
            }
         }
      } else {
         Print("Error executing trade. Error code: ", GetLastError());
      }
   } else {
      Print("Current price is outside the specified entry range.");
   }
}

// Main program
void OnStart() {
   TradeInfo info = FetchTradeInfo();
   
   if(info.asset != "") {
      ExecuteTrade(info);
   } else {
      Print("Failed to fetch valid trade information.");
   }
}
