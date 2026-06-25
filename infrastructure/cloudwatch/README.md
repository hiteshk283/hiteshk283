# CloudWatch Monitoring

Amazon CloudWatch is used to monitor the health and logs of the Control Center infrastructure.

## Container Logging

Since the backend is running on serverless ECS Fargate containers, there is no underlying EC2 instance to SSH into to view application logs. 

Instead, the ECS Task Definition is configured with the `awslogs` log driver:
1. Every standard output (`stdout`) and error (`stderr`) print statement from the FastAPI application is captured by the ECS agent.
2. The logs are streamed in real-time to a **CloudWatch Log Group** (e.g., `/ecs/control-center-backend`).
3. Inside the Log Group, each running container gets its own **Log Stream**.

This allows developers to view, search, and filter backend logs directly from the AWS Console.

## Metrics and Alarms

CloudWatch also tracks standard metrics for the infrastructure:
- **ECS**: CPU and Memory Utilization per service.
- **ALB**: Target Response Time, HTTP 4xx/5xx Error Rates, and Request Count.
- **RDS**: Database Connections, CPU Utilization, and Free Storage Space.

*(Future enhancement: Set up CloudWatch Alarms to send a Slack or email notification if the ALB 5xx error rate spikes, or if the ECS tasks begin failing health checks).*
