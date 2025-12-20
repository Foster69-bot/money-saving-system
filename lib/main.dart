import 'package:flutter/material.dart';

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
      title: 'Money Savings System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A2980)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2BC0E4),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const CustomerListScreen(),
    );
  }
}

// =====================
// 3. SERVICE LAYER
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
      ..sort((a, b) => b.id.compareTo(a.id));
  }
}

// =====================
// 4. BALANCE CARD
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            'GH₵${customer.currentBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// 5. CUSTOMER LIST
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Customer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Customer Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                SavingService.addCustomer(controller.text.trim());
                _refresh();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _refresh();

    return Scaffold(
      appBar: AppBar(title: const Text('Money Savings System')),
      body: customers.isEmpty
          ? const Center(child: Text('No customers added yet'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (_, i) {
                final c = customers[i];
                return Card(
                  child: ListTile(
                    title: Text(c.name),
                    subtitle:
                        Text('Balance: GH₵${c.currentBalance.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepositScreen(customer: c),
                            ),
                          ).then((_) => _refresh()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
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
// 6. DEPOSIT SCREEN
// =====================

class DepositScreen extends StatelessWidget {
  final Customer customer;
  final controller = TextEditingController();

  DepositScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CurrentBalanceCard(customer: customer, color: Colors.green),
            const SizedBox(height: 30),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (GH₵)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  SavingService.deposit(customer.id, amount);
                  Navigator.pop(context);
                }
              },
              child: const Text('Deposit'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// 7. WITHDRAW SCREEN
// =====================

class WithdrawScreen extends StatelessWidget {
  final Customer customer;
  final controller = TextEditingController();

  WithdrawScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CurrentBalanceCard(customer: customer, color: Colors.red),
            const SizedBox(height: 30),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (GH₵)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  SavingService.withdraw(customer.id, amount);
                  Navigator.pop(context);
                }
              },
              child: const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// 8. TRANSACTION HISTORY
// =====================

class TransactionHistoryScreen extends StatelessWidget {
  final Customer customer;

  const TransactionHistoryScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final transactions =
        SavingService.getTransactions(customer.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions yet'))
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (_, i) {
                final t = transactions[i];
                return ListTile(
                  leading: Icon(
                    t.isDeposit ? Icons.arrow_upward : Icons.arrow_downward,
                    color: t.isDeposit ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    '${t.isDeposit ? "+" : "-"}GH₵${t.amount.toStringAsFixed(2)}',
                  ),
                  subtitle:
                      Text('Balance: GH₵${t.runningBalance.toStringAsFixed(2)}'),
                );
              },
            ),
    );
  }
}
