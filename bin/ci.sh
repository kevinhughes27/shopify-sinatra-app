#!/bin/bash

set -e

cd example

bundle install
bundle exec rake db:migrate
bundle exec rake test:prepare
bundle exec rake test
