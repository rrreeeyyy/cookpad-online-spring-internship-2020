namespace :ridgepole do
  desc "Apply ridgepole"
  task :apply do |t, args|
    sh 'ridgepole', '-c', 'config/database.yml', '--apply', '-f', 'db/Schemafile', '-E', Rails.env
  end

  desc "Dry run ridgepole"
  task :dry_run do |t, args|
    sh 'ridgepole', '-c', 'config/database.yml', '--apply', '--dry-run', '-f', 'db/Schemafile', '-E', Rails.env
  end
end
