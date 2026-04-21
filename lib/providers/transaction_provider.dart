import 'package:flutter/material.dart';
import '../models/summary_model.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  SummaryModel? _summary;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  SummaryModel? get summary => _summary;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> fetchSummary() async {
    _isLoading = true;
    notifyListeners();
    _summary = await TransactionService.getSummary();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    _transactions = await TransactionService.getMyTransactions();
    _isLoading = false;
    notifyListeners();
  }
}
