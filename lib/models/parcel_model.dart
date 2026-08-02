class ParcelModel {
  final int id;
  final String trackingNumber;
  final String senderName;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String status;
  final String paymentStatus;
  final bool codSettled;
  final double amount;
  final String originBranchName;
  final String createdAt;

  ParcelModel({
    required this.id,
    required this.trackingNumber,
    required this.senderName,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.status,
    required this.paymentStatus,
    required this.codSettled,
    required this.amount,
    required this.originBranchName,
    required this.createdAt,
  });

  factory ParcelModel.fromJson(Map<String, dynamic> json) {
    return ParcelModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      trackingNumber: json['tracking_number'] ?? '',
      senderName: json['sender_name'] ?? 'N/A',
      receiverName: json['receiver_name'] ?? 'N/A',
      receiverPhone: json['receiver_phone'] ?? '',
      receiverAddress: json['receiver_address'] ?? 'N/A',
      status: json['status'] ?? 'Pending',
      paymentStatus: json['payment_status'] ?? 'Unpaid',
      codSettled: json['cod_settled'].toString() == '1',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      originBranchName: json['origin_branch_name'] ?? 'Central Hub',
      createdAt: json['created_at'] ?? '',
    );
  }

  /// COD is the only delivery payment the rider collects from the receiver.
  /// Unpaid means the sender/account invoice remains outstanding; it is not
  /// rider cash and must never enter the COD settlement flow.
  bool get isCod => paymentStatus == 'COD';

  String get paymentInstruction {
    switch (paymentStatus) {
      case 'COD':
        return 'COD — collect from receiver';
      case 'Paid':
        return 'Prepaid — do not collect';
      default:
        return 'Sender invoice pending — do not collect';
    }
  }

  bool get isDelivered => status == 'Delivered';
}

class ParcelStats {
  final int outForDelivery;
  final int inTransit;
  final int deliveredToday;
  final double codTotal;

  ParcelStats({
    required this.outForDelivery,
    required this.inTransit,
    required this.deliveredToday,
    required this.codTotal,
  });

  factory ParcelStats.fromJson(Map<String, dynamic> json) {
    return ParcelStats(
      outForDelivery: int.tryParse(json['out_for_delivery'].toString()) ?? 0,
      inTransit: int.tryParse(json['in_transit'].toString()) ?? 0,
      deliveredToday: int.tryParse(json['delivered_today'].toString()) ?? 0,
      codTotal: double.tryParse(json['cod_total'].toString()) ?? 0.0,
    );
  }
}
