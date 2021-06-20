if Gem::Specification.find_all_by_name('dotenv').any?
  require 'dotenv'
  Dotenv.load
end

require './src/app'
SinatraApp.set :bind, '0.0.0.0'
SinatraApp.run!
