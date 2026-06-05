# Book Page

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| biblionumber | Integer | Yes |
| title | String | Yes |
| author | String | Yes |
| isbn | String | No |
| coverImage | String | No |
| availabilityStatus | Boolean | Yes |
| branch | String | Yes |
| holdingsCount | Integer | Yes |

---

**User Actions**

**View Book Details**

**View Holdings**

**Place Hold**

**Confirm Hold Booking**

---

**Endpoint 1: Get Book Metadata**

GET /api/v1/public/biblios/{biblionumber}

Response
```json
{

  "biblionumber": 74466,

  "title": "Head First Python",

  "author": "Paul Barry",

  "isbn": "9789355422484",

  "publisher": "O'Reilly",

  "year": "2023"

}
```
---

**Endpoint 2: Get Book Availability / Holdings**

GET /api/v1/public/biblios/{biblionumber}/items

Response
```json
[

  {

    "item\_id": 12709,

    "callnumber": "510:620 NAT.1-2",

    "home\_library\_id": "LIB",

    "checked\_out\_date": null,

    "damaged\_status": 0,

    "lost\_status": 0,

    "not\_for\_loan\_status": 0,

    "withdrawn": 0,

    "external\_id": "1"

  }

]
```
---

**Frontend Mapping**

| UI Element | Backend Field |
| :---- | :---- |
| Book Cover | ISBN → Google Books Cover |
| Heading | title |
| Author | author |
| Status | availabilityStatus |
| Holdings (n) | holdingsCount |
| Library | home\_library\_id |
| Barcode | external\_id |
| Shelf Location | callnumber |

---

**Place Hold Screen**

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| biblionumber | Integer | Yes |
| itemId | Integer | Yes |
| pickupDate | Date | Yes |
| pickupTime | Time | Yes |

---

**User Actions**

**Select Pickup Date**

**Select Pickup Time**

**Confirm Booking**

---

**Endpoint**

POST /holds

Request
```json
{

  "biblionumber": 74466,

  "itemId": 12709,

  "pickupDate": "2026-06-10",

  "pickupTime": "14:30"

}
```
Response
```json
{

  "success": true,

  "holdId": 1001,

  "message": "Hold placed successfully"

}
```
---

**Hold Confirmation Page**

**Data Required**

| Field | Type | Required |
| :---- | :---- | :---- |
| title | String | Yes |
| author | String | Yes |
| holdId | Integer | Yes |
| status | String | Yes |

---

**Endpoint**

GET /holds/{holdId}

Response
```json
{

  "holdId": 1001,

  "status": "CONFIRMED",

  "title": "Head First Python",

  "author": "Paul Barry"

}
```
---

**Notes**

* Book details are currently hardcoded.  
* Holdings count is currently hardcoded as 7\.  
* Book availability status is currently hardcoded.  
* Place Hold availability is currently hardcoded.  
* Hold creation API is not present in the provided library API documentation and will require backend implementation.
