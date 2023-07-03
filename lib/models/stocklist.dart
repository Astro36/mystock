import 'package:mystock/models/stock.dart';

class StockList {
  String name;
  List<Stock> stocks;

  StockList({
    required this.name,
    required this.stocks,
  });

  StockList.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        stocks = (json['stocks'] as List).map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();

  Map<String, dynamic> toJson() => {
        'name': name,
        'stocks': stocks.map((e) => e.toJson()).toList(),
      };

  void sort() {
    stocks.sort((Stock a, Stock b) {
      if (a.priceCurrency != b.priceCurrency) {
        return b.priceCurrency.compareTo(a.priceCurrency);
      }
      return a.ticker.compareTo(b.ticker);
    });
  }
}
