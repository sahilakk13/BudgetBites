import 'package:bb/Screens/CustomerScreens/CustomerSignIn.dart';
import 'package:bb/Screens/RestaurentScreens/RestaurantSignIn.dart';
import 'package:bb/Screens/SignInScreen.dart';
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo
                Image.asset(
                  'assets/logot.png', // Add your logo asset here
                  height: 150,
                ),
                SizedBox(height: 20),
                // Welcome Text
                Text(
                  'Welcome to BudgetBites',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Color(0xFF8B4513), // Dark Brown
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Please choose your role',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    color: Color(0xFF8B4513).withOpacity(0.7), // Lighter Dark Brown
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    AnimatedCircleButton(
                      label: 'Customer',
                      icon: Icons.person,
                      colors: [Color(0xFF6B8E23), Color(0xFFC1E1C1)],
                      onPressed: () {
                        // Navigate to customer registration or login screen
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => CustomerSignInScreen()));

                      },
                    ),
                    SizedBox(width: 40),
                    AnimatedCircleButton(
                      label: 'Restaurant',
                      icon: Icons.restaurant,
                      colors: [Color(0xFFFF6F61), Color(0xFFFFD1BA)],
                      onPressed: () {
                        // Navigate to restaurant owner registration or login screen
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => RestaurantSignInScreen()));

                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedCircleButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onPressed;

  AnimatedCircleButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  @override
  _AnimatedCircleButtonState createState() => _AnimatedCircleButtonState();
}

class _AnimatedCircleButtonState extends State<AnimatedCircleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onPressed();
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _animation,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Icon(
                  widget.icon,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF8B4513), // Dark Brown
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}








