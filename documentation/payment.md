# Payment Page

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| **totalDueAmount** | **Number** | **Yes** |
| **upiId** | **String** | **Yes** |
| **payeeName** | **String** | **Yes** |

---

**User Actions**

**Enter Amount**

**Generate UPI QR**

**Make Payment**

---

**Backend Requirement**

**Backend API Required (not defined in current API documentation)**

**Expected Data**
```json
{

  "totalDueAmount": 2000,

  "upiId": "library@upi",

  "payeeName": "Central Library NITC"

}
```
---

**Frontend Mapping**

| UI Element | Backend Field |
| :---- | :---- |
| **Due Pending** | **totalDueAmount** |
| **UPI ID** | **upiId** |
| **Payee Name** | **payeeName** |

---

**Notes**

* **Due amount is currently hardcoded.**  
* **UPI details are currently hardcoded.**  
* **QR code is generated locally in frontend.**  
* **Accessible from Profile Page.**  
* **Payment verification flow is not implemented.**  
* **Payment-related APIs are not present in the provided library API documentation.**
