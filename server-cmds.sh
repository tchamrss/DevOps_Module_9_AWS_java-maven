#!/usr/bin/env bash

export IMAGE=$1
docker compose -f docker-compose.yaml pull
docker compose -f docker-compose.yaml up -d
echo "success"