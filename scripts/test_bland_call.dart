import 'dart:convert';
import 'dart:io';

void main() async {
  print('📞 Initiating Bland AI test call to +919920359130...');

  final client = HttpClient();
  final request = await client.postUrl(Uri.parse('https://api.bland.ai/v1/calls'));
  
  final apiKey = 'org_189869e62cd02a57a42151682afbcd5759153b6bbb943ab7fcc08b93aec79170faeeb470746ae3c9abdf69';
  request.headers.set('authorization', apiKey);
  request.headers.set('Content-Type', 'application/json');

  final payload = {
    'phone_number': '+919920359130',
    'task': 'You are AdaptQ Emergency Incident Dispatcher. Alert the on-call engineer that AdaptQ has detected an unrecoverable edge case during a 100,000 events/min traffic surge. Say: Hello, this is an emergency alert from AdaptQ data pipeline. Critical unhandled edge case detected. Autonomous agents failed to stabilize P0 payment latency at 145 milliseconds. Immediate human intervention is required.',
    'voice': 'nat',
    'first_sentence': 'Emergency escalation from AdaptQ data pipeline. Critical unhandled edge case detected.',
    'wait_for_greeting': false,
    'record': true,
    'max_duration': 2,
  };

  request.write(jsonEncode(payload));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();

  print('Status Code: ${response.statusCode}');
  print('Response: $responseBody');
  client.close();
}
