import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final bool isDateField;
  final bool isPhoneNumberField;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;

  const CustomTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.labelText,
    required this.obscureText,
    this.isDateField = false,
    this.isPhoneNumberField = false,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        readOnly: isDateField,
        keyboardType:
        isPhoneNumberField ? TextInputType.phone : TextInputType.text,
        inputFormatters: isPhoneNumberField
            ? [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ]
            : [],
        textCapitalization: textCapitalization, // Use the new parameter here
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[600],
          ),
          hintStyle: TextStyle(
            color: Colors.grey[500],
          ),
          suffixIcon: suffixIcon, // Include the suffixIcon if provided
        ),
        onTap: isDateField
            ? () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
          );

          if (pickedDate != null) {
            controller.text =
            pickedDate.toLocal().toString().split(' ')[0];
          }
        }
            : null,
      ),
    );
  }
}