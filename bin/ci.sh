#!/bin/bash

cd example

bundle install
bundle exec rake db:migrate
bundle exec rake test:prepare
bundle exec rake test
EXIT_CODE=$?

cd ../../..

exit $EXIT_CODE
