# Search Results Page

## Data Required

| Field        | Type         | Required |
| ------------ | ------------ | -------- |
| biblionumber | Integer      | Yes      |
| title        | String       | Yes      |
| author       | String       | Yes      |
| isbn         | String       | No       |
| availability | Boolean      | Yes      |
| coverImage   | String (URL) | Optional |

---

## User Actions

### Search Books

### Toggle Books/eBooks

### Toggle E-Journals

### View Book Details

---

## Endpoint

GET /cgi-bin/koha/opac-search.pl?q={searchTerm}&format=rss2

---

## Response

```json
{
  "totalResults": 57,
  "results": [
    {
      "biblionumber": 74466,
      "title": "Head First Python",
      "author": "Paul Barry",
      "isbn": "9789355422484"
    }
  ]
}
```

---

## Additional Data Required

Availability information should be fetched using:

GET /api/v1/public/biblios/{biblionumber}/items

---

## Frontend Mapping

| UI Element          | Backend Field             |
| ------------------- | ------------------------- |
| Book Cover          | ISBN → Google Books Cover |
| Heading             | title                     |
| Author              | author                    |
| Availability        | Availability API          |
| Search Result Count | totalResults              |

---

## Notes

* Search suggestions are currently hardcoded.
* Search result count is currently hardcoded.
* Search results are currently hardcoded.
* E-Journal search backend is not defined.
* Opening a result navigates to Book Page.
