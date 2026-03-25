#!/usr/bin/env bash

iverilog -g2012 -o ledon ledon.sv ledon_tb.sv
vvp ledon
