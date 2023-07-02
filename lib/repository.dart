import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import './model.dart';

class Storage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/stocks.json');
  }

  Future<List<Portfolio>> load() async {
    try {
      final file = await _localFile;
      final content = await file.readAsString();
      final portfolios = jsonDecode(content) as List<dynamic>;
      return portfolios.map((e) => Portfolio.fromJson(e)).toList();
    } catch (e) {
      return [Portfolio(name: '관심', stocks: [])];
    }
  }

  Future<File> save(List<Portfolio> portfolios) async {
    final file = await _localFile;
    return file.writeAsString(jsonEncode(portfolios));
  }
}

class YahooFinance {
  static Future<DateTime> fetchStockEarningsDate(String ticker) async {
    final response = await http.get(Uri.parse('https://query2.finance.yahoo.com/v10/finance/quoteSummary/$ticker?modules=calendarEvents'));
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final eventResult = result['quoteSummary']['result'][0]['calendarEvents'] as Map<String, dynamic>;
      if (eventResult['earnings']['earningsDate'].isNotEmpty) {
        final earningsDate = DateTime.parse(eventResult['earnings']['earningsDate'][0]['fmt']);
        return earningsDate;
      }
    }
    return DateTime.utc(1970);
  }

  static Future<StockPrice> fetchStockPrice(String ticker) async {
    final response = await http.get(Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$ticker?interval=1d'));
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final priceResult = result['chart']['result'][0]['meta'] as Map<String, dynamic>;
      final priceCurrency = (priceResult['currency'] as String).toUpperCase();
      final price = priceResult['regularMarketPrice'] as double;
      final pricePrevious = priceResult['chartPreviousClose'] as double;
      final priceChanges = (price - pricePrevious) / pricePrevious;
      return StockPrice(priceCurrency, price, priceChanges);
    }
    throw Exception('Invalid ticker');
  }

  static Future<List<Stock>> searchStock(String ticker) async {
    final response = await http.get(Uri.parse('https://query1.finance.yahoo.com/v1/finance/search?q=$ticker'));
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final searchResult = result['quotes'] as List;
      return searchResult.map((e) => Stock(ticker: e['symbol'], name: e['longname'] ?? e['shortname'] ?? e['symbol'], exchange: e['exchange'])).toList();
    }
    throw Exception('Invalid ticker');
  }
}
