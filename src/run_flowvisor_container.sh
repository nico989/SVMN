#!/usr/bin/env bash

docker run -v "${PWD}/slicing_scripts:/root/slicing_scripts" -it --rm --network host flowvisor:latest /bin/bash
