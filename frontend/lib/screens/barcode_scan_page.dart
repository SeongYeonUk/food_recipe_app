import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/barcode_lookup_service.dart';

// 알림창을 먼저
typedef ShowAddIngredientDialog =
    Future<void> Function({required BuildContext context, String? initialName});

class BarcodeScanPage extends StatefulWidget {
  final ShowAddIngredientDialog showAddDialog;
  const BarcodeScanPage({super.key, required this.showAddDialog});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final MobileScannerController _controller = MobileScannerController();

  bool _busy = false;
  String? _last;
  //돼지고기
  // [수정] 손전등 상태를 직접 관리하기 위한 변수 추가
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String code) async {
    if (_busy || code == _last) return;

    if (!BarcodeLookupService.isValidEAN13(code)) {
      if (!mounted) return;
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

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('바코드 스캔'),
        actions: [
          // [수정] ValueListenableBuilder 대신 IconButton을 직접 사용합니다.
          IconButton(
            color: _isTorchOn ? Colors.yellow : Colors.grey,
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            iconSize: 32.0,
            onPressed: () {
              // 컨트롤러의 손전등을 토글하고, 화면 상태도 함께 변경합니다.
              _controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final code = capture.barcodes
                  .map((barcode) => barcode.rawValue)
                  .whereNotNull()
                  .firstOrNull;
              if (code != null) _handleCode(code);
            },
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.0),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_busy)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
