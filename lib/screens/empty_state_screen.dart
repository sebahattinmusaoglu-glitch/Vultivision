import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'new_group_screen.dart';

class EmptyStateScreen extends StatelessWidget {
  final VoidCallback onGroupCreated;

  const EmptyStateScreen({super.key, required this.onGroupCreated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Üst bar
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // TV ikonu
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _TVIconPainter(),
                ),
              ),

              const SizedBox(height: 32),

              // Başlık
              const Text(
                "You don't have a group yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              // Açıklama
              const Text(
                'Group the YouTube channels you want to watch.\nOpen and watch. No decisions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // Buton
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NewGroupScreen(),
                      ),
                    );
                    onGroupCreated();
                  },
                  child: const Text('Create Your First Group'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// TV ikonu çizimi
class _TVIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // TV gövdesi
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.55),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, paint);

    // Sol anten
    canvas.drawLine(
      Offset(w * 0.35, h * 0.3),
      Offset(w * 0.22, h * 0.08),
      paint,
    );

    // Sağ anten
    canvas.drawLine(
      Offset(w * 0.65, h * 0.3),
      Offset(w * 0.78, h * 0.08),
      paint,
    );

    // Küçük nokta (sağ alt)
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.78, h * 0.76), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}