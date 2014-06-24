require 'sinatra/activerecord/rake'
require 'resque/tasks'
require 'rake/testtask'
require './lib/app'

task :creds2heroku do
  Bundler.with_clean_env {
    File.readlines('.env').each do |var|
      pipe = IO.popen("heroku config:set #{var}")
      while (line = pipe.gets)
        print line
      end
    end
  }
end

task :deploy2heroku do
  pipe = IO.popen("git push heroku master --force")
  while (line = pipe.gets)
    print line
  end
end
