# eww/Makefile


CC = gcc
FLAGS = -Wall -Wextra -std=c17 -O2 -march=native -s
SRC = ./src
BUILD = ./.bin
OBJDIR = $(BUILD)/obj
DEPDIR = $(BUILD)/dep
SOURCES = $(wildcard $(SRC)/*.c)
TARGETS = $(patsubst $(SRC)/%.c,$(BUILD)/%,$(SOURCES))
LDFLAGS =

# For GPU (NVIDIA), link libdl for dlopen/dlsym
$(BUILD)/get_gpu_info: LDFLAGS += -ldl

all: $(TARGETS)

# Binary linking rule
$(BUILD)/%: $(OBJDIR)/%.o
	@mkdir -p $(BUILD)
	$(CC) $(FLAGS) -o $@ $< $(LDFLAGS)

# Object compilation rule (Note the pattern matches OBJDIR now)
$(OBJDIR)/%.o: $(SRC)/%.c
	@mkdir -p $(OBJDIR) $(DEPDIR)
	$(CC) $(FLAGS) -MMD -MP -c $< -o $@ -MF $(DEPDIR)/$*.d

-include $(wildcard $(DEPDIR)/*.d)

clean:
	rm -rf $(BUILD) .cache
