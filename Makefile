# Self-Documented Makefile
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

tao-docker-run: ## TAO用コンテナを建てる
	docker-compose -f docker-compose.yaml up -d

tao-docker-build: ## TAO用コンテナをビルド
	docker-compose -f docker-compose.yaml build

tao-convert:
	docker exec -it tao-tool-kit tao-converter -k tlt_encode -d 3,544,960 -e /app/src/peoplenet.engine /app/src/output/experiment_dir_final/resnet18_detector.etlt 

tao-docker-login: ## TAO用コンテナにログイン
	docker exec -it tao-tool-kit bash


