local appId = std.extVar('appId');

local fileProvider = std.native('provide.file');
local provide(name) = fileProvider(std.toString({ path: 'hako.env' }), name);

local github_id = std.asciiLower(provide('github_id'));

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
  container(appCpu, appMemory):: {
    cpu: appCpu,
    memory: appMemory,
    log_configuration: logConfiguration(appId),
    env: {
      RAILS_ENV: 'production',
      RAILS_LOG_TO_STDOUT: '1',
      DATABASE_URL: std.format('mysql2://%(user)s@%(github_id)s-aurora-cluster.cluster-%(aurora_id)s.ap-northeast-1.rds.amazonaws.com:3306/tsukurepo_backend?encoding=utf8mb4&collation=utf8mb4_bin', { user: provide('mysql_user'), github_id: github_id, aurora_id: provide('aurora_id') }),
      DATABASE_PASSWORD: provide('mysql_password'),
      SECRET_KEY_BASE: provide('secret_key_base_for_tsukurepo_backend'),
    },
  },
}
