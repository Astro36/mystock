import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import 'package:mystock/models/repository.dart';

part 'stock.g.dart';

@HiveType(typeId: 0)
class Stock extends Equatable {
  @HiveField(0)
  final String ticker;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String exchange;

  @HiveField(3)
  StockPrice _price = StockPrice(currency: 'USD', value: 0, changes: 0);

  @HiveField(4)
  DateTime _priceUpdatedAt = DateTime.utc(1970);

  @HiveField(5)
  DateTime _earningsDate = DateTime.utc(1970);

  @HiveField(6)
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
        _price = StockPrice(currency: json['priceCurrency'] as String, value: json['price'] as double, changes: json['priceChanges'] as double),
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

  String get priceCurrency => _price.currency;

  Future<DateTime> get earningsDates async {
    if (DateTime.timestamp().difference(_earningsDateUpdatedAt).inDays >= 7) {
      await updateEarningsDates();
    }
    return _earningsDate;
  }

  Future<StockPrice> updatePrice() async {
    _priceUpdatedAt = DateTime.timestamp();
    _price = await YahooFinance.fetchStockPrice(ticker);
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

@HiveType(typeId: 1)
class StockPrice {
  @HiveField(0)
  final String currency;

  @HiveField(1)
  final double value;

  @HiveField(2)
  final double changes;

  StockPrice({
    required this.currency,
    required this.value,
    required this.changes,
  });
}

@HiveType(typeId: 2)
class StockList {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<String> tickers;

  StockList({
    required this.name,
    required this.tickers,
  });

  StockList.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        tickers = json['tickers'].cast<String>();

  Map<String, dynamic> toJson() => {
        'name': name,
        'tickers': tickers,
      };
}

void sortTickers(List<String> tickers) {
  tickers.sort((String tickerA, String tickerB) {
    final countryCodeA = (tickerA.split('.')..add('US'))[1];
    final countryCodeB = (tickerB.split('.')..add('US'))[1];
    if (countryCodeA != countryCodeB) {
      return countryCodeA.compareTo(countryCodeB);
    }
    return tickerA.compareTo(tickerB);
  });
}
