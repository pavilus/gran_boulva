import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../config/app_colors.dart';

class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const AvatarCropScreen({super.key, required this.imageBytes});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _controller = TransformationController();
  final _boundaryKey = GlobalKey();
  bool _processing = false;

  static const double _cropSize = 300;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _processing = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: dpr);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Capture echwe');
      final circular = await _applyCircularClip(byteData.buffer.asUint8List());
      if (mounted) Navigator.of(context).pop(circular);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erè: $e',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _processing = false);
      }
    }
  }

  Future<Uint8List> _applyCircularClip(Uint8List pngBytes) async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final size = src.width.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, size, size)));
    canvas.drawImage(src, Offset.zero,
        Paint()..filterQuality = FilterQuality.high);
    final picture = recorder.endRecording();
    final result = await picture.toImage(src.width, src.height);
    final data = await result.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: _processing ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Pozisyone foto w',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Image viewport — only this is captured by RepaintBoundary
                  SizedBox(
                    width: _cropSize,
                    height: _cropSize,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: ClipRect(
                        child: InteractiveViewer(
                          transformationController: _controller,
                          constrained: false,
                          boundaryMargin:
                              const EdgeInsets.all(double.infinity),
                          minScale: 1.0,
                          maxScale: 6.0,
                          child: SizedBox(
                            width: _cropSize,
                            height: _cropSize,
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Dark vignette with circular cutout + guide ring
                  // (painted on top, excluded from capture)
                  const IgnorePointer(
                    child: SizedBox(
                      width: _cropSize,
                      height: _cropSize,
                      child: CustomPaint(
                        painter: _CircleMaskPainter(radius: _cropSize / 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Glise ak grandi foto a pou pozisyone figi w',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _processing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Anile',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _processing ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        disabledBackgroundColor: AppColors.purpleDim,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _processing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Konfime',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  final double radius;
  const _CircleMaskPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
    canvas.drawCircle(center, radius, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // Guide ring
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_CircleMaskPainter old) => old.radius != radius;
}
