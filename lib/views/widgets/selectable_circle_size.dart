import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import 'package:iibsasho/core/model/ProductSize.dart';

class SelectableCircleSize extends StatefulWidget {
  final List<ProductSize> productSize;
  final Color? selectedColor;
  final Color? baseColor;
  final TextStyle? selectedTextStyle;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? margin, padding;
  const SelectableCircleSize({super.key, required this.productSize, this.margin, this.padding, this.selectedColor, this.baseColor, this.textStyle, this.selectedTextStyle});

  @override
  _SelectableCircleState createState() => _SelectableCircleState();
}

class _SelectableCircleState extends State<SelectableCircleSize> {
  int? _selectedIndex;

  void _change(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  TextStyle _getTextStyle(int index) {
    if (index == _selectedIndex) {
      return widget.selectedTextStyle ?? TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
    } else {
      return widget.textStyle ?? TextStyle(color: AppColor.primary, fontWeight: FontWeight.w600);
    }
  }

  Color _getBackgroundColor(int index) {
    if (index == _selectedIndex) {
      return widget.selectedColor ?? AppColor.secondary;
    } else {
      return widget.baseColor ?? AppColor.primarySoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      padding: widget.padding,
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: List.generate(
          widget.productSize.length,
          (index) {
            return InkWell(
              onTap: () {
                _change(index);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(index),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    width: 2,
                    color: AppColor.primarySoft,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.productSize[index].size,
                    style: _getTextStyle(index),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
