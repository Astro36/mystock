import 'package:equatable/equatable.dart';

class Stock extends Equatable {
  final String ticker;
  final String name;
  final String exchange;
  StockPrice _price = StockPrice('USD', 0, 0);
  DateTime priceUpdatedAt = DateTime.utc(1970);
  DateTime _earningsDates = DateTime.utc(1970);
  DateTime earningsDatesUpdatedAt = DateTime.utc(1970);

  Stock({
    required this.ticker,
    required this.name,
    required this.exchange,
  });

  Stock.fromJson(Map<String, dynamic> json)
      : ticker = json['ticker'] as String,
        name = json['name'] as String,
        exchange = json['exchange'] as String,
        _price = StockPrice(json['priceCurrency'] as String, json['price'] as double, json['priceChanges'] as double),
        priceUpdatedAt = DateTime.parse(json['priceUpdatedAt'] as String),
        _earningsDates = DateTime.parse(json['earningsDates'] as String),
        earningsDatesUpdatedAt = DateTime.parse(json['earningsDatesUpdatedAt'] as String);

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'exchange': exchange,
        'priceCurrency': price.currency,
        'price': price.value,
        'priceChanges': price.changes,
        'priceUpdatedAt': priceUpdatedAt.toString(),
        'earningsDates': earningsDates.toString(),
        'earningsDatesUpdatedAt': earningsDatesUpdatedAt.toString(),
      };

  StockPrice get price => _price;

  set price(StockPrice price) {
    _price = price;
    priceUpdatedAt = DateTime.timestamp();
  }

  DateTime get earningsDates => _earningsDates;

  set earningsDates(DateTime earningsDates) {
    _earningsDates = earningsDates;
    earningsDatesUpdatedAt = DateTime.timestamp();
  }

  @override
  List<Object> get props => [ticker];
}

class StockPrice {
  String currency;
  double value;
  double changes;

  StockPrice(this.currency, this.value, this.changes);
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
