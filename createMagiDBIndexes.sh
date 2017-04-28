#!/usr/bin/env bash

echo 'db.experiment_data.createIndex({created: -1})' | mongo localhost:27018/magi
echo 'db.experiment_data.createIndex({agent: -1})' | mongo localhost:27018/magi
