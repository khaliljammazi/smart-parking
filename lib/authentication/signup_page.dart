
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constanst.dart';
import 'auth_provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _passwordFocused = false;
  String _passwordValue = '';

  // Password requirement flags (computed from current value)
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordValue);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordValue);
  bool get _hasSpecial =>
      RegExp(r'[!@#%^&*(),.?":{}|<>_\-+=\[\]\\/`~;' "'" r']').hasMatch(_passwordValue);
  bool get _hasMinLength => _passwordValue.length >= 8;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _passwordValue = _passwordController.text);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _passwordFocused = _passwordFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
      };

      final result = await authProvider.register(userData);

      if (mounted) {
        if (result != null && result['success'] == true) {
           Navigator.of(context).pushReplacementNamed(
            '/verify-email',
            arguments: _emailController.text.trim(),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Registration failed'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign up to get started',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),

                // Name Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    final missing = <String>[];
                    if (value.length < 8) missing.add('at least 8 characters');
                    if (!RegExp(r'[A-Z]').hasMatch(value))
                      missing.add('an uppercase letter');
                    if (!RegExp(r'[0-9]').hasMatch(value))
                      missing.add('a number (0–9)');
                    if (!RegExp(r'[!@#%^&*(),.?":{}|<>_\-+=\[\]\\/`~;' "'" r']')
                        .hasMatch(value))
                      missing.add('a special character (!@#%...)');
                    if (missing.isNotEmpty) {
                      return 'Missing: ${missing.join(', ')}';
                    }
                    return null;
                  },
                ),
                // Real-time requirements checklist
                if (_passwordFocused || _passwordValue.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 4, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRequirement('At least 8 characters', _hasMinLength),
                        _buildRequirement('One uppercase letter (A–Z)', _hasUppercase),
                        _buildRequirement('One number (0–9)', _hasNumber),
                        _buildRequirement('One special character (!@#\$%…)', _hasSpecial),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColor.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColor.navy),
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorMaxLines: 3,
      ),
      validator: validator,
    );
  }

  /// Shows a single password requirement row with a green check (met) or red × (not met).
  Widget _buildRequirement(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: met ? Colors.greenAccent : Colors.redAccent.shade100,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.greenAccent : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
