#!/usr/bin/env sh

stack test --flag wikigame:unit-tests --test-arguments "--format=progress --color --print-cpu-time"
