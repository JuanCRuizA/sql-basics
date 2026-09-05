-- -- DRILLS SQL -- --
-- BLOQUE 1, Base --
SELECT count(*) FROM pagos

PRAGMA table_info(pagos);

-- reto 1
SELECT COUNT(*), COUNT(DISTINCT p.pago_id)
FROM clientes c
JOIN prestamos pr ON c.cliente_id = pr.cliente_id
JOIN pagos p ON pr.prestamo_id = p.prestamo_id;

SELECT COUNT(*)
FROM clientes c
JOIN prestamos pr ON c.cliente_id = pr.cliente_id
JOIN pagos p ON pr.prestamo_id = p.prestamo_id;

SELECT c.segmento, SUM(p.monto_pagado)
FROM clientes c
JOIN prestamos pr ON c.cliente_id = pr.cliente_id
JOIN pagos p ON pr.prestamo_id = p.prestamo_id
GROUP BY c.segmento;

SELECT pago_id, prestamo_id, fecha_pago, monto_esperado, monto_pagado
FROM pagos
WHERE prestamo_id = (
    SELECT prestamo_id
    FROM pagos
    GROUP BY prestamo_id
    HAVING COUNT(*) > 1
    LIMIT 1
)
ORDER BY fecha_pago;

SELECT * 
FROM clientes c
GROUP BY segmento as cliseg
ORDER BY cliseg DESC;

SELECT c.segmento,
       '$' || REPLACE(printf('%,d', SUM(p.monto_pagado)), ',', '.') AS total_pagado
FROM clientes c
JOIN prestamos pr ON c.cliente_id = pr.cliente_id
JOIN pagos p ON pr.prestamo_id = p.prestamo_id
GROUP BY c.segmento;

SELECT c.segmento,
       '$' || REPLACE(printf('%,d', SUM(pr.monto_desembolsado)), ',', '.') AS desembolsado_correcto
FROM clientes c
JOIN prestamos pr ON c.cliente_id = pr.cliente_id
GROUP BY c.segmento;

SELECT c.segmento, SUM(pr.monto_desembolsado) AS desembolsado_correcto
FROM clientes c
JOIN prestamos pr ON c.cliente_id = pr.cliente_id
GROUP BY c.segmento;

SELECT c.segmento,
       '$' || REPLACE(printf('%,d', SUM(pr.monto_desembolsado)), ',', '.') AS desembolsado_inflado
FROM clientes c
JOIN prestamos pr ON c.cliente_id = pr.cliente_id
JOIN pagos p ON pr.prestamo_id = p.prestamo_id
GROUP BY c.segmento;

SELECT c.segmento, SUM(pr.monto_desembolsado) AS desembolsado_inflado
FROM clientes c
JOIN prestamos pr ON c.cliente_id = pr.cliente_id
JOIN pagos p ON pr.prestamo_id = p.prestamo_id
GROUP BY c.segmento;


SELECT segmento, COUNT (*) AS cliXseg 
FROM clientes

-- reto 2
SELECT ciudad, COUNT(*) AS clieXcity, 
       '$' || REPLACE(printf('%,d', ROUND(AVG(ingreso_mensual),0)), ',', '.') AS PromIngrMes
FROM clientes
GROUP BY ciudad
HAVING clieXcity > 100;

-- reto 3
SELECT producto, monto_desembolsado, estado 
FROM prestamos
ORDER BY monto_desembolsado DESC
LIMIT 10;

--reto 4
SELECT COUNT(*) FROM clientes;

SELECT COUNT(ingreso_mensual) FROM clientes;

SELECT
  COUNT(*) AS total,
  COUNT(ingreso_mensual) AS no_null,
  SUM(CASE WHEN ingreso_mensual IS NULL THEN 1 ELSE 0 END) AS son_null,
  SUM(CASE WHEN ingreso_mensual = 0 THEN 1 ELSE 0 END) AS son_cero
FROM clientes;

-- BLOQUE 2. Joins y la trampa del LEFT JOIN --
-- reto 5
SELECT 
  c.segmento,
  COUNT(pr.prestamo_id) AS cantidad_préstamos, 
  SUM(CASE WHEN c.cliente_id IS NULL THEN 1 ELSE 0 END) AS prest_sin_clie
FROM prestamos pr
LEFT JOIN clientes c ON pr.cliente_id = c.cliente_id
GROUP BY c.segmento;

SELECT COUNT(*) FROM prestamos;

SELECT c.segmento, COUNT(pr.prestamo_id) AS cantidad_préstamos
FROM prestamos pr
LEFT JOIN clientes c ON pr.cliente_id = c.cliente_id
GROUP BY c.segmento;

-- reto 6
SELECT 
  COUNT(CASE WHEN pr.cliente_id NOT EXISTS THEN 1 ELSE 0 END) AS clie_sin_préstamos
FROM clientes c
LEFT JOIN prestamos pr ON c.cliente_id = pr.cliente_id;

SELECT c.cliente_id
WHERE pr.prestamo_id IS NULL
FROM clientes c
LEFT JOIN prestamos pr ON c.cliente_id = pr.cliente_id;

SELECT c.cliente_id
FROM clientes c
LEFT JOIN prestamos pr ON c.cliente_id = pr.cliente_id
WHERE pr.prestamo_id IS NULL;

SELECT COUNT(c.cliente_id) AS clie_sin_préstamos
FROM clientes c
WHERE NOT EXISTS (SELECT 1 FROM prestamos pr WHERE pr.cliente_id = c.cliente_id);

SELECT c.cliente_id
FROM clientes c
WHERE NOT EXISTS (SELECT 1 FROM prestamos pr WHERE pr.cliente_id = c.cliente_id);

-- reto 7
SELECT estado, COUNT(estado) AS Tipos_Est
from prestamos
GROUP by estado
order by Tipos_Est DESC;


SELECT c.segmento, COUNT(p.prestamo_id) AS n_prestamos
FROM clientes c
LEFT JOIN prestamos p ON c.cliente_id = p.cliente_id
WHERE p.estado = 'Vigente'
GROUP BY c.segmento;

--solución 1
SELECT c.segmento, COUNT(p.prestamo_id) AS n_prestamos
FROM clientes c
FULL OUTER JOIN prestamos p ON c.cliente_id = p.cliente_id
WHERE p.estado = 'Vigente'
GROUP BY c.segmento
ORDER BY n_prestamos DESC;

--solución 2
SELECT c.segmento, COUNT(p.prestamo_id) AS n_prestamos
FROM prestamos p
LEFT JOIN clientes c ON c.cliente_id = p.cliente_id
WHERE p.estado = 'Vigente'
GROUP BY c.segmento
ORDER BY n_prestamos DESC;

-- BLOQUE 3. Agregación de negocio --
--Reto 8
SELECT producto, count(producto) AS productos
FROM prestamos
GROUP by producto;

SELECT COUNT(pago_id) AS pagos
FROM pagos;

SELECT dias_mora, count(pago_id) AS pagos
FROM pagos
GROUP by dias_mora
ORDER by dias_mora DESC;

SELECT pr.prestamo_id, COUNT(pg.pago_id) AS n_pagos
FROM prestamos pr
LEFT JOIN pagos pg ON pr.prestamo_id = pg.prestamo_id
GROUP BY pr.prestamo_id
ORDER BY n_pagos DESC;

SELECT pr.prestamo_id, COUNT(pg.pago_id) AS n_pagos
FROM prestamos pr
LEFT JOIN pagos pg ON pr.prestamo_id = pg.prestamo_id
where dias_mora > 30;

SELECT pr.producto, COUNT(pg.pago_id) AS n_pagos
FROM prestamos pr
LEFT JOIN pagos pg ON pr.prestamo_id = pg.prestamo_id
--where dias_mora > 30
GROUP BY pr.producto
ORDER BY n_pagos DESC;

SELECT pr.producto, 
  COUNT(CASE WHEN pg.dias_mora > 30 / pg.dias_mora THEN 1 ELSE 0 END) AS mora_sup30
FROM prestamos pr
LEFT JOIN pagos pg ON pr.prestamo_id = pg.prestamo_id
where dias_mora > 30
GROUP BY pr.producto
ORDER BY mora_sup30 DESC;

SELECT pr.producto, 
  SUM (CASE WHEN (pg.dias_mora > 30) / pg.dias_mora THEN 1 END) AS mora_sup30
FROM prestamos pr
LEFT JOIN pagos pg ON pr.prestamo_id = pg.prestamo_id
GROUP BY pr.producto
ORDER BY mora_sup30 DESC;

SELECT pr.producto, 
  SUM (CASE WHEN pg.dias_mora > 30 THEN 1 END) AS "mora sup30",
  COUNT(PG.pago_id) AS "total cuotas",
  ROUND(100.0 * SUM(CASE WHEN pg.dias_mora > 30 THEN 1 END)/COUNT(PG.pago_id),2) AS "% mora > 30d"
FROM prestamos pr
LEFT JOIN pagos pg ON pr.prestamo_id = pg.prestamo_id
GROUP BY pr.producto
ORDER BY "mora sup30" DESC;

-- reto 9
-- vamos por partes
-- 1. Monto pagado total por producto
SELECT r.producto, SUM(g.monto_pagado) AS Total_pagado
FROM prestamos r
JOIN pagos g ON r.prestamo_id = g.prestamo_id
GROUP BY r.producto
ORDER BY Total_pagado DESC;

-- 2. Número de préstamos
SELECT producto, COUNT(prestamo_id) AS "cant. préstamos"
FROM prestamos
GROUP BY producto
ORDER BY "cant. préstamos" DESC;

-- 3. Promedio simple tasa 
SELECT producto, AVG(tasa_ea) AS "prom. simple"
FROM prestamos
GROUP BY producto
ORDER BY "prom. simple" DESC;

-- 4. Promedio ponderado por monto
-- No necesito case when aquí
SELECT r.producto, 
  SUM(CASE WHEN (r.tasa_ea * monto_desembolsado) THEN 1 END) AS "tasa x pago",
  SUM(monto_desembolsado) AS "total pagos",
  ROUND(100.0 * SUM(CASE (WHEN r.tasa_ea * monto_desembolsado) THEN 1 END)/SUM(monto_desembolsado),2) AS "Prom. pond x pago"
FROM prestamos r
LEFT JOIN pagos g ON r.prestamo_id = g.prestamo_id
GROUP BY r.producto
ORDER BY "Prom. pond x pago" DESC;

-- súper contraejemplo
SELECT r.producto, 
  SUM(r.tasa_ea * monto_desembolsado) AS "tasa x pago",
  SUM(monto_desembolsado) AS "total pagos",
  ROUND(100.0 * SUM(r.tasa_ea * monto_desembolsado)/SUM(monto_desembolsado),2) AS "Prom. pond x pago"
FROM prestamos r
LEFT JOIN pagos g ON r.prestamo_id = g.prestamo_id
GROUP BY r.producto
ORDER BY "Prom. pond x pago" DESC;

SELECT producto, 
  SUM(tasa_ea * monto_desembolsado) AS "tasa x pago",
  SUM(monto_desembolsado) AS "total pagos",
  ROUND(100.0 * SUM(tasa_ea * monto_desembolsado)/SUM(monto_desembolsado),2) AS "Prom. pond x pago"
FROM prestamos
GROUP BY producto
ORDER BY "Prom. pond x pago" DESC;

SELECT producto,
  SUM(tasa_ea * monto_desembolsado) AS suma_ponderada,
  SUM(monto_desembolsado) AS suma_montos,
  ROUND(SUM(tasa_ea * monto_desembolsado) / SUM(monto_desembolsado), 4) AS tasa_ponderada
FROM prestamos
GROUP BY producto
ORDER BY tasa_ponderada DESC;

-- reto 10. Distribución de pagos por cubeta de mora
SELECT tasa_ea FROM prestamos LIMIT 5;

SELECT dias_mora, COUNT(pago_id) AS "Cant. pagos"
FROM pagos
GROUP by dias_mora;

-- error
SELECT dias_mora, 
  COUNT(CASE WHEN dias_mora <=0 THEN "Al día" 
        ELSE dias_mora BETWEEN 1 AND 30 then "1-30"
        ELSE dias_mora BETWEEN 31 AND 60 then "31-60"
        ELSE dias_mora BETWEEN 61 AND 90 then "61-90"
        ELSE dias_mora > 90 then "90+" END) AS "Cubeta mora",
  COUNT(pago_id) AS "Cant. pagos"
  ROUND("Cubeta mora")/COUNT(pago_id) AS "Porc. del total"
FROM pagos
GROUP BY dias_mora

-- correcto
SELECT 
  CASE WHEN dias_mora <=0 THEN 'Al día' 
       WHEN dias_mora BETWEEN 1 AND 30 then '1-30'
       WHEN dias_mora BETWEEN 31 AND 60 then '31-60'
       WHEN dias_mora BETWEEN 61 AND 90 then '61-90'
       ELSE '90+' END AS "Cubeta mora",
  COUNT(pago_id) AS "Cant. pagos",
  ROUND(COUNT(pago_id)*100.0 / (SELECT COUNT(pago_id) FROM pagos), 2) As "porc. del total"
FROM pagos
GROUP BY "Cubeta mora"
order by "porc. del total" DESC;

SELECT COUNT(pago_id) FROM pagos
-- la query de la línea 315 tuvo output de 55.305 

-- BLOQUE 4: WINDOW FUNCTIONS --



