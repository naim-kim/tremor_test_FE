// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TestResultAdapter extends TypeAdapter<TestResult> {
  @override
  final int typeId = 0;

  @override
  TestResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestResult(
      id: fields[0] as String,
      userId: fields[1] as String,
      testType: fields[2] as TestType,
      timestamp: fields[3] as DateTime,
      drawingPoints: (fields[4] as List).cast<DrawingPoint>(),
      overallScore: fields[5] as double,
      metrics: fields[6] as TremorMetrics,
      resultCategory: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TestResult obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.testType)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.drawingPoints)
      ..writeByte(5)
      ..write(obj.overallScore)
      ..writeByte(6)
      ..write(obj.metrics)
      ..writeByte(7)
      ..write(obj.resultCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DrawingPointAdapter extends TypeAdapter<DrawingPoint> {
  @override
  final int typeId = 2;

  @override
  DrawingPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawingPoint(
      x: fields[0] as double,
      y: fields[1] as double,
      normalizedX: fields[2] as double,
      normalizedY: fields[3] as double,
      timestamp: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DrawingPoint obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y)
      ..writeByte(2)
      ..write(obj.normalizedX)
      ..writeByte(3)
      ..write(obj.normalizedY)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TremorMetricsAdapter extends TypeAdapter<TremorMetrics> {
  @override
  final int typeId = 3;

  @override
  TremorMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TremorMetrics(
      frequency: fields[0] as double,
      amplitude: fields[1] as double,
      deviationFromBaseline: fields[2] as double,
      testDuration: fields[3] as double,
      averageSpeed: fields[4] as double,
      mean: fields[5] as double,
      std: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TremorMetrics obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.frequency)
      ..writeByte(1)
      ..write(obj.amplitude)
      ..writeByte(2)
      ..write(obj.deviationFromBaseline)
      ..writeByte(3)
      ..write(obj.testDuration)
      ..writeByte(4)
      ..write(obj.averageSpeed)
      ..writeByte(5)
      ..write(obj.mean)
      ..writeByte(6)
      ..write(obj.std);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TremorMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TestTypeAdapter extends TypeAdapter<TestType> {
  @override
  final int typeId = 1;

  @override
  TestType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TestType.spiral;
      case 1:
        return TestType.pentagon;
      default:
        return TestType.spiral;
    }
  }

  @override
  void write(BinaryWriter writer, TestType obj) {
    switch (obj) {
      case TestType.spiral:
        writer.writeByte(0);
        break;
      case TestType.pentagon:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
