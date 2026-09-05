# Soluciones - Drills SQL Dia 1

**No abras esto antes de intentar.** El valor esta en el intento fallido, no en leer la respuesta.

---

**1.**
```sql
SELECT segmento, COUNT(*) AS n FROM clientes GROUP BY segmento ORDER BY n DESC;
```

**2.**
```sql
SELECT ciudad, ROUND(AVG(ingreso_mensual), 0) AS ingreso_prom, COUNT(*) AS n
FROM clientes GROUP BY ciudad HAVING COUNT(*) > 100 ORDER BY ingreso_prom DESC;
```
Ojo: `AVG` ignora los NULL, no los cuenta como cero. Y `COUNT(*)` cuenta filas,
no clientes con ingreso conocido. Si quieres solo los conocidos: `COUNT(ingreso_mensual)`.

**3.**
```sql
SELECT prestamo_id, producto, monto_desembolsado, estado
FROM prestamos ORDER BY monto_desembolsado DESC LIMIT 10;
```

**4.** `COUNT(*)` = 2000 (filas). `COUNT(ingreso_mensual)` = 1855, porque
**COUNT sobre una columna ignora NULLs**. Diferencia: 145 clientes sin ingreso.
Esta es la trampa mas comun de toda la entrevista de SQL.

---

**5.** Hay 12 prestamos huerfanos.
```sql
SELECT COALESCE(c.segmento, 'SIN CLIENTE') AS seg, COUNT(*) AS n
FROM prestamos p LEFT JOIN clientes c ON p.cliente_id = c.cliente_id
GROUP BY 1 ORDER BY n DESC;
```
Con `INNER JOIN` desaparecen silenciosamente. Con `LEFT JOIN` desde `prestamos`
aparecen agrupados bajo NULL. Nomina 1055, Independiente 661, Microempresario 598,
Pensionado 246, sin cliente 12.

**6.** Ambas dan **235**.
```sql
-- forma A
SELECT COUNT(*) FROM clientes c
LEFT JOIN prestamos p ON c.cliente_id = p.cliente_id
WHERE p.prestamo_id IS NULL;

-- forma B
SELECT COUNT(*) FROM clientes c
WHERE NOT EXISTS (SELECT 1 FROM prestamos p WHERE p.cliente_id = c.cliente_id);
```
No uses `NOT IN (SELECT cliente_id FROM prestamos)`: si esa subconsulta devuelve
un solo NULL, el resultado completo es vacio.

**7.** El error: **el `WHERE p.estado = 'Vigente'` convierte el LEFT JOIN en INNER
JOIN**. Para las filas sin match, `p.estado` es NULL, y `NULL = 'Vigente'` no es
verdadero, asi que la fila se descarta. Pierdes los clientes sin prestamos y los
que solo tienen prestamos cancelados. Arreglo: mueve la condicion al `ON`.
```sql
SELECT c.segmento, COUNT(p.prestamo_id) AS n_prestamos
FROM clientes c
LEFT JOIN prestamos p ON c.cliente_id = p.cliente_id AND p.estado = 'Vigente'
GROUP BY c.segmento;
```
Regla: **filtro sobre la tabla izquierda va en WHERE, filtro sobre la derecha va en ON.**

---

**8.**
```sql
SELECT pr.producto, COUNT(*) AS cuotas,
       SUM(CASE WHEN pg.dias_mora > 30 THEN 1 ELSE 0 END) AS mora_30,
       ROUND(100.0 * SUM(CASE WHEN pg.dias_mora > 30 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct
FROM pagos pg JOIN prestamos pr ON pg.prestamo_id = pr.prestamo_id
GROUP BY pr.producto ORDER BY pct DESC;
```
El `100.0` es obligatorio: division entera daria 0.
Resultado: Tarjeta 9.06%, Libre Inversion 9.04%, Microcredito 8.85%, Vehiculo 8.50%.

**9.**
```sql
SELECT producto, SUM(monto_desembolsado) AS monto_total, COUNT(*) AS n,
       ROUND(SUM(tasa_ea * monto_desembolsado) / SUM(monto_desembolsado), 2) AS tasa_ponderada,
       ROUND(AVG(tasa_ea), 2) AS tasa_simple
FROM prestamos GROUP BY producto;
```
Muestra las dos para que veas la diferencia. Un entrevistador de riesgo espera la ponderada.

**10.**
```sql
SELECT CASE WHEN dias_mora = 0 THEN '0 Al dia'
            WHEN dias_mora <= 30 THEN '1 1-30'
            WHEN dias_mora <= 60 THEN '2 31-60'
            WHEN dias_mora <= 90 THEN '3 61-90'
            ELSE '4 90+' END AS cubeta,
       COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM pagos), 2) AS pct
FROM pagos GROUP BY cubeta ORDER BY cubeta;
```
El orden del CASE importa: se evalua de arriba abajo y se detiene en el primer match.

---

**11.** El patron mas preguntado del mundo.
```sql
WITH ranked AS (
  SELECT cliente_id, fecha_score, pd, banda,
         ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY fecha_score DESC) AS rn
  FROM scores
)
SELECT cliente_id, fecha_score, pd, banda FROM ranked WHERE rn = 1;
```
Por que no se puede filtrar `WHERE rn = 1` directo en el mismo SELECT: las window
functions se evaluan **despues** del WHERE. De ahi la necesidad del CTE.

**12.**
```sql
WITH s AS (
  SELECT cliente_id, fecha_score, pd,
         LAG(pd) OVER (PARTITION BY cliente_id ORDER BY fecha_score) AS pd_anterior
  FROM scores
)
SELECT cliente_id, fecha_score, pd, pd_anterior, ROUND(pd - pd_anterior, 4) AS delta
FROM s WHERE pd_anterior IS NOT NULL ORDER BY delta DESC LIMIT 20;
```
El peor deterioro es el cliente 1468: pasa de 0.2547 a 0.4054, delta +0.1507.

**13.**
```sql
WITH tot AS (
  SELECT c.cliente_id, c.ciudad, SUM(p.monto_desembolsado) AS monto
  FROM clientes c JOIN prestamos p ON c.cliente_id = p.cliente_id
  GROUP BY c.cliente_id, c.ciudad
), r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY ciudad ORDER BY monto DESC) AS rn FROM tot
)
SELECT ciudad, cliente_id, ROUND(monto, 0) AS monto FROM r WHERE rn <= 3
ORDER BY ciudad, rn;
```

**14.**
```sql
WITH m AS (
  SELECT canal, strftime('%Y-%m', fecha) AS mes, SUM(monto) AS monto_mes
  FROM transacciones WHERE fecha >= '2026-01-01' GROUP BY canal, mes
)
SELECT canal, mes, ROUND(monto_mes, 0) AS monto_mes,
       ROUND(SUM(monto_mes) OVER (PARTITION BY canal ORDER BY mes), 0) AS acumulado
FROM m ORDER BY canal, mes;
```

---

**15.**
```sql
SELECT strftime('%Y-%m', fecha_desembolso) AS cosecha, COUNT(*) AS n,
       ROUND(100.0 * SUM(CASE WHEN estado = 'Castigado' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_castigo
FROM prestamos GROUP BY cosecha HAVING COUNT(*) >= 30 ORDER BY pct_castigo DESC;
```
Peores cosechas: 2025-08 (13.92%), 2023-03 (12.64%), 2023-07 (12.33%).
**Advertencia conceptual que un entrevistador espera que digas por tu cuenta:** las
cosechas recientes se ven mejor solo porque han tenido menos tiempo de madurar.
Comparar cosechas sin normalizar por meses en libros es un error de analisis, no
de SQL. Lo correcto es medir a un mismo punto de maduracion, por ejemplo mora a
12 meses de desembolsado.

**16.**
```sql
SELECT canal, COUNT(*) AS n, SUM(es_fraude) AS fraudes,
       ROUND(100.0 * SUM(es_fraude) / COUNT(*), 3) AS pct_fraude,
       ROUND(AVG(CASE WHEN es_fraude = 1 THEN monto END), 0) AS monto_prom_fraude,
       ROUND(AVG(CASE WHEN es_fraude = 0 THEN monto END), 0) AS monto_prom_legitimo
FROM transacciones GROUP BY canal ORDER BY pct_fraude DESC;
```
El truco es `CASE WHEN ... THEN monto END` sin `ELSE`: devuelve NULL y `AVG` lo
ignora, asi calculas dos promedios condicionales en una sola pasada.
Las fraudulentas promedian entre 8 y 10 veces el monto de las legitimas, que es
justamente la senal que explota un modelo de fraude.

---

## Respuestas conceptuales

- **Alias en WHERE:** el orden logico de ejecucion es FROM, WHERE, GROUP BY,
  HAVING, SELECT, ORDER BY. Cuando corre el WHERE, el SELECT todavia no existe.
  Por eso el alias si funciona en ORDER BY, que corre despues.
- **WHERE vs HAVING:** WHERE filtra filas antes de agrupar, HAVING filtra grupos
  despues de agregar. `HAVING COUNT(*) > 100` es imposible en WHERE.
- **NOT IN con NULL:** devuelve **cero filas**. `col NOT IN (1,2,NULL)` se expande
  a `col<>1 AND col<>2 AND col<>NULL`, y esa ultima comparacion es UNKNOWN, nunca
  TRUE. Usa `NOT EXISTS`.
- **RANK vs DENSE_RANK vs ROW_NUMBER:** con valores 100, 100, 90 dan
  ROW_NUMBER 1,2,3 | RANK 1,1,3 | DENSE_RANK 1,1,2.
- **CTE vs subconsulta:** el CTE gana en legibilidad, cuando lo reutilizas varias
  veces, y cuando necesitas recursion. En rendimiento suelen ser equivalentes.
