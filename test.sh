#!/bin/bash

cd lib/generator/test

bundle install
bundle exec rake test:prepare
bundle exec rake test

cd ../../..
