import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class PipelineParticleView extends StatefulWidget {
  final int trafficRate;
  final bool isFlowMindActive;

  const PipelineParticleView({
    super.key,
    required this.trafficRate,
    required this.isFlowMindActive,
  });

  @override
  State<PipelineParticleView> createState() => _PipelineParticleViewState();
}

class _PipelineParticleViewState extends State<PipelineParticleView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    _particles.clear();
    int count = widget.trafficRate > 5000 ? 50 : 20;
    for (int i = 0; i < count; i++) {
      _particles.add(Particle(
        progress: _random.nextDouble(),
        speed: 0.2 + _random.nextDouble() * 0.4,
        lane: _random.nextInt(4),
        color: _getPriorityColor(_random.nextInt(4)),
      ));
    }
  }

  Color _getPriorityColor(int lane) {
    switch (lane) {
      case 0:
        return AppColors.p0Critical;
      case 1:
        return AppColors.p1High;
      case 2:
        return AppColors.p2Normal;
      default:
        return AppColors.p3Low;
    }
  }

  @override
  void didUpdateWidget(covariant PipelineParticleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trafficRate != widget.trafficRate) {
      _initParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: PipelineCanvasPainter(
            particles: _particles,
            isFlowMindActive: widget.isFlowMindActive,
            isSpike: widget.trafficRate > 5000,
          ),
        );
      },
    );
  }
}

class Particle {
  double progress;
  double speed;
  int lane;
  Color color;

  Particle({
    required this.progress,
    required this.speed,
    required this.lane,
    required this.color,
  });
}

class PipelineCanvasPainter extends CustomPainter {
  final List<Particle> particles;
  final bool isFlowMindActive;
  final bool isSpike;

  PipelineCanvasPainter({
    required this.particles,
    required this.isFlowMindActive,
    required this.isSpike,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Node Positions
    final startX = size.width * 0.1;
    final classifierX = size.width * 0.35;
    final flowmindX = size.width * 0.6;
    final sinkX = size.width * 0.9;
    final centerY = size.height * 0.5;

    // Draw connecting pipeline conduits
    final path = Path();
    path.moveTo(startX, centerY);
    path.lineTo(classifierX, centerY);
    path.lineTo(flowmindX, centerY);
    path.lineTo(sinkX, centerY);

    canvas.drawPath(path, paintLine);

    // Draw Nodes
    _drawNode(canvas, Offset(startX, centerY), 'INGESTION', AppColors.healthy);
    _drawNode(canvas, Offset(classifierX, centerY), 'ROUTER', AppColors.info);
    _drawNode(canvas, Offset(flowmindX, centerY), 'FLOWMIND', AppColors.agent);
    _drawNode(canvas, Offset(sinkX, centerY), 'WORKERS', isSpike ? AppColors.warning : AppColors.healthy);

    // Render moving particles along pipeline
    for (var particle in particles) {
      particle.progress += 0.01 * particle.speed;
      if (particle.progress > 1.0) particle.progress = 0.0;

      final currentX = startX + (sinkX - startX) * particle.progress;
      final laneOffset = (particle.lane - 1.5) * 8.0;
      final currentY = centerY + laneOffset;

      final particlePaint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), isSpike ? 3.5 : 2.5, particlePaint);
    }
  }

  void _drawNode(Canvas canvas, Offset position, String label, Color color) {
    final bgPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(position, 22, bgPaint);
    canvas.drawCircle(position, 22, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label.substring(0, min(3, label.length)),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant PipelineCanvasPainter oldDelegate) => true;
}
