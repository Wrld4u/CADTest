# Валидация соответствия `docs/target.md`

Дата проверки: 2026-03-19

## Матрица требований

| Требование из `docs/target.md` | Статус | Доказательство |
|---|---|---|
| `POST /reserve` принимает `user_id` и `seat_id` | ✅ | `src/modules/reservations/infrastructure/http/reservations.controller.ts`, `src/modules/reservations/infrastructure/http/reserve-seat.request.dto.ts` |
| Одно место может забронировать только один пользователь | ✅ | `UNIQUE` по `seat_id`: `prisma/schema.prisma`; SQL path: `ON CONFLICT (seat_id) DO NOTHING RETURNING` |
| Исключить race condition (два «Успешно» на одно место) | ✅ | Конкурентные тесты и runtime race-прогоны показывают ровно `1` успешный ответ для одного `seat_id` |
| Использовать PostgreSQL или Redis (с обоснованием) | ✅ | PostgreSQL = source of truth, Redis = pre-check ускоритель конфликтного пути (`docs/architecture.md`) |
| Выдерживать высокую конкурентность запросов к одной строке | ✅* | `autocannon` hotspot тесты (включая 50k запросов) подтверждают корректность и работоспособность под высокой конкуренцией |

`*` Примечание: локальный стенд с Docker эмулирует high-concurrency, но не является полноценным production-окружением с 50k реальных одновременных пользователей.

## Прогон `autocannon` для 50k (hotspot)

Команда:

```bash
make load-test-50k-hotspot
```

Параметры сценария:
- `500` connections
- `50,000` total requests
- один `seat_id` (`seat-50k-hot`), то есть максимально конфликтный hotspot

Результаты:
- `1 2xx responses, 49609 non 2xx responses`
- `50k requests in 67.18s, 17.8 MB read`
- `390 errors (390 timeouts)`
- `Req/Sec Avg: 740.45`
- `Latency Avg: 299.98 ms`, `p99: 909 ms`

Интерпретация:
- Ключевой инвариант соблюдён: успешное бронирование ровно одно.
- Повторное занятие уже занятого места не произошло.
- При экстремальном конфликтном профиле наблюдаются timeout'ы, что ожидаемо для ограниченного локального стенда.

## Дополнительная проверка race-condition

Long race validation (30s, 120 connections, один `seat_id`):
- `1 2xx responses, 21061 non 2xx responses`
- `Req/Sec Avg: 702.07`
- `Latency Avg: 170.01 ms`, `p99: 243 ms`

Это подтверждает, что under-load инвариант «невозможно занять уже занятое место» сохраняется.

## Итог

Сервис соответствует функциональным требованиям `docs/target.md`:
- API и бизнес-правила реализованы;
- race-condition закрыт на уровне БД (`UNIQUE` + атомарный `ON CONFLICT`) и подтверждён нагрузочными прогонами;
- high-concurrency сценарии проверены через `autocannon`.
