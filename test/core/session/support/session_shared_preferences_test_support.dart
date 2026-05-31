import 'package:shared_preferences/shared_preferences.dart';

void resetSessionPreferences([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
}
