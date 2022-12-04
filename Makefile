app-build:
	docker-compose build

app-up:
	docker-compose up -d

app-down:
	docker-compose down

app-prepare-db:
	cp -n .env.example .env || true && \
	docker-compose run --rm bot rake db:create && \
	docker-compose run --rm bot rake db:migrate

app-db-migrate:
	docker-compose run --rm bot rake db:migrate

bash:
	docker-compose exec bot /bin/bash

console:
	docker-compose exec bot rake console

tests:
	docker-compose exec bot rake
