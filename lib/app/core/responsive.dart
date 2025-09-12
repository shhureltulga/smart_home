import 'package:flutter/widgets.dart';

bool isTablet(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= 600;
bool isDesktop(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= 1024;
double gutter(BuildContext ctx) => isTablet(ctx) ? 24 : 16;
