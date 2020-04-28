local appId = std.extVar('appId');

local appCpu = 256;
local appMemory = 512;

local totalCpu = appCpu;
local totalMemory = appMemory;

local fileProvider = std.native('provide.file');
local provide(name) = fileProvider(std.toString({ path: 'hako.env' }), name);

local github_id = std.asciiLower(provide('github_id'));

local main = import './main.libsonnet';

// Send container logs to CloudWatch Logs
local logConfiguration(appId) = {
  log_driver: 'awslogs',
  options: {
    'awslogs-group': std.format('/ecs/hako/%s', appId),
    'awslogs-region': 'ap-northeast-1',
    'awslogs-stream-prefix': 'ecs',
  },
};

{
  scheduler: {
    type: 'ecs',
    region: 'ap-northeast-1',
    cluster: 'cookpad-spring-internship-2020-cluster',
    // IAM role used when staring containers
    // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
    execution_role_arn: provide('execution_role_arn'),
    // IAM role used inside a container (i.e., used by your application)
    // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
    task_role_arn: provide('task_role_arn'),
    // The number of tasks
    desired_count: 2,
    // launch_type and requires_compatibilities fields are required to launch tasks in Fargate
    launch_type: 'FARGATE',
    requires_compatibilities: ['FARGATE'],
    // Available Fargate resources: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size
    cpu: std.toString(totalCpu),
    memory: std.toString(totalMemory),
    // In Fargate, each task has each private IP and security group.
    network_mode: 'awsvpc',
    network_configuration: {
      awsvpc_configuration: {
        security_groups: [provide('ecs_service_sg')],
        subnets: [provide('subnet_c_private'), provide('subnet_d_private')],
      },
    },
  },
  app: main.container(appCpu, appMemory) {
    image: std.format('%(account_id)s.dkr.ecr.ap-northeast-1.amazonaws.com/%(github_id)s-main', { account_id: provide('account_id'), github_id: github_id }),
  },
  scripts: [
    {
      // Create CloudWatch log group automatically
      type: 'create_aws_cloud_watch_logs_log_group',
    },
  ],
}
