#!/bin/bash

cd example/test

bundle install
bundle exec rake test:prepare
bundle exec rake test

cd ../../..
