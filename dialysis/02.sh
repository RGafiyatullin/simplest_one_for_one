#!/bin/bash

cp 01-otp.plt 02.plt

BUILD_PLT=" --plt 02.plt --add_to_plt "

dialyzer $BUILD_PLT --apps ../ebin

