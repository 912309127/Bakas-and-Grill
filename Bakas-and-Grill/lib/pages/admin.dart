import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Generate via flutterfire configure
  );
  runApp(const BakasAdminApp());
}

class BakasAdminApp extends StatelessWidget {
  const BakasAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bakas & Grill - Admin',
      theme: ThemeData(
        primaryColor: const Color(0xFFe61029),
        scaffoldBackgroundColor: const Color(0xFFf4f7f6),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFe61029),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const AdminAuthGuard(),
    );
  }
}

// --- AUTHENTICATION GUARD ---
class AdminAuthGuard extends StatelessWidget {
  const AdminAuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // Verify Admin Role
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (userSnap.hasData && userSnap.data!.exists) {
                if (userSnap.data!.get('role') == 'admin') {
                  return const AdminMainScreen();
                } else {
                  FirebaseAuth.instance.signOut();
                  return const Scaffold(body: Center(child: Text("Unauthorized: Admin Access Only")));
                }
              }
              return const Scaffold(body: Center(child: Text("User not found in database.")));
            },
          );
        }
        return const Scaffold(body: Center(child: Text("Please Login First"))); // Replace with your Login Screen
      },
    );
  }
}

// --- MAIN ADMIN SCREEN & SIDEBAR ---
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  
  final List<String> _titles = [
    'Home Dashboard', 'Financials', 'Requests', 'Inventory', 
    'Menu / Products', 'Employees', 'Add User', 'Archive'
  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // RED SIDEBAR
          NavigationRail(
            backgroundColor: const Color(0xFFc00e22),
            extended: isDesktop,
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('Financials')),
              NavigationRailDestination(icon: Icon(Icons.list_alt), label: Text('Requests')),
              NavigationRailDestination(icon: Icon(Icons.inventory), label: Text('Inventory')),
              NavigationRailDestination(icon: Icon(Icons.restaurant_menu), label: Text('Menu / Products')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Employees')),
              NavigationRailDestination(icon: Icon(Icons.person_add), label: Text('Add User')),
              NavigationRailDestination(icon: Icon(Icons.archive), label: Text('Archive')),
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
                    tooltip: 'Logout',
                  ),
                ),
              ),
            ),
          ),
          
          // MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top Header
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(_titles[_selectedIndex], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {}, // Trigger PDF generation/printing logic here
                        icon: const Icon(Icons.print),
                        label: const Text("Print Report"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      )
                    ],
                  ),
                ),
                // Dynamic View Section
                Expanded(
                  child: Container(
                    color: const Color(0xFFf4f7f6),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildCurrentSection(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_selectedIndex) {
      case 0: return const DashboardSection();
      case 3: return const InventorySection();
      case 4: return const ProductsSection(); // Includes the complex Recipe Builder
      default: return Center(child: Text("${_titles[_selectedIndex]} - Implementation pending"));
    }
  }
}

// --- 1. DASHBOARD SECTION ---
class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Listening to real-time updates for metrics
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnap) {
        if (!orderSnap.hasData) return const CircularProgressIndicator();
        
        double dailySales = 0;
        int dailyOrders = 0;
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);

        for (var doc in orderSnap.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['date_completed'] != null && data['status'] != 'Cancelled') {
            DateTime date = (data['date_completed'] as Timestamp).toDate();
            if (date.isAfter(startOfDay)) {
              dailySales += data['total_amount'] ?? 0;
              dailyOrders++;
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Row
            Row(
              children: [
                Expanded(child: _metricCard("Daily Sales", "₱${NumberFormat('#,##0.00').format(dailySales)}", Icons.monetization_on)),
                const SizedBox(width: 20),
                Expanded(child: _metricCard("Daily Orders", "$dailyOrders", Icons.shopping_cart)),
                const SizedBox(width: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'Pending').snapshots(),
                    builder: (context, reqSnap) {
                      int pending = reqSnap.hasData ? reqSnap.data!.docs.length : 0;
                      return _metricCard("Pending Requests", "$pending", Icons.access_time);
                    }
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Chart Placeholder
            Container(
              height: 400,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text("fl_chart LineChart implementation goes here")),
            ),
          ],
        );
      }
    );
  }

  Widget _metricCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: Color(0xFFe61029), width: 5)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFe61029)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

// --- 2. INVENTORY SECTION ---
class InventorySection extends StatefulWidget {
  const InventorySection({super.key});

  @override
  State<InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<InventorySection> {
  final _nameCtrl = TextEditingController();
  String _cat = 'Meat';
  String _unit = 'Grams';

  void _addIngredient() {
    if (_nameCtrl.text.isEmpty) return;
    FirebaseFirestore.instance.collection('ingredients').doc(_nameCtrl.text).set({
      'name': _nameCtrl.text,
      'category': _cat,
      'unit': _unit,
      'stock_level': 0,
    });
    _nameCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingredient Added!')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ADD FORM
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add New Ingredient", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _cat,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Meat', 'Crops', 'Seasonings', 'Spices'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _cat = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Grams', 'Milliliter', 'Pieces'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addIngredient,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(20)),
                    child: const Text("Add"),
                  )
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // DATA TABLE
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ingredients').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return DataTable(
                columns: const [
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Item Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Stock Level')),
                  DataColumn(label: Text('Unit')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  double stock = (data['stock_level'] ?? 0).toDouble();
                  Color badgeColor = stock <= 0 ? Colors.red : (stock < 2000 ? Colors.orange : Colors.green);
                  String statText = stock <= 0 ? 'Out of Stock' : (stock < 2000 ? 'Low Stock' : 'Available');

                  return DataRow(cells: [
                    DataCell(Chip(label: Text(statText, style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: badgeColor)),
                    DataCell(Text(data['name'])),
                    DataCell(Text(data['category'])),
                    DataCell(Text(stock.toString())),
                    DataCell(Text(data['unit'])),
                    DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete())),
                  ]);
                }).toList(),
              );
            }
          ),
        )
      ],
    );
  }
}

// --- 3. PRODUCTS SECTION (WITH RECIPE BUILDER) ---
class ProductsSection extends StatefulWidget {
  const ProductsSection({super.key});

  @override
  State<ProductsSection> createState() => _ProductsSectionState();
}

// Recipe row model
class RecipeItem {
  String? ingredientName;
  double quantity;
  RecipeItem({this.ingredientName, this.quantity = 0});
}

class _ProductsSectionState extends State<ProductsSection> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _cat = 'Dish';
  
  final List<RecipeItem> _recipeItems = [];
  List<String> _availableIngredients = [];

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
  }

  void _fetchIngredients() async {
    var snap = await FirebaseFirestore.instance.collection('ingredients').get();
    setState(() {
      _availableIngredients = snap.docs.map((doc) => doc.id).toList();
    });
  }

  void _deployProduct() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;

    // 1. Create Menu Item
    await FirebaseFirestore.instance.collection('menu_items').doc(_nameCtrl.text).set({
      'name': _nameCtrl.text,
      'category': _cat,
      'price': double.parse(_priceCtrl.text),
      'image': _urlCtrl.text,
      'is_available': true,
      'promo_discounts': 0,
      'stock': 0,
    });

    // 2. Map recipes for backend
    Map<String, double> recipeMap = {};
    for (var item in _recipeItems) {
      if (item.ingredientName != null && item.quantity > 0) {
        recipeMap[item.ingredientName!] = item.quantity;
      }
    }

    // 3. Create Recipe Document
    if (recipeMap.isNotEmpty) {
      await FirebaseFirestore.instance.collection('recipes').doc(_nameCtrl.text).set({
        'ingredients': recipeMap
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product Deployed Successfully!')));
    setState(() {
      _nameCtrl.clear(); _priceCtrl.clear(); _urlCtrl.clear(); _recipeItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PRODUCT FORM & RECIPE BUILDER
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create New Product & Recipe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Dish Name', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _cat,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Dish', 'Drinks', 'Dessert', 'Grains'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _cat = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₱)', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Photo URL', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 20),
              
              // Dynamic Recipe Builder
              const Text("Ingredients Computation Setup", style: TextStyle(color: Color(0xFFe61029), fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._recipeItems.asMap().entries.map((entry) {
                int idx = entry.key;
                RecipeItem item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: item.ingredientName,
                          hint: const Text('Select Ingredient'),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: _availableIngredients.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => item.ingredientName = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty (e.g. 100)', border: OutlineInputBorder()),
                          onChanged: (v) => item.quantity = double.tryParse(v) ?? 0,
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() => _recipeItems.removeAt(idx))),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _recipeItems.add(RecipeItem())),
                icon: const Icon(Icons.add),
                label: const Text("Add Ingredient Row"),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(onPressed: _deployProduct, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Proceed & Deploy Product")),
              )
            ],
          ),
        ),
      ],
    );
  }
}