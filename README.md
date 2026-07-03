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
  "success": true,
  "data": {
    "url": "https://example.com"
  }
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
```
3. User can send sql injection params to server
```
I use default rails's built in method that prevent sql injection like: ShortenedUrl.find_by(short_code: params[:short_code]) 
```
## Scalability, race condition and collision
1. Don't generate new shorten url for existed url
```
My idea is only generate shorten url one time for each user submit url. By this way, the table rows will not increase by the user request.
So I design db table add `idempotency_key` and add uniq index to this field to prevent duplicate
The `idempotency_key` is md5 hashing of the original url that make the 32 chars string used to check existed shortened or not 
```

2. Scale up later when we want to manage shorten urls by user
```
Current implement only support generate shorten url one time per original url. But later if business requirement allow user to logged in then manage their generated urls we can add user_id to `shortened_urls` table. And update logic to generate idempotency_key like `Digest::MD5.hexdigest("#{user_id}#{original_url})`
```

3. How to generate shorten code
```
Here is logic: app/services/friendly_code_generator.rb

I want to generate the shorten code that easy to read by user so I don't generate the characters that look alike: 0, O, I, l

So I build the string contains all normal chars, uppercase chars, numbers exclude 0, O, I, l

Then I pick random X chars - default is 6 in the string to build the shorten code 
```

4. Handle collision
```
By default I generate 6 chars that have space about 3 billion records (58^6) but because random generate it so still have possibility of duplication. So I add unique index in db for field short_code and catch the db raise when create record then retry.

I set default retry times is 5 and add error log when it reach 5 retries but can't generate the unique short_code then I will increase the short code generate from 6 to 7 chars and so on
```

6. Race condition 
There is case one url is submitted by 2 or more requests in same time
I add uniq index for `idempotency_key` so it will prevent create duplicate records
