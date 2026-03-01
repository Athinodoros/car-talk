import 'package:flutter/material.dart';

import '../utils/plate_formatter.dart';

class PlateInputField extends StatelessWidget {
  const PlateInputField({
    super.key,
    required this.controller,
    this.validator,
    this.label,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [PlateInputFormatter()],
      decoration: InputDecoration(
        labelText: label ?? 'License Plate',
        prefixIcon: const Icon(Icons.directions_car),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
