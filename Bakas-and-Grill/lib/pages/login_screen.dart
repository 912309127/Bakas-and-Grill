import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = "";
  
  // Math CAPTCHA variables
  int _num1 = 0;
  int _num2 = 0;

  // Background Animation
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _generateMathProblem();
    // 20 second loop just like the CSS animation
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _generateMathProblem() {
    final random = Random();
    setState(() {
      _num1 = random.nextInt(99) + 1; // 1 to 99 matches HTML
      _num2 = random.nextInt(99) + 1;
      _captchaController.clear();
      _errorMessage = "";
    });
  }

  Future<void> _login() async {
    setState(() => _errorMessage = "");

    // 1. Validate CAPTCHA
    int userAnswer = int.tryParse(_captchaController.text) ?? -1;
    if (userAnswer != (_num1 + _num2)) {
      setState(() => _errorMessage = "Incorrect math answer. Please try again.");
      _generateMathProblem();
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = "Please enter email and password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Authenticate
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Check Role & Status in Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        if (userData['status'] == 'archived' || userData['isActive'] == false) {
          await FirebaseAuth.instance.signOut();
          throw Exception("Access Denied: Your account is archived or disabled.");
        }

        String role = userData['role'] ?? '';
        if (role != 'admin' && role != 'kitchen' && role != 'cashier') {
          await FirebaseAuth.instance.signOut();
          throw Exception("Role not recognized in system.");
        }
        
        // NO NAVIGATOR CALLS HERE! 
        // AuthWrapper will detect the successful login and route automatically.

      } else {
        await FirebaseAuth.instance.signOut();
        throw Exception("No role assigned to this user.");
      }
    } catch (e) {
      // Only real errors will trigger this block now
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
        _generateMathProblem(); // Refresh captcha on failure
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAboutModal() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: const DecorationImage(
                image: AssetImage('assets/image/background.jpg'),
                fit: BoxFit.cover,
              ),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5))],
            ),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.95)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -10,
                    right: -10,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 30, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFe61029),
                          image: const DecorationImage(image: AssetImage('assets/image/logo.jpg'), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text("About Us", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 15),
                      const Text(
                        "Welcome to Bakas & Grill! Sabaw nga makatagbaw. We pride ourselves on serving the best grilled dishes and savory soups. Built with passion and dedicated to quality service.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Color(0xFF050505), height: 1.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shared styling for input borders mimicking CSS: border: 3px solid #000;
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Colors.black, width: 3),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dynamic Twirling Backgrounds matching the CSS
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Twirl 1 (Top Left)
                  Positioned(
                    top: -100, left: -100,
                    child: Transform.rotate(
                      angle: _bgController.value * 2 * pi,
                      child: _buildTwirl(350, const BorderRadius.only(topLeft: Radius.circular(120), bottomRight: Radius.circular(150), topRight: Radius.circular(180), bottomLeft: Radius.circular(90))),
                    ),
                  ),
                  // Twirl 2 (Bottom Right - Reverse)
                  Positioned(
                    bottom: -150, right: -150,
                    child: Transform.rotate(
                      angle: -_bgController.value * 2 * pi * 1.1, // slightly faster reverse
                      child: _buildTwirl(350, const BorderRadius.only(topLeft: Radius.circular(150), bottomRight: Radius.circular(120), topRight: Radius.circular(180), bottomLeft: Radius.circular(180))),
                    ),
                  ),
                  // Twirl 3 (Right Side)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.25, right: -50,
                    child: Transform.rotate(
                      angle: _bgController.value * 2 * pi * 1.3,
                      child: Opacity(opacity: 0.85, child: _buildTwirl(200, const BorderRadius.only(topLeft: Radius.circular(120), bottomRight: Radius.circular(100), topRight: Radius.circular(100), bottomLeft: Radius.circular(120)))),
                    ),
                  ),
                  // Twirl 4 (Left Side - Reverse)
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.25, left: -50,
                    child: Transform.rotate(
                      angle: -_bgController.value * 2 * pi * 0.9,
                      child: Opacity(opacity: 0.85, child: _buildTwirl(250, const BorderRadius.only(topLeft: Radius.circular(90), bottomRight: Radius.circular(150), topRight: Radius.circular(150), bottomLeft: Radius.circular(90)))),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Main Login Box (Glassmorphism Effect)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 350),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 32, offset: Offset(0, 8))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // CSS Logo
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFe61029),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                              image: const DecorationImage(
                                image: AssetImage('assets/image/logo.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text("WELCOME", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1)),
                          const SizedBox(height: 25),
                          
                          // Error Message
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                            ),

                          // Email Input
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: const TextStyle(color: Color(0xFFa0a0a0)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder,
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // Password Input
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Color(0xFFa0a0a0)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: _isPasswordVisible ? const Color(0xFFe61029) : const Color(0xFF333333),
                                ),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // Math CAPTCHA Container
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildCaptchaBox(_num1.toString()),
                                const Text("+", style: TextStyle(fontSize: 18, color: Color(0xFF64748b), fontWeight: FontWeight.w500)),
                                _buildCaptchaBox(_num2.toString()),
                                const Text("=", style: TextStyle(fontSize: 18, color: Color(0xFF64748b), fontWeight: FontWeight.w500)),
                                
                                // Captcha Input Box
                                Container(
                                  width: 55,
                                  height: 45,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                  child: TextField(
                                    controller: _captchaController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFcbd5e1), width: 1), borderRadius: BorderRadius.circular(6)),
                                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                
                                // Refresh Button
                                GestureDetector(
                                  onTap: _generateMathProblem,
                                  child: const Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: Icon(Icons.refresh, color: Color(0xFF94a3b8), size: 26),
                                  ),
                                )
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFe61029),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                  : const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            ),
                          ),

                          const SizedBox(height: 20),
                          
                          // About Link
                          GestureDetector(
                            onTap: _showAboutModal,
                            child: const Text(
                              "About Bakas & Grill",
                              style: TextStyle(
                                color: Color(0xFF1c21a9),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF1c21a9)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to draw the Math boxes exactly like CSS: .captcha-box
  Widget _buildCaptchaBox(String text) {
    return Container(
      width: 55,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFcbd5e1), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF64748b))),
    );
  }

  // Helper widget for background twirls
  Widget _buildTwirl(double size, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [Color(0xFFe61029), Color(0xFFb30c20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}