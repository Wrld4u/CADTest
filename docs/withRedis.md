# Нагрузочный тест с Redis (`load-test-mixed`)

Дата: 2026-03-19

## Профиль

- Команда: `make load-test-mixed`
- Длительность: `20s`
- Смешанная нагрузка:
  - `160` соединений на unique-поток (`user_id`/`seat_id` разные)
  - `40` соединений на hotspot-поток (один и тот же `seat_id`)

## Краткая сводка

- Unique-поток (`160 connections`):
  - `2k requests in 20.14s, 727 kB read`
  - `40 errors (40 timeouts)`
  - `Avg latency: 1441.15 ms`, `p99: 8626 ms`
  - `Req/Sec Avg: 89.05`
- Hotspot-поток (`40 connections`):
  - `1` успешная бронь (`2xx`), `3795` неуспешных (`non-2xx`) — ожидаемо для одного `seat_id`
  - `4k requests in 20.22s, 1.36 MB read`
  - `Avg latency: 210.41 ms`, `p99: 631 ms`
  - `Req/Sec Avg: 189.8`

## Быстрое сравнение с `docs/noRedis.md`

- Hotspot-path заметно ускорился:
  - latency в среднем снизилась примерно с `~1580 ms` до `~210 ms`
  - throughput вырос с `~24 req/s` до `~190 req/s`
- Unique-path почти не изменился:
  - `Req/Sec` около `86 → 89`
  - высокий хвост latency сохраняется

## Сырой вывод autocannon (очищен от ANSI)

```text
(sh -c "npx autocannon -m POST -d 20 -c 160 -I -H 'content-type: application/json' -b '{\"user_id\":\"user-[<id>]\",\"seat_id\":\"seat-[<id>]\"}' http://localhost:3000/reserve") & \
	(sh -c "npx autocannon -m POST -d 20 -c 40 -H 'content-type: application/json' -b '{\"user_id\":\"mixed-hot\",\"seat_id\":\"mixed-hot-seat\"}' http://localhost:3000/reserve") & \
	wait
Running 20s test @ http://localhost:3000/reserve
40 connections

Running 20s test @ http://localhost:3000/reserve
160 connections


┌─────────┬────────┬─────────┬─────────┬─────────┬────────────┬────────────┬─────────┐
│ Stat    │ 2.5%   │ 50%     │ 97.5%   │ 99%     │ Avg        │ Stdev      │ Max     │
├─────────┼────────┼─────────┼─────────┼─────────┼────────────┼────────────┼─────────┤
│ Latency │ 305 ms │ 1036 ms │ 7259 ms │ 8626 ms │ 1441.15 ms │ 1556.82 ms │ 9924 ms │
└─────────┴────────┴─────────┴─────────┴─────────┴────────────┴────────────┴─────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg     │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 5       │ 5       │ 91      │ 160     │ 89.05   │ 36.97   │ 5       │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 2.04 kB │ 2.04 kB │ 37.2 kB │ 65.3 kB │ 36.3 kB │ 15.1 kB │ 2.04 kB │
└───────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

2k requests in 20.14s, 727 kB read
40 errors (40 timeouts)

┌─────────┬───────┬────────┬────────┬────────┬───────────┬───────────┬─────────┐
│ Stat    │ 2.5%  │ 50%    │ 97.5%  │ 99%    │ Avg       │ Stdev     │ Max     │
├─────────┼───────┼────────┼────────┼────────┼───────────┼───────────┼─────────┤
│ Latency │ 73 ms │ 182 ms │ 475 ms │ 631 ms │ 210.41 ms │ 162.96 ms │ 3396 ms │
└─────────┴───────┴────────┴────────┴────────┴───────────┴───────────┴─────────┘
┌───────────┬─────────┬─────────┬─────────┬────────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%  │ Avg     │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼─────────┼────────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 47      │ 47      │ 191     │ 318    │ 189.8   │ 60.28   │ 47      │
├───────────┼─────────┼─────────┼─────────┼────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 16.8 kB │ 16.8 kB │ 68.4 kB │ 114 kB │ 67.9 kB │ 21.6 kB │ 16.8 kB │
└───────────┴─────────┴─────────┴─────────┴────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

1 2xx responses, 3795 non 2xx responses
4k requests in 20.22s, 1.36 MB read
```

## Повторный mixed-прогон после тюнинга Postgres (2026-03-19)

Параметры Postgres в `docker-compose.yml`: `max_connections=300`, `shared_buffers=256MB`,
`effective_cache_size=768MB`, `work_mem=4MB`, `synchronous_commit=off` и др.

### Краткая сводка (тюнинг + Redis)

- Hotspot-поток (`40 connections`):
  - `1` успешная бронь (`2xx`), `5345` неуспешных (`non-2xx`) — ожидаемо для одного `seat_id`
  - `5k requests in 20.07s, 1.91 MB read`
  - `Avg latency: 148.68 ms`, `p99: 462 ms`
  - `Req/Sec Avg: 267.3`
- Unique-поток (`160 connections`):
  - `2k requests in 20.21s, 882 kB read`
  - `85 errors (85 timeouts)`
  - `Avg latency: 1035.32 ms`, `p99: 9099 ms`
  - `Req/Sec Avg: 108.05`

### Быстрое сравнение с предыдущим прогоном `withRedis`

- Hotspot-path улучшился дополнительно:
  - `Req/Sec: 189.8 -> 267.3`
  - `Avg latency: 210.41 ms -> 148.68 ms`
- Unique-path частично улучшился по throughput:
  - `Req/Sec: 89.05 -> 108.05`
  - `Avg latency: 1441.15 ms -> 1035.32 ms`
- Но хвост latency и timeout'ы на unique-path всё ещё высокие (`p99 ~9s`, `85 timeouts`).

### Сырой вывод autocannon (очищен от ANSI)

```text
(sh -c "npx autocannon -m POST -d 20 -c 160 -I -H 'content-type: application/json' -b '{\"user_id\":\"user-[<id>]\",\"seat_id\":\"seat-[<id>]\"}' http://localhost:3000/reserve") & \
	(sh -c "npx autocannon -m POST -d 20 -c 40 -H 'content-type: application/json' -b '{\"user_id\":\"mixed-hot\",\"seat_id\":\"mixed-hot-seat\"}' http://localhost:3000/reserve") & \
	wait
Running 20s test @ http://localhost:3000/reserve
40 connections

Running 20s test @ http://localhost:3000/reserve
160 connections


┌─────────┬───────┬────────┬────────┬────────┬───────────┬──────────┬─────────┐
│ Stat    │ 2.5%  │ 50%    │ 97.5%  │ 99%    │ Avg       │ Stdev    │ Max     │
├─────────┼───────┼────────┼────────┼────────┼───────────┼──────────┼─────────┤
│ Latency │ 54 ms │ 118 ms │ 410 ms │ 462 ms │ 148.68 ms │ 96.73 ms │ 1476 ms │
└─────────┴───────┴────────┴────────┴────────┴───────────┴──────────┴─────────┘
┌───────────┬─────────┬─────────┬─────────┬────────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%  │ Avg     │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼─────────┼────────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 80      │ 80      │ 248     │ 419    │ 267.3   │ 92.63   │ 80      │
├───────────┼─────────┼─────────┼─────────┼────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 28.7 kB │ 28.7 kB │ 88.8 kB │ 150 kB │ 95.7 kB │ 33.2 kB │ 28.6 kB │
└───────────┴─────────┴─────────┴─────────┴────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

1 2xx responses, 5345 non 2xx responses
5k requests in 20.07s, 1.91 MB read

┌─────────┬────────┬────────┬─────────┬─────────┬────────────┬────────────┬─────────┐
│ Stat    │ 2.5%   │ 50%    │ 97.5%   │ 99%     │ Avg        │ Stdev      │ Max     │
├─────────┼────────┼────────┼─────────┼─────────┼────────────┼────────────┼─────────┤
│ Latency │ 305 ms │ 536 ms │ 7895 ms │ 9099 ms │ 1035.32 ms │ 1687.02 ms │ 9949 ms │
└─────────┴────────┴────────┴─────────┴─────────┴────────────┴────────────┴─────────┘
┌───────────┬─────┬──────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%  │ 2.5% │ 50%     │ 97.5%   │ Avg     │ Stdev   │ Min     │
├───────────┼─────┼──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 0   │ 0    │ 110     │ 221     │ 108.05  │ 62.24   │ 4       │
├───────────┼─────┼──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 0 B │ 0 B  │ 44.9 kB │ 90.2 kB │ 44.1 kB │ 25.4 kB │ 1.63 kB │
└───────────┴─────┴──────┴─────────┴─────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

2k requests in 20.21s, 882 kB read
85 errors (85 timeouts)
```

## Третий mixed-прогон: тюнинг Postgres + pool + backpressure (2026-03-19)

Дополнительно к предыдущему шагу:

- `DATABASE_URL`: `connection_limit=60`, `pool_timeout=20`
- `RESERVE_MAX_IN_FLIGHT=80` (ограничение одновременных DB-операций reserve в приложении)

### Краткая сводка

- Hotspot-поток (`40 connections`):
  - `1` успешная бронь (`2xx`), `6428` неуспешных (`non-2xx`) — ожидаемо для одного `seat_id`
  - `6k requests in 20.04s, 2.3 MB read`
  - `Avg latency: 123.79 ms`, `p99: 295 ms`
  - `Req/Sec Avg: 321.45`
- Unique-поток (`160 connections`):
  - `3k requests in 20.1s, 1.13 MB read`
  - `43 errors (43 timeouts)`
  - `Avg latency: 978.65 ms`, `p99: 8114 ms`
  - `Req/Sec Avg: 138.1`

### Сравнение с предыдущим шагом (тюнинг Postgres без backpressure)

- Hotspot-path:
  - `Req/Sec: 267.3 -> 321.45`
  - `Avg latency: 148.68 ms -> 123.79 ms`
  - `p99: 462 ms -> 295 ms`
- Unique-path:
  - `Req/Sec: 108.05 -> 138.1`
  - `Avg latency: 1035.32 ms -> 978.65 ms`
  - `Timeouts: 85 -> 43`
  - `p99: 9099 ms -> 8114 ms`

### Сырой вывод autocannon (очищен от ANSI)

```text
(sh -c "npx autocannon -m POST -d 20 -c 160 -I -H 'content-type: application/json' -b '{\"user_id\":\"user-[<id>]\",\"seat_id\":\"seat-[<id>]\"}' http://localhost:3000/reserve") & \
	(sh -c "npx autocannon -m POST -d 20 -c 40 -H 'content-type: application/json' -b '{\"user_id\":\"mixed-hot\",\"seat_id\":\"mixed-hot-seat\"}' http://localhost:3000/reserve") & \
	wait
Running 20s test @ http://localhost:3000/reserve
40 connections

Running 20s test @ http://localhost:3000/reserve
160 connections


┌─────────┬───────┬────────┬────────┬────────┬───────────┬──────────┬─────────┐
│ Stat    │ 2.5%  │ 50%    │ 97.5%  │ 99%    │ Avg       │ Stdev    │ Max     │
├─────────┼───────┼────────┼────────┼────────┼───────────┼──────────┼─────────┤
│ Latency │ 51 ms │ 115 ms │ 231 ms │ 295 ms │ 123.79 ms │ 55.27 ms │ 1130 ms │
└─────────┴───────┴────────┴────────┴────────┴───────────┴──────────┴─────────┘
┌───────────┬─────────┬─────────┬────────┬────────┬────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%    │ 97.5%  │ Avg    │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼────────┼────────┼────────┼─────────┼─────────┤
│ Req/Sec   │ 234     │ 234     │ 326    │ 405    │ 321.45 │ 58.11   │ 234     │
├───────────┼─────────┼─────────┼────────┼────────┼────────┼─────────┼─────────┤
│ Bytes/Sec │ 83.8 kB │ 83.8 kB │ 117 kB │ 145 kB │ 115 kB │ 20.8 kB │ 83.8 kB │
└───────────┴─────────┴─────────┴────────┴────────┴────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

1 2xx responses, 6428 non 2xx responses
6k requests in 20.04s, 2.3 MB read

┌─────────┬────────┬────────┬─────────┬─────────┬───────────┬────────────┬─────────┐
│ Stat    │ 2.5%   │ 50%    │ 97.5%   │ 99%     │ Avg       │ Stdev      │ Max     │
├─────────┼────────┼────────┼─────────┼─────────┼───────────┼────────────┼─────────┤
│ Latency │ 282 ms │ 773 ms │ 5178 ms │ 8114 ms │ 978.65 ms │ 1213.78 ms │ 9981 ms │
└─────────┴────────┴────────┴─────────┴─────────┴───────────┴────────────┴─────────┘
┌───────────┬─────┬──────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%  │ 2.5% │ 50%     │ 97.5%   │ Avg     │ Stdev   │ Min     │
├───────────┼─────┼──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 0   │ 0    │ 135     │ 210     │ 138.1   │ 57.67   │ 7       │
├───────────┼─────┼──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 0 B │ 0 B  │ 55.1 kB │ 85.7 kB │ 56.4 kB │ 23.5 kB │ 2.86 kB │
└───────────┴─────┴──────┴─────────┴─────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

3k requests in 20.1s, 1.13 MB read
43 errors (43 timeouts)
```

## A/B матрица параметров (чистый state на каждый прогон)

Профиль для всех комбинаций: `make load-test-mixed` (20s, `160 unique + 40 hotspot`).

| `RESERVE_MAX_IN_FLIGHT` | `connection_limit` | Hotspot Req/Sec Avg | Hotspot p99 | Unique Req/Sec Avg | Unique p99 | Unique errors/timeouts |
| ----------------------- | -----------------: | ------------------: | ----------: | -----------------: | ---------: | ---------------------: |
| 64                      |                 40 |                 430 |       276ms |                220 |     6042ms |                  44/44 |
| 64                      |                 80 |                 360 |       350ms |                171 |     7905ms |                  54/54 |
| 96                      |                 40 |                 433 |       326ms |                210 |     5865ms |                  15/15 |
| 96                      |                 80 |                 462 |       372ms |                240 |     6124ms |                  64/64 |

### Выбранные дефолты

В качестве сбалансированного значения по `p99` и timeout'ам выбран профиль:

- `RESERVE_MAX_IN_FLIGHT=96`
- `connection_limit=40`

Почему не `96/80`:

- даёт лучший `Unique Req/Sec`, но резко увеличивает timeout'ы (`64`) и хуже по стабильности хвоста.

## Контрольный mixed-прогон после `ON CONFLICT DO NOTHING RETURNING` (2026-03-19)

Профиль окружения: `connection_limit=40`, `RESERVE_MAX_IN_FLIGHT=96`.

### Краткая сводка

- Hotspot-поток (`40 connections`):
  - `0` успешных (`2xx`), `6753` non-2xx
  - `7k requests in 20.05s, 2.42 MB read`
  - `Avg latency: 117.62 ms`, `p99: 285 ms`
  - `Req/Sec Avg: 337.65`
- Unique-поток (`160 connections`):
  - `3k requests in 20.09s, 1.2 MB read`
  - `29 errors (29 timeouts)`
  - `Avg latency: 967.81 ms`, `p99: 8300 ms`
  - `Req/Sec Avg: 147.31`

### Примечание

`0` успешных в hotspot-ветке объясняется тем, что в это же время unique-ветка могла
успеть занять `mixed-hot-seat` раньше. Для проверки бизнес-логики hotspot это не ошибка,
а артефакт параллельного mixed-профиля.

### Сырой вывод autocannon (очищен от ANSI)

```text
(sh -c "npx autocannon -m POST -d 20 -c 160 -I -H 'content-type: application/json' -b '{\"user_id\":\"user-[<id>]\",\"seat_id\":\"seat-[<id>]\"}' http://localhost:3000/reserve") & \
	(sh -c "npx autocannon -m POST -d 20 -c 40 -H 'content-type: application/json' -b '{\"user_id\":\"mixed-hot\",\"seat_id\":\"mixed-hot-seat\"}' http://localhost:3000/reserve") & \
	wait
Running 20s test @ http://localhost:3000/reserve
40 connections

Running 20s test @ http://localhost:3000/reserve
160 connections


┌─────────┬───────┬────────┬────────┬────────┬───────────┬──────────┬─────────┐
│ Stat    │ 2.5%  │ 50%    │ 97.5%  │ 99%    │ Avg       │ Stdev    │ Max     │
├─────────┼───────┼────────┼────────┼────────┼───────────┼──────────┼─────────┤
│ Latency │ 68 ms │ 110 ms │ 215 ms │ 285 ms │ 117.62 ms │ 49.27 ms │ 1059 ms │
└─────────┴───────┴────────┴────────┴────────┴───────────┴──────────┴─────────┘
┌───────────┬─────────┬─────────┬────────┬────────┬────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%    │ 97.5%  │ Avg    │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼────────┼────────┼────────┼─────────┼─────────┤
│ Req/Sec   │ 180     │ 180     │ 352    │ 417    │ 337.65 │ 54.82   │ 180     │
├───────────┼─────────┼─────────┼────────┼────────┼────────┼─────────┼─────────┤
│ Bytes/Sec │ 64.4 kB │ 64.4 kB │ 126 kB │ 149 kB │ 121 kB │ 19.6 kB │ 64.4 kB │
└───────────┴─────────┴─────────┴────────┴────────┴────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

0 2xx responses, 6753 non 2xx responses
7k requests in 20.05s, 2.42 MB read

┌─────────┬────────┬────────┬─────────┬─────────┬───────────┬────────────┬─────────┐
│ Stat    │ 2.5%   │ 50%    │ 97.5%   │ 99%     │ Avg       │ Stdev      │ Max     │
├─────────┼────────┼────────┼─────────┼─────────┼───────────┼────────────┼─────────┤
│ Latency │ 278 ms │ 791 ms │ 5478 ms │ 8300 ms │ 967.81 ms │ 1218.59 ms │ 9986 ms │
└─────────┴────────┴────────┴─────────┴─────────┴───────────┴────────────┴─────────┘
┌───────────┬─────┬──────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%  │ 2.5% │ 50%     │ 97.5%   │ Avg     │ Stdev   │ Min     │
├───────────┼─────┼──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 0   │ 0    │ 160     │ 220     │ 147.31  │ 58.98   │ 9       │
├───────────┼─────┼──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 0 B │ 0 B  │ 65.3 kB │ 89.8 kB │ 60.1 kB │ 24.1 kB │ 3.67 kB │
└───────────┴─────┴──────┴─────────┴─────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

3k requests in 20.09s, 1.2 MB read
29 errors (29 timeouts)
```

## Long race validation (30s)

Профиль:

- `POST /reserve`
- `120` connections
- `30s`
- все запросы в один `seat_id` (`race-hot-seat-long`)

Результат:

- `1 2xx responses, 21061 non 2xx responses`
- `21k requests in 30.07s`
- `Req/Sec Avg: 702.07`
- `Latency Avg: 170.01 ms`
- `p99 latency: 243 ms`

Вывод:

- Инвариант корректности соблюдён: успешно забронировать место удалось ровно один раз.
- Повторно занять уже занятое место при длительной конкурентной нагрузке не удалось.
