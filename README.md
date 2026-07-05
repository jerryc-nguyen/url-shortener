# URL Shortener APIs
A simple URL shorten service 

## Requirements

- Ruby 3.4.4
- sqlite - default rails database

## Setup

bundle install

rails db:create
rails db:migrate

rails server

## Run tests

bundle exec rspec


## API Documentation

### Encode URL

Create a shortened URL

#### Request

**POST** `/encode`

#### Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | string | Yes | Original URL (HTTP or HTTPS). |

#### Example

```http
POST /encode
Content-Type: application/json

{
  "url": "https://example.com"
}
```

#### Success Response

**200 OK**

```json
{
  "short_code": "A3RxY2"
}
```

#### Error Response

**422 Unprocessable Entity**

```json
{
  "error": {
    "code": "validation_error",
    "message": "URL is invalid"
  }
}
```

---

### Decode API

Get original URL by short code.

#### Request

**GET** `/decode?short_code={short_code}`

#### Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `short_code` | string | Yes | 6-character short code. |

#### Example

```http
GET /decode?short_code=A3RxY2
```

#### Success Response

**200 OK**

```json
{
  "url": "https://example.com"
}

```

#### Error Responses

**422 Unprocessable Entity**

```json
{
  "error": {
    "code": "validation_error",
    "message": "Original url is invalid",
    "details": {}
  }
}
```

**404 Not Found**

```json
{
  "error": {
    "code": "record_not_found",
    "message": "Short code not found",
    "details": {}
  }
}
```

## Security
### There are some potential issues and mitigated
1. User can send many api requests to encode, decode, potentially causing server overload
```
I use rack_attack gem to throttle user's requests by IP in our application level
For /encode, we limit 10 requests per minutes
For /decode, we limit 20 requests per minutes
```
2. User can send invalid url or try to send fake url with large payload to flood our database
```
I add validation only accept valid url: http, https and limit the length of the url to 2000 characters

But this way does not fully protect our service when a user sends a fake URL - a non-live URL or domain. 
So we should check whether the URL is live or not by background job, then count the invalid URLs per hour for user's IP. 
If a user sends X invalid URLs per hour, then we should block the user's requests by IP + remove invalid records.
```
3. User can send sql injection params to server
```
I use Rails' built-in methods to prevent SQL injection, for example:

`ShortenedUrl.find_by(short_code: params[:short_code])`
```

## Scalability, race condition and collision
1. Don't generate new shorten url for existed url
```
My idea is to generate a shortened URL only once for each submitted URL. This way, the number of rows in the table will not increase with repeated requests for the same URL.

So I designed the database table to include an `idempotency_key` column and added a unique index on this field to prevent duplicates.

The `idempotency_key` is the MD5 hash of the original URL, which generates a 32-character string used to check whether a shortened URL already exists.
```

2. Scale up later when we want to manage shorten urls by user
```
The current implementation only supports generating one shortened URL per original URL. However, if a future business requirement allow user to logged in then manage their generated urls we can add a user_id column to `shortened_urls` table. And update logic to generate idempotency_key like `Digest::MD5.hexdigest("#{user_id}#{original_url})`
```

3. How to generate shorten code
```
Here is logic: app/services/friendly_code_generator.rb

I want to generate a shortened code that is easy for users to read, so I don't generate characters that look alike: 0, O, I, l.

So I build the string contains all normal chars, uppercase chars, numbers exclude 0, O, I, l

Then I pick random X chars (default is 6) from the string to build the shorten code 
```

4. Handle collision
```
By default, I generate a 6-character code, which provides a space of about 3 billion combinations (58^6). However, because the code is generated randomly, there is still a possibility of duplication. So I add a unique index in the database for the `short_code` field and catch the database exception when creating the record, then retry.

I set the default retry count to 5 and add an error log when it reaches 5 retries but still can't generate a unique `short_code`. Then I will increase the generated short code length from 6 to 7 characters, and so on.
```

6. Race condition 
```
There is a case where the same URL is submitted by two or more requests at the same time.

I add a unique index for `idempotency_key`, so it prevents duplicate records from being created.
```
