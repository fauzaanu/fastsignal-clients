#property strict

// JSON parsing library
#include <JAson.mqh>

// inputs
extern string base_url="example.com"

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
   string url = StringConcatenate(base_url,"/next");
   string headers = "Content-Type: application/json\r\n";
   char post[];
   char result[];
   string resultString;
   
   int res = WebRequest("GET", url, headers, 0, post, result, headers);
   
   if(res == -1) {
      Print("Error in WebRequest. Error code: ", GetLastError());
      return TradeInfo();
   }
   
   resultString = CharArrayToString(result);
   
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
   double currentPrice = MarketInfo(info.asset, MODE_ASK);
   
   if(currentPrice >= info.entryLow && currentPrice <= info.entryHigh) {
      int ticket = OrderSend(info.asset, OP_BUY, 0.1, currentPrice, 3, info.sl, info.tp1);
      
      if(ticket > 0) {
         Print("Trade executed successfully. Ticket: ", ticket);
         
         // Modify order to add TP2 and TP3 if they exist
         if(info.tp2 > 0) {
            OrderModify(ticket, OrderOpenPrice(), info.sl, info.tp2, 0, CLR_NONE);
         }
         if(info.tp3 > 0) {
            int ticket2 = OrderSend(info.asset, OP_BUY, 0.1, currentPrice, 3, info.sl, info.tp3);
            if(ticket2 > 0) {
               Print("Additional trade for TP3 executed. Ticket: ", ticket2);
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
