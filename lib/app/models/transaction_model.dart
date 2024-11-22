enum TransactionType {
  transfer,
  payment,
  deposit,
  withdrawal
}

class Transaction {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final TransactionType type;
  final DateTime timestamp;
  final String status;
  final bool feesPaidBySender; // Nouveau champ

  Transaction({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.type,
    DateTime? timestamp,
    this.status = 'completed',
    this.feesPaidBySender = true, // Par défaut, le sender paie les frais
  }) : timestamp = timestamp ?? DateTime.now() {
    // Validation pour empêcher les auto-transferts
    if (senderId == receiverId) {
      throw ArgumentError('L\'expéditeur et le destinataire ne peuvent pas être identiques');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'feesPaidBySender': feesPaidBySender,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    if (map['senderId'] == map['receiverId']) {
      throw ArgumentError('L\'expéditeur et le destinataire ne peuvent pas être identiques');
    }
    
    return Transaction(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      amount: map['amount'],
      type: TransactionType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type']
      ),
      timestamp: DateTime.parse(map['timestamp']),
      status: map['status'] ?? 'completed',
      feesPaidBySender: map['feesPaidBySender'] ?? true,
    );
  }
}