class Transaction {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final TransactionType type;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      amount: map['amount'],
      type: TransactionType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type']
      ),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

enum TransactionType {
  transfer,
  payment,
  deposit,
  withdrawal
}