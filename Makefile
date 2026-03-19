setup:
	npm install
	npm run prisma:generate

test:
	npm run test
	npm run test:e2e

lint:
	npm run lint

run:
	npm run start:dev

docker-up:
	docker compose up --build

docker-down:
	docker compose down

docker-clean:
	docker compose down --remove-orphans

docker-nuke:
	docker compose down --remove-orphans --rmi local --volumes

load-test:
	npx autocannon -m POST -d 20 -c 200 -H 'content-type: application/json' -b '{"user_id":"load-user","seat_id":"load-seat"}' http://localhost:3000/reserve

load-test-unique:
	npx autocannon -m POST -d 20 -c 200 -I -H 'content-type: application/json' -b '{"user_id":"user-[<id>]","seat_id":"seat-[<id>]"}' http://localhost:3000/reserve

load-test-mixed:
	(sh -c "npx autocannon -m POST -d 20 -c 160 -I -H 'content-type: application/json' -b '{\"user_id\":\"user-[<id>]\",\"seat_id\":\"seat-[<id>]\"}' http://localhost:3000/reserve") & \
	(sh -c "npx autocannon -m POST -d 20 -c 40 -H 'content-type: application/json' -b '{\"user_id\":\"mixed-hot\",\"seat_id\":\"mixed-hot-seat\"}' http://localhost:3000/reserve") & \
	wait
