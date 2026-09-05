// Execute the shared 85-suite feature inventory on a physical Android engine.
// Its deterministic services and input do not qualify real audio or Android IME.
import 'linux_feature_regression_test.dart' as features;

void main() => features.main(includeHostChecks: false);
