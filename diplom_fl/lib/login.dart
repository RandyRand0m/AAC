import 'dart:convert';
import 'package:diplom_fl/overview.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://localhost:9090/api/v1/auth/auth_phone?phone=$phone'),
      headers: {'Content-Type': 'application/json'},
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EnterCodeScreen(phone: phone)),
      );
    } else {
      print("Ошибка: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка при отправке номера")),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f8),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(50.0), 
                child: Image.asset('assets/GYMAPP.png', height: 60),
              ),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Введите номер телефона",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '7 (XXX) XXX XX XX',
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _login,
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text("Войти через Telegram",
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w500),),
                  ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Продолжая, вы соглашаетесь с обработкой\nПерсональных данных и Пользовательским соглашением",
                style: TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnterCodeScreen extends StatefulWidget {
  final String phone;

  const EnterCodeScreen({super.key, required this.phone});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final tgResponse = await http.post(
      Uri.parse('http://localhost:9090/api/v1/auth/code?phone=${widget.phone}&code=$code'),
      headers: {'Content-Type': 'application/json'},
    );

    if (tgResponse.statusCode == 200) {
      final token = jsonDecode(tgResponse.body)['access_token'];

      if (token == null || token.isEmpty) {
        print("Ошибка: отсутствует токен");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final myResponse = await http.post(
          Uri.parse('http://localhost:9096/api/login-by-token'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'phone': widget.phone}),
        );

        if (myResponse.statusCode == 200) {
          final userId = jsonDecode(myResponse.body)['user_id'];

          if (userId == null) {
            print("Ошибка: отсутствует user_id");
            return;
          }
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);

          if (!mounted) return;
          print("userId = $userId — переходим на ProjectsOverviewScreen");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProjectsOverviewScreen(userId: userId)),
            );
          });
        } else {
          print("Ошибка авторизации на сервере: ${myResponse.body}");
        }
      } catch (e) {
        print("Ошибка при отправке запроса на сервер: $e");
      }
    } else {
      print("Неверный код от Telegram-бота");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Неверный код. Попробуйте ещё раз.")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = widget.phone.replaceRange(5, widget.phone.length - 2, '*' * (widget.phone.length - 7));

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f8),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/GYMAPP.png', height: 60),
              const SizedBox(height: 16),
              const Text(
                "Подтверждение номера телефона",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Мы отправили SMS с кодом на номер $maskedPhone",
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Код из SMS",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  child: _isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Подтвердить"),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Продолжая, вы соглашаетесь с обработкой\nперсональных данных и пользовательским соглашением",
                style: TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
