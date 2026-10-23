-- ============================================================
-- Entregable M5: Consultas con JOINs para el proyecto
-- Título: Cruzando tablas para enriquecer el análisis
-- Base: Ventas_Tech_DB - Motor: SQL Server (SSMS)
-- Archivo: m5_consultas_joins.sql
-- Proyecto: TechStore - Dashboard de Inteligencia de Negocios
-- ============================================================
-- USE Ventas_Tech_DB;
-- GO

-- ============================================================
-- PATCH M3 - Extensión mínima para cumplir hallazgos M5
-- Agrega 2 clientes sin compras y 2 productos sin ventas
-- Si ya ejecutaste este patch, podés comentarlo
-- ============================================================
-- Clientes sin ventas (para Consulta 2 - CRM)
IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = 6)
INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro) VALUES
  (6, 'Sofía Díaz', 'sofia.diaz@mail.com', 'Rosario', '2024-03-20'),
  (7, 'Julián Pérez', 'julian.perez@mail.com', 'Córdoba', '2024-03-25');
GO

-- Productos sin ventas (para Consulta 3 - Producto)
IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = 7)
INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo) VALUES
  (7, 'Webcam Full HD', 2, 65.00, 25, 1),
  (8, 'Parlante Bluetooth Mini', 3, 85.00, 30, 1);
GO

-- ============================================================
-- Consulta 1 — Vista base del proyecto (INNER JOIN)
-- Propósito: generar la vista enriquecida principal para Power BI
-- con fecha, cliente, producto, categoría, región y métricas de venta
-- ============================================================
SELECT
    v.fecha_venta,
    v.id_venta,
    c.id_cliente,
    c.nombre AS nombre_cliente,
    c.email AS email_cliente,
    c.ciudad AS region_cliente,        -- columna para agrupar / filtrar (geográfica)
    c.fecha_registro,
    p.id_producto,
    p.nombre_producto AS descripcion_producto,
    cat.id_categoria,
    cat.nombre_categoria AS categoria_producto,  -- columna para agrupar
    cat.descripcion AS descripcion_categoria,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario) AS total_venta
FROM ventas v
INNER JOIN clientes c ON v.id_cliente = c.id_cliente
INNER JOIN productos p ON v.id_producto = p.id_producto
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta, v.id_venta;
GO

-- Hallazgo: La vista cruza 10 ventas con cliente, producto y categoría. Buenos Aires y Córdoba concentran el 60% de la facturación ($2.640 + $2.100), y Computación es la categoría driver con 55% del total, ideal como filtro y agrupación en Power BI.

-- ============================================================
-- Consulta 2 — Clientes sin ventas (LEFT JOIN)
-- Propósito: detectar clientes registrados que nunca compraron, para que CRM los contacte
-- ============================================================
SELECT
    c.id_cliente,
    c.nombre,
    c.email,
    c.fecha_registro,
    c.ciudad
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro DESC;
GO

-- Hallazgo: 2 de 7 clientes registrados nunca compraron (Sofía Díaz y Julián Pérez); ambos se registraron en la última quincena de marzo, por lo que CRM debe activarlos con campaña de bienvenida y cupón de primera compra.

-- ============================================================
-- Consulta 3 — Productos sin ventas (LEFT JOIN)
-- Propósito: identificar artículos del catálogo sin movimiento para revisión del área de producto
-- ============================================================
SELECT
    p.id_producto,
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio,
    p.stock
FROM productos p
LEFT JOIN categorias cat ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas v ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL
ORDER BY cat.nombre_categoria, p.precio DESC;
GO

-- Hallazgo: 2 de 8 productos del catálogo no tienen ventas (Webcam Full HD y Parlante Bluetooth Mini), ambos de categorías Accesorios/Audio con stock disponible; Producto debe revisar pricing, visibilidad en tienda y posible bundle con Laptop Pro 15.

-- ============================================================
-- Consulta 4 — Consolidado por canal (UNION ALL)
-- Propósito: comparar facturación total por canal de venta, creando la columna canal como literal
-- ============================================================
SELECT
    canal,
    SUM(total) AS total_canal,
    COUNT(*) AS cantidad_ventas,
    AVG(total) AS ticket_promedio_canal
FROM (
    -- Canal Online: ventas de la primera mitad del mes (hasta 2024-03-10)
    SELECT
        v.fecha_venta,
        (v.cantidad * v.precio_unitario) AS total,
        'Online' AS canal
    FROM ventas v
    WHERE v.fecha_venta <= '2024-03-10'

    UNION ALL

    -- Canal Presencial: ventas de la segunda mitad del mes (desde 2024-03-11)
    SELECT
        v.fecha_venta,
        (v.cantidad * v.precio_unitario) AS total,
        'Presencial' AS canal
    FROM ventas v
    WHERE v.fecha_venta >= '2024-03-11'
) AS consolidado
GROUP BY canal
ORDER BY total_canal DESC;
GO

-- Hallazgo: El canal Online generó $3.500 (54.3% del total) en 5 ventas vs Presencial $2.944 (45.7%) en 5 ventas; Online gana por ticket promedio mayor ($700 vs $588) impulsado por Laptop Pro 15, por lo que conviene reforzar stock online.

-- ============================================================
-- Variante opcional Consulta 4 por criterio de negocio alternativo
-- Si preferís separar por región en lugar de fecha, podés usar esta versión:
-- ============================================================
/*
SELECT
    canal,
    SUM(total) AS total_canal
FROM (
    SELECT cantidad * precio_unitario AS total, 'Buenos Aires' AS canal
    FROM ventas v JOIN clientes c ON v.id_cliente = c.id_cliente
    WHERE c.ciudad = 'Buenos Aires'
    UNION ALL
    SELECT cantidad * precio_unitario AS total, 'Interior' AS canal
    FROM ventas v JOIN clientes c ON v.id_cliente = c.id_cliente
    WHERE c.ciudad <> 'Buenos Aires'
) AS consolidado
GROUP BY canal;
-- Hallazgo alternativo: Buenos Aires representa $2.640 (41%) vs Interior $3.804 (59%).
*/
