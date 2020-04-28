local appId = std.extVar('appId');

local totalCpu = 512;
local totalMemory = 1024;

local nginxCpu = 32;
local nginxMemory = 64;

local appCpu = (totalCpu - nginxCpu) / 3;
local appMemory = (totalMemory - nginxMemory) / 3;

local appPort = '3000';

local fileProvider = std.native('provide.file');
local provide(name) = fileProvider(std.toString({ path: 'hako.env' }), name);

local github_id = std.asciiLower(provide('github_id'));

local main = import './main.libsonnet';
local tsukurepo_backend = import './tsukurepo_backend.libsonnet';

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
    elb_v2: {
      scheme: 'internet-facing',
      vpc_id: provide('vpc_id'),
      subnets: [provide('subnet_c_public'), provide('subnet_d_public')],  // public subnets
      security_groups: [provide('http_open_sg')],
      health_check_path: '/site/sha',
      listeners: [
        {
          port: 80,
          protocol: 'HTTP',
        },
      ],
      load_balancer_attributes: {
        'idle_timeout.timeout_seconds': '30',
      },
      target_group_attributes: {
        // Configure deregistration delay for faster deployment
        // https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#deregistration-delay
        'deregistration_delay.timeout_seconds': '20',
      },
      tags: {
        Owner: "CookpadInternship",
        ExpireDate: "2020-04-30",
      },
    },
  },
  app: {
    cpu: appCpu,
    memory: appMemory,
    image: std.format('%(account_id)s.dkr.ecr.ap-northeast-1.amazonaws.com/%(github_id)s-bff', { account_id: provide('account_id'), github_id: github_id, }),
    log_configuration: logConfiguration(appId),
    env: {
      RAILS_ENV: 'production',
      RAILS_LOG_TO_STDOUT: '1',
      SECRET_KEY_BASE: provide('secret_key_base_for_bff'),
      PIDFILE: '/tmp/server.pid',
      MAIN_GRPC_HOST: '127.0.0.1',
      MAIN_GRPC_PORT: '8081',
      TSUKUREPO_GRPC_HOST: '127.0.0.1',
      TSUKUREPO_GRPC_PORT: '8082',
    },
  },
  additional_containers: {
    front: {
      cpu: nginxCpu,
      memory: nginxMemory,
      image_tag: std.format('%s.dkr.ecr.ap-northeast-1.amazonaws.com/hako-nginx:latest', provide('account_id')),
      log_configuration: logConfiguration(appId),
    },
    main: main.container(appCpu, appMemory) {
      image_tag: std.format('%(account_id)s.dkr.ecr.ap-northeast-1.amazonaws.com/%(github_id)s-main:latest', { account_id: provide('account_id'), github_id: github_id }),
    },
    tsukurepo_backend: tsukurepo_backend.container(appCpu, appMemory) {
      image_tag: std.format('%(account_id)s.dkr.ecr.ap-northeast-1.amazonaws.com/%(github_id)s-tsukurepo_backend:latest', { account_id: provide('account_id'), github_id: github_id }),
    },
  },
  scripts: [
    {
      // Create CloudWatch log group automatically
      type: 'create_aws_cloud_watch_logs_log_group',
    },
    {
      type: 'nginx_front',
      // Proxy HTTP requests to app container's port
      backend_port: appPort,
      locations: {
        '/': {
          https_type: 'null',
        },
      },
    // nginx configuration is saved to s3://cookpad-internship/common/hako/front_config/
      s3: {
        region: 'ap-northeast-1',
        bucket: 'cookpad-internship',
        prefix: 'common/hako/front_config',
      },
    },
  ],
}
