# Notifications Page

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| id | String | Yes |
| message | String | Yes |
| text | String | Yes |
| timeString | String | Yes |
| read | Boolean | Yes |

---

**User Actions**

**View Notifications**

**Filter Notifications (All / Read / Unread)**

**Mark Notification as Read**

**Mark Notification as Unread**

**View Notification Details**

**Clear Notifications**

---

**Backend Requirement**

Backend API Required (not defined in current API documentation)

**Get Notifications**

Expected Response
```json
[

  {

	"id": "1",

    "message": "Book Due Reminder",

	"text": "Head First Python is due tomorrow.",

    "timeString": "2026-06-02 10:30:00",

	"read": false

  }

]
```
---

**Update Notification Read Status**

Expected Data
```json
{

  "id": "1",

  "read": true

}
```
---

**Clear Notifications**

Expected Data
```json
{

  "userId": "user\_id"

}
```
---

**Frontend Mapping**

| UI Element | Backend Field |
| :---- | :---- |
| Notification Title | message |
| Notification Preview | text |
| Notification Timestamp | timeString |
| Read / Unread State | read |

---

**Notification Details Page**

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| message | String | Yes |
| text | String | Yes |
| timeString | String | Yes |
| read | Boolean | Yes |

---

**User Actions**

**View Full Notification**

**Toggle Read / Unread Status**

---

**Notes**

* Notifications are currently stored locally using SharedPreferences.  
* Sample notifications are currently hardcoded.  
* Read/unread status is currently managed locally.  
* Notification filters are implemented in frontend.  
* Backend notification APIs are not present in the provided library API documentation.

 
