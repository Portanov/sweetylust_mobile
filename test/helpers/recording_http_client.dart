import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

typedef HttpResponder = http.Response Function(http.BaseRequest request);

/// Small in-memory HTTP adapter used by service tests.
/// It records requests and returns deterministic responses without a backend.
class RecordingHttpClient extends http.BaseClient {
  RecordingHttpClient(this.responder);

  final HttpResponder responder;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = responder(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

http.Response jsonResponse(Object body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}
