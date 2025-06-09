#!/bin/bash

echo -n "$1" | nc -w1 $2 $3
