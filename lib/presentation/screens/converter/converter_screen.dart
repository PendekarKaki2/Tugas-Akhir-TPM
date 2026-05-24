import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/converter_provider.dart';
import '../../providers/location_provider.dart';
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
  final Map<String, double> _timeZoneOffsets = const {
    'UTC': 0.0,
    'WIB (UTC+7)': 7.0,
    'WITA (UTC+8)': 8.0,
    'WIT (UTC+9)': 9.0,
    'GMT-8 / PST': -8.0,
    'GMT-7 / MST': -7.0,
    'GMT-6 / CST': -6.0,
    'GMT-5 / EST': -5.0,
    'GMT+1 / CET': 1.0,
    'GMT+2 / EET': 2.0,
    'GMT+5.5 / IST': 5.5,
    'GMT+8 / SGT': 8.0,
    'GMT+9 / JST': 9.0,
    'GMT+10 / AEST': 10.0,
    'GMT+12 / NZST': 12.0,
  };
  String _sourceZone = 'Auto (Lokasi Saya)';
  String _targetZone = 'WIB (UTC+7)';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ConverterProvider>().getExchangeRates('USD');
    });
  }

  double _zoneToOffset(String zone, {Position? position}) {
    if (zone == 'Auto (Lokasi Saya)') {
      final lon = position?.longitude;
      if (lon != null) {
        final estimated = (lon / 15.0).round();
        return estimated.clamp(-12, 14).toDouble();
      }
      return DateTime.now().timeZoneOffset.inMinutes / 60.0;
    }

    return _timeZoneOffsets[zone] ?? 0.0;
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

            Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                return CustomCard(
                  backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Timezone Source',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _sourceZone,
                        decoration: const InputDecoration(labelText: 'Dari zona waktu'),
                        items: [
                          'Auto (Lokasi Saya)',
                          ..._timeZoneOffsets.keys,
                        ]
                            .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sourceZone = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _targetZone,
                        decoration: const InputDecoration(labelText: 'Ke zona waktu'),
                        items: _timeZoneOffsets.keys
                            .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _targetZone = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Lokasi: ${locationProvider.locationLabel}'),
                      if (locationProvider.error != null) ...[
                        const SizedBox(height: 6),
                        Text(locationProvider.error!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: locationProvider.isLoading
                            ? null
                            : () async {
                                await locationProvider.fetchLocation();
                                if (!mounted) return;
                                setState(() {
                                  _sourceZone = 'Auto (Lokasi Saya)';
                                });
                              },
                        icon: locationProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Gunakan lokasi saya sebagai sumber'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Consumer<ConverterProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: 'Convert Time',
                  onPressed: () {
                    final locationProvider = context.read<LocationProvider>();
                    final times = provider.convertTime(
                      hour: _timeController.text,
                      sourceOffsetHours: _zoneToOffset(
                        _sourceZone,
                        position: locationProvider.position,
                      ),
                      targetOffsets: {
                        _targetZone: _zoneToOffset(
                          _targetZone,
                          position: locationProvider.position,
                        ),
                        for (final entry in _timeZoneOffsets.entries) entry.key: entry.value,
                      },
                    );

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Time Conversion'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...times.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('${e.key}: ${e.value}'),
                              ),
                            ),
                            if (_sourceZone == 'Auto (Lokasi Saya)')
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Sumber dihitung dari lokasi atau zona waktu perangkat.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
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
                  Text('🌍 UTC, PST, MST, CST, EST'),
                  Text('🇮🇩 WIB (UTC +7), WITA (UTC +8), WIT (UTC +9)'),
                  Text('🌏 CET, EET, IST, SGT, JST, AEST, NZST'),
                  Text('📍 Auto uses device/location offset'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
