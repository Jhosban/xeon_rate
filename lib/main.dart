import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CurrencyConverterApp());

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const CurrencyConverterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController amountController = TextEditingController();
  final List<String> currencies = ['COP', 'USD', 'EUR', 'GBP'];
  String? fromCurrency;
  String? toCurrency;
  double? convertedResult;
  bool isLoading = false;

  String defaultLanguage = 'es';
  bool languageLoaded = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  final Map<String, Map<String, String>> appTexts = {
    'es': {
      'title': 'Convertidor de Divisas',
      'settings': 'Configuración',
      'language': 'Idioma',
      'close': 'Cerrar',
      'convert': 'Convertir',
      'amount': 'Importe',
      'defaultWarning':
          'Usando tasas predeterminadas (podrían no estar actualizadas)',
    },
    'en': {
      'title': 'Currency Converter',
      'settings': 'Settings',
      'language': 'Language',
      'close': 'Close',
      'convert': 'Convert',
      'amount': 'Amount',
      'defaultWarning': 'Using default rates (might not be updated)',
    },
  };

  @override
  void initState() {
    super.initState();
    fromCurrency = currencies[0];
    toCurrency = currencies[1];
    loadLanguage();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOffline = results.every((result) => result == ConnectivityResult.none);
      if (isOffline && !_wasOffline) {
        _showSnackBar(
          appTexts[defaultLanguage]?['defaultWarning'] ??
              'Sin conexión a Internet. Se usaron tasas aproximadas.',
        );
      }
      _wasOffline = isOffline;
    });

  }

    @override
  void dispose() {
    _connectivitySubscription?.cancel();
    amountController.dispose();
    super.dispose();
  }
  Future<void> loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultLanguage = prefs.getString('language') ?? 'es';
      languageLoaded = true;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> changeLanguage(String newLang) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLang);
    setState(() {
      defaultLanguage = newLang;
    });
    Navigator.of(context).pop();
    _showSettings();
  }

  Future<void> _convertCurrency() async {
    final amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount <= 0 || fromCurrency == null || toCurrency == null) return;

    setState(() {
      isLoading = true;
      convertedResult = null;
    });

    final result = await CurrencyService.convertCurrency(
      amount: amount,
      fromCurrency: fromCurrency!,
      toCurrency: toCurrency!,
    );

    setState(() {
      convertedResult = result;
      isLoading = false;
    });
  }

  void _showSettings() {
    showDialog(context: context, builder: (context) => _buildSettingsDialog());
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        appTexts[defaultLanguage]!['title']!,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: _showSettings,
        ),
      ],
    );
  }

  Widget _buildSettingsDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 10),
                Text(
                  appTexts[defaultLanguage]!['settings']!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildLanguageSetting(),
            const SizedBox(height: 18),
            Align(alignment: Alignment.centerRight, child: _buildCloseButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          appTexts[defaultLanguage]!['language']!,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              value: defaultLanguage,
              items: [
                DropdownMenuItem(
                  value: 'es',
                  child: Text(
                    "Español",
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(
                    "English",
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
              onChanged: (String? newLang) {
                if (newLang != null) changeLanguage(newLang);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close, color: Colors.white, size: 18),
      label: Text(
        appTexts[defaultLanguage]!['close']!,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!languageLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 420,
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Icon(
                          Icons.currency_exchange,
                          size: 60,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAmountInput(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCurrencyDropdown(fromCurrency, (value) {
                              setState(() => fromCurrency = value);
                            }),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.swap_horiz,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          Expanded(
                            child: _buildCurrencyDropdown(toCurrency, (value) {
                              setState(() => toCurrency = value);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildConvertButton(),
                      if (convertedResult != null) _buildResultDisplay(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appTexts[defaultLanguage]!['amount']!,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          items: currencies
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildConvertButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _convertCurrency,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          elevation: 6,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.blue)
              : Text(
                  appTexts[defaultLanguage]!['convert']!,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${convertedResult!.toStringAsFixed(2)} $toCurrency',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}

// Servicio para conversión de monedas
class CurrencyService {
  static const String _apiKey = 'cb4f8b24f9d7dbe5eb2dab34';
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  static const Map<String, double> _defaultRates = {
    'USD': 0.00025,
    'EUR': 0.00023,
    'GBP': 0.00020,
    'COP': 1.0,
  };

  static Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {

    try {
      if (fromCurrency == toCurrency) {
        return amount;
      }

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {

        if (_defaultRates.containsKey(fromCurrency) &&
            _defaultRates.containsKey(toCurrency)) {
          final fromRate = _defaultRates[fromCurrency]!;
          final toRate = _defaultRates[toCurrency]!;
          final result = amount * (toRate / fromRate);

          return result;
        } else {
          throw 'Tasas por defecto no disponibles para $fromCurrency o $toCurrency';
        }
      }

      // Conexión disponible: utiliza el API
      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiKey/pair/$fromCurrency/$toCurrency'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          final rate = data['conversion_rate'];
          final result = amount * rate;
          print('Resultado desde API: $result');
          return result;
        }
      }

      //Si falla la API, usa las tasas por defecto
      if (_defaultRates.containsKey(fromCurrency) &&
          _defaultRates.containsKey(toCurrency)) {
        final fromRate = _defaultRates[fromCurrency]!;
        final toRate = _defaultRates[toCurrency]!;
        final result = amount * (toRate / fromRate);
        return result;
      } else {
        throw 'Tasas por defecto no disponibles para $fromCurrency o $toCurrency';
      }
    } catch (e) {
      if (_defaultRates.containsKey(fromCurrency) &&
          _defaultRates.containsKey(toCurrency)) {
        final fromRate = _defaultRates[fromCurrency]!;
        final toRate = _defaultRates[toCurrency]!;
        final result = amount * (toRate / fromRate);
        return result;
      }
    }
    throw 'Error al convertir';
  }
}