#!/bin/bash
wla-z80 -o main.o main.asm
wlalink -r -v -S objs.txt smb.sms
