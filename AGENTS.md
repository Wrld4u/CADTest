# Repository Guidelines

## Communication Preferences

Язык: отвечай и задавай вопросы на русском.
Обращение: используйте «ты» или имя Master.
Перед изменением файлов: описывай план в нескольких пунктах и жди подтверждения.
Отчёт по работе: указывай выполненные шаги и оставшиеся задачи списком.
При необходимости задавай дополнительные вопросы.

## Project Structure & Module Organization

This repository is currently a clean scaffold (no source files yet). Keep the layout predictable as code is added:

- `src/` — application source code, organized by feature or domain.
- `tests/` — automated tests mirroring `src/` paths.
- `assets/` — static files (images, fixtures, sample CAD files).
- `docs/` — design notes, architecture decisions, and onboarding docs.

Example layout:
`src/import/`, `src/export/`, `tests/import/test_parser.*`.

## Build, Test, and Development Commands

No build tooling is configured yet. When adding tooling, expose a minimal, consistent command set (via `Makefile` or package scripts):

- `make setup` — install dependencies and prepare local environment.
- `make test` — run all tests.
- `make lint` — run static checks/formatting validation.
- `make run` — start local app or CLI entrypoint.

If you choose another toolchain (e.g., `npm`, `poetry`, `cargo`), keep equivalent commands documented in `README.md`.

## Coding Style & Naming Conventions

- Use 4 spaces for indentation unless language conventions require otherwise.
- Prefer descriptive, domain-based names (`cad_parser`, `step_exporter`) over abbreviations.
- Use `snake_case` for files/modules in Python-style projects, `kebab-case` for scripts, and `PascalCase` for class names.
- Add and enforce formatter/linter configs early (for example: `prettier`, `eslint`, `black`, `ruff`) and run them before opening PRs.

## Testing Guidelines

- Place tests under `tests/` with names that mirror implementation paths.
- Test files should follow framework defaults (for example, `test_*.py`, `*.spec.ts`).
- Include unit tests for new logic and regression tests for bug fixes.
- Aim for meaningful coverage on core workflows, not just line-count targets.

## Commit & Pull Request Guidelines

Git history is not available in this snapshot, so use a conventional style moving forward:

- Commit format: `type(scope): short summary` (e.g., `feat(parser): add STEP header validation`).
- Keep commits focused and atomic.
- PRs should include: purpose, change summary, test evidence, and any related issue/ticket.
- Include screenshots or sample input/output when behavior is user-visible.

## Security & Configuration Tips

- Never commit secrets, credentials, or proprietary CAD samples without approval.
- Store local settings in ignored files (for example, `.env.local`) and provide `.env.example` templates.

## Stack & Architecture (Current Project)

- Текущий стек: `NestJS + TypeScript`.
- Архитектурный стиль: `DDD + Hexagonal`.
- Основная БД: `PostgreSQL` через `Prisma`.
- `Redis` допускается как опциональный инфраструктурный компонент при необходимости оптимизаций.

### Functional Scope (Test Assignment)

- Реализуется только один endpoint: `POST /reserve`.
- Принимает: `user_id`, `seat_id`.
- Бронь вечная: нет отмены, нет TTL.
- При повторной попытке бронирования занятого места возвращать `409` и текст:
  `К сожалению место уже забронировано`.

### Concurrency & Consistency Rules

- Гарантия «одно место — один пользователь» обеспечивается на уровне БД.
- Обязательно использовать уникальное ограничение на `seat_id` (или эквивалент).
- Обработка конкурентных запросов должна опираться на атомарную операцию записи и корректный маппинг ошибки unique violation в HTTP `409`.

### Docker Runtime Constraints

- Использовать `docker-compose` для локального запуска приложения и Postgres.
- Персистентные тома не использовать (ни bind, ни named volumes).
- Данные хранятся только пока контейнеры активны.

## AITM task manager

Ссылка на AITM: https://gitlab.com/Wrld4u/aitm

Используй `aitm` для создания и отслеживания задач. MCP предпочтителен при наличии, CLI допустим.
Если MCP доступен, используй MCP-инструменты (mcp**aitm**\*). CLI (aitm через shell) использовать только при отсутствии MCP или при ошибке MCP.

## AITM — кратко о модели

- Epic — цель/результат, Task — шаг к Epic. Не смешивай сущности.
- Контекст задачи хранится в Brief: Goal, Non-goals, Constraints, Acceptance, References.
- Порядок работы задаёт система через `task next`, агент не придумывает порядок сам.

## Обязательные команды (агент)

- Если MCP доступен, выполняй команды через MCP; CLI используй только если MCP недоступен.
- `aitm task next` — получить следующий список задач.
- `aitm task show -id <id>` — детали задачи и статусы.
- `aitm brief show|edit -task <id>` — чтение/редактирование Brief.
- `aitm dep add|rm` — зависимости и блокировки.
- `aitm validate` — проверка инвариантов (запускай при сомнениях/ошибках).

## Рабочий цикл

Если MCP доступен, выполняй шаги через MCP; CLI используй только при отсутствии MCP.

1. `aitm task next` → выбери задачу без блокеров.
2. Проверь блокировки через `aitm task show` и `aitm dep`.
3. Если создаёшь задачу — сразу добавь Brief (если контекст неполон, уточни у Master).
4. Взял задачу → `task status` в `doing`, Epic статус в `active`.
5. Завершил задачу → `task status` в `done`; Epic в `done` только если задач не осталось.

## Приоритеты, порядок, зависимости

- При создании нескольких задач задай `priority` и `order_in_epic`.
- Добавляй зависимости, чтобы зафиксировать порядок выполнения и блокировки.
- Статусы задач: `todo|doing|blocked|done|canceled`.
- Статусы эпиков: `active|paused|done`.

## Ошибки и детерминизм

- Не гадай и не исправляй на глаз — фиксируй точный текст ошибки.
- При проблемах инвариантов запускай `aitm validate` и жди инструкции.
