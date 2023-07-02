import 'package:equatable/equatable.dart';
import './repository.dart';

class Stock extends Equatable {
  final String ticker;
  final String name;
  final String exchange;
  StockPrice _price = StockPrice('USD', 0, 0);
  DateTime _priceUpdatedAt = DateTime.utc(1970);
  DateTime _earningsDate = DateTime.utc(1970);
  DateTime _earningsDateUpdatedAt = DateTime.utc(1970);

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
        _priceUpdatedAt = DateTime.parse(json['priceUpdatedAt'] as String),
        _earningsDate = DateTime.parse(json['earningsDates'] as String),
        _earningsDateUpdatedAt = DateTime.parse(json['earningsDateUpdatedAt'] as String);

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'exchange': exchange,
        'priceCurrency': _price.currency,
        'price': _price.value,
        'priceChanges': _price.changes,
        'priceUpdatedAt': _priceUpdatedAt.toString(),
        'earningsDates': _earningsDate.toString(),
        'earningsDateUpdatedAt': _earningsDateUpdatedAt.toString(),
      };

  Future<StockPrice> get price async {
    if (DateTime.timestamp().difference(_priceUpdatedAt).inSeconds > 60) {
      _price = await YahooFinance.fetchStockPrice(ticker);
      _priceUpdatedAt = DateTime.timestamp();
    }
    return _price;
  }

  Future<DateTime> get earningsDates async {
    if (DateTime.timestamp().difference(_earningsDateUpdatedAt).inDays > 7) {
      _earningsDate = await YahooFinance.fetchStockEarningsDate(ticker);
      _earningsDateUpdatedAt = DateTime.timestamp();
    }
    return _earningsDate;
  }

  Future<StockPrice> updatePrice() async {
    _price = await YahooFinance.fetchStockPrice(ticker);
    _priceUpdatedAt = DateTime.timestamp();
    return _price;
  }

  Future<DateTime> updateEarningsDates() async {
    _earningsDate = await YahooFinance.fetchStockEarningsDate(ticker);
    _earningsDateUpdatedAt = DateTime.timestamp();
    return _earningsDate;
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
