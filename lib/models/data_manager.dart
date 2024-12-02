import 'package:madtrack/controllers/database_controller.dart';
import 'package:madtrack/models/sensors_data.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();

  factory DataManager() {
    return _instance;
  }

  DataManager._internal();

  List<SensorsData> dataList = [];
  Function()? onDataChange;
  Function()? onValuesChange;

  Future<void> initializeData() async {
    dataList = await DatabaseController().getData();
  }

  Future<void> updateData() async {
    dataList = await DatabaseController().getData();
    onDataChange?.call();
    onValuesChange?.call();
  }

  void deleteData(int index) {
    dataList.removeAt(index);
    onDataChange?.call();
    onValuesChange?.call();
  }
}
