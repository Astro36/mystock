import 'package:equatable/equatable.dart';

import 'package:mystock/models/repository.dart';

class Stock extends Equatable {
  final String ticker;
  final String name;
  final String exchange;
  String priceCurrency = 'USD';
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
        priceCurrency = json['priceCurrency'] as String,
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
    if (DateTime.timestamp().difference(_priceUpdatedAt).inMinutes >= 5) {
      await updatePrice();
    }
    return _price;
  }

  Future<DateTime> get earningsDates async {
    if (DateTime.timestamp().difference(_earningsDateUpdatedAt).inDays >= 7) {
      await updateEarningsDates();
    }
    return _earningsDate;
  }

  Future<StockPrice> updatePrice() async {
    _priceUpdatedAt = DateTime.timestamp();
    _price = await YahooFinance.fetchStockPrice(ticker);
    priceCurrency = _price.currency;
    return _price;
  }

  Future<DateTime> updateEarningsDates() async {
    _earningsDateUpdatedAt = DateTime.timestamp();
    _earningsDate = await YahooFinance.fetchStockEarningsDate(ticker);
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
