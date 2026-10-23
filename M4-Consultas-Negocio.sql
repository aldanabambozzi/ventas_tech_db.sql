-- ============================================================
-- Pre-entrega M4: Consultas SQL de negocio
-- Base: Ventas_Tech_DB - Motor: SQL Server (SSMS)
-- Archivo: m4_consultas_negocio.sql
-- Proyecto: TechStore - Dashboard de Inteligencia de Negocios
-- ============================================================
-- USE Ventas_Tech_DB;
-- GO

-- ------------------------------------------------------------
-- Consulta 1 — Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes
-- ------------------------------------------------------------
SELECT 
    MONTH(fecha_venta) AS mes,
    SUM(cantidad * precio_unitario) AS total_facturado,
    COUNT(id_venta) AS cantidad_pedidos,
    AVG(cantidad * precio_unitario) AS ticket_promedio
FROM ventas
GROUP BY MONTH(fecha_venta)
ORDER BY mes;
-- Nota PostgreSQL: Reemplazar MONTH(fecha_venta) por EXTRACT(MONTH FROM fecha_venta)
GO

-- ------------------------------------------------------------
-- Consulta 2 — Ranking de productos
-- Top 5 de id_producto por total facturado
-- ------------------------------------------------------------
SELECT TOP 5
    id_producto,
    SUM(cantidad) AS unidades_vendidas,
    SUM(cantidad * precio_unitario) AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;
GO

-- ------------------------------------------------------------
-- Consulta 3 — Clientes recurrentes
-- Clientes con más de un pedido
-- ------------------------------------------------------------
SELECT 
    id_cliente,
    COUNT(*) AS cantidad_pedidos,
    SUM(cantidad * precio_unitario) AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;
GO

-- ------------------------------------------------------------
-- Consulta 4 — Meses por encima / por debajo del promedio
-- Total por mes comparado con el promedio mensual general
-- ------------------------------------------------------------
WITH facturacion_mensual AS (
    SELECT 
        MONTH(fecha_venta) AS mes,
        SUM(cantidad * precio_unitario) AS total_facturado_mes
    FROM ventas
    GROUP BY MONTH(fecha_venta)
),
promedio_general AS (
    SELECT AVG(total_facturado_mes) AS promedio_mensual
    FROM facturacion_mensual
)
SELECT 
    fm.mes,
    fm.total_facturado_mes,
    pg.promedio_mensual,
    CASE 
        WHEN fm.total_facturado_mes >= pg.promedio_mensual THEN 'Por encima'
        ELSE 'Por debajo'
    END AS comparativa_promedio
FROM facturacion_mensual fm
CROSS JOIN promedio_general pg
ORDER BY fm.mes;
GO

-- ------------------------------------------------------------
-- Bloque de cierre — 3 hallazgos concretos
-- ------------------------------------------------------------
-- Hallazgo 1: El producto 1 (Laptop Pro 15) concentra el 55.9% de la facturación total ($3.600 de $6.444),
--            a pesar de representar solo 3 unidades vendidas. Es el claro driver de ingresos.
-- Hallazgo 2: El 100% de los clientes son recurrentes en este corte (5 de 5 clientes tienen 2 pedidos),
--            pero con ticket muy desigual: cliente 1 ($2.640) y cliente 5 ($2.100) juntos representan
--            el 73.5% del total facturado, lo que muestra concentración de riesgo en 2 cuentas.
-- Hallazgo 3: El mes de marzo (único mes con datos en esta muestra) tiene un ticket promedio de $644.4
--            y 10 pedidos. El producto más vendido por volumen es el id_producto 2 (Mouse Inalámbrico)
--            con 13 unidades, pero solo genera 5.6% de la facturación, indicando oportunidad de
--            estrategia de cross-selling con la Laptop Pro 15 para aumentar ticket.
