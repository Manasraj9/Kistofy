import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/seller_profile_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/customermanagementscreen.dart';
import 'screens/notificationscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    // authFlowType: AuthFlowType.pkce, // Required for secure login on web/mobile
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kistofy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/login',
      routes: {
        '/register': (_) => const RegisterScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/seller-profile': (_) => const SellerProfileScreen(),
        '/products': (_) => const ProductListScreen(),
        '/add-product': (_) => const AddProductScreen(),
        '/edit-product':(_) => const EditProductScreen(),
        '/create-invoice':(_) => const CreateInvoiceScreen(),
        '/customers': (_) => const CustomerManagementScreen(),
        '/notifications': (_) => const NotificationScreen(),
      },
    );
  }
}
