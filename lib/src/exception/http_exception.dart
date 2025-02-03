import 'dart:io';

import '../http/response/response.dart';
import 'base_http_exception.dart';

class HttpResponseException extends BaseHttpResponseException {
  HttpResponseException({
    super.message,
    super.code = HttpStatus.found,
    super.responseType = ResponseType.json,
    super.errorCode = 'Error',
  });
}
