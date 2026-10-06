// Test registration only: no runtime factories or injectable public writer APIs.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/channel/hermes_detached_run_store.dart';

import '../../../integration_test/support/m2_metadata.dart';

part 'm2_diagnostic_writer.dart';
part 'm2_observer_cases.dart';
part 'm2_receipt_admission_cases.dart';
