# Flutter Navigation

```mermaid
graph TD
    A[App Startup] --> B{Auth Valid?}
    B -- Yes --> C[Home Screen Shell]
    B -- No --> D[Login Screen]
    
    D --> |New User?| E[Register Screen]
    E --> |Success| D
    
    C --> F[/chat]
    C --> G[/notifications]
    C --> H[/settings]
    
    H --> |Logout| D
```
