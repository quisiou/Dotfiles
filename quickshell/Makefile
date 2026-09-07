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

# For volume-related, link these libs
$(BUILD)/get_volume: LDFLAGS += -lasound -lm
$(BUILD)/set_volume: LDFLAGS += -lasound -lm

# For network-related binaries, link libnm and pass compile flags
$(BUILD)/get_netinfo: LDFLAGS += $(shell pkg-config --libs libnm)
$(OBJDIR)/get_netinfo.o: FLAGS += $(shell pkg-config --cflags libnm)

$(BUILD)/get_netlist: LDFLAGS += $(shell pkg-config --libs libnm)
$(OBJDIR)/get_netlist.o: FLAGS += $(shell pkg-config --cflags libnm)

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
