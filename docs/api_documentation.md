# Control Center API Documentation

## Authentication (`/auth`)

### POST `/auth/register`
Register a new user.
- **Request Body**: `{"email": "...", "username": "...", "password": "..."}`
- **Response (201)**: `UserResponse` object (id, email, username, is_active, created_at, updated_at).

### POST `/auth/login`
Authenticate user and receive tokens.
- **Request Body**: `OAuth2PasswordRequestForm` (username, password).
- **Response (200)**: `{"access_token": "...", "refresh_token": "...", "token_type": "bearer"}`.

### POST `/auth/logout`
Invalidate current session.
- **Request Body**: `{"refresh_token": "..."}`
- **Response (200)**: `{"msg": "Successfully logged out"}`.

### POST `/auth/refresh`
Obtain a new access token using a refresh token.
- **Request Body**: `{"refresh_token": "..."}`
- **Response (200)**: `{"access_token": "...", "refresh_token": "...", "token_type": "bearer"}`.

## Messages (`/api/messages`)

### GET `/api/messages/`
Fetch latest messages (chronological).
- **Query Params**: `skip` (int), `limit` (int)
- **Response (200)**: `List[MessageResponse]`

### POST `/api/messages/`
Send a new message to the global chat.
- **Request Body**: `{"message_text": "..."}`
- **Response (201)**: `MessageResponse`

## Notifications (`/api/notifications`)

### GET `/api/notifications/`
Fetch user's notifications.
- **Query Params**: `skip` (int), `limit` (int)
- **Response (200)**: `List[NotificationResponse]`
