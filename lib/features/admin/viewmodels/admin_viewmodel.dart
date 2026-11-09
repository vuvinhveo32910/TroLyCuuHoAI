import 'package:flutter/material.dart';

import 'admin_auth_viewmodel.dart';
import 'admin_dashboard_viewmodel.dart';
import 'admin_management_viewmodel.dart';
import 'admin_navigation_viewmodel.dart';

class AdminViewModel extends ChangeNotifier
    with
        DieuHuongQuanTriViewModel,
        DangNhapQuanTriViewModel,
        DashboardQuanTriViewModel,
        AdminManagementViewModel {}
