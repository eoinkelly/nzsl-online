require "bundler/capistrano"
# require "whenever/capistrano"

set :application, "nzsl-online"
set :repository,  "./"
set :deploy_to, "/var/rails/#{application}"

set :scm, :none
default_run_options[:pty] = true
set :deploy_via, :copy
# set :copy_cache, '/tmp/deploy-cache/nzsl-online'
set :copy_exclude, [".git", "config/database.yml", "config/deploy.rb", "public/images/signs", ".bundle", "db/*.sqlite3", "log/*.log", "tmp/**/*", ".rvmrc", ".DS_Store", "public/videos/", "public/system/videos/", "config/initializers/access.rb"]
set :use_sudo, false

# If this breaks on a mac, you need to `brew install gnu-tar`
set :copy_local_tar, "tar"
set :copy_local_tar, "/usr/local/bin/gtar" if `uname` =~ /Darwin/

set :stages, %w(production draft)
set :default_stage, "draft"
require 'capistrano/ext/multistage'


#Make the remote and local dirs different, so we can test by deploying to localhost
set :remote_copy_dir, "/tmp/deploy-remote"
set :copy_dir, "/tmp/deploy-local"


namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "touch #{File.join(current_path,'tmp','restart.txt')}"
   end
end

after "deploy:update_code" do
  run "cd #{release_path} && ln -s #{shared_path}/cached/images/signs #{release_path}/public/images/"
  run "cd #{release_path} && ln -s #{shared_path}/bundle #{release_path}/vendor/bundle"

  #our database config is not in git
  run "ln -s #{shared_path}/configuration/database.yml #{release_path}/config/database.yml"

  #and our user/pass file is not in git
  run "ln -s #{shared_path}/configuration/access.rb #{release_path}/config/initializers/access.rb"
end

namespace :rabid do
  desc "Compress assets in a local file"
  task :compress_assets do
    run_locally("rm -rf public/assets/*")
    run_locally("bundle exec rake assets:precompile")
    run_locally("touch assets.tgz && rm assets.tgz")
    run_locally("#{copy_local_tar} zcvf assets.tgz public/assets/")
    run_locally("mv assets.tgz public/assets/")
  end

  desc "Upload assets"
  task :upload_assets do
    upload("public/assets/assets.tgz", release_path + '/assets.tgz')
    run "cd #{release_path}; tar zxvf assets.tgz; rm assets.tgz"
  end
   desc "Make local and remote dirs"
   task :make_dirs do
     #note we make the local and remote folders different, so we can deploy to localhost

     #local build folder
     run_locally("mkdir -p #{copy_dir}")

     #remote landing folder for tar ball
     run("mkdir -p #{remote_copy_dir}")

     #create log file folder on server, (or cold deploy will fail)
     run("mkdir -p #{shared_path}/log")
   end
end

before "deploy:update_code", "rabid:make_dirs"
before "deploy:update_code", "rabid:compress_assets"
after "deploy:symlink", "rabid:upload_assets"
