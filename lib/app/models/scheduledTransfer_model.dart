// scheduled_transfer_model.dart

enum TransferFrequency {
  once,
  daily,
  weekly,
  monthly
}

class ScheduledTransfer {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final DateTime executionDate;
  final TransferFrequency frequency;
  final bool isActive;
  final bool feesPaidBySender;
  final DateTime createdAt;

  ScheduledTransfer({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.executionDate,
    required this.frequency,
    this.isActive = true,
    this.feesPaidBySender = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'executionDate': executionDate.toIso8601String(),
      'frequency': frequency.toString().split('.').last,
      'isActive': isActive,
      'feesPaidBySender': feesPaidBySender,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScheduledTransfer.fromMap(Map<String, dynamic> map, String id) {
    return ScheduledTransfer(
      id: id,
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      amount: map['amount'],
      executionDate: DateTime.parse(map['executionDate']),
      frequency: TransferFrequency.values.firstWhere(
        (f) => f.toString().split('.').last == map['frequency']
      ),
      isActive: map['isActive'] ?? true,
      feesPaidBySender: map['feesPaidBySender'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
