import 'package:http/http.dart' as http;

import 'http_transport_io.dart'
    if (dart.library.html) 'http_transport_web.dart' as platform;

http.Client createHttpClient() => platform.createHttpClient();
