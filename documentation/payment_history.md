# Payment Hostory Page

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| **totalDueAmount** | **Number** | **Yes** |

**Payment History**

| Field | Type | Required |
| :---- | :---- | :---- |
| **paymentDate** | **Date** | **Yes** |
| **amount** | **Number** | **Yes** |

---

**User Actions**

**View Due Amount**

**View Payment History**

**Open Payment Page**

---

**Backend Requirement**

**Backend API Required (not defined in current API documentation)**

**Expected Data**
```json
{

  "totalDueAmount": 2000,

  "paymentHistory": [

	{

      "paymentDate": "2026-06-01",

      "amount": 200

	}

  ]

}

```
---

**Frontend Mapping**

| UI Element | Backend Field |
| :---- | :---- |
| **Due Pending** | **totalDueAmount** |
| **History Date** | **paymentDate** |
| **History Amount** | **amount** |

---

**Notes**

* **Due amount is currently hardcoded.**  
* **Payment history is currently hardcoded.**  
* **Accessible from Profile Page.**  
* **Payment-related APIs are not present in the provided library API documentation.**