import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../../presentation/providers/converter_provider.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final double _basePriceUSD = 4.99;
  String _targetCurrency = 'IDR';
  double _baseConvertedPrice = 0;
  bool _isLoadingPrice = false;
  bool _isProcessingPayment = false;
  String _selectedPlanCode = 'monthly';
  String _paymentMethod = 'QRIS';
  String? _receiptId;
  DateTime? _validUntil;
  bool _acknowledgeTerms = false;

  final List<_MembershipPlan> _plans = const [
    _MembershipPlan(
      code: 'monthly',
      title: 'Bulanan',
      description: 'Akses premium penuh selama 30 hari.',
      multiplier: 1.0,
      duration: Duration(days: 30),
    ),
    _MembershipPlan(
      code: 'semester',
      title: 'Semester',
      description: 'Lebih hemat untuk 6 bulan akses premium.',
      multiplier: 5.2,
      duration: Duration(days: 182),
    ),
    _MembershipPlan(
      code: 'yearly',
      title: 'Tahunan',
      description: 'Paling hemat untuk 12 bulan akses premium.',
      multiplier: 9.6,
      duration: Duration(days: 365),
    ),
  ];

  final List<String> _paymentMethods = const [
    'QRIS',
    'Transfer Bank',
    'E-Wallet',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrice();
      _loadSavedPurchase();
    });
  }

  Future<void> _loadPrice() async {
    if (!mounted) return;
    setState(() => _isLoadingPrice = true);

    try {
      final provider = context.read<ConverterProvider>();
      await provider.convertCurrency('USD', _targetCurrency, _basePriceUSD);
      if (!mounted) return;
      setState(() {
        _baseConvertedPrice = provider.convertedAmount;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingPrice = false);
      }
    }
  }

  Future<void> _loadSavedPurchase() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _receiptId = prefs.getString('membership_receipt_id');
      final validUntil = prefs.getString('membership_valid_until');
      _validUntil = validUntil != null ? DateTime.tryParse(validUntil) : null;
    });
  }

  _MembershipPlan get _selectedPlan => _plans.firstWhere(
        (plan) => plan.code == _selectedPlanCode,
        orElse: () => _plans.first,
      );

  Future<void> _showCheckoutConfirmation() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu sebelum membeli membership.')),
      );
      return;
    }

    if (!_acknowledgeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setujui syarat membership terlebih dahulu.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembelian'),
        content: Text(
          'Kamu akan membeli paket ${_selectedPlan.title} dengan metode $_paymentMethod.\n\n'
          'Setelah proses verifikasi selesai, akses premium akan aktif pada akun ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _processPurchase();
    }
  }

  Future<void> _processPurchase() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final priceInTargetCurrency = _baseConvertedPrice * _selectedPlan.multiplier;
      final generatedReceipt = _generateReceiptId();
      final expiresAt = DateTime.now().add(_selectedPlan.duration);

      await Future<void>.delayed(const Duration(milliseconds: 800));

      final activated = await authProvider.setPremiumStatus(true);
      if (!activated) {
        throw Exception('Gagal mengaktifkan membership pada akun yang sedang login.');
      }

      final recorded = await authProvider.recordMembershipPurchase(
        planCode: _selectedPlan.code,
        paymentMethod: _paymentMethod,
        receiptId: generatedReceipt,
        purchasedAt: DateTime.now(),
        validUntil: expiresAt,
      );

      if (!recorded) {
        throw Exception('Gagal menyimpan bukti pembelian.');
      }

      if (!mounted) return;
      setState(() {
        _receiptId = generatedReceipt;
        _validUntil = expiresAt;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembayaran terverifikasi. Premium aktif: ${_selectedPlan.title} ${priceInTargetCurrency.toStringAsFixed(2)} $_targetCurrency',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembelian gagal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  String _generateReceiptId() {
    final random = Random();
    final token = List.generate(8, (_) => random.nextInt(10)).join();
    return 'EDU-$token-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _refreshPrice() async {
    await _loadPrice();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPremium = authProvider.isPremium;
    final purchaseSummary = _receiptId == null
        ? null
        : 'Receipt $_receiptId${_validUntil != null ? '\nAktif sampai ${_validUntil!.toLocal()}' : ''}';

    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: isPremium ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Membership aktif' : 'Upgrade ke Premium',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPremium
                          ? 'Akun ini sudah memiliki akses premium penuh.'
                          : 'Pilih paket, metode pembayaran, lalu selesaikan checkout untuk mengaktifkan fitur premium.',
                    ),
                    if (purchaseSummary != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        purchaseSummary,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Paket',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._plans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RadioListTile<String>(
                  value: plan.code,
                  groupValue: _selectedPlanCode,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedPlanCode = value);
                  },
                  title: Text(plan.title),
                  subtitle: Text(plan.description),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Currency:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _targetCurrency,
                  items: const ['IDR', 'USD', 'EUR']
                      .map((currency) => DropdownMenuItem(value: currency, child: Text(currency)))
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _targetCurrency = value);
                    await _refreshPrice();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isLoadingPrice
                          ? 'Menghitung harga...'
                          : 'Estimasi harga: ${(_baseConvertedPrice * _selectedPlan.multiplier).toStringAsFixed(2)} $_targetCurrency',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Checkout memakai harga dasar USD $_basePriceUSD lalu dikonversi sesuai currency yang dipilih.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _paymentMethods
                  .map(
                    (method) => ChoiceChip(
                      label: Text(method),
                      selected: _paymentMethod == method,
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() => _paymentMethod = method);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _acknowledgeTerms,
              onChanged: (value) {
                setState(() => _acknowledgeTerms = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Saya setuju membership diproses sebagai checkout simulasi aplikasi.'),
              subtitle: const Text('Status premium dan bukti transaksi akan disimpan ke akun ini.'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isProcessingPayment ? null : _showCheckoutConfirmation,
              icon: _isProcessingPayment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_open),
              label: Text(_isProcessingPayment ? 'Memproses...' : 'Lanjut ke Checkout'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoadingPrice ? null : _refreshPrice,
              child: const Text('Refresh Kurs'),
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Keuntungan Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• Chatbot tanpa batas'),
                    Text('• Akses konten premium'),
                    Text('• Statistik lanjutan'),
                    Text('• Membership tersimpan di profil akun'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipPlan {
  final String code;
  final String title;
  final String description;
  final double multiplier;
  final Duration duration;

  const _MembershipPlan({
    required this.code,
    required this.title,
    required this.description,
    required this.multiplier,
    required this.duration,
  });
}
