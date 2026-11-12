import 'package:flutter/material.dart';

AppBar buildAppBar(
  BuildContext context,
  String title, {
  List<Widget>? actions,
  bool showBackButton = true,
  VoidCallback? onBackPressed,
  Color? backgroundColor,
  Color? titleColor,
  double? titleSize,
}) {
  return AppBar(
    backgroundColor: backgroundColor ?? Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: showBackButton
        ? IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: onBackPressed ?? () => Navigator.pop(context),
          )
        : null,
    title: Text(
      title,
      style: TextStyle(
        color: titleColor ?? Colors.black,
        fontSize: titleSize ?? 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    centerTitle: true,
    actions: actions,
  );
}

Widget buildBottomButton(
  String text,
  IconData icon,
  VoidCallback? onPressed, {
  bool isLoading = false,
}) {
  return Container(
    padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
    ),
    child: SizedBox(
      width: double.infinity,
      height: 56.5,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 20),
                ],
              ),
      ),
    ),
  );
}

Widget buildInputLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
  );
}

Widget buildTextField({
  TextEditingController? controller,
  required String hint,
  IconData? icon,
  bool isPassword = false,
  bool obscureText = false,
  VoidCallback? onToggleVisibility,
  bool isDate = false,
  TextInputType? keyboardType,
  bool readOnly = false,
  VoidCallback? onTap,
  String? errorText,
  String? Function(String?)? validator,
  int? maxLines = 1,
  int? maxLength,
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    obscureText: isPassword ? obscureText : false,
    keyboardType: keyboardType,
    validator: validator,
    maxLines: maxLines,
    maxLength: maxLength,
    style: const TextStyle(fontWeight: FontWeight.w300),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      errorText: errorText,
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.black54, size: 20)
          : null,
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.black54,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            )
          : (isDate
                ? IconButton(
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.black54,
                      size: 20,
                    ),
                    onPressed: onTap,
                  )
                : null),
      filled: true,
      fillColor: const Color(0xFFF2F2F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    ),
  );
}
