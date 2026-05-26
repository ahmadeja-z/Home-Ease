import 'package:flutter/material.dart';

import '../core/assets/font_family.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    required this.validator,
    required this.textEditingController,
    this.textInputType,
    required this.hint,
    this.maxLineLength = 1,
    this.obscureText = false,
    this.isEnabled = true,
    this.focusNode,
    this.nextFocusNode,
    this.haveCalendar = false,
    this.havePopupMenu = false,
    this.popupMenuItems,
    this.contentHorizontalPadding = 20,
    this.contentVerticalPadding = 15,
    this.haveDropdownMenu = false,
    this.dropdownMenuItems,
    this.onChanged,
  });

  final String hint;
  final double contentHorizontalPadding;
  final double contentVerticalPadding;
  final Function(String?)? validator;
  final TextInputType? textInputType;
  final bool obscureText;
  final bool isEnabled;
  final int maxLineLength;
  final TextEditingController textEditingController;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool haveCalendar;
  final bool havePopupMenu;
  final List<String>? popupMenuItems;
  final bool haveDropdownMenu;
  final List<String>? dropdownMenuItems;
  final ValueChanged<String>? onChanged;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool hidePassword;

  @override
  void initState() {
    super.initState();
    hidePassword = widget.obscureText;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      // keyboardType: widget.textInputType,
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: 'Select a date',
      cancelText: 'Cancel',
      confirmText: 'Ok',
      fieldHintText: 'mm/dd/yyyy',
      fieldLabelText: 'Enter your date',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Theme.of(
              context,
            ).colorScheme.primary, // header background color
            hintColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: .7), // input hint color
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, // calendar header
              onPrimary: Theme.of(
                context,
              ).colorScheme.secondary, // header text color
              onSurface: Theme.of(
                context,
              ).colorScheme.shadow, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.primary, // button text color
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.onPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        widget.textEditingController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _onDropdownItemSelected(String? value) {
    if (value != null) {
      setState(() {
        widget.textEditingController.text = value;
      });

      // Call the onChanged callback if provided
      if (widget.onChanged != null) {
        widget.onChanged!(value);
      }
      if (widget.nextFocusNode != null) {
        FocusScope.of(context).requestFocus(widget.nextFocusNode);
      } else {
        // Remove focus from dropdown if no next field is set
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.haveDropdownMenu && widget.dropdownMenuItems != null) {
      // Ensure dropdownMenuItems contains unique values
      final uniqueDropdownItems = widget.dropdownMenuItems!.toSet().toList();

      // Check if the current textController value exists in the unique list; if not, reset it
      if (widget.textEditingController.text.isNotEmpty &&
          !uniqueDropdownItems.contains(widget.textEditingController.text)) {
        widget.textEditingController.clear(); // Reset to avoid invalid value
      }

      return DropdownButtonFormField<String>(
        focusNode: widget.focusNode,
        initialValue:
            widget.textEditingController.text.isNotEmpty &&
                uniqueDropdownItems.contains(widget.textEditingController.text)
            ? widget.textEditingController.text
            : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,

        // value: widget.textEditingController.text.isNotEmpty &&
        //     uniqueDropdownItems.contains(widget.textEditingController.text)
        //     ? widget.textEditingController.text
        //     : null,
        hint: Text(
          widget.hint,
          style: TextStyle(
            fontSize: 14,
            fontFamily: FontFamily.fontsPoppinsRegular,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        items: uniqueDropdownItems.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                fontFamily: FontFamily.fontsPoppinsRegular,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          );
        }).toList(),
        onChanged: widget.isEnabled ? _onDropdownItemSelected : null,
        // validator: (value) => widget.validator!(value),
        validator: (value) {
          if (widget.validator != null) {
            return widget.validator!(value ?? '');
          }
          return null;
        },

        decoration: InputDecoration(
          fillColor: Theme.of(context).colorScheme.onPrimary,
          filled: true,
          hintText: widget.hint,
          contentPadding: EdgeInsets.symmetric(
            vertical: widget.contentVerticalPadding,
            horizontal: widget.contentHorizontalPadding,
          ),
          border: _border(),
          errorBorder: _errorBorder(),
          enabledBorder: _enabledBorder(),
          focusedBorder: _focusedBorder(),
          focusedErrorBorder: _focusedErrorBorder(),
          // disabledBorder: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(5),
          //   borderSide:
          //   BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
          // ),
        ),
        dropdownColor: Theme.of(context).colorScheme.onPrimary,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      );
    }

    return TextFormField(
      maxLines: widget.maxLineLength,
      cursorColor: Theme.of(context).colorScheme.primary,
      style: TextStyle(
        fontSize: 14,
        fontFamily: "Poppins",
        color: Theme.of(context).colorScheme.onSecondary,
      ),
      enabled: widget.isEnabled,
      obscureText: hidePassword,
      controller: widget.textEditingController,
      keyboardType: widget.textInputType,
      validator: (value) => widget.validator!(value),
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      onFieldSubmitted: (value) {
        if (widget.nextFocusNode != null) {
          FocusScope.of(context).requestFocus(widget.nextFocusNode);
        }
      },
      readOnly: widget.haveCalendar || widget.havePopupMenu,
      onTap: widget.haveCalendar ? () => _selectDate(context) : null,
      decoration: InputDecoration(
        suffixIcon: widget.obscureText
            ? InkWell(
                onTap: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
                child: Icon(
                  hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              )
            : widget.havePopupMenu && widget.popupMenuItems != null
            ? PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: .4),
                  ),
                ),
                color: Theme.of(context).colorScheme.onPrimary,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: Theme.of(context).colorScheme.shadow,
                ),
                onSelected: (String value) {
                  setState(() {
                    widget.textEditingController.text = value;
                  });
                },
                itemBuilder: (BuildContext context) {
                  return widget.popupMenuItems!.map((String item) {
                    return PopupMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontFamily: FontFamily.fontsPoppinsRegular,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList();
                },
              )
            : null,
        hintText: widget.hint,
        hintStyle: TextStyle(
          fontSize: 14,
          fontFamily: FontFamily.fontsPoppinsRegular,
          color: Theme.of(
            context,
          ).colorScheme.onSecondary.withValues(alpha: .8),
        ),
        errorStyle: TextStyle(
          fontSize: 12,
          fontFamily: FontFamily.fontsPoppinsRegular,
          color: Theme.of(context).colorScheme.error,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: widget.contentVerticalPadding,
          horizontal: widget.contentHorizontalPadding,
        ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.onPrimary.withValues(alpha: .5),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        counterText: '',
        errorBorder: _errorBorder(),
        border: _border(),
        enabledBorder: _enabledBorder(),
        focusedBorder: _focusedBorder(),
        focusedErrorBorder: _focusedErrorBorder(),
      ),
    );
  }

  OutlineInputBorder _errorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Colors.red),
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .4),
      ),
    );
  }

  OutlineInputBorder _enabledBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .3),
      ),
    );
  }

  OutlineInputBorder _focusedErrorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Colors.red),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
    );
  }
}

class OwnerDropdownField<T> extends StatelessWidget {
  final String hint;
  final List<T> items;
  final String Function(T) labelBuilder;
  final TextEditingController? controller;
  final dynamic Function(T) valueBuilder;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const OwnerDropdownField({
    super.key,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    this.controller,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: controller != null && controller!.text.isNotEmpty
          ? items.firstWhere(
              (item) => valueBuilder(item).toString() == controller!.text,
              orElse: () => items.first,
            )
          : null,

      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(labelBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
