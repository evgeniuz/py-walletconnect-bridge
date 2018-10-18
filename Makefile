# make targets for WalletConnect/py-walletconnect-bridge

BRANCH=master

default:
	echo "Available tasks: build, clean, renew, run, run_skip_certbot, update"

build:
	docker build . -t py-walletconnect-bridge --build-arg branch=$(BRANCH)

clean:
	sudo rm -rfv ssl/certbot/*

renew:
	make clean && make run

run:
	docker run -it -v $(shell pwd)/:/source/ -p 443:443 -p 80:80 --name "py-walletconnect-bridge" py-walletconnect-bridge

run_skip_certbot:
	docker run -it -v $(shell pwd)/:/source/ -p 443:443 -p 80:80 --name "py-walletconnect-bridge" py-walletconnect-bridge --skip-certbot

update:
	# save current state of DB and copy it to local machine
	docker exec py-walletconnect-bridge redis-cli SAVE
	docker cp py-walletconnect-bridge:/py-walletconnect-bridge/dump.rdb dump.rdb
	
	# stop existing container instance
	docker container rm -f py-walletconnect-bridge

	# remove existing image and build new one
	docker rmi py-walletconnect-bridge
	docker build . -t py-walletconnect-bridge --build-arg branch=$(BRANCH)

	# start the container with `-d` to run in background
	docker run -it -v $(shell pwd)/:/source/ -p 443:443 -p 80:80 --name "py-walletconnect-bridge" -d py-walletconnect-bridge
	
	# stop the redis server, copy the previous state and restart the server
	docker exec py-walletconnect-bridge redis-cli SHUTDOWN
	docker cp dump.rdb py-walletconnect-bridge:/py-walletconnect-bridge/dump.rdb
	docker exec py-walletconnect-bridge chown redis: /py-walletconnect-bridge/dump.rdb
	docker exec -d py-walletconnect-bridge redis-server
	rm dump.rdb
