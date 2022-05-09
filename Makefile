
BIN_DIR := bin
OBJ_DIR := build
SRC_DIR := src

TARGET   := $(BIN_DIR)/perceptron
INCLUDES := $(shell find $(SRC_DIR)/* -type f \( -iname "*.inc" \) )
SOURCES  := $(shell find $(SRC_DIR)/* -type f \( -iname "*.asm" \) )
OBJECTS  := $(foreach OBJECT, $(patsubst %.asm, %.o, $(SOURCES)), $(OBJ_DIR)/$(OBJECT))

AS := nasm
AS_FLAGS = -felf64 -g -i $(INCLUDES)

LD := ld
LD_FLAGS := 

GDB := gdb
GDB_FLAGS := -ex 'file $(TARGET)' \
	-ex 'target remote localhost:1234' \
	-ex 'layout regs'

.PHONY:	.FORCE
.FORCE:

all:		build

build:		clean $(TARGET)

$(TARGET):	$(OBJECTS)
	@mkdir -p $(@D)
	$(LD) $(LD_FLAGS) $+ -o $@

$(OBJ_DIR)/%.o: %.asm
	@mkdir -p $(@D)
	$(AS) $(AS_FLAGS) $< -o $@

clean:
	@rm -rf $(BIN_DIR)/* $(OBJ_DIR)/*

debug:	build
	$(GDB) $(GDB_FLAGS)

run:	build
	@$(TARGET)
