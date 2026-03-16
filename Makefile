CC       = gcc
GNATMAKE = gnatmake
SRC      = src
OBJ      = obj
BIN      = blasterman

.PHONY: all clean run

all: $(OBJ) $(BIN)

$(OBJ):
	mkdir -p $(OBJ)

$(OBJ)/terminal_c.o: $(SRC)/terminal_c.c | $(OBJ)
	$(CC) -c -o $@ $<

$(BIN): $(OBJ)/terminal_c.o | $(OBJ)
	$(GNATMAKE) -o $(BIN) -aI$(SRC) -D $(OBJ) $(SRC)/main.adb \
		-largs $(OBJ)/terminal_c.o

clean:
	rm -rf $(OBJ) $(BIN)

run: all
	./$(BIN)
