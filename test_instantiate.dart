import 'package:super_drag_and_drop/super_drag_and_drop.dart';
void main() {
  try {
    var f = FileFormat(extensions: ['mp3']);
    print('Success');
  } catch (e) {
    print('Error: $e');
  }
}
