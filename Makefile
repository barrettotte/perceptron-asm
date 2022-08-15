
BIN_DIR := bin
OBJ_DIR := build
DUMP_DIR := dump
INC_DIR := inc
SRC_DIR := src

TARGET   := $(BIN_DIR)/perceptron
PPM      := model.ppm
INCLUDES := $(shell find $(INC_DIR)/* -type f \( -iname "*.inc" \) )
SOURCES  := $(shell find $(SRC_DIR)/* -type f \( -iname "*.asm" \) )
OBJECTS  := $(foreach OBJECT, $(patsubst %.asm, %.o, $(SOURCES)), $(OBJ_DIR)/$(OBJECT))

AS := nasm
AS_FLAGS = -f elf64 -g

LD := ld
LD_FLAGS :=

GDB := gdb
GDB_FLAGS := -ex 'set confirm off' \
	-ex 'file $(TARGET)' \
	-ex 'break _start' \
	-ex 'layout asm' \
	-ex 'layout regs' \
	-ex 'run $(TARGET)'

.PHONY:	.FORCE
.FORCE:

all:	build

build:	clean $(TARGET)

$(TARGET):	$(OBJECTS)
	@mkdir -p $(DUMP_DIR)
	@mkdir -p $(@D)
	$(LD) $(LD_FLAGS) $+ -o $@

$(OBJ_DIR)/%.o: %.asm
	@mkdir -p $(@D)
	$(AS) $(AS_FLAGS) $< -o $@

clean:
	@rm -rf $(BIN_DIR)/* $(OBJ_DIR)/* $(DUMP_DIR)/*
	@rm -f $(PPM)

debug:	build
	$(GDB) $(GDB_FLAGS)

run:	build
	@$(TARGET)

assets:
	@ffmpeg -y -i $(DUMP_DIR)/weights-%d.ppm -vf scale=320:-1 -filter:v "setpts=PTS/15,fps=30" docs/training.mp4
	@convert model.ppm docs/model.png
