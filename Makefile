export RUSTFLAGS := -Ctarget-cpu=native

EXE := reckless
TARGET_TUPLE := $(shell rustc --print host-tuple)

ifdef MSYSTEM
	NAME := $(EXE).exe
	ENV = UNIX
else ifeq ($(OS),Windows_NT)
	NAME := $(EXE).exe
	ENV = WINDOWS
else
	NAME := $(EXE)
	ENV := UNIX
endif

ifeq ($(ENV),UNIX)
	PGO_MOVE := mv "target/$(TARGET_TUPLE)/release/reckless" "$(NAME)"
else
	PGO_MOVE := move /Y "target\$(TARGET_TUPLE)\release\reckless.exe" "$(NAME)"
endif

rule:
	cargo rustc --release -- -C target-cpu=native --emit link=$(NAME)

sse41popcnt:
	cargo rustc --release -- -C target-feature=+sse4.1,+popcnt --emit link=$(NAME)

avx2:
	cargo rustc --release -- -C target-cpu=x86-64-v3 --emit link=$(NAME)

generic:
	cargo rustc --release -- -C target-cpu=x86-64 --emit link=$(NAME)

# Native local PGO build
pgo:
	cargo pgo instrument
	cargo pgo run -- bench
	cargo pgo optimize
	$(PGO_MOVE)

# Reproducible distributable PGO builds
pgo-sse41popcnt:
	cargo pgo instrument
	RUSTFLAGS="-C target-feature=+sse4.1,+popcnt" cargo pgo run -- bench
	RUSTFLAGS="-C target-feature=+sse4.1,+popcnt" cargo pgo optimize
	$(PGO_MOVE)

pgo-avx2:
	cargo pgo instrument
	RUSTFLAGS="-C target-cpu=x86-64-v3" cargo pgo run -- bench
	RUSTFLAGS="-C target-cpu=x86-64-v3" cargo pgo optimize
	$(PGO_MOVE)

pgo-generic:
	cargo pgo instrument
	RUSTFLAGS="-C target-cpu=x86-64" cargo pgo run -- bench
	RUSTFLAGS="-C target-cpu=x86-64" cargo pgo optimize
	$(PGO_MOVE)
