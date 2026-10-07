CONFIG_DIR = config

# DYA Studio 対応: 依存モジュールは config/west.yml の一覧と同じものを docker 側に用意しておく。
#   (west でワークスペースを作っている場合は ZMK_EXTRA_MODULES は不要。未検証)
ZMK_MODULES = $(shell grep -E '^\s+- name: zmk-' $(CONFIG_DIR)/west.yml | grep -v 'name: zmk$$' | sed -E 's/.*name: //; s#^#/workspaces/zmk-modules/#' | paste -sd ';' -)

SRCS_LEFT = $(shell find $(CONFIG_DIR) -type f ! -name "*_right*")
SRCS_RIGHT = $(shell find $(CONFIG_DIR) -type f ! -name "*_left*")

TARGET_LEFT = ../zmk/app/build/left/zephyr/zmk.uf2
TARGET_RIGHT = ../zmk/app/build/right/zephyr/zmk.uf2

.PHONY: build clean

build: $(TARGET_LEFT) $(TARGET_RIGHT)

#build: $(TARGET_RIGHT)

$(TARGET_LEFT): $(SRCS_LEFT)
	docker exec -w /workspaces/zmk/app -it $(container_name) west build -d build/left -b xiao_ble//zmk -- -DSHIELD=LiNEA40_left -DZMK_CONFIG="/workspaces/zmk-config/config"
	docker exec -w /workspaces/zmk/app -it $(container_name) cp build/left/zephyr/zmk.uf2 build/LiNEA40_left.uf2

$(TARGET_RIGHT): $(SRCS_RIGHT)
	docker exec -w /workspaces/zmk/app -it $(container_name) west build -d build/right -b xiao_ble//zmk -S studio-rpc-usb-uart -S zmk-usb-logging -- -DSHIELD=LiNEA40_right -DZMK_CONFIG="/workspaces/zmk-config/config" -DZMK_EXTRA_MODULES="$(ZMK_MODULES)"
	docker exec -w /workspaces/zmk/app -it $(container_name) cp build/right/zephyr/zmk.uf2 build/LiNEA40_right.uf2

clean:
	docker exec -it $(container_name) rm -rf /workspaces/zmk/app/build
