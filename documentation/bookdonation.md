# Book Donation Page

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| title | String | Yes |
| author | String | Yes |
| publicationYear | Integer | Yes |
| goodCondition | Boolean | Yes |

---

**User Actions**

**Submit Book Donation**

---

**Backend Requirement**

Backend API Required (not defined in current API documentation)

Expected Data
```json
{

  "title": "Head First Python",

  "author": "Paul Barry",

  "publicationYear": 2023,

  "goodCondition": true

}
```
---

**Notes**

* Frontend contains TODO for sending donation data to backend.  
* Submission is only allowed when the book condition checkbox is checked.  
* Donation management APIs are not present in the provided library API documentation.