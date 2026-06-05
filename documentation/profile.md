# Profile Page

**Data Required**

**User Profile**

| Field | Type | Required |
| :---- | :---- | :---- |
| name | String | Yes |
| email | String | Yes |
| rollNumber | String | Yes |
| profileImage | String (URL) | Optional |

**Borrowed Books Summary**

| Field | Type | Required |
| :---- | :---- | :---- |
| borrowedBooks | Integer | Yes |
| maxBooksAllowed | Integer | Yes |

**My Books**

| Field | Type | Required |
| :---- | :---- | :---- |
| biblionumber | Integer | Yes |
| title | String | Yes |
| author | String | Yes |
| dueDate | Date | Yes |
| coverImage | String (URL) | Optional |

---

**User Actions**

**Logout**

**View Payment of Late Dues**

**View History of Late Dues**

**View Borrowed Books**

**Open Book Renewal Page**

---

**Backend Requirement**

**User Profile**

Backend API Required (not defined in current API documentation)

Expected Data
```json
{

  "name": "John Doe",

  "email": "john@nitc.ac.in",

  "rollNumber": "B230001CS",

  "profileImage": "image\_url"

}
```
---

**Borrowed Books Summary**

Backend API Required (not defined in current API documentation)

Expected Data
```json
{

  "borrowedBooks": 3,

  "maxBooksAllowed": 5

}
```
---

**My Books**

Backend API Required (not defined in current API documentation)

Expected Data
```json
[

  {

    "biblionumber": 74466,

	"title": "Head First Python",

    "author": "Paul Barry",

    "dueDate": "2026-06-10"

  }

]
```
---

**Frontend Mapping**

| UI Element | Backend Field |
| :---- | :---- |
| Username | name |
| Email | email |
| Roll Number | rollNumber |
| Borrowed Books Indicator | borrowedBooks, maxBooksAllowed |
| Book Title | title |
| Author | author |
| Due Date | dueDate |

---

**Notes**

* Profile data is currently hardcoded.  
* Borrowed books count is currently hardcoded.  
* My Books list is currently hardcoded.  
* Logout functionality is not implemented.  
* Payment pages are accessible from this page.

 

