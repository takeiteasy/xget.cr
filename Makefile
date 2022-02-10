CC=crystal
SRC=src/xget.cr
OUTD=build/
OUT=$(OUTD)xget

.PHONY: default clean run

default: $(OUT)

$(OUTD):
	mkdir $(OUTD)

$(OUT): $(SRC) $(OUTD)
	$(CC) build --progress  $(SRC) -o $(OUT) $(ARGS)

run:
	$(CC) run $(SRC) -- $(ARGS)

clean:
	rm -rf $(OUTD)

veryclean: clean
	rm -rf lib/ shard.lock
