import 'package:flutter_riverpod/flutter_riverpod.dart';
class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void test() {
    state = 1;
  }
}
void main() {}
