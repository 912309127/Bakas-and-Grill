import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// --- AUTHENTICATION GUARD ---
class CashierAuthGuard extends StatelessWidget {
  const CashierAuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // Verify Cashier Role
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFc00e22))));
              }
              if (userSnap.hasData && userSnap.data!.exists) {
                if (userSnap.data!.get('role') == 'cashier') {
                  String name = userSnap.data!.get('name') ?? snapshot.data!.email;
                  return CashierMainScreen(cashierName: name, cashierEmail: snapshot.data!.email!);
                } else {
                  FirebaseAuth.instance.signOut();
                  return const Scaffold(body: Center(child: Text("Unauthorized: Cashier Access Only")));
                }
              }
              return const Scaffold(body: Center(child: Text("User not found.")));
            },
          );
        }
        return const Scaffold(body: Center(child: Text("Please Login First"))); // Redirect to login
      },
    );
  }
}

// --- MAIN CASHIER SCREEN ---
class CashierMainScreen extends StatefulWidget {
  final String cashierName;
  final String cashierEmail;
  const CashierMainScreen({super.key, required this.cashierName, required this.cashierEmail});

  @override
  State<CashierMainScreen> createState() => _CashierMainScreenState();
}

class _CashierMainScreenState extends State<CashierMainScreen> {
  int _selectedIndex = 0; // 0 = POS, 1 = Queue
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf4f7f6),
      body: Row(
        children: [
          // SIDEBAR
          NavigationRail(
            backgroundColor: const Color(0xFFc00e22),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.point_of_sale), label: Text('POS')),
              NavigationRailDestination(icon: Icon(Icons.list_alt), label: Text('Queue')),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ),
              ),
            ),
          ),
          
          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // Top Header
                Container(
                  height: 75,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Bakas & Grill POS", style: TextStyle(color: Color(0xFFc00e22), fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("Cagayan de Oro City, Misamis Oriental", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.account_circle, color: Color(0xFFc00e22)),
                            const SizedBox(width: 10),
                            Text(widget.cashierName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                // Views
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      POSView(cashierEmail: widget.cashierEmail, cashierName: widget.cashierName),
                      const QueueView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 1. POS & CART VIEW ---
class POSView extends StatefulWidget {
  final String cashierEmail;
  final String cashierName;
  const POSView({super.key, required this.cashierEmail, required this.cashierName});

  @override
  State<POSView> createState() => _POSViewState();
}

class _POSViewState extends State<POSView> {
  String _searchQuery = "";
  String _categoryFilter = "All";
  final List<Map<String, dynamic>> _cart = [];
  double _cashTendered = 0.0;
  int _dailyOrderNum = 1;

  final NumberFormat _currency = NumberFormat.currency(symbol: '₱');

  @override
  void initState() {
    super.initState();
    _initDailyOrderNumber();
  }

  Future<void> _initDailyOrderNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString('bg_orderDate') != today) {
      await prefs.setString('bg_orderDate', today);
      await prefs.setInt('bg_orderNum', 1);
    }
    setState(() {
      _dailyOrderNum = prefs.getInt('bg_orderNum') ?? 1;
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    int stock = product['stock'] ?? 0;
    if (stock < 1) return;

    double price = (product['price'] ?? 0).toDouble();
    if (product['promo_discounts'] != null && product['promo_discounts'] > 0) {
      price = price - (price * (product['promo_discounts'] / 100));
    }

    setState(() {
      int index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index != -1) {
        if (_cart[index]['qty'] + 1 > stock) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Limit Reached! Only $stock left.')));
          return;
        }
        _cart[index]['qty']++;
      } else {
        _cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': price,
          'qty': 1,
          'image': product['image'] ?? 'logo.jpg',
          'max_stock': stock,
        });
      }
    });
  }

  void _updateQty(String id, int delta) {
    setState(() {
      int index = _cart.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        int newQty = _cart[index]['qty'] + delta;
        if (newQty > _cart[index]['max_stock']) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limit Reached!')));
           return;
        }
        if (newQty <= 0) {
          _cart.removeAt(index);
        } else {
          _cart[index]['qty'] = newQty;
        }
      }
    });
  }

  Future<void> _processCheckout(double grandTotal, double vatableSales, double vatAmount) async {
    if (_cashTendered < grandTotal) return;

    final String orderNumStr = "#${_dailyOrderNum.toString().padLeft(3, '0')}";
    
    try {
      // 1. Create Order
      await FirebaseFirestore.instance.collection('orders').add({
        'order_number': orderNumStr,
        'cashier_name': widget.cashierEmail,
        'items_sold': _cart.map((e) => {
          'id': e['id'], 'name': e['name'], 'price': e['price'], 'qty': e['qty']
        }).toList(),
        'total_amount': grandTotal,
        'net_sales': vatableSales,
        'vat_amount': vatAmount,
        'payment_method': 'Cash',
        'status': 'Pending',
        'date_completed': FieldValue.serverTimestamp(),
      });

      // 2. Deduct Inventory limits (Batch Write for safety)
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var item in _cart) {
        DocumentReference docRef = FirebaseFirestore.instance.collection('menu_items').doc(item['id']);
        batch.update(docRef, {'stock': FieldValue.increment(-item['qty'])});
      }
      await batch.commit();

      // 3. Print logic goes here (e.g., using the `printing` package)
      // printReceipt(cart, grandTotal, cashTendered);

      // 4. Update local state
      final prefs = await SharedPreferences.getInstance();
      _dailyOrderNum++;
      await prefs.setInt('bg_orderNum', _dailyOrderNum);

      setState(() {
        _cart.clear();
        _cashTendered = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Success! Order sent to kitchen.")));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Checkout Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = _cart.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
    double vatableSales = grandTotal / 1.12;
    double vatAmount = grandTotal - vatableSales;
    double change = _cashTendered - grandTotal;
    bool canCheckout = _cart.isNotEmpty && _cashTendered >= grandTotal;

    return Row(
      children: [
        // LEFT: MENU GRID (Flex 6.5)
        Expanded(
          flex: 65,
          child: Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _categoryFilter,
                      items: ['All', 'Dish', 'Drinks', 'Dessert', 'Grains']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _categoryFilter = v!),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search menu items...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                      ),
                    ),
                  ],
                ),
              ),
              // Grid
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('menu_items').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    var products = snapshot.data!.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
                    
                    // Apply Filters
                    if (_categoryFilter != 'All') {
                      products = products.where((p) => p['category'] == _categoryFilter).toList();
                    }
                    if (_searchQuery.isNotEmpty) {
                      products = products.where((p) => p['name'].toString().toLowerCase().contains(_searchQuery)).toList();
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        var p = products[index];
                        int stock = p['stock'] ?? 0;
                        bool isPhasedOut = p['is_available'] == false;
                        bool isAvail = !isPhasedOut && stock > 0;
                        
                        double finalPrice = (p['price'] ?? 0).toDouble();
                        if (p['promo_discounts'] != null && p['promo_discounts'] > 0) {
                           finalPrice = finalPrice - (finalPrice * (p['promo_discounts'] / 100));
                        }

                        return InkWell(
                          onTap: isAvail ? () => _addToCart(p) : null,
                          child: Card(
                            elevation: 2,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, color: Colors.grey, size: 40)), // Replace with Image.network if URL exists
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(p['name'] ?? '', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(_currency.format(finalPrice), style: const TextStyle(color: Color(0xFFc00e22), fontWeight: FontWeight.bold, fontSize: 15)),
                                                Text("Stock: $stock", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                if (p['promo_discounts'] != null && p['promo_discounts'] > 0)
                                  Positioned(
                                    top: 5, right: 5,
                                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: Colors.amber, child: Text("${p['promo_discounts']}% OFF", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  ),
                                if (!isAvail)
                                  Container(
                                    color: Colors.white.withOpacity(0.7),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        color: Colors.red,
                                        child: Text(isPhasedOut ? "PHASED OUT" : "OUT OF STOCK", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),
              )
            ],
          ),
        ),
        
        // RIGHT: CART SECTION (Flex 3.5)
        Expanded(
          flex: 35,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Cart Header
                Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.grey.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Current Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFc00e22), borderRadius: BorderRadius.circular(5)),
                        child: Text("Order #${_dailyOrderNum.toString().padLeft(3, '0')}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                
                // Cart Items List
                Expanded(
                  child: _cart.isEmpty 
                    ? const Center(child: Text("Cart is empty\nSelect products from menu", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(15),
                        itemCount: _cart.length,
                        separatorBuilder: (_, __) => const Divider(height: 30),
                        itemBuilder: (context, index) {
                          var item = _cart[index];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(_currency.format(item['price'] * item['qty']), style: const TextStyle(color: Color(0xFFc00e22), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQty(item['id'], -1)),
                                  Text("${item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQty(item['id'], 1)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _cart.removeAt(index))),
                                ],
                              )
                            ],
                          );
                        },
                      ),
                ),
                
                // Cart Summary & Checkout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFfdfdfd),
                    border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Vatable Sales"), Text(_currency.format(vatableSales))]),
                      const SizedBox(height: 5),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("VAT (12%)"), Text(_currency.format(vatAmount))]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(_currency.format(grandTotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 15),
                      
                      // Payment Box
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFc00e22)), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Cash Tendered:", style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                    decoration: const InputDecoration(isDense: true, prefixText: "₱ "),
                                    onChanged: (v) => setState(() => _cashTendered = double.tryParse(v) ?? 0.0),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Change:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(change >= 0 ? _currency.format(change) : "₱0.00", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFc00e22),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          onPressed: canCheckout ? () => _processCheckout(grandTotal, vatableSales, vatAmount) : null,
                          child: const Text("Proceed to Queue & Print", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}

// --- 2. QUEUE MANAGER VIEW ---
class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      color: const Color(0xFFf4f7f6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Customer Queue Manager", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const Text("Track kitchen progress and deliver orders.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Firebase 'in' queries allow fetching both statuses concurrently.
              stream: FirebaseFirestore.instance.collection('orders')
                  .where('status', whereIn: ['Pending', 'Prepared'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var orders = snapshot.data!.docs;
                // Sort by oldest first locally 
                orders.sort((a, b) {
                  Timestamp tA = a['date_completed'] ?? Timestamp.now();
                  Timestamp tB = b['date_completed'] ?? Timestamp.now();
                  return tA.compareTo(tB);
                });

                if (orders.isEmpty) {
                  return const Center(child: Text("No active orders in the queue.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var doc = orders[index];
                    Map<String, dynamic> o = doc.data() as Map<String, dynamic>;
                    bool isPrepared = o['status'] == 'Prepared';
                    
                    DateTime date = (o['date_completed'] as Timestamp?)?.toDate() ?? DateTime.now();
                    String timeStr = DateFormat('hh:mm a').format(date);
                    List items = o['items_sold'] ?? [];

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border(top: BorderSide(color: isPrepared ? Colors.green : Colors.amber, width: 6)),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Badge
                            Align(
                              alignment: Alignment.topRight,
                              child: Chip(
                                backgroundColor: isPrepared ? Colors.green : Colors.amber,
                                label: Text(
                                  isPrepared ? "READY TO SERVE" : "COOKING",
                                  style: TextStyle(color: isPrepared ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            // Order Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(o['order_number'] ?? 'Order', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                    Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                                Text("₱${(o['total_amount'] ?? 0).toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFc00e22))),
                              ],
                            ),
                            const Divider(height: 30),
                            // Items List
                            Expanded(
                              child: ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text("${items[i]['qty']}x ${items[i]['name']}", style: const TextStyle(fontSize: 16)),
                                  );
                                },
                              ),
                            ),
                            // Action Buttons
                            if (isPrepared)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      icon: const Icon(Icons.local_shipping, color: Colors.white),
                                      label: const Text("Deliver", style: TextStyle(color: Colors.white)),
                                      onPressed: () => FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'status': 'Completed'}),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      label: const Text("Remove", style: TextStyle(color: Colors.white)),
                                      onPressed: () => FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'status': 'Cancelled'}),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                                child: const Text("Waiting for Kitchen...", textAlign: TextAlign.center, style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}