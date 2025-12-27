import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// =====================
// 1. DATA MODELS
// =====================

class Customer {
  final int id;
  final String name;
  double currentBalance;

  Customer({
    required this.id,
    required this.name,
    this.currentBalance = 0.0,
  });
}

class Transaction {
  final int id;
  final int customerId;
  final DateTime dateAdded;
  final double amount;
  final double runningBalance;
  final bool isDeposit;

  Transaction({
    required this.id,
    required this.customerId,
    required this.dateAdded,
    required this.amount,
    required this.runningBalance,
    required this.isDeposit,
  });
}

// =====================
// 2. MAIN APP
// =====================

void main() {
  runApp(const MoneySavingApp());
}

class MoneySavingApp extends StatelessWidget {
  const MoneySavingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Money Savings',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF2F4F8),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const CustomerListScreen(),
    );
  }
}

// =====================
// 3. SERVICE LAYER (UNCHANGED)
// =====================

class SavingService {
  static int _customerIdCounter = 1;
  static int _transactionIdCounter = 1;

  static final Map<int, Customer> _customers = {};
  static final List<Transaction> _transactions = [];

  static Customer addCustomer(String name) {
    final customer = Customer(id: _customerIdCounter++, name: name);
    _customers[customer.id] = customer;
    return customer;
  }

  static List<Customer> getCustomers() {
    return _customers.values.toList();
  }

  static Transaction? deposit(int customerId, double amount) {
    final customer = _customers[customerId];
    if (customer == null || amount <= 0) return null;

    customer.currentBalance += amount;

    final transaction = Transaction(
      id: _transactionIdCounter++,
      customerId: customerId,
      dateAdded: DateTime.now(),
      amount: amount,
      runningBalance: customer.currentBalance,
      isDeposit: true,
    );

    _transactions.add(transaction);
    return transaction;
  }

  static Transaction? withdraw(int customerId, double amount) {
    final customer = _customers[customerId];
    if (customer == null || amount <= 0 || amount > customer.currentBalance) {
      return null;
    }

    customer.currentBalance -= amount;

    final transaction = Transaction(
      id: _transactionIdCounter++,
      customerId: customerId,
      dateAdded: DateTime.now(),
      amount: amount,
      runningBalance: customer.currentBalance,
      isDeposit: false,
    );

    _transactions.add(transaction);
    return transaction;
  }

  static List<Transaction> getTransactions(int customerId) {
    return _transactions
        .where((t) => t.customerId == customerId)
        .toList()
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  }
}

// =====================
// 4. BEAUTIFUL BALANCE CARD
// =====================

class CurrentBalanceCard extends StatelessWidget {
  final Customer customer;
  final Color color;

  const CurrentBalanceCard({
    super.key,
    required this.customer,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'GH₵${customer.currentBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// 5. CUSTOMER LIST SCREEN (MODERN)
// =====================

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Customer> customers = [];

  void _refresh() {
    setState(() {
      customers = SavingService.getCustomers();
    });
  }

  void _addCustomer() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  SavingService.addCustomer(controller.text.trim());
                  _refresh();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _refresh();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Savings'),
        centerTitle: true,
      ),
      body: customers.isEmpty
          ? const Center(child: Text('No customers added yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              itemBuilder: (_, i) {
                final c = customers[i];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Balance: GH₵${c.currentBalance.toStringAsFixed(2)}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepositScreen(customer: c),
                            ),
                          ).then((_) => _refresh()),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WithdrawScreen(customer: c),
                            ),
                          ).then((_) => _refresh()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TransactionHistoryScreen(customer: c),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// =====================
// 6. DEPOSIT SCREEN (POLISHED)
// =====================

class DepositScreen extends StatelessWidget {
  final Customer customer;
  final controller = TextEditingController();

  DepositScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return _TransactionScreen(
      title: 'Deposit',
      color: Colors.green,
      buttonText: 'Confirm Deposit',
      onSubmit: () {
        final amount = double.tryParse(controller.text);
        if (amount != null && amount > 0) {
          SavingService.deposit(customer.id, amount);
          Navigator.pop(context);
        }
      },
      customer: customer,
      controller: controller,
    );
  }
}

// =====================
// 7. WITHDRAW SCREEN (POLISHED)
// =====================

class WithdrawScreen extends StatelessWidget {
  final Customer customer;
  final controller = TextEditingController();

  WithdrawScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return _TransactionScreen(
      title: 'Withdraw',
      color: Colors.red,
      buttonText: 'Confirm Withdrawal',
      onSubmit: () {
        final amount = double.tryParse(controller.text);
        if (amount != null && amount > 0) {
          SavingService.withdraw(customer.id, amount);
          Navigator.pop(context);
        }
      },
      customer: customer,
      controller: controller,
    );
  }
}

// =====================
// 8. TRANSACTION HISTORY (CLEAN)
// =====================

class TransactionHistoryScreen extends StatelessWidget {
  final Customer customer;

  const TransactionHistoryScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy • hh:mm a');
    final transactions = SavingService.getTransactions(customer.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (_, i) {
          final t = transactions[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    t.isDeposit ? Colors.green : Colors.red,
                child: Icon(
                  t.isDeposit ? Icons.add : Icons.remove,
                  color: Colors.white,
                ),
              ),
              title: Text(
                '${t.isDeposit ? '+' : '-'}GH₵${t.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${formatter.format(t.dateAdded)}\nBalance: GH₵${t.runningBalance.toStringAsFixed(2)}',
              ),
            ),
          );
        },
      ),
    );
  }
}

// =====================
// SHARED TRANSACTION UI
// =====================

class _TransactionScreen extends StatelessWidget {
  final String title;
  final Color color;
  final String buttonText;
  final VoidCallback onSubmit;
  final Customer customer;
  final TextEditingController controller;

  const _TransactionScreen({
    required this.title,
    required this.color,
    required this.buttonText,
    required this.onSubmit,
    required this.customer,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CurrentBalanceCard(customer: customer, color: color),
            const SizedBox(height: 30),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (GH₵)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: onSubmit,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
