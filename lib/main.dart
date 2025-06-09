import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

void main() => runApp(CurrencyConverterApp());

// Clase principal de la aplicación
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

// Pantalla principal del conversor
class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  // Controladores y estado
  final TextEditingController amountController = TextEditingController(
    text: '0.00',
  );
  final List<String> currencies = ['COP', 'USD', 'EUR', 'GBP'];
  String? fromCurrency;
  String? toCurrency;
  double? convertedResult;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fromCurrency = currencies[0];
    toCurrency = currencies[1];
  }

  // Métodos de la pantalla
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

    if (result == null) {
      _showSnackBar('Using default rates (might not be updated)');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSettings() {
    showDialog(context: context, builder: (context) => _buildSettingsDialog());
  }

  Widget _buildSettingsDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            _buildLanguageSetting(),
            const SizedBox(height: 8),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Language', style: TextStyle(fontSize: 18)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'English',
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text(
        'Close',
        style: TextStyle(fontSize: 16, color: Colors.blue),
      ),
    );
  }

  // Construcción de la interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Currency Converter',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: _showSettings,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [_buildConverterCard()]),
    );
  }

  Widget _buildConverterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountInput(),
          const SizedBox(height: 24),
          _buildCurrencyDropdown(fromCurrency, (value) {
            setState(() => fromCurrency = value);
          }, 'From'),
          const SizedBox(height: 16),
          const Center(
            child: Icon(Icons.swap_vert, color: Colors.blue, size: 32),
          ),
          const SizedBox(height: 16),
          _buildCurrencyDropdown(toCurrency, (value) {
            setState(() => toCurrency = value);
          }, 'To'),
          const SizedBox(height: 24),
          _buildConvertButton(),
          if (convertedResult != null) _buildResultDisplay(),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Importe',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(
    String? value,
    ValueChanged<String?> onChanged,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              items: currencies
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 16)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
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
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.blue,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Convertir',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          '${convertedResult!.toStringAsFixed(2)} $toCurrency',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
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
      if (fromCurrency == toCurrency) return amount;

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        return amount * (_defaultRates[toCurrency] ?? 1.0);
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiKey/pair/$fromCurrency/$toCurrency'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          return amount * data['conversion_rate'];
        }
      }

      return amount * (_defaultRates[toCurrency] ?? 1.0);
    } catch (e) {
      print('Conversion error: $e');
      return amount * (_defaultRates[toCurrency] ?? 1.0);
    }
  }
}
