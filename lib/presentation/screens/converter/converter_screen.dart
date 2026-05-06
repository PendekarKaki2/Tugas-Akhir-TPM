import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/converter_provider.dart';
import '../../widgets/custom_widgets.dart';

/// Converter Screen
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  final _timeController = TextEditingController(text: '12');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ConverterProvider>().getExchangeRates('USD');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Converter'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Currency'),
            Tab(text: 'Time'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrencyTab(),
          _buildTimeTab(),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'Amount',
              controller: _amountController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.money),
            ),
            const SizedBox(height: 24),

            // From Currency
            DropdownButton<String>(
              isExpanded: true,
              value: _fromCurrency,
              items: ['USD', 'IDR', 'EUR', 'GBP', 'JPY']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() => _fromCurrency = value!);
              },
            ),
            const SizedBox(height: 16),

            Center(
              child: IconButton(
                icon: const Icon(Icons.compare_arrows),
                onPressed: () {
                  setState(() {
                    final temp = _fromCurrency;
                    _fromCurrency = _toCurrency;
                    _toCurrency = temp;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // To Currency
            DropdownButton<String>(
              isExpanded: true,
              value: _toCurrency,
              items: ['USD', 'IDR', 'EUR', 'GBP', 'JPY']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() => _toCurrency = value!);
              },
            ),
            const SizedBox(height: 24),

            // Convert Button
            Consumer<ConverterProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: 'Convert',
                  isLoading: provider.isLoading,
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    if (amount > 0) {
                      provider.convertCurrency(
                        _fromCurrency,
                        _toCurrency,
                        amount,
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Result
            Consumer<ConverterProvider>(
              builder: (context, provider, _) {
                if (provider.convertedAmount == 0) {
                  return const SizedBox.shrink();
                }
                return CustomCard(
                  backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  child: Text(
                    '${_amountController.text} $_fromCurrency = ${provider.convertedAmount.toStringAsFixed(2)} $_toCurrency',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'Hour (0-23)',
              controller: _timeController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            Consumer<ConverterProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: 'Convert Time',
                  onPressed: () {
                    final times =
                        provider.convertTime(_timeController.text);

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Time Conversion'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: times.entries
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text('${e.key}: ${e.value}'),
                                ),
                              )
                              .toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            const CustomCard(
              backgroundColor: Color(0xFFFFA500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Zones:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('🌍 London (UTC)'),
                  Text('🇮🇩 WIB (UTC +7)'),
                  Text('🇮🇩 WITA (UTC +8)'),
                  Text('🇮🇩 WIT (UTC +9)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
