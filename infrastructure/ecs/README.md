# Elastic Container Service (ECS)

The Control Center backend is fully containerized and deployed on **AWS ECS** using the **Fargate** launch type. This allows the application to run as a serverless container without managing the underlying EC2 instances.

## Architecture

1. **Amazon ECR (Elastic Container Registry)**:
   - Repository: `control-center-backend`
   - Stores the Docker images built by the GitHub Actions pipeline.

2. **ECS Cluster**:
   - Cluster Name: `control-center-cluster`
   - Hosts the backend services and manages scaling.

3. **Task Definition**:
   - Family: `control-center-backend-task`
   - Defines the container specifications, including CPU and Memory limits.
   - Specifies the Docker image URI from ECR.
   - Declares the container port mapping (Port `8000` for FastAPI).
   - Injects environment variables (like `DATABASE_URL` and `JWT_SECRET_KEY`) into the container.

4. **ECS Service**:
   - Service Name: `control-center-backend-task-service`
   - Maintains the desired number of running tasks (e.g., 1 or more).
   - Integrates with the Application Load Balancer to distribute incoming traffic across the healthy Fargate tasks.
   - Automatically restarts tasks if they fail health checks.
