# Drills SQL - Dia 1

Base: `banca_practica.db` (SQLite). Datos 100% sinteticos.

## Como correrlo

Opcion A, sin instalar nada: abre https://sqliteonline.com, boton **File > Open DB**, carga el archivo.

Opcion B, local:
```bash
sqlite3 banca_practica.db
.headers on
.mode column
```

Opcion C, en Python:
```python
import sqlite3, pandas as pd
con = sqlite3.connect("banca_practica.db")
pd.read_sql("SELECT * FROM clientes LIMIT 5", con)
```

## Esquema

```
clientes(cliente_id, ciudad, segmento, genero, edad, ingreso_mensual, fecha_vinculacion)
prestamos(prestamo_id, cliente_id, producto, monto_desembolsado, tasa_ea, plazo_meses, fecha_desembolso, estado)
pagos(pago_id, prestamo_id, fecha_vencimiento, fecha_pago, monto_esperado, monto_pagado, dias_mora)
scores(score_id, cliente_id, fecha_score, pd, score, banda, model_version)
transacciones(txn_id, cliente_id, fecha, monto, canal, comercio, es_fraude)
```

Filas: clientes 2.000 | prestamos 2.572 | pagos 55.305 | scores 6.866 | transacciones 59.965

**La base tiene trampas a proposito.** Hay NULLs, hay prestamos huerfanos y hay
clientes con varios scores. Si tu numero no cuadra, la causa casi siempre es una
de esas tres.

---

## Bloque 1: base (haz estos en 8 minutos)

**1.** Cuantos clientes hay por segmento, ordenado de mayor a menor.

**2.** Ingreso mensual promedio por ciudad, solo ciudades con mas de 100 clientes.
Redondea a 0 decimales.

**3.** Los 10 prestamos de mayor monto desembolsado, mostrando producto, monto y estado.

**4.** Corre estas dos y explica por que dan distinto:
```sql
SELECT COUNT(*) FROM clientes;
SELECT COUNT(ingreso_mensual) FROM clientes;
```

---

## Bloque 2: joins y la trampa del LEFT JOIN

**5.** Numero de prestamos por segmento de cliente. Ojo: hay prestamos cuyo
cliente no existe en la tabla `clientes`. Cuantos son y donde quedan en tu resultado.

**6.** Clientes que **no** tienen ningun prestamo. Resuelvelo de dos formas
distintas (LEFT JOIN con IS NULL, y NOT EXISTS) y verifica que dan el mismo numero.

**7.** Esta consulta esta mal. Encuentra el error, explicalo y arreglalo:
```sql
SELECT c.segmento, COUNT(p.prestamo_id) AS n_prestamos
FROM clientes c
LEFT JOIN prestamos p ON c.cliente_id = p.cliente_id
WHERE p.estado = 'Vigente'
GROUP BY c.segmento;
```

---

## Bloque 3: agregacion de negocio

**8.** Tasa de mora por producto: porcentaje de cuotas con `dias_mora > 30`
sobre el total de cuotas de ese producto. Ordena de peor a mejor.

**9.** Por producto: monto total desembolsado, numero de prestamos, tasa promedio
ponderada por monto (no el promedio simple de `tasa_ea`).

**10.** Distribucion de cuotas por cubeta de mora, usando CASE:
`Al dia` (0), `1-30`, `31-60`, `61-90`, `90+`. Muestra conteo y porcentaje del total.

---

## Bloque 4: window functions (aqui se decide la entrevista)

**11.** El score **mas reciente** de cada cliente. Devuelve cliente_id, fecha_score,
pd, banda. Este es el patron mas preguntado que existe.

**12.** Para cada cliente con 2 o mas scores: su pd actual, su pd anterior, y la
diferencia. Ordena por mayor deterioro. Pista: `LAG`.

**13.** Los 3 clientes de mayor monto desembolsado **dentro de cada ciudad**.
Pista: `ROW_NUMBER` con `PARTITION BY`.

**14.** Monto transado acumulado mes a mes durante 2026, por canal. Pista:
`SUM(...) OVER (PARTITION BY ... ORDER BY ...)`.

---

## Bloque 5: patrones de banca

**15.** Analisis de cosechas simplificado. Agrupa los prestamos por mes de
desembolso (`strftime('%Y-%m', fecha_desembolso)`) y calcula, para cada cosecha,
el porcentaje de prestamos que hoy estan en estado `Castigado`. Muestra solo
cosechas con al menos 30 prestamos.

**16.** Tasa de fraude por canal: numero de transacciones, numero de fraudes,
porcentaje de fraude, y monto promedio de las fraudulentas frente al de las
legitimas. Todo en una sola consulta.

---

## Preguntas conceptuales (respondelas en voz alta, no escritas)

- Por que `WHERE` no puede usar un alias definido en el `SELECT`.
- Diferencia entre `WHERE` y `HAVING`.
- Que devuelve `SELECT * FROM t WHERE col NOT IN (1, 2, NULL)` y por que.
- Diferencia entre `RANK`, `DENSE_RANK` y `ROW_NUMBER` cuando hay empates.
- Cuando un `CTE` es mejor que una subconsulta, y cuando da igual.
