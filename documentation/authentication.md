# Authentication Page

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| userId | String | Yes |
| name | String | Yes |
| email | String | Yes |
| accessToken | String | Yes |

---

**User Actions**

**Login**

---

**Endpoint**

**POST /auth/login**

Request
```json
{

  "email": "user@nitc.ac.in",

  "password": "password"

}
```
Response
```json
{

  "success": true,

  "user": {

	"userId": "2024BCS001",

	"name": "John Doe",

	"email": "user@nitc.ac.in"

  },

  "accessToken": "jwt\_token"

}
```
---

**Notes**

* Login functionality is not implemented in frontend yet.  
* Current button directly navigates to MainPage().  
* Authentication API is not present in the provided library API documentation.

 