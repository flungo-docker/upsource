include config.sample.mk
-include config.mk
#UPSOURCE_CONF_ARG += -J"-Djava.awt.headless=true"
UPSOURCE_CONF_ARG += --listen-port $(UPSOURCE_DOCKER_PORT)

ifneq ($(UPSOURCE_BASE_URL),)
UPSOURCE_CONF_ARG += --base-url $(UPSOURCE_BASE_URL)
endif

.PHONY: build configure data run

build: .build
data: .data
configure: .configure

.build: Dockerfile entry.sh
	docker build -t $(UPSOURCE_DOCKER_IMAGE) .
	touch .build

ifeq ($(UPSOURCE_DATA_CONTAINER),)

# Not using a data container; uses mapped volumes

UPSOURCE_DATA_VOLUMES := $(UPSOURCE_CONF) $(UPSOURCE_DATA) $(UPSOURCE_LOGS) $(UPSOURCE_BACKUPS)

ifneq ($(UPSOURCE_CONF),)
UPSOURCE_DOCKER_RUN_ARGS  += -v $(realpath $(UPSOURCE_CONF)):/opt/Upsource/conf
endif
ifneq ($(UPSOURCE_DATA),)
UPSOURCE_DOCKER_RUN_ARGS  += -v $(realpath $(UPSOURCE_DATA)):/opt/Upsource/data
endif
ifneq ($(UPSOURCE_LOGS),)
UPSOURCE_DOCKER_RUN_ARGS  += -v $(realpath $(UPSOURCE_LOGS)):/opt/Upsource/logs
endif
ifneq ($(UPSOURCE_BACKUPS),)
UPSOURCE_DOCKER_RUN_ARGS  += -v $(realpath $(UPSOURCE_BACKUPS)):/opt/Upsource/backups
endif

$(UPSOURCE_DATA_VOLUMES):
	mkdir -p $@

.data: | $(UPSOURCE_DATA_VOLUMES)
	touch .data

else # Create a data container

UPSOURCE_DOCKER_RUN_ARGS  += --volumes-from $(UPSOURCE_DATA_CONTAINER)

.data:
	docker create $(UPSOURCE_DOCKER_RUN_ARGS) $(UPSOURCE_DATA_DOCKER_IMAGE)
	touch .data

endif

.configure: UPSOURCE_DOCKER_RUN_ARGS+=--rm
.configure: build data
	docker run $(UPSOURCE_DOCKER_RUN_ARGS) $(UPSOURCE_DOCKER_IMAGE) configure $(UPSOURCE_CONF_ARG)
	touch .configure

run: UPSOURCE_DOCKER_RUN_ARGS+=--name=$(UPSOURCE_CONTAINER)
run: configure
	-@docker kill $(UPSOURCE_CONTAINER)
	-@docker rm $(UPSOURCE_CONTAINER)
	docker run $(UPSOURCE_DOCKER_RUN_ARGS) $(UPSOURCE_DOCKER_IMAGE) run

.PHONY: clean
clean:
	rm -rf .build .data .configure
	-@docker kill $(UPSOURCE_CONTAINER)
	-@docker rm $(UPSOURCE_CONTAINER)
