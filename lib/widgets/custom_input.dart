import 'package:nova/util/const.dart';
import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode ?focusNode;
  final TextInputAction ?textInputAction;
  final bool ?isPasswordField;
  final Iterable<String> ?autoFillHints;
  final TextEditingController ?autoFillController;
  const CustomInput({required this.hintText, required this.onChanged, required this.onSubmitted, this.focusNode, this.textInputAction, this.isPasswordField, this.autoFillHints, this.autoFillController});

  @override
  Widget build(BuildContext context) {
    bool _isPasswordField = isPasswordField ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 24.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12.0)
      ),
      child: TextField(
        obscureText: _isPasswordField,
        controller: autoFillController,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: textInputAction,
        autofillHints: autoFillHints,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 20.0,
          )
        ),
        style: Constants.regularDarkText,
      ),
    );
  }
}
