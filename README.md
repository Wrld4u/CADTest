# Сервис бронирования билетов

Тестовый микросервис бронирования билетов на `NestJS + TypeScript` в архитектуре `DDD + Hexagonal`.

## Функциональность

- `POST /reserve`
- Вход: `user_id`, `seat_id`
- Успех: `201`
- Конфликт занятого места: `409` и сообщение `К сожалению место уже забронировано`
- Бронь постоянная, без отмены
- Вставка в БД: `INSERT ... ON CONFLICT DO NOTHING RETURNING` (без exception-path для конфликтов)

## Стек

- `NestJS`
- `PostgreSQL`
- `Prisma`
- `Redis` (опциональный pre-check для ускорения conflict-path)
- `Jest` (`unit + e2e`)

## Локальный запуск без Docker

1. Установить зависимости:

```bash
npm install
```

2. Создать `.env` на основе `.env.example`.

   Если `REDIS_URL` не задан, сервис работает только через Postgres.
   Для тюнинга можно менять `DATABASE_URL` (`connection_limit`, `pool_timeout`) и
   `RESERVE_MAX_IN_FLIGHT` (backpressure лимит одновременных операций reserve).
   Текущие дефолты после A/B: `connection_limit=40`, `RESERVE_MAX_IN_FLIGHT=96`.

3. Поднять Postgres (любой локальный способ) и применить миграции:

```bash
npm run prisma:generate
npm run prisma:migrate:dev -- --name init
```

4. Запустить приложение:

```bash
npm run start:dev
```

## Запуск через Docker Compose

```bash
docker compose up --build
```

Важно: тома для Postgres не используются, данные живут только пока контейнеры активны.

Профиль Postgres в `docker-compose.yml` уже содержит базовый тюнинг для нагрузочного локального прогона
(`max_connections`, `shared_buffers`, `work_mem`, `synchronous_commit=off` и др.).

## Команды

- `make setup` — установка зависимостей и генерация Prisma client
- `make run` — запуск dev-сервера
- `make test` — unit + e2e тесты
- `make lint` — линтинг
- `make docker-up` — поднять сервисы в Docker (`app + db`) с пересборкой
- `make docker-down` — остановить и удалить контейнеры проекта
- `make docker-clean` — остановить и очистить контейнеры/сеть/orphans проекта
- `make docker-nuke` — удалить контейнеры, сеть и локальные образы проекта
- `make load-test` — нагрузочный hotspot-тест (все запросы в один `seat_id`)
- `make load-test-unique` — нагрузочный тест с уникальными `user_id/seat_id` через `autocannon`
- `make load-test-mixed` — смешанный профиль: 80% unique + 20% hotspot одновременно
- `make load-test-50k-hotspot` — hotspot-сценарий на 50k запросов (`autocannon`)

Результаты нагрузочных прогонов:
- без Redis: `docs/noRedis.md`
- с Redis pre-check: `docs/withRedis.md`

Итоговая валидация требований тестового задания:
- `docs/target-validation.md`
