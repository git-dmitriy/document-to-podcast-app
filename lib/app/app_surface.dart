import 'package:flutter/foundation.dart';

enum AppSurface { native, web }

AppSurface currentAppSurface() {
  return kIsWeb ? AppSurface.web : AppSurface.native;
}
