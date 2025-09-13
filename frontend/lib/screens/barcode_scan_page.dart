import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/barcode_lookup_service.dart';

typedef ShowAddIngredientDialog = Future<void> Function({
required BuildContext context,
String? initialName,
});

class BarcodeScanPage extends StatefulWidget {
  final ShowAddIngredientDialog showAddDialog;
  const BarcodeScanPage({super.key, required this.showAddDialog});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _busy = false;
  String? _last;

  Future<void> _handleCode(String code) async {
    if (_busy || code == _last) return;

    // EAN-13 검증(원하면 제거 가능)
    if (!BarcodeLookupService.isValidEAN13(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효하지 않은 EAN-13 바코드예요. 다시 스캔해 주세요.')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _last = code;
    });

    String? productName;
    try {
      productName = await BarcodeLookupService.findProductName(code);
    } catch (_) {
      // 네트워크/파싱 에러 등은 조용히 무시하고 수기 입력 유도
    }

    if (!mounted) return;
    await widget.showAddDialog(context: context, initialName: productName);
    if (mounted) Navigator.pop(context); // 스캔 화면 닫기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('바코드 스캔'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (cap) {
              final code =
                  cap.barcodes.map((b) => b.rawValue).whereNotNull().firstOrNull;
              if (code != null) _handleCode(code);
            },
          ),
          if (_busy)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
