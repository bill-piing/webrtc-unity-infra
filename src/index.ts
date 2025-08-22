import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as docker from "@pulumi/docker";

// Get configuration
const config = new pulumi.Config();
const accountId = config.require("accountId");
const instanceId = config.require("instanceId");
const clusterName = config.require("clusterName");
const ecrRepositoryName = config.require("ecrRepository");
const securityGroupId = config.require("securityGroupId");

// Reference existing resources (not managing them)
const cluster = aws.ecs.Cluster.get("unity-streaming-test", clusterName);
const instance = aws.ec2.Instance.get("unity-ec2-instance", instanceId);

// Reference existing security group
const existingSecurityGroup = aws.ec2.SecurityGroup.get("unity-security-group", securityGroupId);

// Reference existing ECR repository
const ecrRepository = aws.ecr.Repository.get("piing-streaming-unity", ecrRepositoryName);

// Build and push Docker image (skip if Docker not running)
// To skip Docker build, set: pulumi config set unity-webrtc-streaming:skipDockerBuild true
const skipDockerBuild = config.getBoolean("skipDockerBuild") || false;

const dockerImage = skipDockerBuild ? 
    { imageName: pulumi.interpolate`${accountId}.dkr.ecr.eu-west-2.amazonaws.com/${ecrRepositoryName}:latest` } :
    new docker.Image("unity-gpu-image", {
        imageName: pulumi.interpolate`${accountId}.dkr.ecr.eu-west-2.amazonaws.com/${ecrRepositoryName}:latest`,
        build: {
            context: "../",
            dockerfile: "../Dockerfile.gpu",
            platform: "linux/amd64",
            args: {
                BUILDKIT_INLINE_CACHE: "1",
            },
        },
        registry: {
            server: pulumi.interpolate`${accountId}.dkr.ecr.eu-west-2.amazonaws.com`,
            username: "AWS",
            password: pulumi.secret(
                aws.ecr.getAuthorizationToken({}).then(auth => auth.password)
            ),
        },
    });

// Reference existing CloudWatch Log Group
const logGroup = aws.cloudwatch.LogGroup.get("unity-streaming-logs", "/ecs/unity-streaming-test");

// Create IAM role for ECS task execution (if not exists)
const executionRole = new aws.iam.Role("ecs-task-execution-role", {
    name: "unity-streaming-execution-role",
    assumeRolePolicy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
            Action: "sts:AssumeRole",
            Principal: {
                Service: "ecs-tasks.amazonaws.com",
            },
            Effect: "Allow",
        }],
    }),
});

// Attach policies to execution role
new aws.iam.RolePolicyAttachment("ecs-task-execution-role-policy", {
    role: executionRole.name,
    policyArn: "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
});

// Additional policy for CloudWatch logs
new aws.iam.RolePolicy("ecs-task-execution-logs-policy", {
    role: executionRole.name,
    policy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
            Effect: "Allow",
            Action: [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
            ],
            Resource: "*",
        }],
    }),
});

// ECS Task Definition with GPU support
const taskDefinition = new aws.ecs.TaskDefinition("unity-streaming-task", {
    family: "unity-streaming-test",
    requiresCompatibilities: ["EC2"],
    networkMode: "bridge",
    cpu: "4096",  // Max CPU for g4dn.xlarge
    memory: "15360", // Use most of the 16GB RAM
    executionRoleArn: executionRole.arn,
    
    containerDefinitions: pulumi.jsonStringify([{
        name: "unity-streaming-test-container",
        image: dockerImage.imageName,
        cpu: 4096,    // Max CPU
        memory: 15360, // Max memory
        memoryReservation: 8192, // Soft limit
        essential: true,
        
        resourceRequirements: [{
            type: "GPU",
            value: "1",
        }],
        
        environment: [
            // NVIDIA_VISIBLE_DEVICES is automatically set by ECS when using GPU
            { name: "NVIDIA_DRIVER_CAPABILITIES", value: "graphics,utility,compute,display" },
            { name: "DISPLAY", value: ":99" },
        ],
        
        portMappings: [
            { containerPort: 8080, hostPort: 8080, protocol: "tcp" },
            { containerPort: 3478, hostPort: 3478, protocol: "udp" },
            { containerPort: 3479, hostPort: 3479, protocol: "udp" },
            { containerPort: 49152, hostPort: 49152, protocol: "udp" },
            { containerPort: 65535, hostPort: 65535, protocol: "udp" },
        ],
        
        logConfiguration: {
            logDriver: "awslogs",
            options: {
                "awslogs-group": logGroup.name,
                "awslogs-region": "eu-west-2",
                "awslogs-stream-prefix": "ecs",
            },
        },
        
        linuxParameters: {
            sharedMemorySize: 1024,
        },
    }]),
});

// ECS Service
const service = new aws.ecs.Service("unity-streaming-service", {
    name: "unity-webrtc-service",
    cluster: cluster.id,  // Now using the imported cluster
    taskDefinition: taskDefinition.arn,
    desiredCount: 1,
    launchType: "EC2",
    
    placementConstraints: [{
        type: "memberOf",
        expression: pulumi.interpolate`ec2InstanceId==${instance.id}`,  // Using imported instance
    }],
    
    deploymentMaximumPercent: 100,
    deploymentMinimumHealthyPercent: 0,
    
    // Force new deployment when task definition changes
    forceNewDeployment: true,
});


// Outputs
export const ecrRepositoryUri = pulumi.interpolate`${accountId}.dkr.ecr.eu-west-2.amazonaws.com/${ecrRepositoryName}`;
export const clusterArn = cluster.arn;
export const serviceArn = service.id;
export const taskDefinitionArn = taskDefinition.arn;
export const ec2InstanceId = instance.id;  // Renamed to avoid conflict
export const instancePublicIp = instance.publicIp;
export const instanceState = instance.instanceState;
export const webrtcEndpoint = pulumi.interpolate`https://${instance.publicIp}:443`;

// Export useful commands
export const commands = {
    viewLogs: `aws logs tail /ecs/unity-streaming-test --follow`,
    startInstance: `aws ec2 start-instances --instance-ids ${instanceId}`,
    stopInstance: `aws ec2 stop-instances --instance-ids ${instanceId}`,
    updateService: `pulumi up`,
    scaleDown: `aws ecs update-service --cluster ${clusterName} --service unity-webrtc-service --desired-count 0`,
    scaleUp: `aws ecs update-service --cluster ${clusterName} --service unity-webrtc-service --desired-count 1`,
};