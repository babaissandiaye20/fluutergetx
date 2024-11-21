class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final String displayName;
  double balance;
  Map<String, double> monthlyTransactions;
  final double maxBalance;
  final double monthlyTransactionLimit;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.displayName,
    this.balance = 0.0,
    Map<String, double>? monthlyTransactions,
    double? maxBalance,
    double? monthlyTransactionLimit,
  }) : 
    monthlyTransactions = monthlyTransactions ?? {},
    maxBalance = maxBalance ?? _getMaxBalanceByRole(role),
    monthlyTransactionLimit = monthlyTransactionLimit ?? _getMonthlyLimitByRole(role);

  // Méthodes pour déterminer les limites selon le rôle
  static double _getMaxBalanceByRole(String role) {
    switch (role) {
      case 'client': return 1000000; // 1 million
      case 'agent': return 10000000; // 10 millions
      case 'marchand': return 6000000; // 6 millions
      case 'admin': return double.infinity;
      default: return 0;
    }
  }

  static double _getMonthlyLimitByRole(String role) {
    switch (role) {
      case 'client': return 4000000; // 4 millions
      case 'agent': return 35000000; // 35 millions
      case 'marchand': return 18000000; // 18 millions
      case 'admin': return double.infinity;
      default: return 0;
    }
  }

  // Méthode pour vérifier si une transaction est possible
  bool canMakeTransaction(double amount) {
    // Vérifier le solde maximum
    if (balance + amount > maxBalance) return false;

    // Vérifier le cumul mensuel
    final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
    final monthTotal = monthlyTransactions[currentMonth] ?? 0.0;
    if (monthTotal + amount > monthlyTransactionLimit) return false;

    return true;
  }

  // Méthode pour mettre à jour la transaction
  void updateTransaction(double amount) {
    if (canMakeTransaction(amount)) {
      balance += amount;
      final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
      monthlyTransactions[currentMonth] = 
        (monthlyTransactions[currentMonth] ?? 0.0) + amount;
    } else {
      throw Exception('Transaction impossible : limite dépassée');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'displayName': displayName,
      'balance': balance,
      'monthlyTransactions': monthlyTransactions,
      'maxBalance': maxBalance,
      'monthlyTransactionLimit': monthlyTransactionLimit,
    };
  }

 factory User.fromMap(Map<String, dynamic> map, [String? id]) {
  return User(
    id: id ?? map['id'] ?? '',  // Use provided id or from map, default to empty string
    firstName: map['firstName'],
    lastName: map['lastName'],
    email: map['email'],
    phoneNumber: map['phoneNumber'],
    role: map['role'],
    displayName: map['displayName'],
    balance: (map['balance'] ?? 0.0).toDouble(),
    monthlyTransactions: Map<String, double>.from(map['monthlyTransactions'] ?? {}),
    maxBalance: (map['maxBalance'] ?? 0.0).toDouble(),
    monthlyTransactionLimit: (map['monthlyTransactionLimit'] ?? 0.0).toDouble(),
  );
}
}