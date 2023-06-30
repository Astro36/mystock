class Stock {
  final String ticker;
  final String name;
  final String exchange;
  double price = 0;
  double priceChanges = 0;

  Stock({
    required this.ticker,
    required this.name,
    required this.exchange,
  });

  Stock.fromJson(Map<String, dynamic> json)
      : ticker = json['ticker'] as String,
        name = json['name'] as String,
        exchange = json['exchange'] as String,
        price = json['price'] as double,
        priceChanges = json['priceChanges'] as double;

  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'name': name,
    'exchange': exchange,
    'price': price,
    'priceChanges': priceChanges,
  };
}

class Portfolio {
  String name;
  List<Stock> stocks;

  Portfolio({
    required this.name,
    required this.stocks,
  });

  Portfolio.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        stocks = (json['stocks'] as List).map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();

  Map<String, dynamic> toJson() => {
    'name': name,
    'stocks': stocks.map((e) => e.toJson()).toList(),
  };
}