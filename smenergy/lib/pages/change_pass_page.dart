import 'package:flutter/material.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class ChangePassPage extends StatefulWidget {
  const ChangePassPage({super.key});

  @override
  State<ChangePassPage> createState() => _ChangePassPageState();
}

class _ChangePassPageState extends State<ChangePassPage> {
  final TextEditingController _currentPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Redefinir Password',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CustomPopOutInput(
              controller: _currentPass,
              icon: Icons.more_horiz,
              hint: 'Password atual',
              gradient: myGradient,
              isPassword: true,
              isObscure: _obscureCurrent,
              onToggleVisibility: () {
                setState(() => _obscureCurrent = !_obscureCurrent);
              },
            ),
            const SizedBox(height: 16),
            CustomPopOutInput(
              controller: _newPass,
              icon: Icons.more_horiz,
              hint: 'Password',
              gradient: myGradient,
              isPassword: true,
              isObscure: _obscureNew,
              onToggleVisibility: () {
                setState(() => _obscureNew = !_obscureNew);
              },
            ),
            const SizedBox(height: 16),
            CustomPopOutInput(
              controller: _confirmPass,
              icon: Icons.more_horiz,
              hint: 'Confirma a tua Password',
              gradient: myGradient,
              isPassword: true,
              isObscure: _obscureConfirm,
              onToggleVisibility: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
            ),
            const SizedBox(height: 24),
            CustomGradientButton(
              text: 'Confirmar',
              gradient: myGradient,
              onPressed: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
