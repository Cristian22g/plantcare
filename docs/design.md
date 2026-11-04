# PlantCare: diseño (v1)

## 1. Identidad y tokens
- Sin cuentas. Cada jardín tiene `edit_token` y `view_token` (UUID aleatorios, únicos).
- `edit_token`: cabecera `Authorization: Bearer <token>`. Da acceso completo a SU jardín. El token identifica el jardín, no se envía id de jardín.
- `view_token`: solo en la URL del calendario. Solo lectura del `.ics`.
- Toda consulta de plantas filtra por `garden_id` del token (evita IDOR).
- Errores: 401 token ausente o inválido, 404 recurso inexistente en ese jardín, 400 datos inválidos.

## 2. Modelo de datos
garden: id, name, description, latitude, longitude, timezone (por defecto Europe/Madrid), edit_token (único), view_token (único), last_checked_on (DATE), created_at
plant: id, garden_id (FK, ON DELETE CASCADE), name, exposure (INDOOR | OUTDOOR), planted_on (opcional), last_watered_on, interval_days (> 0), next_watering_on, created_at
- `desc` es palabra reservada de SQL: la columna se llama `description`.
- `next_watering_on` es columna porque saltar o posponer el riego son decisiones que se recuerdan.
- La previsión del tiempo NO se guarda: se pide a Open-Meteo y se cachea por coordenadas (unas horas).

## 3. Regla de riego (función pura, sin BD ni red)
Entrada: exposure, next_watering_on, interval_days, today, previsión (mm por día).
Salida: nueva fecha de próximo riego y estado (SCHEDULED, DUE_TODAY, POSTPONED, SKIPPED, OVERDUE).

    si next < today            -> (next, OVERDUE)       sin mirar el clima
    si next > today            -> (next, SCHEDULED)     aún no hay nada que decidir
    si INDOOR                  -> (today, DUE_TODAY)
    OUTDOOR, p0 = mm(hoy), p1 = mm(mañana):
      p0 < 5                   -> (today, DUE_TODAY)
      p0 > 10                  -> (today + interval, SKIPPED)
      5 <= p0 <= 10:
        p1 < 5                 -> (today + 1, POSTPONED)
        si no                  -> (today + interval, SKIPPED)
- Saltar = darlo por regado: el ciclo reinicia desde hoy.
- Si falta la previsión de un día, se asume 0 mm.
- Los umbrales son inclusivos en 5 y 10 (5,0 pospone; 10,0 pospone; 10,1 salta).
- La lluvia solo se evalúa el día que toca regar. Si ya va retrasada, se marca en rojo y punto.

Casos (hoy = D, intervalo = 3):
| Caso | Planta | next | mm hoy / mañana | Resultado |
|---|---|---|---|---|
| 1 | interior | D | 20 / - | (D, DUE_TODAY) |
| 2 | exterior | D | 0,2 / - | (D, DUE_TODAY) |
| 3 | exterior | D | 7 / 2 | (D+1, POSTPONED) |
| 4 | exterior | D | 7 / 8 | (D+3, SKIPPED) |
| 5 | exterior | D | 12 / - | (D+3, SKIPPED) |
| 6 | exterior | D-2 | 12 / - | (D-2, OVERDUE) |
| 7 | exterior | D+3 | - | (D+3, SCHEDULED) |
| 8 | exterior | D | 4,9 / 5,0 / 10,0 / 10,1 | límites: riega, pospone, pospone, salta |

## 4. Cuándo se evalúa
- Sin tareas programadas (el backend gratuito se duerme). Al entrar al jardín por primera vez cada día
  (GET plantas o GET calendario), si `last_checked_on < hoy`, se aplica la regla a las plantas
  con next_watering_on = hoy y se guarda `last_checked_on = hoy`.
- Calendario: un evento por planta con su próximo riego.

## 5. Endpoints
| Método | Ruta | Auth | Qué hace |
|---|---|---|---|
| POST | /api/gardens | ninguna | Crea jardín. 201 con datos y ambos tokens |
| GET | /api/garden | edit | Datos del jardín y URL del calendario |
| PUT | /api/garden | edit | Edita nombre, descripción y coordenadas |
| DELETE | /api/garden | edit | Elimina jardín y plantas (204) |
| GET | /api/garden/plants | edit | Lista con próximo riego y estado |
| POST | /api/garden/plants | edit | Crea planta (201) |
| GET | /api/garden/plants/{id} | edit | Una planta |
| PUT | /api/garden/plants/{id} | edit | Edita planta |
| DELETE | /api/garden/plants/{id} | edit | Elimina planta (204) |
| POST | /api/garden/plants/{id}/watering | edit | Marca como regada hoy |
| GET | /calendar/{viewToken}.ics | token en URL | Feed iCalendar (text/calendar) |

