# Security Architecture

Security is implemented at multiple layers of the Control Center, spanning from the mobile client down to the database network.

## Application Security

1. **Authentication (JWT)**:
   - The backend uses JSON Web Tokens (JWT) for stateless authentication.
   - Tokens are signed with a secure `JWT_SECRET_KEY` injected via ECS environment variables.
   - The Flutter client securely stores these tokens using the `flutter_secure_storage` package (which uses EncryptedSharedPreferences on Android and Keychain on iOS).

2. **Cleartext Traffic Policy**:
   - Since the Application Load Balancer currently serves traffic over HTTP (port 80), the Android app's `AndroidManifest.xml` explicitly permits `usesCleartextTraffic="true"` to allow the connection.
   - *(Future enhancement: Attach an SSL/TLS certificate from AWS ACM to the Load Balancer to enforce HTTPS, and remove the cleartext exemption from the mobile app).*

## Network Security

1. **Private Subnets**:
   - The ECS Fargate tasks and the RDS PostgreSQL database are placed in Private Subnets. They do not have public IP addresses and cannot be reached from the public internet.
   
2. **Security Groups**:
   - **ALB SG**: Allows public ingress on 80/443.
   - **ECS SG**: Allows ingress on 8000 *only* from the ALB SG.
   - **RDS SG**: Allows ingress on 5432 *only* from the ECS SG (and developer IP if explicitly whitelisted).

3. **Frontend CDN Security**:
   - The S3 bucket is completely private. Files can only be downloaded via the CloudFront distribution using Origin Access Control (OAC).
