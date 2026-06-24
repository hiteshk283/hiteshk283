# Testing Report

## Backend Testing Strategy

Testing framework: `pytest` with `pytest-asyncio` for asynchronous test cases.
Database: `aiosqlite` is configured to run tests using an in-memory SQLite database, guaranteeing test isolation and speed without needing a live PostgreSQL instance for unit tests.

### Completed Tests
1. **Authentication Tests (`backend/tests/test_auth.py`)**
   - `test_register_user`: Verifies successful creation of a new user.
   - `test_login_user`: Validates that a registered user can login and receive an `access_token` and `refresh_token`.

### Pending Automated Tests
- WebSockets: Test client connections and ping/pong responses using `fastapi.testclient`.
- Messaging API: Test sending and receiving messages.
- Notification API: Test fetching user notifications.

## Flutter Frontend Testing Strategy

Testing framework: `flutter_test`.
Provider state tests will involve mocking the `ApiClient` and `WebSocketClient`.

### Manual Testing Protocol
1. Start the FastAPI backend and apply alembic migrations.
2. Launch Flutter App.
3. Register a new account (`/register` flow).
4. Login using the newly created credentials (`/login` flow).
5. Verify WebSocket connection activates upon successful login.
6. Navigate to Global Chat and send a test message.
7. Confirm message appears immediately (via local UI update + WS broadcast).
8. Verify Session persistence on app restart.
