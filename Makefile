SHELL := /bin/bash
VERSION := 1.0.1

DOCKER_FILE := docker-compose.yml
COMPOSE := docker compose
SERVICE_COMMANDS := pull build kill rm ps stop events unpause restart port pause create
COMPOSE_COMMANDS := config version $(SERVICE_COMMANDS)
SERVICES := $(shell $(COMPOSE) config --services)
include .env

.PHONY: $(SERVICES) up down

help: 
	@echo '_________________'
	@echo '| Make targets: |'
	@echo '-----------------'
	@cat Makefile | grep -E '^[a-zA-Z\/_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo 


up: ## Bring system up, see docker-compose.yml
	$(COMPOSE) up -d

# down: ## stop all services
# 	$(COMPOSE) down

all: up ## Brings up all services, see docker-compose.yml

logs: ## Follow all container logs in terminal
	$(COMPOSE) logs -f

clean: ## Clean Docker System Temporary Files
	docker system prune -foreach

reboot: ## Reboot All Services
	make down up

$(SERVICES): # 
	make $@/up

$(COMPOSE_COMMANDS): ## 
	$(COMPOSE) "$@"

$(foreach service,$(SERVICES),$(service)/bash): ## Start a bash shell in the given container
	$(COMPOSE) exec $(word 1, $(subst /, ,$@)) bash

$(foreach service,$(SERVICES),$(service)/sh): ## Start a bash shell in the given container
	$(COMPOSE) exec $(word 1, $(subst /, ,$@)) sh

$(foreach service,$(SERVICES),$(service)/reboot): ## Stop, remove then up a container
	$(eval TASK := $(subst /, ,$@))
	make $(word 1, $(TASK))/stop $(word 1, $(TASK))/rm $(word 1, $(TASK))/up

$(foreach service,$(SERVICES),$(service)/up): ## Start a container in the background
	$(COMPOSE) up -d $(word 1, $(subst /, ,$@))

$(foreach service,$(SERVICES),$(service)/down):
	$(COMPOSE) down $(word 1, $(subst /, ,$@))

$(foreach service,$(SERVICES),$(service)/downv):
	$(COMPOSE) down -v $(word 1, $(subst /, ,$@))

$(foreach service,$(SERVICES),$(service)/logs): ## Attach to the container's log output
	$(COMPOSE) logs -f $(word 1, $(subst /, ,$@))

$(foreach service,$(SERVICES),$(service)/cplog): ## Copy log file from container to host (apply for backend service)
	$(eval SERVICE_NAME := $(word 1, $(subst /, ,$@)))
	docker cp ${SERVICE_NAME}:/app/logs/app.log logs/${SERVICE_NAME}.log

$(foreach service,$(SERVICES),$(foreach command,$(SERVICE_COMMANDS),$(service)/$(command))):
	$(eval TASK := $(subst /, ,$@))
	$(COMPOSE) $(word 2, $(TASK)) $(word 1, $(TASK))
