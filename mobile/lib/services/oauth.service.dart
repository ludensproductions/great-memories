import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:great_memories_mobile/services/api.service.dart';
import 'package:logging/logging.dart';
import 'package:openapi/api.dart';

// Redirect URL = app.great-memories:///oauth-callback

class OAuthService {
  final ApiService _apiService;
  final callbackUrlScheme = 'app.great-memories';
  final log = Logger('OAuthService');
  OAuthService(this._apiService);

  Future<String?> getOAuthServerUrl(String serverUrl, String state, String codeChallenge) async {
    // Resolve API server endpoint from user provided serverUrl
    await _apiService.resolveAndSetEndpoint(serverUrl);
    final redirectUri = '$callbackUrlScheme:///oauth-callback';
    log.info("Starting OAuth flow with redirect URI: $redirectUri");

    final dto = await _apiService.oAuthApi.startOAuth(
      OAuthConfigDto(
        redirectUri: redirectUri,
        state: Optional.present(state),
        codeChallenge: Optional.present(codeChallenge),
      ),
    );

    final authUrl = dto?.url;
    log.info('Received Authorization URL: $authUrl');

    return authUrl;
  }

  Future<LoginResponseDto?> oAuthLogin(String oauthUrl, String state, String codeVerifier) async {
    String result = await FlutterWebAuth2.authenticate(url: oauthUrl, callbackUrlScheme: callbackUrlScheme);

    log.info('Received OAuth callback: $result');

    if (result.startsWith('app.great-memories:/oauth-callback')) {
      result = result.replaceAll('app.great-memories:/oauth-callback', 'app.great-memories:///oauth-callback');
    }

    return await _apiService.oAuthApi.finishOAuth(
      OAuthCallbackDto(url: result, state: Optional.present(state), codeVerifier: Optional.present(codeVerifier)),
    );
  }
}
