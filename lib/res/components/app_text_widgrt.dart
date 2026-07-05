// xs
// sm
// md
// lg
// xl

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget customText({
  String? text,
  double? size,
  FontWeight? fontWeight,
  Color? color,
}) {
  return Text(
    text ?? 'custom text',
    style: TextStyle(
      fontSize: size ?? 10.spMin,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      overflow: TextOverflow.ellipsis,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}

Widget xsText({String? text, Color? color}) {
  return Text(
    text ?? 'xs text',
    style: TextStyle(
      fontSize: 10.spMin,
      fontWeight: FontWeight.normal,
      color: color,
      overflow: TextOverflow.ellipsis,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}

Widget xsTextBold({
  String? text,
  Color? color,
  TextAlign? textAlign,
  int? maxLines,
}) {
  return Text(
    text ?? 'xs text',
    style: TextStyle(
      color: color,
      fontSize: 10.spMin,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
    ),
    textAlign: textAlign,
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines ?? 1,
  );
}

Widget smText({
  String? text,
  double? letterSpacing,
  Color? color,
  TextAlign? textAlign,
  int? maxLines,
  double? height,
}) {
  return Text(
    text ?? 'xs text',
    style: TextStyle(
      fontSize: 12.spMin,
      fontWeight: FontWeight.normal,
      letterSpacing: letterSpacing,
      color: color,
      overflow: TextOverflow.ellipsis,
      height: height,
    ),

    textAlign: textAlign,
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines ?? 1,
  );
}

Widget smTextBold({
  String? text,
  double? letterSpacing,
  Color? color,
  int? maxLines,
  TextAlign? textAlign,
}) {
  return Text(
    text ?? 'xs text',
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines ?? 1,
    textAlign: textAlign,
    style: TextStyle(
      overflow: TextOverflow.ellipsis,
      fontSize: 12.spMin,
      fontWeight: FontWeight.bold,
      letterSpacing: letterSpacing,
      color: color,
    ),
  );
}

Widget mdText({
  String? text,
  double? letterSpacing,
  Color? color,
  TextAlign? textAlign,
}) {
  return Text(
    text ?? 'xs text',
    maxLines: 1, // Ensures a single line
    overflow: TextOverflow.ellipsis, // Adds "..." when text overflows
    softWrap: false,
    textAlign: textAlign,
    style: TextStyle(
      color: color,
      fontSize: 14.spMin,
      fontWeight: FontWeight.normal,
      letterSpacing: letterSpacing,
    ),
  );
}

Widget mdTextBold({
  String? text,
  double? letterSpacing,
  Color? color,
  int? maxLines,
}) {
  return Text(
    text ?? 'xs text',
    style: TextStyle(
      fontSize: 14.spMin,
      fontWeight: FontWeight.bold,
      letterSpacing: letterSpacing,
      color: color,
      overflow: TextOverflow.ellipsis,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines,
  );
}

Widget lgText({String? text, Color? color}) {
  return Text(
    text ?? 'xs text',
    style: TextStyle(
      fontSize: 16.spMin,
      fontWeight: FontWeight.normal,
      color: color,
      overflow: TextOverflow.ellipsis,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}

Widget lgTextBold({String? text, Color? color}) {
  return Text(
    text ?? 'xs text',
    style: TextStyle(
      fontSize: 16.spMin,
      fontWeight: FontWeight.bold,
      color: color,
      overflow: TextOverflow.ellipsis,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}

Widget xlText({String? text, Color? color}) {
  return Text(
    text ?? 'xs text',
    style: TextStyle(
      color: color,
      fontSize: 18.spMin,
      fontWeight: FontWeight.normal,
      overflow: TextOverflow.ellipsis,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}

Widget xlTextBold({String? text, Color? color}) {
  return Text(
    text ?? 'xs text',
    style: TextStyle(
      fontSize: 18.spMin,
      fontWeight: FontWeight.bold,
      color: color,
      overflow: TextOverflow.ellipsis,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}
