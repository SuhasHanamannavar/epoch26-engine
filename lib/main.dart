import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epoch26 Engine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'EPOCH 26',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Verification Engine',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IssueScreen()),
              ),
              child: const Text('Issue Certificate',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
              child: const Text('Verify Certificate',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class IssueScreen extends StatefulWidget {
  const IssueScreen({super.key});

  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  final idController = TextEditingController();
  final dataController = TextEditingController();
  String? generatedHash;
  String? qrData;
  bool loading = false;

  Future<void> issueCredential() async {
    setState(() => loading = true);
    try {
      final response = await http.post(
        Uri.parse(
            'http://127.0.0.1:8000/store?id=${idController.text}&data=${dataController.text}'),
      );
      final result = jsonDecode(response.body);
      setState(() {
        generatedHash = result['hash'];
        qrData =
            '${idController.text}||${result['hash']}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Issue Certificate',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: idController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Certificate ID',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dataController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Certificate Data',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple),
              onPressed: loading ? null : issueCredential,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate & Store',
                      style: TextStyle(color: Colors.white)),
            ),
            if (qrData != null) ...[
              const SizedBox(height: 30),
              const Text('Scan this QR to verify:',
                  style: TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              QrImageView(
                data: qrData!,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                'Hash: ${generatedHash!.substring(0, 20)}...',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool scanned = false;

  Future<void> verifyQR(String rawValue) async {
    if (scanned) return;
    scanned = true;

    final parts = rawValue.split('||');
    if (parts.length != 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ResultScreen(isValid: false),
        ),
      );
      return;
    }

    final id = parts[0];
    final hash = parts[1];

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/verify?id=$id&data=&original_hash=$hash'),
      );
      final result = jsonDecode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(isValid: result['valid']),
        ),
      );
    } catch (e) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ResultScreen(isValid: false),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Scan & Verify',
            style: TextStyle(color: Colors.white)),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            verifyQR(barcode.rawValue!);
          }
        },
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final bool isValid;
  const ResultScreen({super.key, required this.isValid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isValid ? Colors.green : Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 120,
            ),
            const SizedBox(height: 20),
            Text(
              isValid ? 'VALID ✅' : 'INVALID ❌',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isValid
                  ? 'Certificate is authentic'
                  : 'Certificate is tampered',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(
                  context, (route) => route.isFirst),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}