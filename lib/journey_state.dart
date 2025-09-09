import 'package:flutter/foundation.dart';


/// Cross-page app state for the current journey session.
class JourneyState {
  JourneyState._();
  static final instance = JourneyState._();


  final data = ValueNotifier<Map<String, dynamic>?>(null);
  final loading = ValueNotifier<bool>(false);
  final error = ValueNotifier<String?>(null);


  void reset() {
    data.value = null;
    loading.value = false;
    error.value = null;
  }
}