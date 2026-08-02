import 'package:cheetah_driver_app/models/parcel_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses parcel and COD statistics returned by the driver API', () {
    final parcel = ParcelModel.fromJson({
      'id': '42',
      'tracking_number': 'CH-42',
      'sender_name': 'Sender',
      'receiver_name': 'Receiver',
      'receiver_phone': '03001234567',
      'receiver_address': 'Karachi',
      'status': 'Out for Delivery',
      'payment_status': 'COD',
      'cod_settled': 0,
      'amount': '1250.50',
      'origin_branch_name': 'Central Hub',
      'created_at': '2026-08-02 10:00:00',
    });
    final stats = ParcelStats.fromJson({
      'out_for_delivery': '2',
      'in_transit': 3,
      'delivered_today': 1,
      'cod_total': '2500.75',
    });

    expect(parcel.id, 42);
    expect(parcel.amount, 1250.50);
    expect(parcel.status, 'Out for Delivery');
    expect(parcel.isCod, isTrue);
    expect(stats.outForDelivery, 2);
    expect(stats.codTotal, 2500.75);
  });

  test('uses safe defaults for incomplete API data', () {
    final parcel = ParcelModel.fromJson({});
    final stats = ParcelStats.fromJson({});

    expect(parcel.id, 0);
    expect(parcel.status, 'Pending');
    expect(stats.codTotal, 0.0);
    expect(parcel.isCod, isFalse);
  });

  test('keeps delivered Unpaid parcels out of the rider cash settlement flow', () {
    final parcel = ParcelModel.fromJson({
      'payment_status': 'Unpaid',
      'status': 'Delivered',
      'cod_settled': 0,
    });

    expect(parcel.isCod, isFalse);
    expect(parcel.isDelivered, isTrue);
    expect(parcel.codSettled, isFalse);
    expect(parcel.paymentInstruction, 'Sender invoice pending — do not collect');
  });
}
