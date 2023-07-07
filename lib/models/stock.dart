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
}

void sortStockList(List<Stock> stocks) {
  stocks.sort((Stock a, Stock b) {
    if (a.priceCurrency != b.priceCurrency) {
      return b.priceCurrency.compareTo(a.priceCurrency);
    }
    return a.ticker.compareTo(b.ticker);
  });
}
