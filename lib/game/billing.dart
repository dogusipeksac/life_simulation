import 'session.dart' show ActionResult;

enum BillingState { pending, verified, canceled, failed }

class BillingUpdate {
  const BillingUpdate(this.product, this.state, this.message);
  final String product, message;
  final BillingState state;
}

class RestoreResult {
  const RestoreResult(this.success, this.products, this.message);
  final bool success;
  final Set<String> products;
  final String message;
}

abstract interface class BillingGateway {
  bool get available;
  String get status;
  Map<String, String> get prices;
  Stream<BillingUpdate> get updates;
  void Function()? get onChanged;
  set onChanged(void Function()? value);
  Future<void> initialize(Set<String> products);
  Future<ActionResult> purchase(String product);
  Future<RestoreResult> restore();
  void dispose();
}
