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
  "password": "password"
}
```
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

* Login functionality is not yet implemented in the frontend. The current button in `authScreen.dart` directly navigates to `MainPage()`.
* Users are identified by roll number (e.g. `B23CS001`), not email. NITC Koha uses roll number as `userid`.
* On login, store the `access_token` in memory and the `refresh_token` in the OS Keychain/Keystore (Flutter: `flutter_secure_storage`).
* The access token expires in 15 minutes. Use `POST /auth/refresh` to get a new one silently before it expires.
* See `library-app-backend/documentation/auth.md` for the full authentication specification.
