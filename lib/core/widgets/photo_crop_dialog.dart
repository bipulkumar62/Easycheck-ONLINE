import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Opens a crop/adjust sheet and returns PNG bytes for the selected area.
///
/// The preview and the exported image use the same source rectangle, so what
/// the clinic admin sees is exactly what patients receive. [aspectRatio] is the
/// final card shape (16:9 for the clinic cover, 1:1 for the doctor portrait).
Future<Uint8List?> showPhotoCropDialog(
  BuildContext context, {
  required Uint8List bytes,
  required double aspectRatio,
  required String title,
}) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _PhotoCropDialog(bytes: bytes, aspectRatio: aspectRatio, title: title),
  );
}

class _PhotoCropDialog extends StatefulWidget {
  const _PhotoCropDialog({
    required this.bytes,
    required this.aspectRatio,
    required this.title,
  });

  final Uint8List bytes;
  final double aspectRatio;
  final String title;

  @override
  State<_PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<_PhotoCropDialog> {
  ui.Image? _image;
  String? _error;
  double _zoom = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).t('cropDecodeFailed');
      });
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Rect _baseCropRect(ui.Image image) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final sourceAspect = width / height;
    double cropWidth;
    double cropHeight;
    if (sourceAspect > widget.aspectRatio) {
      cropHeight = height;
      cropWidth = height * widget.aspectRatio;
    } else {
      cropWidth = width;
      cropHeight = width / widget.aspectRatio;
    }
    return Rect.fromLTWH(
      (width - cropWidth) / 2,
      (height - cropHeight) / 2,
      cropWidth,
      cropHeight,
    );
  }

  Rect _cropRect(ui.Image image) {
    final base = _baseCropRect(image);
    final cropWidth = base.width / _zoom;
    final cropHeight = base.height / _zoom;
    final maxDx = (base.width - cropWidth) / 2;
    final maxDy = (base.height - cropHeight) / 2;
    return Rect.fromCenter(
      center: Offset(
        base.center.dx + _offsetX * maxDx,
        base.center.dy + _offsetY * maxDy,
      ),
      width: cropWidth,
      height: cropHeight,
    );
  }

  Future<void> _apply() async {
    final image = _image;
    if (image == null || _applying) return;
    setState(() => _applying = true);
    try {
      final source = _cropRect(image);
      var outputWidth = source.width;
      var outputHeight = source.height;
      const maxDimension = 1600.0;
      if (outputWidth > maxDimension || outputHeight > maxDimension) {
        final scale =
            maxDimension /
            (outputWidth > outputHeight ? outputWidth : outputHeight);
        outputWidth *= scale;
        outputHeight *= scale;
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        source,
        Rect.fromLTWH(0, 0, outputWidth, outputHeight),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final output = await picture.toImage(
        outputWidth.round().clamp(1, 1600).toInt(),
        outputHeight.round().clamp(1, 1600).toInt(),
      );
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      output.dispose();
      picture.dispose();
      if (!mounted) return;
      Navigator.of(context).pop(data?.buffer.asUint8List());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = AppLocalizations.of(context).t('cropExportFailed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final maxPreviewHeight = MediaQuery.sizeOf(context).height * 0.42;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.crop_rounded,
                      color: scheme.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTypography.titleMd),
                        const SizedBox(height: 2),
                        Text(
                          l10n.t('cropHint'),
                          style: AppTypography.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceLg),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Text(
                    _error!,
                    style: AppTypography.bodySm.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                )
              else if (_image == null)
                SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(color: scheme.primary),
                  ),
                )
              else ...[
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxPreviewHeight),
                    child: AspectRatio(
                      aspectRatio: widget.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: _CropPreviewPainter(
                            image: _image!,
                            sourceRect: _cropRect(_image!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceMd),
                _sliderRow(
                  icon: Icons.photo_size_select_small_rounded,
                  endIcon: Icons.photo_size_select_large_rounded,
                  label: l10n.t('cropSize'),
                  value: _zoom,
                  min: 1,
                  max: 3,
                  onChanged: (value) => setState(() => _zoom = value),
                ),
                _sliderRow(
                  icon: Icons.swap_horiz_rounded,
                  label: l10n.t('cropHorizontal'),
                  value: _offsetX,
                  min: -1,
                  max: 1,
                  onChanged: (value) => setState(() => _offsetX = value),
                ),
                _sliderRow(
                  icon: Icons.swap_vert_rounded,
                  label: l10n.t('cropVertical'),
                  value: _offsetY,
                  min: -1,
                  max: 1,
                  onChanged: (value) => setState(() => _offsetY = value),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _zoom = 1.0;
                      _offsetX = 0.0;
                      _offsetY = 0.0;
                    }),
                    icon: const Icon(Icons.restart_alt_rounded, size: 17),
                    label: Text(l10n.t('cropReset')),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _applying
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _image == null || _error != null || _applying
                          ? null
                          : _apply,
                      child: _applying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.t('cropUsePhoto')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderRow({
    required IconData icon,
    IconData? endIcon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (endIcon != null)
              Icon(endIcon, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: min == 1 && max == 3 ? 40 : 40,
          activeColor: scheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CropPreviewPainter extends CustomPainter {
  _CropPreviewPainter({required this.image, required this.sourceRect});

  final ui.Image image;
  final Rect sourceRect;

  @override
  void paint(Canvas canvas, Size size) {
    final destination = Offset.zero & size;
    canvas.drawImageRect(
      image,
      sourceRect,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropPreviewPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.sourceRect != sourceRect;
  }
}
