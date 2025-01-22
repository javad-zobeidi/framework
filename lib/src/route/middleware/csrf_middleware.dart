import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:vania/src/exception/page_expired_exception.dart';
import 'package:vania/src/utils/functions.dart';
import 'package:vania/vania.dart';

import 'dart:async';

class CsrfMiddleware extends Middleware {
  /// This middleware is used to verify the CSRF token in the request.
  ///
  /// The middleware checks if the request method is one of the [POST],[PUT],[Patch]
  /// and checks if the request URI is not in the list of excluded paths from the CSRF
  /// validation.
  ///
  /// If the request URI is not in the excluded list, then it checks if the
  /// _csrf or _token input field is present in the request, if not then it
  /// throws a PageExpiredException.
  ///
  /// If the token is present, then it verifies the token with the stored token
  /// in the session, if the verification fails then it throws a
  /// PageExpiredException.
  ///
  @override
  Future<void> handle(Request req) async {
    if (req.method!.toLowerCase() == 'post' ||
        req.method!.toLowerCase() == 'put' ||
        req.method!.toLowerCase() == 'patch') {
      List<String> csrfExcept = ['api/*'];
      csrfExcept.addAll(Config().get('csrf_except') ?? []);

      String uri = Uri.parse(
        sanitizeRoutePath(
          req.uri.toString(),
        ),
      ).path.toLowerCase();

      if (!_isUrlExcluded(uri, csrfExcept)) {
        String csrfToken = req.cookie('XSRF-TOKEN') ?? '';
        if (csrfToken.isNotEmpty) {
          csrfToken = _fixBase64Padding(csrfToken);
        }
        String? token = req.input('_csrf');
        token ??= req.input('_token');
        token ??= req.header('X-CSRF-TOKEN');

        if (token == null) {
          throw PageExpiredException();
        }

        String storedToken = await getSession<String?>('x_csrf_token') ?? '';
        if (storedToken != token) {
          throw PageExpiredException();
        }
        String iv = await getSession<String?>('x_csrf_token_iv') ?? '';
        var hmac = Hmac(sha512, utf8.encode(iv));
        final Digest hash = hmac.convert(utf8.encode(token));
        if (base64.encode(hash.bytes) != csrfToken) {
          throw PageExpiredException();
        }
      }
    }
  }

  String _fixBase64Padding(String value) {
    while (value.length % 4 != 0) {
      value += '=';
    }
    return value;
  }

  bool _isUrlExcluded(String path, List<String> csrfExcept) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    for (var pattern in csrfExcept) {
      final cleanPattern =
          pattern.startsWith('/') ? pattern.substring(1) : pattern;
      if (cleanPattern.contains('*')) {
        final regexStr =
            cleanPattern.replaceAll('*', '.*').replaceAll('/', '\\/');
        final regex = RegExp('^$regexStr\$', caseSensitive: false);
        if (regex.hasMatch(cleanPath)) {
          return true;
        }
      } else if (cleanPath
          .toLowerCase()
          .startsWith(cleanPattern.toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}
