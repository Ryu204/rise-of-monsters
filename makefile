BUILD_TYPE						?= dev
CXX_COMPILER					?= g++
BUILD_DIR						?= artifacts

ifeq ($(BUILD_TYPE),dev)
	CMAKE_PRESET := dev
else ifeq ($(BUILD_TYPE),prod)
	CMAKE_PRESET := release
else
	$(error Invalid BUILD_TYPE '$(BUILD_TYPE)'. Allowed values are: dev, prod)
endif

# Log functions
CYAN := \033[36m
GREEN := \033[32m
RESET := \033[0m
SEPARATOR						:= "============================================"
header = @printf "$(CYAN)$(SEPARATOR)\n$(1)\n$(SEPARATOR)\n$(RESET)"
success = @printf "$(GREEN)[SUCCESS] $(1)$(RESET)\n"

.PHONY: simulation game-runner website

all: game-runner website

simulation:
	$(call header,Building simulation shared lib)
	cd simulation && \
	cmake --preset=$(CMAKE_PRESET) \
		-DCMAKE_INSTALL_PREFIX=../$(BUILD_DIR)/simulation \
		-DCMAKE_CXX_COMPILER=$(CXX_COMPILER) && \
	cmake --build build/$(CMAKE_PRESET) -j && \
	cmake --install build/$(CMAKE_PRESET)
	$(call success,Simulation shared lib)

game-runner: simulation
	$(call header,Building game runner executable)
	cd game-runner && \
	cmake --preset=$(CMAKE_PRESET) \
		-DCMAKE_PREFIX_PATH='$(realpath $(BUILD_DIR)/simulation/lib/cmake/rise-of-monsters-simulation)' \
		-DCMAKE_INSTALL_PREFIX=../$(BUILD_DIR)/game-runner \
		-DCMAKE_CXX_COMPILER=$(CXX_COMPILER) && \
	cmake --build build/$(CMAKE_PRESET) -j && \
	cmake --install build/$(CMAKE_PRESET)
	$(call success,Game runner executable)

website:
	$(call header,Building website)
	cd website && \
	bun install && \
	bun run build && \
	cp dist -r ../$(BUILD_DIR)/website
	$(call success,Website)

ifeq ($(BUILD_TYPE),dev)
.PHONY: test

test: simulation game-runner website
	$(call header,Test simulation lib)
	ctest --test-dir=simulation/build/$(BUILD_TYPE)/test
	$(call header,Test game runner)
	ctest --test-dir=game-runner/build/$(BUILD_TYPE)/test
	$(call header,Test website)
	cd website && bun run test
endif