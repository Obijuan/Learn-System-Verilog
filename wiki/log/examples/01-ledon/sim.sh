#!/usr/bin/env bash

iverilog -g2012 -o ledon.out ledon.sv ledon_tb.sv
vvp ledon.out
