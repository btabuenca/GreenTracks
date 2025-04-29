import 'package:flutter/material.dart';
import 'package:d_chart/d_chart.dart';

// ignore: must_be_immutable
class Chart extends StatelessWidget {
  final List<double?> valuesList;
  final int time;
  final ColorScheme colorScheme;
  int parts = 6;

  Chart({
    super.key,
    required this.valuesList,
    required this.time,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (parts >= valuesList.length) parts = valuesList.length;
    List<Map<String, double>> minMaxValues = getMinMaxValues(valuesList, parts);
    List<OrdinalData> maxDataList = generateList(minMaxValues, true);
    List<OrdinalData> minDataList = generateList(minMaxValues, false);

    return SizedBox(
      height: 300,
      child: DChartBarO(
        groupList: [
          OrdinalGroup(
            id: 'max',
            data: maxDataList,
          ),
          OrdinalGroup(
            id: 'min',
            data: minDataList,
          ),
        ],
        animate: true,
      ),
    );
  }

  List<OrdinalData> generateList(
      List<Map<String, double>> minMaxValues, bool isMax) {
    List<int> timePortions = accumulateTime();
    List<OrdinalData> dataList = [];

    for (var i = 0; i < parts; i++) {
      double? value = isMax ? minMaxValues[i]['max'] : minMaxValues[i]['min'];

      dataList.add(OrdinalData(
        domain: formatSeconds(timePortions[i]).toString(),
        measure: value!,
      ));
    }
    return dataList;
  }

  String formatSeconds(int seconds) {
    Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes'$twoDigitSeconds''";
  }

  List<int> accumulateTime() {
    int division = (time / parts).floor();
    int remainder = time % parts;
    List<int> portions =
    List.generate(parts, (index) => division * (index + 1));
    portions[parts - 1] += remainder;
    return portions;
  }

  List<Map<String, double>> getMinMaxValues(
      List<double?> valuesList, int parts) {
    List<Map<String, double>> result = [];

    int division = (valuesList.length / parts).floor();
    int remainder = valuesList.length % parts;

    int start = 0;
    for (int i = 0; i < parts; i++) {
      int end = start + division;
      if (remainder > 0) {
        end += 1;
        remainder -= 1;
      }

      List<double?> portion = valuesList.sublist(start, end);
      double? maxValue = portion.reduce((a, b) => a! > b! ? a : b);
      double? minValue = portion.reduce((a, b) => a! < b! ? a : b);

      result.add({
        'max': maxValue!,
        'min': minValue!,
      });

      start = end;
    }

    return result;
  }
}