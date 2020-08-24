#!/bin/bash

echo "Starting Time Test for PR93458"
for i in {1..100}
do
  echo "Test Run #$i"
  ./pr93458.sh
  sleep 20
done
