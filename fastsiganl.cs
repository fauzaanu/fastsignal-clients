using System;
using System.Net.Http;
using System.Threading.Tasks;
using cAlgo.API;
using cAlgo.API.Internals;
using cAlgo.API.Indicators;
using cAlgo.API.Instances;
using Newtonsoft.Json.Linq;

namespace cAlgo.Robots
{
    [Robot(TimeZone = TimeZones.UTC, AccessRights = AccessRights.FullAccess)]
    public class TradeExecutionBot : Robot
    {
        [Parameter("Base URL", DefaultValue = "https://example.com")]
        public string BaseUrl { get; set; }

        private HttpClient httpClient;

        protected override void OnStart()
        {
            httpClient = new HttpClient();
            ExecuteTrades();
        }

        private async void ExecuteTrades()
        {
            try
            {
                var tradeInfo = await FetchTradeInfo();
                if (tradeInfo != null)
                {
                    ExecuteTrade(tradeInfo);
                }
                else
                {
                    Print("Failed to fetch valid trade information.");
                }
            }
            catch (Exception ex)
            {
                Print($"Error: {ex.Message}");
            }
        }

        private async Task<TradeInfo> FetchTradeInfo()
        {
            string url = $"{BaseUrl}/next";
            var response = await httpClient.GetStringAsync(url);
            var json = JObject.Parse(response);

            var entryRange = json["entry_range"].ToString().Split('-');

            return new TradeInfo
            {
                Asset = json["asset"].ToString(),
                EntryLow = double.Parse(entryRange[0]),
                EntryHigh = double.Parse(entryRange[1]),
                StopLoss = json["sl"].Value<double>(),
                TakeProfit1 = json["tp1"].Value<double>(),
                TakeProfit2 = json["tp2"].Value<double>(),
                TakeProfit3 = json["tp3"].Value<double>()
            };
        }

        private void ExecuteTrade(TradeInfo info)
        {
            var symbol = Symbols.GetSymbol(info.Asset);
            double currentPrice = symbol.Bid;

            if (currentPrice >= info.EntryLow && currentPrice <= info.EntryHigh)
            {
                var result = ExecuteMarketOrder(TradeType.Buy, symbol, 0.1, "Trade Execution Bot", info.StopLoss, info.TakeProfit1);
                if (result.IsSuccessful)
                {
                    Print($"Trade executed successfully. Ticket: {result.Position.Id}");

                    if (info.TakeProfit2 > 0)
                    {
                        ModifyPosition(result.Position, info.StopLoss, info.TakeProfit2);
                    }

                    if (info.TakeProfit3 > 0)
                    {
                        var result2 = ExecuteMarketOrder(TradeType.Buy, symbol, 0.1, "Trade Execution Bot TP3", info.StopLoss, info.TakeProfit3);
                        if (result2.IsSuccessful)
                        {
                            Print($"Additional trade for TP3 executed. Ticket: {result2.Position.Id}");
                        }
                    }
                }
                else
                {
                    Print($"Error executing trade. Error message: {result.Error}");
                }
            }
            else
            {
                Print("Current price is outside the specified entry range.");
            }
        }

        private class TradeInfo
        {
            public string Asset { get; set; }
            public double EntryLow { get; set; }
            public double EntryHigh { get; set; }
            public double StopLoss { get; set; }
            public double TakeProfit1 { get; set; }
            public double TakeProfit2 { get; set; }
            public double TakeProfit3 { get; set; }
        }
    }
}
