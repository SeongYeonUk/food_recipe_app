import 'package:flutter/material.dart';
import 'package:food_recipe_app/common/const/colors.dart';

class CustomTextForm extends StatelessWidget {
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  const CustomTextForm({
    this.onChanged,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.controller,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: INPUT_BORDER_COLOR,
        width: 1.0,
      )
    );
    return TextFormField(
      controller: controller,
      cursorColor: PRIMARY_COLOR,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(20),
        hintText: hintText,
        errorText: errorText,
        hintStyle: TextStyle(
          color: BODY_TEXT_COLOR,
          fontSize: 14.0,
        ),
        fillColor: INPUT_BG_COLOR,
        filled: true,
        border: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: baseBorder.borderSide.copyWith(
            color: PRIMARY_COLOR,
          ),
        ),

      ),
    );
  }
}
