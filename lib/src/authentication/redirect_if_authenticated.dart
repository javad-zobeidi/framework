import 'package:vania/vania.dart';

class RedirectIfAuthenticated extends Middleware {
  final String path;
  RedirectIfAuthenticated({required this.path});

  @override
  Future handle(Request req) async {
    bool loggedIn = await getSession<bool?>('logged_in') ?? false;
    if (loggedIn) {
      throw RedirectException(
        message: path,
        responseType: ResponseType.html,
      );
    }
  }
}
