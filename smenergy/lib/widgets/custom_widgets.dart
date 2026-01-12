import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient blueLinear = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFF1D7EF8), Color(0xFF3DA5FA)],
  );
}

class CustomPopOutInput extends StatelessWidget {
  final TextEditingController? controller;
  final IconData icon;
  final String hint;
  final LinearGradient gradient;
  final bool isPassword;
  final bool isObscure;
  final VoidCallback? onToggleVisibility;

  const CustomPopOutInput({
    super.key,
    this.controller,
    required this.icon,
    required this.hint,
    required this.gradient,
    this.isPassword = false,
    this.isObscure = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.0,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 50.0,
            margin: const EdgeInsets.only(left: 30.0),
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(25),
                left: Radius.circular(10),
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(23.5),
                  left: Radius.circular(8.5),
                ),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: isObscure,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(height: 1.0, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(left: 45),
                  suffixIcon: isPassword
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: gradient.colors.last,
                          ),
                          onPressed: onToggleVisibility,
                        )
                      : const SizedBox(width: 48),
                ),
              ),
            ),
          ),
          Container(
            width: 64.0,
            height: 64.0,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: gradient.colors.last, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomGradientButton extends StatelessWidget {
  final String text;
  final LinearGradient gradient;
  final VoidCallback onPressed;

  const CustomGradientButton({
    super.key,
    required this.text,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
