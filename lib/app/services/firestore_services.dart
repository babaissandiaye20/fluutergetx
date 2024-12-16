import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart' as custom;
import 'package:wave_mercredi/app/models/favorite_model.dart';
import 'package:wave_mercredi/app/models/scheduledTransfer_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future addTransaction(custom.Transaction transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }


  Future setUser(String userId, User user) async {
    final userRef = _firestore.collection('users').doc(userId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          transaction.set(userRef, user.toMap());
        } else {
          throw Exception('Utilisateur déjà existant');
        }
      });
    } catch (e) {
      print('Erreur lors de l\'enregistrement: $e');
      rethrow;
    }
  }

  Future<User?> getUser(String userId) async {
    final docSnapshot = await _firestore.collection('users').doc(userId).get();
    if (docSnapshot.exists) {
      return User.fromMap(docSnapshot.data()!, docSnapshot.id);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs
        .map((doc) => User.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<User?> userStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return User.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<User?> getUserByPhone(String? phoneNumber) async {
    try {
      if (phoneNumber == null || phoneNumber.trim().isEmpty) {
        return null;
      }

      final cleanedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

      if (cleanedPhone.isEmpty) {
        return null;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanedPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final userId = querySnapshot.docs.first.id;

        return userData != null ? User.fromMap(userData, userId) : null;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  Stream<List<User>> usersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<List<custom.Transaction>> getTransactionsByUser(String userId) async {
    try {
      // Get transactions where user is either sender or receiver
      final QuerySnapshot senderSnapshot = await _firestore
          .collection('transactions')
          .where('senderId', isEqualTo: userId)
          .get();

      final QuerySnapshot receiverSnapshot = await _firestore
          .collection('transactions')
          .where('receiverId', isEqualTo: userId)
          .get();

      // Convert sender transactions
      final List<custom.Transaction> senderTransactions = senderSnapshot.docs
          .map((doc) => custom.Transaction.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();

      // Convert receiver transactions
      final List<custom.Transaction> receiverTransactions = receiverSnapshot
          .docs
          .map((doc) => custom.Transaction.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();

      // Combine both lists and remove duplicates based on transaction ID
      final Map<String, custom.Transaction> uniqueTransactions = {};

      for (var transaction in [
        ...senderTransactions,
        ...receiverTransactions
      ]) {
        uniqueTransactions[transaction.id] = transaction;
      }

      return uniqueTransactions.values.toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  // Add new method to get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return User.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Dans FirestoreService
  Stream<User?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? User.fromMap(doc.data()!, doc.id) : null);
  }

  Stream<QuerySnapshot> getTransactionStreamByUser(String userId) {
    return _firestore
        .collection('transactions')
        .where('senderId', isEqualTo: userId)
        .snapshots();
  }

  Future<bool> cancelTransaction(
      custom.Transaction transaction, String currentUserId) async {
    try {
      return await _firestore.runTransaction((transactionDb) async {
        // Vérifier si l'utilisateur est l'expéditeur
        if (transaction.senderId != currentUserId) {
          throw Exception('Seul l\'expéditeur peut annuler la transaction');
        }

        // Vérifier si la transaction n'est pas déjà annulée
        final transactionDoc = await transactionDb
            .get(_firestore.collection('transactions').doc(transaction.id));

        if ((transactionDoc.data() as Map<String, dynamic>)['status'] ==
            'cancelled') {
          throw Exception('Cette transaction a déjà été annulée');
        }

        // Vérifier si la transaction peut être annulée (30 minutes)
        final timeDifference = DateTime.now().difference(transaction.timestamp);
        if (timeDifference.inMinutes > 30) {
          throw Exception(
              'La transaction ne peut plus être annulée après 30 minutes');
        }

        // Récupérer les documents des utilisateurs
        final senderDoc = await transactionDb
            .get(_firestore.collection('users').doc(transaction.senderId));
        final receiverDoc = await transactionDb
            .get(_firestore.collection('users').doc(transaction.receiverId));

        if (!senderDoc.exists || !receiverDoc.exists) {
          throw Exception('Utilisateur non trouvé');
        }

        final receiverData = receiverDoc.data() as Map<String, dynamic>;
        final receiverBalance = receiverData['balance'] as double;

        // Vérifier si le destinataire a suffisamment de fonds
        if (receiverBalance < transaction.amount) {
          throw Exception('Solde insuffisant pour annuler la transaction');
        }

        // Mettre à jour les soldes
        final senderData = senderDoc.data() as Map<String, dynamic>;
        final senderBalance = senderData['balance'] as double;

        transactionDb.update(
            _firestore.collection('users').doc(transaction.senderId),
            {'balance': senderBalance + transaction.amount});

        transactionDb.update(
            _firestore.collection('users').doc(transaction.receiverId),
            {'balance': receiverBalance - transaction.amount});

        // Marquer la transaction comme annulée
        transactionDb.update(
            _firestore.collection('transactions').doc(transaction.id),
            {'status': 'cancelled'});

        return true;
      });
    } catch (e) {
      print('Erreur lors de l\'annulation de la transaction: $e');
      rethrow;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      if (email.isEmpty) {
        return null;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final userId = querySnapshot.docs.first.id;

        return userData != null ? User.fromMap(userData, userId) : null;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur par e-mail: $e');
      return null;
    }
  }


  Future<void> addFavorite(String userId, String favoriteUserId) async {
    final favorite = Favorite(
      id: '${userId}_$favoriteUserId',
      userId: userId,
      favoriteUserId: favoriteUserId,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('favorites')
        .doc(favorite.id)
        .set(favorite.toMap());
  }

  // Supprimer un favori
  Future<void> removeFavorite(String userId, String favoriteUserId) async {
    await _firestore
        .collection('favorites')
        .doc('${userId}_$favoriteUserId')
        .delete();
  }

  // Récupérer les favoris d'un utilisateur
  Stream<List<User>> getFavoriteUsersStream(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final favoriteUserIds = snapshot.docs
          .map((doc) => doc.data()['favoriteUserId'] as String)
          .toList();

      if (favoriteUserIds.isEmpty) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: favoriteUserIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => User.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Vérifier si un utilisateur est un favori
  Future<bool> isFavorite(String userId, String favoriteUserId) async {
    final doc = await _firestore
        .collection('favorites')
        .doc('${userId}_$favoriteUserId')
        .get();
    return doc.exists;
  }
  
  Future<void> addScheduledTransfer(ScheduledTransfer transfer) async {
    try {
      await FirebaseFirestore.instance
          .collection('scheduledTransfers')
          .doc(transfer.id)
          .set(transfer.toMap());
    } catch (e) {
      print('Error adding scheduled transfer: $e');
      rethrow;
    }
  }

  Future<void> updateScheduledTransfer(String id, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('scheduledTransfers')
          .doc(id)
          .update(data);
    } catch (e) {
      print('Error updating scheduled transfer: $e');
      rethrow;
    }
  }

  Stream<List<ScheduledTransfer>> getScheduledTransfersStream(String userId) {
    return FirebaseFirestore.instance
        .collection('scheduledTransfers')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduledTransfer.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }
Future<void> deleteScheduledTransfer(String transferId) async {
  try {
    // Supprimer le transfert planifié
    await _firestore.collection('scheduledTransfers').doc(transferId).delete();

    // Supprimer la transaction associée
    await _firestore.collection('transactions')
      .where('id', isEqualTo: transferId)
      .get()
      .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.delete();
        }
      });
  } catch (e) {
    print('Erreur lors de la suppression : $e');
    throw e;
  }
}

}
