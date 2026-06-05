# Home Page

**Data Required**

**User Statistics**

| Field | Type | Required |
| :---- | :---- | :---- |
| borrowedBooks | Integer | Yes |
| maxBooksAllowed | Integer | Yes |
| dueBookTitle | String | Yes |
| dueDate | Date | Yes |

**New Arrivals**

| Field | Type | Required |
| :---- | :---- | :---- |
| biblionumber | Integer | Yes |
| title | String | Yes |
| coverImage | String (URL) | Optional |

**Your Items**

| Field | Type | Required |
| :---- | :---- | :---- |
| biblionumber | Integer | Yes |
| title | String | Yes |
| coverImage | String (URL) | Optional |

---

**User Actions**

**Search Books**

**Open Notifications**

**Open Book Sharing Corner**

**View Book Details**

**Renew Borrowed Book**

---

**Endpoint 1: Search Books**

GET /cgi-bin/koha/opac-search.pl?q={searchTerm}\&format=rss2

Response
```json
{

  "totalResults": 57,

  "results": [

	{

      "biblionumber": 74466,

      "title": "Head First Python",

      "isbn": "9789355422484"

	}

  ]

}
```
---

**Frontend Mapping**

| UI Element | Backend Field |
| :---- | :---- |
| Search Result Title | title |
| Search Result Cover | ISBN → Google Books Cover |
| Search Result Availability | Availability API |
| Search Result Count | totalResults |

---

**Backend Requirement**

**User Statistics**

Backend API Required (not defined in current API documentation)

Expected Data
```json
{

  "borrowedBooks": 3,

  "maxBooksAllowed": 5,

  "dueBookTitle": "Book 1",

  "dueDate": "2026-06-10"

}
```
---

**New Arrivals**

Backend API Required (not defined in current API documentation)

Expected Data
```json
[

  {

    "biblionumber": 74466,

	"title": "Head First Python",

	"isbn": "9789355422484"

  }

]
```
---

**Your Items**

Backend API Required (not defined in current API documentation)

Expected Data
```json
[

  {

    "biblionumber": 74466,

	"title": "Head First Python",

	"isbn": "9789355422484"

  }

]
```
---

**Notes**

* User statistics are currently hardcoded.  
* Borrowed books count is currently hardcoded.  
* Progress indicator value is currently hardcoded.  
* Due book title is currently hardcoded.  
* New Arrivals list is currently hardcoded.  
* Your Items list is currently hardcoded.  
* Search suggestions are currently hardcoded.  
* Search result count is currently hardcoded.  
* Search result data is currently hardcoded.  
* Renew functionality is not implemented.  
* Notifications functionality handled in separate page.