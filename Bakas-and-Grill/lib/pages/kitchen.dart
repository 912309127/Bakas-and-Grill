import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- EXACT CSS VARIABLES MAPPED TO FLUTTER ---
class AppColors {
  static const Color primary = Color(0xFFc00e22);
  static const Color primaryHover = Color(0xFF8a0916);
  static const Color sidebarBg = Color(0xFFc00e22);
  static const Color bg = Color(0xFFf0f2f5);
  static const Color textDark = Color(0xFF2c3e50);
  static const Color cardBg = Color(0xFFffffff);
  static const Color border = Color(0xFFe2e8f0);
  static const Color success = Color(0xFF10b981);
  static const Color warning = Color(0xFFf59e0b);
  static const Color danger = Color(0xFFef4444);
  static const Color info = Color(0xFF3b82f6);
  
  static const Color availBg = Color(0xFFd1fae5);
  static const Color availText = Color(0xFF047857);
  static const Color lowBg = Color(0xFFfef3c7);
  static const Color lowText = Color(0xFFb45309);
  static const Color outBg = Color(0xFFfee2e2);
  static const Color outText = Color(0xFFb91c1c);
}

// --- GLOBAL LOW STOCK THRESHOLD LOGIC ---
bool isItemLowStock(double stock, String unit) {
  if (stock <= 0) return false; // Handled separately as Out of Stock
  String u = unit.toLowerCase();
  if (u.contains('gram') || u == 'g') return stock < 1500;
  if (u.contains('mili') || u.contains('ml') || u.contains('milliliter')) return stock < 1000;
  if (u.contains('piece') || u.contains('pcs') || u == 'pc') return stock < 20;
  return stock < 20; // Fallback
}

class KitchenDashboard extends StatefulWidget {
  const KitchenDashboard({super.key});

  @override
  State<KitchenDashboard> createState() => _KitchenDashboardState();
}

class _KitchenDashboardState extends State<KitchenDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String _currentView = 'dashboard';
  String _staffName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          // Changed to 'name' to match your database exactly
          _staffName = userDoc.get('name') ?? user.email ?? "Kitchen Staff";
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ==========================================
  // SIDEBAR NAVIGATION
  // ==========================================
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.1), width: 1)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/image/logo.jpg', 
                    width: 40, 
                    height: 40, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Kitchen Hub', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: AppColors.primary)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_staffName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                      const Text('Kitchen Staff', style: TextStyle(color: Color(0xFFfca5a5), fontSize: 13)),
                    ],
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildNavItem('dashboard', 'Dashboard Overview', Icons.dashboard),
                _buildNavItem('orders', 'Live Orders', Icons.local_fire_department),
                _buildNavItem('inventory', 'Live Inventory', Icons.inventory_2),
                _buildNavItem('cooking', 'Cooking Station', Icons.soup_kitchen),
                _buildNavItem('requests', 'Supply Requests', Icons.assignment),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.primary, size: 20),
              label: const Text('Logout', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(String id, String title, IconData icon) {
    bool isActive = _currentView == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _currentView = id);
          if (MediaQuery.of(context).size.width < 900 && _scaffoldKey.currentState?.isDrawerOpen == true) {
            Navigator.pop(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: isActive ? const Color.fromRGBO(255, 255, 255, 0.1) : Colors.transparent,
            border: Border(left: BorderSide(color: isActive ? Colors.white : Colors.transparent, width: 4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? Colors.white : const Color(0xFFfca5a5), size: 20),
              const SizedBox(width: 15),
              Text(title, style: TextStyle(color: isActive ? Colors.white : const Color(0xFFfca5a5), fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW ROUTER
  // ==========================================
  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'orders': return const OrdersView();
      case 'inventory': return const InventoryView();
      case 'cooking': return const CookingStationView();
      case 'requests': return SupplyRequestView(staffName: _staffName);
      case 'dashboard':
      default:
        return _buildDashboardView();
    }
  }

  // ==========================================
  // VIEW 1: DASHBOARD (FULLY RESPONSIVE)
  // ==========================================
  Widget _buildDashboardView() {
    bool isDesktop = MediaQuery.of(context).size.width >= 900;

    Widget statCards = _buildStatCards(isDesktop);
    Widget lowStockPanel = _buildLowStockPanel(isDesktop);
    Widget recentActivityPanel = _buildRecentActivityPanel(isDesktop);

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statCards,
            const SizedBox(height: 30),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: lowStockPanel),
                  const SizedBox(width: 30),
                  Expanded(flex: 7, child: recentActivityPanel),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statCards,
            const SizedBox(height: 25),
            lowStockPanel,
            const SizedBox(height: 25),
            recentActivityPanel,
            const SizedBox(height: 40), 
          ],
        ),
      );
    }
  }

  Widget _buildStatCards(bool isDesktop) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ingredients').snapshots(),
      builder: (context, invSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('requests').snapshots(),
          builder: (context, reqSnap) {
            int lowStockCount = 0;
            int outOfStockCount = 0;
            if (invSnap.hasData) {
              for (var doc in invSnap.data!.docs) {
                double stock = (doc.data() as Map<String, dynamic>).containsKey('stock_level') ? (doc['stock_level'] ?? 0).toDouble() : 0;
                String unit = (doc.data() as Map<String, dynamic>).containsKey('unit') ? doc['unit'] : 'Grams';
                
                if (stock <= 0) outOfStockCount++;
                else if (isItemLowStock(stock, unit)) lowStockCount++;
              }
            }

            int pendingReqs = 0;
            int approvedToday = 0;
            if (reqSnap.hasData) {
              for (var doc in reqSnap.data!.docs) {
                String status = (doc.data() as Map<String, dynamic>).containsKey('status') ? doc['status'] : 'Pending';
                if (status == 'Pending') pendingReqs++;
                if (status == 'Approved') {
                  if ((doc.data() as Map<String, dynamic>).containsKey('timestamp') && doc['timestamp'] != null) {
                    DateTime dt = (doc['timestamp'] as Timestamp).toDate();
                    if (dt.day == DateTime.now().day) approvedToday++;
                  }
                }
              }
            }

            Widget rowOfCards = Row(
              children: [
                Expanded(child: _buildSingleStatCard('Low Stock', lowStockCount.toString(), Icons.warning_amber_rounded, AppColors.warning)),
                const SizedBox(width: 15),
                Expanded(child: _buildSingleStatCard('Pending', pendingReqs.toString(), Icons.hourglass_empty, AppColors.info)),
                const SizedBox(width: 15),
                Expanded(child: _buildSingleStatCard('Approved', approvedToday.toString(), Icons.check_circle_outline, AppColors.success)),
                const SizedBox(width: 15),
                Expanded(child: _buildSingleStatCard('Out of Stock', outOfStockCount.toString(), Icons.error_outline, AppColors.danger)),
              ],
            );

            if (isDesktop) return rowOfCards;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 750, 
                child: rowOfCards,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSingleStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 20, offset: Offset(0, 4))]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748b), fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLowStockPanel(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 20, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items to Restock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Icon(Icons.warning, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ingredients').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              
              var lowStockItems = snap.data!.docs.where((doc) {
                double stock = (doc.data() as Map<String, dynamic>).containsKey('stock_level') ? (doc['stock_level'] ?? 0).toDouble() : 0;
                String unit = (doc.data() as Map<String, dynamic>).containsKey('unit') ? doc['unit'] : 'Grams';
                return stock > 0 && isItemLowStock(stock, unit);
              }).toList();

              if (lowStockItems.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No items critically low.', style: TextStyle(color: Color(0xFF94a3b8)))));
              }

              Widget list = ListView.builder(
                shrinkWrap: !isDesktop, 
                physics: isDesktop ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(), 
                itemCount: lowStockItems.length,
                itemBuilder: (context, index) {
                  var item = lowStockItems[index];
                  double stock = (item.data() as Map<String, dynamic>).containsKey('stock_level') ? (item['stock_level'] ?? 0).toDouble() : 0;
                  String unit = (item.data() as Map<String, dynamic>).containsKey('unit') ? item['unit'] : 'g';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfffbeb),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFfde68a)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Text((item.data() as Map<String, dynamic>).containsKey('name') ? item['name'] : 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          ],
                        ),
                        Text('$stock $unit', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                      ],
                    ),
                  );
                },
              );

              return isDesktop ? Expanded(child: list) : list;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityPanel(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 20, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('requests').orderBy('timestamp', descending: true).limit(10).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No recent activity.', style: TextStyle(color: Color(0xFF94a3b8)))));
              }

              Widget list = ListView.builder(
                shrinkWrap: !isDesktop, 
                physics: isDesktop ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(), 
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, index) {
                  var req = snap.data!.docs[index];
                  String status = (req.data() as Map<String, dynamic>).containsKey('status') ? req['status'] : 'Pending';
                  String timeStr = "Just now";
                  if ((req.data() as Map<String, dynamic>).containsKey('timestamp') && req['timestamp'] != null) {
                    timeStr = DateFormat('MMM dd, hh:mm a').format((req['timestamp'] as Timestamp).toDate());
                  }

                  IconData icon = Icons.timer;
                  Color iconColor = AppColors.warning;
                  if (status == 'Approved') { icon = Icons.check_circle; iconColor = AppColors.success; }
                  else if (status == 'Rejected') { icon = Icons.cancel; iconColor = AppColors.danger; }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.only(bottom: 15),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFf8fafc), borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Requested ${req['quantity']} ${req['unit']} of ${req['itemName']}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              Text('Requested by ${req['kitchen_staff']} • $timeStr', style: const TextStyle(fontSize: 12, color: Color(0xFF64748b))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: status == 'Approved' ? AppColors.availBg : (status == 'Rejected' ? AppColors.outBg : const Color(0xFFf1f5f9)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: status == 'Approved' ? AppColors.availText : (status == 'Rejected' ? AppColors.outText : const Color(0xFF475569)))),
                        )
                      ],
                    ),
                  );
                },
              );

              return isDesktop ? Expanded(child: list) : list;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: isDesktop ? null : AppBar(
        title: const Text('Kitchen Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.sidebarBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(child: _buildCurrentView()),
        ],
      ),
    );
  }
}

// ==========================================
// VIEW 1.5: ORDERS TICKET VIEW
// ==========================================
class OrdersView extends StatelessWidget {
  const OrdersView({Key? key}) : super(key: key);

  Future<void> _markComplete(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': 'Completed'});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Order Tickets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 5),
          const Text('Orders currently pending preparation.', style: TextStyle(color: Color(0xFF64748b), fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'Pending').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(50),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFcbd5e1), width: 2)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 50, color: AppColors.success),
                        SizedBox(height: 15),
                        Text('All Caught Up!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        Text('No pending orders in the queue.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94a3b8))),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisExtent: 280,
                    crossAxisSpacing: 25,
                    mainAxisSpacing: 25,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    var id = docs[index].id;
                    
                    String timeStr = 'Just Now';
                    if (data['date_completed'] != null && data['date_completed'] is Timestamp) {
                       timeStr = DateFormat('hh:mm a').format((data['date_completed'] as Timestamp).toDate());
                    }

                    List<dynamic> items = data['items_sold'] ?? [];

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 15, offset: Offset(0, 6))],
                        border: const Border(top: BorderSide(color: AppColors.warning, width: 6)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            decoration: const BoxDecoration(color: Color(0xFFfff8e6), border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(data['order_number']?.toString() ?? 'Order', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFb45309))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFfef3c7), borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 13, color: Color(0xFF92400e)),
                                      const SizedBox(width: 5),
                                      Text(timeStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400e))),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(color: AppColors.border, thickness: 1, height: 16),
                              itemBuilder: (context, i) {
                                var item = items[i];
                                return Row(
                                  children: [
                                    Text('${item['qty']}x', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16)),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                                  ],
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            decoration: const BoxDecoration(
                              color: Color(0xFFf8fafc),
                              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _markComplete(id),
                                icon: const Icon(Icons.check, color: Colors.white, size: 16),
                                label: const Text('Mark as Prepared', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.all(12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// VIEW 2: INVENTORY
// ==========================================
class InventoryView extends StatefulWidget {
  const InventoryView({Key? key}) : super(key: key);
  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Inventory Status', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 5),
          const Text('Real-time tracking for kitchen ingredients.', style: TextStyle(color: Color(0xFF64748b))),
          const SizedBox(height: 20),
          
          Container(
            width: isMobile ? double.infinity : 350,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF94a3b8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(hintText: 'Search ingredients...', border: InputBorder.none, isDense: true),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ingredients').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs.where((d) {
                  var data = d.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 280, mainAxisExtent: 210, crossAxisSpacing: 20, mainAxisSpacing: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    double stock = data.containsKey('stock_level') ? (data['stock_level'] ?? 0).toDouble() : 0;
                    String unit = data.containsKey('unit') ? data['unit'] : 'Grams';
                    bool isLow = isItemLowStock(stock, unit);
                    
                    Color statusBg = AppColors.availBg;
                    Color statusText = AppColors.availText;
                    String statusLabel = 'AVAILABLE';
                    Color borderBottom = AppColors.success;
                    Color cardBg = AppColors.cardBg;

                    if (stock <= 0) {
                      statusBg = AppColors.outBg; statusText = AppColors.outText;
                      statusLabel = 'OUT OF STOCK'; borderBottom = AppColors.danger; cardBg = const Color(0xFFfff5f5);
                    } else if (isLow) {
                      statusBg = AppColors.lowBg; statusText = AppColors.lowText;
                      statusLabel = 'LOW STOCK'; borderBottom = AppColors.warning; cardBg = const Color(0xFFfffdf5);
                    }

                    return Container(
                      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 25),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 15, offset: Offset(0, 4))], border: Border(bottom: BorderSide(color: borderBottom, width: 5))),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -23, right: -8, 
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                              child: Text(statusLabel, style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2, size: 30, color: Color(0xFFcbd5e1)),
                                const SizedBox(height: 10),
                                Text(data.containsKey('name') ? data['name'] : 'Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF475569)), textAlign: TextAlign.center),
                                const SizedBox(height: 5),
                                Text(stock.toStringAsFixed(0), style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: stock <= 0 ? AppColors.danger : AppColors.textDark, height: 1)),
                                const SizedBox(height: 5),
                                Text(unit.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94a3b8), letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// VIEW 3: COOKING STATION (WITH STRICT VALIDATION)
// ==========================================
class CookingStationView extends StatefulWidget {
  const CookingStationView({Key? key}) : super(key: key);
  @override
  State<CookingStationView> createState() => _CookingStationViewState();
}

class _CookingStationViewState extends State<CookingStationView> {
  String? _selectedDishId;
  int _servings = 1;
  bool _isProcessing = false;

  Future<void> _processCooking() async {
    setState(() => _isProcessing = true);
    try {
      DocumentSnapshot recipeDoc = await FirebaseFirestore.instance.collection('recipes').doc(_selectedDishId).get();
      if (!recipeDoc.exists) throw Exception("Recipe not found!");
      Map<String, dynamic> ingredients = recipeDoc.get('ingredients');

      // PRE-TRANSACTION VALIDATION CHECK
      for (String ingName in ingredients.keys) {
        DocumentSnapshot ingSnap = await FirebaseFirestore.instance.collection('ingredients').doc(ingName).get();
        double needed = (ingredients[ingName] as num).toDouble() * _servings;
        double available = 0;
        if (ingSnap.exists) {
          Map<String, dynamic> data = ingSnap.data() as Map<String, dynamic>;
          available = data.containsKey('stock_level') ? (data['stock_level'] ?? 0).toDouble() : 0;
        }

        if (available < needed) {
          // Validation stops it right here and shows clear exact error
          throw Exception("Validation Failed: Insufficient '$ingName' in Inventory.\n\nYou need $needed but only have $available.");
        }
      }

      // PROCEED IF VALIDATION PASSED
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        for (String ingName in ingredients.keys) {
          DocumentReference ingRef = FirebaseFirestore.instance.collection('ingredients').doc(ingName);
          double needed = (ingredients[ingName] as num).toDouble() * _servings;
          transaction.update(ingRef, {'stock_level': FieldValue.increment(-needed)});
        }

        DocumentReference menuRef = FirebaseFirestore.instance.collection('menu_items').doc(_selectedDishId);
        transaction.update(menuRef, {'stock': FieldValue.increment(_servings)});
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cook Successful! Inventory explicitly deducted.'), backgroundColor: AppColors.success));
      setState(() { _selectedDishId = null; _servings = 1; });
    } catch (e) {
      // Show exact validation error directly
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')), 
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 900;

    // LEFT CARD: FORM
    Widget leftCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 20, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Vital for scrolling safely
        children: [
          const Text('Prepare Menu Item', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('Select a dish to automatically deduct exact ingredient amounts from the inventory.', style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
          const SizedBox(height: 25),
          
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Dish to Cook:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('menu_items').snapshots(),
                  builder: (context, menuSnap) {
                    if (!menuSnap.hasData) return const LinearProgressIndicator();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: const Color(0xFFf8fafc), border: Border.all(color: AppColors.border, width: 2), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedDishId,
                          hint: const Text('-- Choose Dish --', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                          items: menuSnap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text((doc.data() as Map<String, dynamic>).containsKey('name') ? doc['name'] : 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                          onChanged: (val) => setState(() => _selectedDishId = val),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Number of Servings / Batches:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: "1",
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFf8fafc),
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border, width: 2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                  onChanged: (val) => setState(() => _servings = int.tryParse(val) ?? 1),
                ),
              ],
            ),
          ),
          
          if (isDesktop) const Spacer() else const SizedBox(height: 10),
          
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_selectedDishId == null || _isProcessing) ? null : _processCooking,
              icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.restaurant, color: Colors.white),
              label: Text(_isProcessing ? 'Processing...' : 'Cook & Deduct Inventory', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFcbd5e1),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );

    // RIGHT CARD: PREVIEW
    Widget rightCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 20, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Vital for scrolling safely
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 2))),
            child: const Row(
              children: [
                Icon(Icons.balance, color: Color(0xFF1e293b)),
                SizedBox(width: 10),
                Text('Ingredient Validation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1e293b))),
              ],
            ),
          ),
          
          if (_selectedDishId == null)
            const Padding(padding: EdgeInsets.only(top: 20, bottom: 20), child: Center(child: Text('Select a dish to preview requirements.', style: TextStyle(color: Color(0xFF94a3b8), fontStyle: FontStyle.italic))))
          else
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('recipes').doc(_selectedDishId).snapshots(),
              builder: (context, recipeSnap) {
                if (!recipeSnap.hasData) return const Center(child: CircularProgressIndicator());
                if (!recipeSnap.data!.exists) return const Center(child: Text("Recipe not found."));
                
                Map<String, dynamic> ingredientsMap = recipeSnap.data!.get('ingredients');
                
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('ingredients').snapshots(),
                  builder: (context, invSnap) {
                    if (!invSnap.hasData) return const Center(child: CircularProgressIndicator());
                    
                    Map<String, double> currentInv = {};
                    for (var doc in invSnap.data!.docs) {
                      currentInv[doc.id] = (doc.data() as Map<String, dynamic>).containsKey('stock_level') ? (doc['stock_level'] ?? 0).toDouble() : 0;
                    }

                    bool canCook = true;
                    List<Widget> reqList = [];

                    ingredientsMap.forEach((ingName, qtyPerServing) {
                      double totalNeeded = (qtyPerServing as num).toDouble() * _servings;
                      double available = currentInv[ingName] ?? 0;
                      bool shortage = available < totalNeeded;
                      if (shortage) canCook = false;

                      reqList.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: shortage ? const Color(0xFFfff5f5) : const Color(0xFFf8fafc),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(left: BorderSide(color: shortage ? AppColors.danger : AppColors.success, width: 4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(shortage ? Icons.error : Icons.check_circle, color: shortage ? AppColors.danger : AppColors.success, size: 16),
                                  const SizedBox(width: 8),
                                  Text(ingName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('$totalNeeded needed', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: shortage ? AppColors.danger : AppColors.textDark)),
                                  if (shortage) Text('Only $available avail.', style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                                ],
                              )
                            ],
                          ),
                        )
                      );
                    });

                    Widget listWidget = ListView(
                      shrinkWrap: !isDesktop, // Magic responsive shrink
                      physics: isDesktop ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                      children: reqList,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(margin: const EdgeInsets.only(bottom: 15), child: Text('Requirements for $_servings batch(es):', style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600))),
                        isDesktop ? Expanded(child: listWidget) : listWidget,
                        if (!canCook)
                          Container(
                            width: double.infinity, margin: const EdgeInsets.only(top: 15), padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Color(0xFFfff5f5), border: Border(left: BorderSide(color: AppColors.danger, width: 4))),
                            child: const Text('Validation Failed: Insufficient Ingredients in Inventory.', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                          )
                      ],
                    );
                  },
                );
              },
            )
        ],
      ),
    );

    // ===================================
    // RESPONSIVE LAYOUT SWITCH
    // ===================================
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [ 
            Expanded(child: leftCard), 
            const SizedBox(width: 30), 
            Expanded(child: rightCard) 
          ]
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [ 
            leftCard, 
            const SizedBox(height: 25), 
            rightCard, 
            const SizedBox(height: 40) // Bottom buffer
          ]
        ),
      );
    }
  }
}

// ==========================================
// VIEW 4: REQUESTS
// ==========================================
class SupplyRequestView extends StatefulWidget {
  final String staffName;
  const SupplyRequestView({Key? key, required this.staffName}) : super(key: key);
  @override
  State<SupplyRequestView> createState() => _SupplyRequestViewState();
}

class _SupplyRequestViewState extends State<SupplyRequestView> {
  String? _selectedIngredient;
  final TextEditingController _qtyController = TextEditingController();
  
  // NEW ADDITION: Unit explicitly selected by User
  String _selectedUnit = 'Grams';
  final List<String> _unitOptions = ['Grams', 'Pieces', 'Milliliter'];
  
  bool _isSending = false;

  Future<void> _submitRequest() async {
    if (_selectedIngredient == null || _qtyController.text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'itemName': _selectedIngredient,
        'quantity': int.parse(_qtyController.text),
        'unit': _selectedUnit,
        'kitchen_staff': widget.staffName,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _qtyController.clear();
      setState(() { 
        _selectedIngredient = null; 
        _selectedUnit = 'Grams';
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Sent.'), backgroundColor: AppColors.success));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if(mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 900;

    // LEFT: FORM CARD
    Widget leftCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 20, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Vital for scrolling safely
        children: [
          Container(margin: const EdgeInsets.only(bottom: 20), child: const Text('Submit Restock Request', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ingredient Name:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('ingredients').snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const LinearProgressIndicator();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: const Color(0xFFf8fafc), border: Border.all(color: AppColors.border, width: 2), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true, value: _selectedIngredient, hint: const Text('-- Select Ingredient --'),
                          items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text((doc.data() as Map<String, dynamic>).containsKey('name') ? doc['name'] : 'Unknown'))).toList(),
                          onChanged: (val) => setState(() => _selectedIngredient = val),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantity Needed:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qtyController, keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g., 5000', filled: true, fillColor: const Color(0xFFf8fafc),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unit:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Container(
                      height: 55, // match textfield height
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFFf8fafc), border: Border.all(color: AppColors.border, width: 2), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true, 
                          value: _selectedUnit, 
                          items: _unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setState(() => _selectedUnit = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (isDesktop) const Spacer() else const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _submitRequest,
              icon: _isSending ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white),
              label: const Text('Send to Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          )
        ],
      ),
    );

    // RIGHT: TABLE CARD
    Widget rightCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 20, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Vital for scrolling safely
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: const Row(children: [ Icon(Icons.history, color: Color(0xFF1e293b)), SizedBox(width: 10), Text('Recent Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))) ]),
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('requests').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              
              // Wrapping inside SingleChildScrollView prevents Table Columns from squishing on thin phones
              Widget tableContent = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFf8fafc)),
                  columns: const [ DataColumn(label: Text('DATE')), DataColumn(label: Text('ITEM REQUESTED')), DataColumn(label: Text('QTY')), DataColumn(label: Text('STATUS')) ],
                  rows: snap.data!.docs.map((doc) {
                    var r = doc.data() as Map<String, dynamic>;
                    String dStr = r.containsKey('timestamp') && r['timestamp'] != null ? DateFormat('MM/dd').format((r['timestamp'] as Timestamp).toDate()) : 'Today';
                    bool isApproved = r['status'] == 'Approved';
                    return DataRow(cells: [
                      DataCell(Text(dStr)), DataCell(Text(r.containsKey('itemName') ? r['itemName'] : '', style: const TextStyle(fontWeight: FontWeight.w700))), 
                      DataCell(Text('${r['quantity']} ${r['unit']}')),
                      DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isApproved ? AppColors.availBg : AppColors.lowBg, borderRadius: BorderRadius.circular(20)), child: Text((r['status'] ?? 'Pending').toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isApproved ? AppColors.availText : AppColors.lowText))))
                    ]);
                  }).toList(),
                ),
              );

              return isDesktop ? Expanded(child: SingleChildScrollView(child: tableContent)) : tableContent;
            },
          ),
        ],
      ),
    );

    // ===================================
    // RESPONSIVE LAYOUT SWITCH
    // ===================================
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [ 
            Expanded(flex: 4, child: leftCard), 
            const SizedBox(width: 30), 
            Expanded(flex: 6, child: rightCard) 
          ]
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [ 
            leftCard, 
            const SizedBox(height: 25), 
            rightCard, 
            const SizedBox(height: 40) // Bottom buffer
          ]
        ),
      );
    }
  }
}