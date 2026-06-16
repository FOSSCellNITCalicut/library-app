# Authentication Page

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| roll\_no | String | Yes |
| name | String | Yes |
| accessToken | String | Yes |
| refreshToken | String | Yes |

---

**User Actions**

**Login**

---

**Endpoint**

**POST /login**

Request
```json
{
  "roll_no": "B23CS001",
  "password": "password",
  "remember_me": false
}
```

`remember_me` (optional, defaults to `false`) tells the backend to securely store the password (AES-GCM encrypted) so it can silently re-authenticate with Koha if the Koha session expires mid-action. It does not affect how long the app itself stays logged in -- that's controlled by the refresh token, which is always stored regardless of this flag.

Response
```json
{
  "success": true,
  "user": {
    "roll_no": "B23CS001",
    "name": "John Doe"
  },
  "access_token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token"
}
```

---

**Token Refresh**

**POST /auth/refresh**

Request
```json
{
  "refresh_token": "jwt_refresh_token"
}
```
Response
```json
{
  "access_token": "new_jwt_access_token",
  "refresh_token": "new_jwt_refresh_token"
}
```

---

**Logout**

**POST /auth/logout**

Requires `Authorization: Bearer <access_token>` header.

Response
```json
{
  "success": true
}
```

---

**Notes**

* Login is browse-first: the app never forces a login screen on startup. Public pages (home, search, about) work without an account. `AuthScreen` is only pushed when the user taps a protected action (currently: the profile tab) or explicitly taps "Login".
* On startup, `LoadingScreen` silently calls `tryRefresh()` using any stored refresh token. If it succeeds the user is already logged in by the time `MainPage` loads; if it fails (no token, or expired), the user just browses as a guest until they choose to log in.
* Users are identified by roll number (e.g. `B23CS001`), not email. NITC Koha uses roll number as `userid`.
* On login, store the `access_token` in memory and the `refresh_token` in the OS Keychain/Keystore (Flutter: `flutter_secure_storage`).
* The access token expires in 15 minutes. Use `POST /auth/refresh` to get a new one silently before it expires.
* The `remember_me` checkbox in `AuthScreen` is unrelated to `tryRefresh()` -- it controls whether the *backend* can re-authenticate with Koha on the app's behalf, not whether the app itself stays logged in.
* See `library-app-backend/documentation/auth.md` for the full authentication specification.
