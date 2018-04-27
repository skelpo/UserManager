# User Service Route Documentation

The User Service handles user authentication with JWT (JSON Web Tokens) and keeps custom data in user attributes.

## Routes:

Marked routes require a JWT access token passed in with the `Authorization` header with OAuth 2 format:

    Bearer {{token}}
    
---

### OPTIONS `/*`

Returns `options allowed` text response

**Paramaters:** `N/A`

**Response:**

    options allowed

---

### POST `/*/users/accessToken`

Gets a JWT (JSON Web Token) access token that can be used to authenticate with other services.

The payload contains the following keys:

|        key        |  Type  |
|-------------------|--------|
| `permissionLevel` | `int`  |
| `firstname`       | String |
| `lastname`        | String |
| `language`        | String |
| `exp`             | Int    |
| `iat`             | Int    |
| `email`           | String |
| `id`    			| String |

The payload may contain other values depending on the User Service configuration.

**Parameters:**

|       Name      |  Type    |                  Description                   | Required |
|-----------------|----------|------------------------------------------------|----------|
| `refreshToken`  | `string` | A refresh token that is accessed at user login |   True   |

**Response:**

	{
	    "status": "success",
	    "accessToken": "eyJjcml0IjpbImV4cCIsImF1ZCJdLCJhbGciOiJSUzI1NiIsImtpZCI6InJldmlld3NlbmRlciJ9.eyJlbWFpbCI6ImNhbGViLmtsZXZldGVyQGdtYWlsLmNvbSIsImxhc3RuYW1lIjoiIiwiZmlyc3RuYW1lIjoiIiwiaWQiOjEsImxhbmd1YWdlIjoiZW4iLCJwZXJtaXNzaW9uTGV2ZWwiOjAsImV4cCI6IjE1MTQzMzEzMzMiLCJpYXQiOiIxNTE0MzI3NzMzIn0.Q0vQ75qFyhokHUL1kjRYlxClfUVyWB8Eq4Dpm6xAOydWO1iQ7ykafx1_92q4te2SdSzGS3Wr-0buhbUSmkuxF9nrYzGcyN0uqthu5ML0HLKLIELV0lGEYn5xN5tvMscfIcF6sF80F2bXp6XRR02vELqVQOYQNvEc8ir0ZwHfVDe9BR8rc4sTK_Ox5cVaI5ZMkKV75VWnBUjU8s5ijlbVavkTlcom9EE1g7I1rDvNnNHS4toe2BOU9xoS93BdTXhvbsG-r40F-AZ1QmUBEgDm4FUyDivCafXIpQu-wAWVAXUNHpkrkiGRzJW-E6Nvlf1rlg7zgnRImBVF9qeY4KsKLQ"
	}

---

### POST, GET `/*/users/activate`

Confirms the user, allowing them to authenticate. This route is used when the service is configured for email confimation. Otherwise, the user is already confirmed.

**Parameters:**

|  Name   |  Type    |                      Description                        | Required |
|---------|----------|---------------------------------------------------------|----------|
| `code`  | `string` | The confimation code that was generated on registration |   True   |

**Response:**

	{
	    "status": "success",
	    "user": {
	        "confirmed": true,
	        "firstname": "",
	        "lastname": "",
	        "email": "fourth@exmaple.com",
	        "id": 1,
	        "language": "en",
	        "permissionLevel": 0
	    }
	}

---

### GET `/*/users/health`

Used by AWS to check if the E2C instance should be rebooted.

**Parameters:** `N/A`

**Response:**

    all good

---

### POST `/*/users/login`

Authenticates a user, sending back a refresh token and an access token.

**Parameters:**

|    Name    |  Type    |                        Description                | Required |
|------------|----------|---------------------------------------------------|----------|
| `email`    | `string` | The email of the user that is authenticating      |   True   |
| `password` | `string` | The raw password to check against the user's hash |   True   |

**Response:**

	{
	    "refreshToken": "eyJjcml0IjpbImV4cCIsImF1ZCJdLCJhbGciOiJSUzI1NiIsImtpZCI6InJldmlld3NlbmRlciJ9.eyJpZCI6MSwiaWF0IjoiMTUxNDMyODkzOSIsImV4cCI6IjE1MTY5MjA5MzkifQ.Oi2SO5szl2qUZ3uYpTrrqV1hj13iMIHHW24_wkoIe7BRm8t0aT6SeY5eDPIPzRv9aa_bmELFam9sK-mYhpu4q19OAG-FtJZO5VdZWskalbY7BwQv3t7nZOXuFioMmhHwdk6yBHkkl-lOdTSHhQEhO0P94kws2dfgwGtIR8mjs1sLyT3TefQJi5hVhfRzIH2cO7X7co8s0Fph_AtCUsgtAGV-m_NsvViDqqDLAdrr7WXWSrjQkr0P-h331oW2M7IM5FzN5FmBhvR_ehw8D9ERwAFjJL5MN7CTMYAUX-7qC4MOoI5Eh3Y1Ot46auEY1u-dt2notkWr3VaS5TCfaCrafg",
	    "status": "success",
	    "user": {
	        "confirmed": true,
	        "firstname": "",
	        "lastname": "",
	        "email": "fourth@exmaple.com",
	        "id": 1,
	        "language": "en",
	        "permissionLevel": 0
	    },
	    "accessToken": "eyJjcml0IjpbImV4cCIsImF1ZCJdLCJhbGciOiJSUzI1NiIsImtpZCI6InJldmlld3NlbmRlciJ9.eyJlbWFpbCI6ImZvdXJ0aEBleG1hcGxlLmNvbSIsImxhc3RuYW1lIjoiIiwiZmlyc3RuYW1lIjoiIiwiaWQiOjEsImxhbmd1YWdlIjoiZW4iLCJwZXJtaXNzaW9uTGV2ZWwiOjAsImV4cCI6IjE1MTQzMzI1MzkiLCJpYXQiOiIxNTE0MzI4OTM5In0.IVgj3QGINdk-7dbYXZtCXEBIe5ILEufGmuI6p3CnfOP_mmZ6UD70DeekKxqI-5RP5nt5gYBU6QMG5ovSDJMNqi1u4CR0RFmAW9sLck-pjyrkH9H8hsWWQNpTZC7XE8TpXBhqqmyC9wycb8E_2-LXdI5G2yHDwBRBFl8e7m-booi_o7M6sLkHL_X8SFNLoCFPrqVQ3oNVRS4zR2f7aHcKqoqxjtgQ3sjSjNylDIuUcVy3alz554xwdHUYnFHk9L9GmqoGRfIKGTyiZ1E5I5DK45v-RVOSQc6ts70rtQ2lH_RPcb1CE_22VnZVfFWC7HSy0_Dlw4w6MGWoQ5APFv2qwQ"
	}

---

### POST `/*/users/newPassword`

Resets the user's password hash. This route will then send an email to the address that was passed in with the new password.

**Parameters:**

|    Name    |  Type    |                        Description               | Required |
|------------|----------|--------------------------------------------------|----------|
| `email`    | `string` | The email of the user to update the password for |   True   |

**Response:**

	{
	    "status": "success",
	    "user": {
	        "confirmed": true,
	        "firstname": "",
	        "lastname": "",
	        "email": "fourth@exmaple.com",
	        "id": 1,
	        "language": "en",
	        "permissionLevel": 0
	    }
	}

---

### POST `/*/users/register`

Creates a new user. The user may or may not be auto-confirmed based on the service configuration.


**Parameters:**

|    Name    |  Type    |                     Description             | Required |
|------------|----------|---------------------------------------------|----------|
| `email`    | `string` | The email for the user that will be created |   True   |
| `password` | `string` | The raw password for the new user           |   True   |


**Response:**

	{
	    "status": "success",
	    "user": {
	        "confirmed": false,
	        "firstname": null,
	        "lastname": null,
	        "email": "user@example.com",
	        "id": 2,
	        "language": "en",
	        "permissionLevel": 0
	    }
	}

---

### POST `/v1/users/attributes`

Creates a new custom attribute with a key and and value for a user. If a attribute with the key pased in already exists, the value of the attribute will be updated.

**Requires Access Token**

**Parameters:**

|      Name       |  Type    |                    Description            | Required |
|-----------------|----------|-------------------------------------------|----------|
| `attributeKey`  | `string` | An identifier that is unique for the user |   True   |
| `attributeText` | `string` | The value for the attribute               |   True   |

**Response:**

	{
	    "status": "success",
	    "user": {
	        "confirmed": false,
	        "attributes": {
	            "key_one": "env=\"CLIENT_ID=91838_018381_0381980\""
	        },
	        "firstname": "",
	        "lastname": "",
	        "email": "user@example.com",
	        "id": 2,
	        "language": "en",
	        "permissionLevel": 0
	    }
	}

---

### GET `/v1/users/attributes`

Returns all the user's attributes in a JSON object.

**Requires Access Token**

**Parameters:** `N/A`

**Response:**

	{
	    "key_two": "env=\"CLIENT_SECRET=???\"",
	    "key_one": "env=\"CLIENT_ID=91838_018381_0381980\""
	}

---

### DELETE  `/v1/users/attributes`

Removes an attribute from a user.

**Requires Access Token**

**Parameters:**

|      Name       |  Type    |                    Description             | Required  |
|-----------------|----------|--------------------------------------------|-----------|
| `attributeKey`  | `string` | The database ID of the attribute to remove |   False   |
| `attributeText` | `string` | The key for the user's attribute to remove |   False   |
 Note: You do have to pass in one of the above parameters.
 
 **Response:**
 
	 {
	    "status": "success",
	    "user": {
	        "confirmed": false,
	        "attributes": {
	            "key_one": "env=\"CLIENT_ID=91838_018381_0381980\""
	        },
	        "firstname": "",
	        "lastname": "",
	        "email": "user@example.com",
	        "id": 2,
	        "language": "en",
	        "permissionLevel": 0
	    }
	}

---

### POST `/v1/users/profile`

Updates a user's `firstname` and `lastname` attributes.

**Requires Access Token**

**Request Data**

|    Name     |  Type    |                  Description            | Required  |
|-------------|----------|-----------------------------------------|-----------|
| `firstname` | `string` | The new value of the user's `firstname` |   False   |
| `lastname`  | `string` | The new value of the user's `lastname`  |   False   |

Note: Any parameters that are not passed in will set the value of the user's property to `nil`.

**Response:**

	{
	    "status": "success",
	    "user": {
	        "confirmed": true,
	        "attributes": {
	            "key_one": "env=\"CLIENT_ID=91838_018381_0381980\""
	        },
	        "firstname": "Barney",
	        "lastname": "Fife",
	        "email": "user@example.com",
	        "id": 2,
	        "language": "en",
	        "permissionLevel": 0
	    }
	}

---

### GET `/v1/users/profile`

Returns data about the user appropriate for a profile.

**Requires Access Token**

**Parameters:** `N/A`

**Response:**

	{
	    "status": "success",
	    "user": {
	        "confirmed": true,
	        "attributes": {
	            "key_one": "env=\"CLIENT_ID=91838_018381_0381980\""
	        },
	        "firstname": "Barney",
	        "lastname": "Fife",
	        "email": "user@example.com",
	        "id": 2,
	        "language": "en",
	        "permissionLevel": 0
	    }
	}

---

### GET `/v1/users/status`

Returns a JSON representation of the current user. This endpoint does not return the user's attributes in the JSON response.

**Requires Access Token**

**Parameters:** `N/A`

**Response:**

	{
	    "status": "success",
	    "user": {
	        "confirmed": false,
	        "firstname": "",
	        "lastname": "",
	        "email": "user@example.com",
	        "id": 2,
	        "language": "en",
	        "permissionLevel": 0
	    }
	}