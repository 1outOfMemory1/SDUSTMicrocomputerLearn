###############################################################################
# Makefile for project 
###############################################################################

## General options
PROJECT = 
MCU = 8086
COMPILER = "MASM32"
TARGET = Debug
SHELL = C:\WINDOWS\system32\cmd.exe

## Tools general options
ASMFLAGS=/c /Zd /Zi
LDFLAGS=/CODEVIEW

## Processing Tools
ASM=ml.exe
LD=link16.exe
#  F:/project/github/unfinished/SDUSTMicrocomputerLearn/proteus/8086+8255并行io接口Example/8086/Debug/Debug.exe: TOOL=LD
#     F:/project/github/unfinished/SDUSTMicrocomputerLearn/proteus/8086+8255并行io接口Example/8086/Debug/main.obj: TOOL=ASM
#        F:/project/github/unfinished/SDUSTMicrocomputerLearn/proteus/8086+8255并行io接口Example/main.asm

# Build tree:
all:	Debug

Debug:	Debug.exe

Debug.exe:	main.obj 
	$(LD) $(LDFLAGS) main.obj,Debug.exe,nul.map,,,

main.obj:	../../main.asm 
	$(ASM) $(ASMFLAGS) ../../main.asm

# tidy - delete all temporary files which are not involved in the target generation
tidy:

# cleanup - delete all generated files
clean:	tidy
	rm -rf Debug.exe
	rm -rf main.obj
