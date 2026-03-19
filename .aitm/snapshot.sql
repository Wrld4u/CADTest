BEGIN TRANSACTION;
CREATE TABLE briefs (
	task_id INTEGER PRIMARY KEY,
	goal TEXT NOT NULL,
	non_goals TEXT NOT NULL,
	constraints TEXT NOT NULL,
	acceptance TEXT NOT NULL,
	refs TEXT NOT NULL,
	updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);
CREATE TABLE deps (
	blocker_task_id INTEGER NOT NULL,
	blocked_task_id INTEGER NOT NULL,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (blocker_task_id, blocked_task_id),
	FOREIGN KEY (blocker_task_id) REFERENCES tasks(id) ON DELETE CASCADE,
	FOREIGN KEY (blocked_task_id) REFERENCES tasks(id) ON DELETE CASCADE
);
CREATE TABLE epics (
	id INTEGER PRIMARY KEY,
	title TEXT NOT NULL,
	summary TEXT NOT NULL,
	priority TEXT NOT NULL CHECK (priority IN ('P0', 'P1', 'P2', 'P3')),
	status TEXT NOT NULL CHECK (status IN ('active', 'paused', 'done')),
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE events (
	id INTEGER PRIMARY KEY,
	epic_id INTEGER,
	task_id INTEGER,
	event_type TEXT NOT NULL,
	payload TEXT NOT NULL,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (epic_id) REFERENCES epics(id) ON DELETE CASCADE,
	FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
	CHECK (
		(epic_id IS NOT NULL AND task_id IS NULL)
		OR (epic_id IS NULL AND task_id IS NOT NULL)
	)
);
CREATE TABLE notes (
	id INTEGER PRIMARY KEY,
	epic_id INTEGER,
	task_id INTEGER,
	body TEXT NOT NULL,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (epic_id) REFERENCES epics(id) ON DELETE CASCADE,
	FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
	CHECK (
		(epic_id IS NOT NULL AND task_id IS NULL)
		OR (epic_id IS NULL AND task_id IS NOT NULL)
	)
);
CREATE TABLE schema_migrations (
			id INTEGER PRIMARY KEY CHECK (id = 1),
			version INTEGER NOT NULL
		);
CREATE TABLE tasks (
	id INTEGER PRIMARY KEY,
	epic_id INTEGER NOT NULL,
	title TEXT NOT NULL,
	status TEXT NOT NULL CHECK (status IN ('todo', 'doing', 'blocked', 'done', 'canceled')),
	priority TEXT NOT NULL CHECK (priority IN ('P0', 'P1', 'P2', 'P3')),
	order_in_epic INTEGER NOT NULL,
	estimate INTEGER,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (epic_id) REFERENCES epics(id) ON DELETE RESTRICT
);
CREATE INDEX idx_briefs_task_id ON briefs(task_id);
CREATE INDEX idx_deps_blocked ON deps(blocked_task_id);
CREATE INDEX idx_deps_blocker ON deps(blocker_task_id);
CREATE INDEX idx_epics_created_at ON epics(created_at);
CREATE INDEX idx_epics_priority ON epics(priority);
CREATE INDEX idx_epics_status ON epics(status);
CREATE INDEX idx_events_epic_id ON events(epic_id);
CREATE INDEX idx_events_task_id ON events(task_id);
CREATE INDEX idx_notes_epic_id ON notes(epic_id);
CREATE INDEX idx_notes_task_id ON notes(task_id);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
CREATE INDEX idx_tasks_epic_id ON tasks(epic_id);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_status ON tasks(status);
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (1,'Зафиксировать согласованные требования тестового задания и целевую архитектуру реализации.','Реализация бизнес-логики и инфраструктуры.','Только один endpoint POST /reserve; вечная бронь без отмены; при конфликте 409 и сообщение на русском.','В AGENTS.md и docs есть явная фиксация стека, архитектуры и правил конкурентности.','docs/target.md; пользовательские уточнения Master от 2026-03-19','2026-03-19 12:40:56 +0000 UTC');
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (2,'Подготовить базовый рабочий проект NestJS + TypeScript с командами разработки и тестирования.','Реализация полной бизнес-логики бронирования.','Структура должна соответствовать DDD+Hex и быть минимальной для тестового задания.','Есть package.json, tsconfig, базовые Nest entrypoint файлы, команды запуска и тестов.','docs/target.md; AGENTS.md','2026-03-19 12:41:00 +0000 UTC');
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (3,'Реализовать модуль reservations с гарантией отсутствия двойного бронирования одного места.','Поддержка отмены брони, TTL, дополнительных endpoint.','Использовать Postgres + Prisma; unique seat_id; response 409 с текстом ''К сожалению место уже забронировано''.','POST /reserve работает; при конкуренции только один успешный ответ, остальные 409.','docs/target.md; пользовательские уточнения Master от 2026-03-19','2026-03-19 12:41:04 +0000 UTC');
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (4,'Добавить docker-окружение для локального запуска приложения и Postgres без постоянного хранения данных.','Продакшн-конфигурация, persistent volumes, оркестрация.','Данные сохраняются только пока контейнеры активны; без volume bind/named volume.','docker compose up поднимает app+db; остановка и удаление контейнеров приводит к потере данных.','пользовательские уточнения Master от 2026-03-19','2026-03-19 12:41:08 +0000 UTC');
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (5,'Добавить минимальный набор тестов для критичного поведения бронирования.','Высокое покрытие всего проекта.','Нужны unit и e2e сценарии, включая конфликт при бронировании одного seat_id.','Тесты подтверждают успех первого бронирования и 409 при повторном/конкурентном запросе.','docs/target.md; архитектурные требования проекта','2026-03-19 12:41:16 +0000 UTC');
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (6,'Снизить latency/нагрузку на Postgres в hotspot за счёт Redis pre-check при сохранении строгой консистентности через unique constraint в БД.','Замена Postgres как источника истины, внедрение TTL/отмены брони.','Сохранить текущий контракт API; Redis опционален (при отсутствии REDIS_URL сервис работает только через Postgres).','Код содержит Redis pre-check + fallback на Postgres unique; docker-compose поднимает Redis; есть отчёт withRedis.md с результатом mixed теста.','docs/noRedis.md; Master approval на внедрение Redis от 2026-03-19','2026-03-19 13:35:39 +0000 UTC');
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (7,'Снизить накладные расходы на конфликтном пути бронирования, заменив exception-based обработку уникальности на SQL ON CONFLICT DO NOTHING RETURNING.','Изменение API-контракта, отмена Redis pre-check, изменение бизнес-правил бронирования.','Сохранить корректность race condition и 409 message; final source of truth остается Postgres unique constraint.','reserve path использует ON CONFLICT DO NOTHING RETURNING; тесты зелёные; документация обновлена.','Master request от 2026-03-19; docs/withRedis.md; src/modules/reservations/infrastructure/persistence/prisma-reservation.repository.ts','2026-03-19 14:34:23 +0000 UTC');
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (8,'Синхронизировать стратегию идентификаторов reservations на UUID на уровне Prisma schema, SQL migration и raw INSERT.','Изменение API контрактов и бизнес-логики бронирования.','После изменения тип id в БД должен быть UUID; код должен оставаться совместимым с ON CONFLICT path.','schema использует @default(uuid()) @db.Uuid; есть миграция alter type; insert использует uuid-cast; тесты зелёные.','Master request 2026-03-19; src/modules/reservations/infrastructure/persistence/prisma-reservation.repository.ts; prisma/schema.prisma','2026-03-19 14:41:02 +0000 UTC');
INSERT INTO briefs (task_id,goal,non_goals,constraints,acceptance,refs,updated_at) VALUES (9,'Сформировать итоговый документ соответствия docs/target.md с подтверждающими артефактами тестов, включая autocannon сценарий на 50k запросов.','Гарантировать абсолютную production готовность на реальном трафике без внешней инфраструктуры.','Использовать autocannon; явно отмечать границы локальной эмуляции 50k; сохранить честную интерпретацию результатов.','Есть Makefile команда для 50k сценария, выполнен прогон, создан docs/target-validation.md с матрицей требований и метриками.','docs/target.md; существующие отчеты docs/noRedis.md и docs/withRedis.md; Master request 2026-03-19','2026-03-19 15:22:21 +0000 UTC');
INSERT INTO epics (id,title,summary,priority,status,created_at) VALUES (1,'Микросервис бронирования билетов (NestJS + DDD + Hexagonal)','Реализовать тестовое API POST /reserve с защитой от race condition и docker-окружением','P1','done','2026-03-19 12:40:20 +0000 UTC');
INSERT INTO epics (id,title,summary,priority,status,created_at) VALUES (2,'Оптимизация бронирования: Redis pre-check','Добавить Redis ускоритель для conflict-path и сравнить mixed-нагрузку','P1','done','2026-03-19 13:35:19 +0000 UTC');
INSERT INTO epics (id,title,summary,priority,status,created_at) VALUES (3,'Оптимизация conflict-path: ON CONFLICT DO NOTHING','Убрать exception-based конфликтный путь и перейти на SQL upsert-style insert returning','P1','done','2026-03-19 14:34:08 +0000 UTC');
INSERT INTO epics (id,title,summary,priority,status,created_at) VALUES (4,'Финальная валидация требований target.md','Проверить соответствие функциональным требованиям и зафиксировать доказательства нагрузочным сценарием autocannon','P1','done','2026-03-19 15:22:07 +0000 UTC');
INSERT INTO schema_migrations (id,version) VALUES (1,1);
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (1,1,'Зафиксировать требования и архитектуру в документации','done','P1',1,NULL,'2026-03-19 12:40:23 +0000 UTC');
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (2,1,'Инициализировать NestJS TypeScript проект','done','P1',2,NULL,'2026-03-19 12:40:28 +0000 UTC');
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (3,1,'Реализовать модуль reservations с DDD+Hex и Prisma','done','P1',3,NULL,'2026-03-19 12:40:33 +0000 UTC');
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (4,1,'Добавить Docker Compose с временным Postgres','done','P1',4,NULL,'2026-03-19 12:40:37 +0000 UTC');
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (5,1,'Покрыть критичный сценарий unit и e2e тестами','done','P1',5,NULL,'2026-03-19 12:40:49 +0000 UTC');
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (6,2,'Интегрировать Redis pre-check в POST /reserve','done','P1',1,NULL,'2026-03-19 13:35:30 +0000 UTC');
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (7,3,'Перевести reserve на INSERT ... ON CONFLICT DO NOTHING RETURNING','done','P1',1,NULL,'2026-03-19 14:34:16 +0000 UTC');
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (8,3,'Перевести reservations.id на UUID (@db.Uuid) и синхронизировать SQL insert','done','P1',2,NULL,'2026-03-19 14:40:55 +0000 UTC');
INSERT INTO tasks (id,epic_id,title,status,priority,order_in_epic,estimate,created_at) VALUES (9,4,'Добавить и прогнать autocannon сценарий 50k и оформить target-validation отчет','done','P1',1,NULL,'2026-03-19 15:22:12 +0000 UTC');
COMMIT;
