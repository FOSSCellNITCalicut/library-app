# Book Sharing Corner Page

**Data Required**

**Latest Donations**

| Field | Type | Required |
| :---- | :---- | :---- |
| title | String | Yes |
| author | String | Yes |
| coverImage | String | No |

---

**User Actions**

**View Latest Donations**

**Open Book Donation Form**

---

**Backend Requirement**

**Get Latest Donations**

Backend API Required (not defined in current API documentation)

Response
```json
[

  {

	"title": "Head First Python",

    "author": "Paul Barry",

    "coverImage": "image\_url"

  }

]
```
---

**Notes**

* Latest donations count is currently hardcoded as 7\.  
* Book title, author and cover image are currently hardcoded.  
* Donation data API is not present in the provided library API documentation.
