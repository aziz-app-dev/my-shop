import 'package:flutter/material.dart';
import '../view/dashboard/dashborad_view.dart';
import '../view/login/login_view.dart';
import '../view/main/main_view.dart';
import '../view/profile/edit_profile_view.dart';
import '../view/shopping_list/shopping_list_search_view.dart';
import '../view/sign_up/sign_up_view.dart';
import '../view/splash_screen.dart';
import 'routes_name.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splashScreen:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case RouteName.dashBordScreen:
        return MaterialPageRoute(builder: (_) => const DashboradView());
      case RouteName.mainScreen:
        return MaterialPageRoute(builder: (_) => MainScrenn());

      case RouteName.loginView:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case RouteName.signUpView:
        return MaterialPageRoute(builder: (_) => const SignUpView());
      case RouteName.profileEdit:
        return MaterialPageRoute(builder: (_) => const EditProfile());

      case RouteName.shoppingListSearchView:
        return MaterialPageRoute(
            builder: (_) => const ShoppingListSearchView());

      // case RouteName.thridScreen:
      //   if (arguments is Map<String, String>) {
      //     return MaterialPageRoute(
      //       builder: (_) => SecondPage.fromArgs(arguments),
      //     );
      //   }
      //   return _errorRoute(settings.name);

      default:
        return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? name) {
    return MaterialPageRoute(
      builder:
          (_) =>
              Scaffold(body: Center(child: Text('No route defined for $name'))),
    );
  }
}
