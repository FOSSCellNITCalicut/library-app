# Chat bot page

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| message | String | Yes |
| response | String | Yes |
| timestamp | DateTime | No |

---

**User Actions**

**Send Message**

**View Chat Response**

---

**Backend Requirement**

Backend API Required (not defined in current API documentation)

Expected Data Sent
```json
{

  "message": "Where can I find Head First Python?"

}
```
Expected Data Received
```json
{

  "response": "Head First Python is available in LIB branch."

}
```
---

**Frontend Mapping**

| UI Element | Backend Field |
| :---- | :---- |
| User Chat Bubble | message |
| Bot Chat Bubble | response |

---

**Notes**

* Chatbot response is currently hardcoded.  
* Frontend contains TODO to fetch chatbot response from backend.  
* Chat history is currently maintained only in frontend memory.  
* Chatbot APIs are not present in the provided library API documentation.