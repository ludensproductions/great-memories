import { CookieOptions, Response } from 'express';
import { Duration } from 'luxon';
import { CookieResponse } from 'src/dtos/auth.dto';
import { GreatMemoriesCookie } from 'src/enum';

export const respondWithCookie = <T>(res: Response, body: T, { isSecure, values }: CookieResponse) => {
  const defaults: CookieOptions = {
    path: '/',
    sameSite: 'lax',
    httpOnly: true,
    secure: isSecure,
    maxAge: Duration.fromObject({ days: 400 }).toMillis(),
  };

  const cookieOptions: Record<GreatMemoriesCookie, CookieOptions> = {
    [GreatMemoriesCookie.AuthType]: defaults,
    [GreatMemoriesCookie.AccessToken]: defaults,
    [GreatMemoriesCookie.MaintenanceToken]: { ...defaults, maxAge: Duration.fromObject({ days: 1 }).toMillis() },
    [GreatMemoriesCookie.OAuthState]: defaults,
    [GreatMemoriesCookie.OAuthCodeVerifier]: defaults,
    // no httpOnly so that the client can know the auth state
    [GreatMemoriesCookie.IsAuthenticated]: { ...defaults, httpOnly: false },
    [GreatMemoriesCookie.SharedLinkToken]: { ...defaults, maxAge: Duration.fromObject({ days: 1 }).toMillis() },
  };

  for (const { key, value } of values) {
    const options = cookieOptions[key];
    res.cookie(key, value, options);
  }

  return body;
};

export const respondWithoutCookie = <T>(res: Response, body: T, cookies: GreatMemoriesCookie[]) => {
  for (const cookie of cookies) {
    res.clearCookie(cookie);
  }

  return body;
};
