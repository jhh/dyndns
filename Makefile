NS := j3ff
VERSION := $(shell git rev-parse --short HEAD)
IMAGE_NAME := dyndns

.PHONY: build push run wheel

build: requirements.txt wheel
	docker build $(EXTRA_BUILD_ARGS) -t $(NS)/$(IMAGE_NAME):latest -t $(NS)/$(IMAGE_NAME):$(VERSION) .

push: build
	docker push $(NS)/$(IMAGE_NAME):latest
	docker push $(NS)/$(IMAGE_NAME):$(VERSION)

run:
	docker run -it --rm --name dyndns --env-file .env j3ff/dyndns

requirements.txt: poetry.lock
	poetry export -f requirements.txt --output requirements.txt

wheel:
	poetry build --format wheel