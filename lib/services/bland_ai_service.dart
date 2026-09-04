import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlandAiCallRecord {
  final String callId;
  final String phoneNumber;
  final DateTime timestamp;
  final String status;
  final String reason;
  final String? transcript;
  final bool isSimulated;

  const BlandAiCallRecord({
    required this.callId,
    required this.phoneNumber,
    required this.timestamp,
    required this.status,
    required this.reason,
    this.transcript,
    this.isSimulated = false,
  });
}

/// Service to trigger outbound phone calls using Bland AI (https://bland.ai)
/// when the data pipeline experiences unrecoverable edge cases that
/// autonomous agents cannot resolve.
class BlandAiService {
  static final BlandAiService _instance = BlandAiService._internal();
  factory BlandAiService() => _instance;

  static const String _prefApiKey = 'bland_ai_api_key';
  static const String _prefPhoneNumber = 'bland_ai_phone_number';
  static const String _blandApiUrl = 'https://api.bland.ai/v1/calls';

  final StreamController<BlandAiCallRecord> _emergencyCallController =
      StreamController<BlandAiCallRecord>.broadcast();
  Stream<BlandAiCallRecord> get onEmergencyCall => _emergencyCallController.stream;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  String? _apiKey = 'org_189869e62cd02a57a42151682afbcd5759153b6bbb943ab7fcc08b93aec79170faeeb470746ae3c9abdf69';
  String? _onCallPhoneNumber = '+919920359130';
  bool _isDispatching = false;
  BlandAiCallRecord? _latestCall;
  final List<BlandAiCallRecord> _callHistory = [];

  bool get isDispatching => _isDispatching;
  BlandAiCallRecord? get latestCall => _latestCall;
  List<BlandAiCallRecord> get callHistory => List.unmodifiable(_callHistory);
  String? get apiKey => _apiKey;
  String? get onCallPhoneNumber => _onCallPhoneNumber;

  BlandAiService._internal() {
    _loadConfig();
  }

  void notifyCallEvent(BlandAiCallRecord record) {
    _emergencyCallController.add(record);
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(_prefApiKey) ?? 'org_189869e62cd02a57a42151682afbcd5759153b6bbb943ab7fcc08b93aec79170faeeb470746ae3c9abdf69';
      _onCallPhoneNumber = prefs.getString(_prefPhoneNumber) ?? '+919920359130';
    } catch (_) {}
  }

  Future<void> saveConfig({required String apiKey, required String phoneNumber}) async {
    _apiKey = apiKey.trim();
    _onCallPhoneNumber = phoneNumber.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, _apiKey!);
    await prefs.setString(_prefPhoneNumber, _onCallPhoneNumber!);
  }

  /// Triggers an emergency call to the on-call engineer.
  /// If an API key is provided, it calls the live Bland AI API.
  /// If no key is set, it executes a realistic simulated dispatch.
  Future<BlandAiCallRecord> triggerEmergencyCall({
    required String incidentTitle,
    required String reason,
    required double p0LatencyMs,
    required int trafficRate,
  }) async {
    final timestamp = DateTime.now();
    final targetPhone = _onCallPhoneNumber?.isNotEmpty == true ? _onCallPhoneNumber! : '+919920359130';

    if (_isDispatching) {
      return _latestCall ??
          BlandAiCallRecord(
            callId: 'c_pending_${timestamp.millisecondsSinceEpoch}',
            phoneNumber: targetPhone,
            timestamp: timestamp,
            status: 'DISPATCHING',
            reason: reason,
          );
    }

    _isDispatching = true;

    // Immediately emit incoming call event so the phone rings on screen without waiting for HTTP delays
    final initialRecord = BlandAiCallRecord(
      callId: 'c_${timestamp.millisecondsSinceEpoch.toString().substring(7)}',
      phoneNumber: targetPhone,
      timestamp: timestamp,
      status: 'INITIATED',
      reason: reason,
      transcript: 'Emergency escalation from AdaptQ data pipeline. P0 Latency: ${p0LatencyMs.toStringAsFixed(1)}ms.',
    );
    _latestCall = initialRecord;
    _callHistory.insert(0, initialRecord);
    _emergencyCallController.add(initialRecord);

    final taskPrompt = '''
You are AdaptQ Autonomous Incident Dispatcher. 
Alert the on-call engineer that the AdaptQ real-time data pipeline has encountered an UNRECOVERABLE EDGE CASE.
Incident: $incidentTitle.
Traffic Rate: $trafficRate events/min.
P0 Payment Latency: ${p0LatencyMs.toStringAsFixed(1)}ms (SLA Ceiling Exceeded).
Reason: $reason.
The autonomous FlowMind Optimizer and Evaluator agents attempted 3 consecutive rollbacks but could not stabilize the pipeline.
Inform the engineer that manual intervention is required to approve emergency partition shedding or throttle upstream ingestion.
Speak urgently, clearly, and professionally. Ask the engineer to acknowledge receipt of the alert.
''';

    // Check if live Bland AI API key is configured
    if (_apiKey != null && _apiKey!.isNotEmpty && !_apiKey!.contains('mock')) {
      try {
        final response = await _dio.post(
          _blandApiUrl,
          options: Options(
            headers: {
              'authorization': _apiKey,
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'phone_number': targetPhone,
            'task': taskPrompt,
            'voice': 'nat',
            'first_sentence': 'Emergency escalation from AdaptQ data pipeline. Critical unhandled edge case detected.',
            'wait_for_greeting': false,
            'record': true,
            'max_duration': 3,
            'metadata': {
              'system': 'AdaptQ',
              'incident': incidentTitle,
              'p0_latency': p0LatencyMs,
            },
          },
        );

        final callId = response.data['call_id'] ?? 'c_${DateTime.now().millisecondsSinceEpoch}';
        final record = BlandAiCallRecord(
          callId: callId,
          phoneNumber: targetPhone,
          timestamp: timestamp,
          status: 'DISPATCHED_LIVE',
          reason: reason,
          transcript: 'Call initiated to on-call engineer via Bland AI telephone network.',
          isSimulated: false,
        );

        _latestCall = record;
        _isDispatching = false;
        return record;
      } catch (e) {
        String errorMsg = e.toString();
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        }

        // Fallback to simulated record if API network or international credits block occurs
        final fallback = BlandAiCallRecord(
          callId: 'c_bland_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          phoneNumber: targetPhone,
          timestamp: timestamp,
          status: errorMsg.contains('International') ? 'INTL_CREDITS_REQUIRED' : 'API_ERROR_FALLBACK',
          reason: 'Bland AI ($errorMsg). Emergency alert recorded in SRE dispatch log.',
          transcript: taskPrompt,
          isSimulated: true,
        );
        _latestCall = fallback;
        _callHistory.insert(0, fallback);
        _isDispatching = false;
        _emergencyCallController.add(fallback);
        return fallback;
      }
    } else {
      // Realistic simulation mode
      await Future.delayed(const Duration(milliseconds: 1200));
      final record = BlandAiCallRecord(
        callId: 'c_sim_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        phoneNumber: targetPhone,
        timestamp: timestamp,
        status: 'DISPATCHED_SIMULATED',
        reason: reason,
        transcript: 'Simulated Voice Dispatch: "Emergency escalation from AdaptQ. Critical edge case: $reason. P0 Latency: ${p0LatencyMs.toStringAsFixed(1)}ms."',
        isSimulated: true,
      );

      _latestCall = record;
      _callHistory.insert(0, record);
      _isDispatching = false;
      _emergencyCallController.add(record);
      return record;
    }
  }
}
