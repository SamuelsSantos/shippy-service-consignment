.PHONY: all
all: build
FORCE: ;

BIN_DIR = $(PWD)/bin

.PHONY: build

clean:
	rm -rf bin/*

gen:
	mkdir -p consignment/domain/pb
	protoc --proto_path=proto proto/consignment/*.proto --go_out=plugins=grpc:consignment/domain/pb

dependencies:
	go mod download

build: dependencies clean build-api linux-binaries

build-api: 
	go build -o ./bin/shippy-service-consignment api/grpc/main.go

linux-binaries:
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o ./bin/shippy-service-consignment-linux api/grpc/main.go

fmt: ## gofmt and goimports all go files
	find . -name '*.go' -not -wholename './vendor/*' | while read -r file; do gofmt -w -s "$$file"; goimports -w "$$file"; done

docker-build: build
	@docker image build -t shippy-service-consignment . 


server:
	go run consignment/api/server/main.go

server:
	go run consignment/api/cli/main.go 

test:
	mkdir -p ./coverage
	@for d in $$(go list ./... | grep -v /domain/pb | grep -v /cmd); do go test $${d} -v -coverprofile=./coverage/tests.out; done
	go tool cover -html=./coverage/tests.out -o ./coverage/coverage-report.html