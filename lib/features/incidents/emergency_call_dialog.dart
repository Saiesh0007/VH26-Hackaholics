import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pipeline_provider.dart';
import '../../core/theme/app_colors.dart';

enum CallState {
  ringing,
  connected,
  ended,
}

class EmergencyCallDialog extends ConsumerStatefulWidget {
  final String incidentTitle;
  final String reason;
  final double p0LatencyMs;
  final int trafficRate;

  const EmergencyCallDialog({
    super.key,
    this.incidentTitle = 'UNRECOVERABLE PIPELINE EDGE CASE',
    this.reason = 'Autonomous agent rollbacks failed to stabilize pipeline. P0 Latency ceiling breached.',
    this.p0LatencyMs = 148.5,
    this.trafficRate = 100000,
  });

  static Future<void> show(
    BuildContext context, {
    String incidentTitle = 'UNRECOVERABLE PIPELINE EDGE CASE',
    String reason = 'Autonomous agent rollbacks failed to stabilize pipeline. P0 Latency ceiling breached.',
    double p0LatencyMs = 148.5,
    int trafficRate = 100000,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmergencyCallDialog(
        incidentTitle: incidentTitle,
        reason: reason,
        p0LatencyMs: p0LatencyMs,
        trafficRate: trafficRate,
      ),
    );
  }

  @override
  ConsumerState<EmergencyCallDialog> createState() => _EmergencyCallDialogState();
}

class _EmergencyCallDialogState extends ConsumerState<EmergencyCallDialog> with SingleTickerProviderStateMixin {
  CallState _callState = CallState.ringing;
  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  Timer? _ringHapticTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final String _speechScript =
      'Hello on-call engineer. This is AdaptQ Autonomous SRE Dispatcher. '
      'A critical unrecoverable edge case has occurred in the data pipeline at 100,000 events per minute. '
      'Autonomous FlowMind agent attempted multiple rollbacks, but P0 payment latency remains critical at 148 milliseconds. '
      'Please confirm immediate authorization for emergency partition load shedding.';

  String _visibleSpeech = '';
  int _speechCharIndex = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial ring haptic vibrations
    _startRingingHaptics();
  }

  void _startRingingHaptics() {
    HapticFeedback.vibrate();
    _ringHapticTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (_callState == CallState.ringing) {
        HapticFeedback.vibrate();
      }
    });
  }

  void _answerCall() {
    _ringHapticTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _callState = CallState.connected;
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callDurationSeconds++);
      }
    });

    // Start typewriter speech readout simulation
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (_speechCharIndex < _speechScript.length) {
        if (mounted) {
          setState(() {
            _visibleSpeech += _speechScript[_speechCharIndex];
            _speechCharIndex++;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _declineCall() {
    _cleanup();
    Navigator.pop(context);
  }

  void _authorizeEmergencyMitigation() {
    HapticFeedback.mediumImpact();
    // Execute mitigation through repository
    ref.read(pipelineRepositoryProvider).recover();
    setState(() {
      _callState = CallState.ended;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.healthy,
            content: Text('✅ SRE AUTHORIZATION GRANTED: Emergency mitigation applied. Pipeline stabilized.'),
          ),
        );
      }
    });
  }

  void _cleanup() {
    _durationTimer?.cancel();
    _ringHapticTimer?.cancel();
    _typewriterTimer?.cancel();
    _pulseController.dispose();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _callState == CallState.ringing ? AppColors.critical : AppColors.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_callState == CallState.ringing ? AppColors.critical : AppColors.primary).withOpacity(0.35),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _callState == CallState.ringing
                      ? AppColors.critical.withOpacity(0.18)
                      : AppColors.healthy.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _callState == CallState.ringing ? AppColors.critical : AppColors.healthy,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _callState == CallState.ringing ? AppColors.critical : AppColors.healthy,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _callState == CallState.ringing
                          ? 'INCOMING EMERGENCY CALL'
                          : (_callState == CallState.connected
                              ? 'CONNECTED (${_formatDuration(_callDurationSeconds)})'
                              : 'CALL ENDED'),
                      style: TextStyle(
                        color: _callState == CallState.ringing ? AppColors.critical : AppColors.healthy,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pulsing Avatar Emblem
              ScaleTransition(
                scale: _callState == CallState.ringing ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _callState == CallState.ringing
                          ? [AppColors.critical, const Color(0xFFB91C1C)]
                          : [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_callState == CallState.ringing ? AppColors.critical : AppColors.primary).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _callState == CallState.ringing ? Icons.phone_in_talk_rounded : Icons.headset_mic_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Caller ID Details
              const Text(
                'AdaptQ Autonomous SRE Dispatcher',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bland AI Automated Voice Gateway • +1 (800) 555-ADAPTQ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),

              // Incident Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'INCIDENT ALERT',
                          style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.trafficRate} e/min',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reason,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('P0 Payment Latency: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        Text(
                          '${widget.p0LatencyMs.toStringAsFixed(1)} ms',
                          style: const TextStyle(color: AppColors.critical, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // In-Call Live Spoken Transcript & Equalizer
              if (_callState == CallState.connected) ...[
                // Simulated Audio Equalizer Bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(12, (index) {
                    final heights = [12.0, 24.0, 36.0, 18.0, 42.0, 28.0, 38.0, 16.0, 32.0, 22.0, 14.0, 26.0];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 40)),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 4,
                      height: heights[index % heights.length],
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  constraints: const Duration(seconds: 0) == Duration.zero ? const BoxConstraints(maxHeight: 110) : null,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _visibleSpeech.isEmpty ? 'Connecting audio stream...' : _visibleSpeech,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons
              if (_callState == CallState.ringing) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline Button
                    InkWell(
                      onTap: _declineCall,
                      borderRadius: BorderRadius.circular(35),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.critical,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 6),
                          const Text('Decline', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    // Accept Button
                    InkWell(
                      onTap: _answerCall,
                      borderRadius: BorderRadius.circular(35),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.healthy,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 6),
                          const Text('Accept', style: TextStyle(color: AppColors.healthy, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else if (_callState == CallState.connected) ...[
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.healthy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _authorizeEmergencyMitigation,
                        icon: const Icon(Icons.verified, size: 18),
                        label: const Text(
                          'AUTHORIZE EMERGENCY SHEDDING',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _declineCall,
                      icon: const Icon(Icons.call_end, size: 16, color: AppColors.critical),
                      label: const Text('End Call & Keep Monitoring', style: TextStyle(color: AppColors.critical, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
