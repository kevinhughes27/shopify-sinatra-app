#!/bin/bash

cd lib/generator/test

bundle exec rake test:prepare
bundle exec rake test

cd ../../..
