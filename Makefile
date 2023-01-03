.PHONY: deploy

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

logs:
	docker-compose logs bot -f --tail=100

bash:
	docker-compose exec bot /bin/bash

console:
	docker-compose exec checker rake console

tests:
	docker-compose run --rm bot rake

sync-files:
	rsync -a -P apps@bot-prod:/opt/docker/kdmid-bot/checker-files/ ./debug/

deploy:
	cd deploy; make deploy; cd -
