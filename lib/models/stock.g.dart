// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockAdapter extends TypeAdapter<Stock> {
  @override
  final int typeId = 0;

  @override
  Stock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stock(
      ticker: fields[0] as String,
      name: fields[1] as String,
      exchange: fields[2] as String,
    )
      .._price = fields[3] as StockPrice
      .._priceUpdatedAt = fields[4] as DateTime
      .._earningsDate = fields[5] as DateTime
      .._earningsDateUpdatedAt = fields[6] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Stock obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.ticker)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.exchange)
      ..writeByte(3)
      ..write(obj._price)
      ..writeByte(4)
      ..write(obj._priceUpdatedAt)
      ..writeByte(5)
      ..write(obj._earningsDate)
      ..writeByte(6)
      ..write(obj._earningsDateUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockPriceAdapter extends TypeAdapter<StockPrice> {
  @override
  final int typeId = 1;

  @override
  StockPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockPrice(
      currency: fields[0] as String,
      value: fields[1] as double,
      changes: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StockPrice obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.currency)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.changes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockListAdapter extends TypeAdapter<StockList> {
  @override
  final int typeId = 2;

  @override
  StockList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockList(
      name: fields[0] as String,
      stocks: (fields[1] as List).cast<Stock>(),
    );
  }

  @override
  void write(BinaryWriter writer, StockList obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.stocks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
