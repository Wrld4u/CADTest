# Нагрузочный тест success-path (`POST /reserve`)

Дата: 2026-04-14

## Цель

Оценить, сколько стабильно держит текущая сборка в профиле, где бронирования в основном успешные
(уникальные `user_id` и `seat_id`, без конфликтного hotspot).

## Конфигурация

- Endpoint: `POST /reserve`
- Параллелизм: `500 connections`
- Тело запроса: `{"user_id":"user-[<id>]","seat_id":"seat-[<id>]"}`
- Инструмент: `autocannon`

## Прогон 1: фиксированный объём (50k)

Команда:

```bash
make load-test-50k-all-success
```

Параметры:

- `-a 50000`
- `-c 500`
- `-t 20`
- `-I` (динамические `id`)

Результаты:

- `50k requests in 101.14s, 20.9 MB read`
- `Req/Sec Avg: 495.05`
- `Req/Sec p50: 531`
- `Latency Avg: 958.11 ms`
- `Latency p99: 2724 ms`
- `Max latency: 12287 ms`
- Ошибки/таймауты: не зафиксированы в выводе `autocannon`

## Прогон 2: устойчивый RPS (30s)

Команда:

```bash
make load-test-30s-all-success
```

Параметры:

- `-d 30`
- `-c 500`
- `-t 20`
- `-I` (динамические `id`)

Результаты:

- `15k requests in 30.13s, 5.88 MB read`
- `Req/Sec Avg: 468.07`
- `Req/Sec p50: 500`
- `Latency Avg: 1052.58 ms`
- `Latency p99: 4802 ms`
- `Max latency: 8294 ms`
- Ошибки/таймауты: не зафиксированы в выводе `autocannon`

## Сравнение

- Throughput:
  - `50k fixed`: `495.05 req/s`
  - `30s sustained`: `468.07 req/s`
- Разница по среднему `Req/Sec`: около `-5.4%` в sustained-профиле.
- Latency в sustained-профиле хуже по хвостам (`p99 4802 ms` vs `2724 ms`).

## Вывод по стабильной нагрузке

Текущая сборка стабильно держит порядка `~450-500 req/s` на success-path при `500` concurrent
в условиях этого локального стенда (Docker, без production-оптимизаций).

Практический ориентир для «стабильного» значения: `~470 req/s`.
