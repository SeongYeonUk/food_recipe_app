import 'package:flutter/material.dart';

enum ButtonType {
  elevated,
  outlined,
}


class CustomAuthButton extends StatelessWidget {

  final String text;
  final String route;
  final ButtonType buttonType;

  final Color? backgroundColor;
  final Color? textColor;


  final Color? borderColor;

  const CustomAuthButton({
    required this.text,
    required this.route,
    required this.buttonType,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (buttonType) {
      case ButtonType.elevated:
        return ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(route);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        );

      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(route);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: borderColor ?? Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        );
    }
  }
}
