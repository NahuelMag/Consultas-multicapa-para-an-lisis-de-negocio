
-- ============================================================
-- PRE-ENTREGA MODULO 4
-- CONSULTAS MULTICAPA PARA ANALISIS DE NEGOCIO
-- Motor de base de datos: PostgreSQL
--
-- OBJETIVO GENERAL:
-- Analizar la facturacion por categoria, identificar clientes
-- sin compras y conocer el producto mas comprado por cliente.
-- Estos resultados permiten tomar decisiones comerciales
-- basadas en los datos almacenados en la base de datos.
-- ============================================================


-- ============================================================
-- PREPARACION DE LA ESTRUCTURA
--
-- La base original contiene clientes, productos y ventas, pero
-- no incluye categorias para los productos ni fechas de venta.
-- Agregamos esos datos para poder realizar las consultas.
-- ============================================================

-- Crear la tabla de categorias si todavia no existe.
-- SERIAL genera identificadores automaticamente.
-- PRIMARY KEY identifica cada categoria de forma unica.
-- UNIQUE evita nombres de categorias duplicados.
-- NOT NULL obliga a que cada categoria tenga un nombre.
CREATE TABLE IF NOT EXISTS categorias (
    categoria_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);


-- Agregar categoria_id a producto si la columna no existe.
-- Esta columna permitira relacionar cada producto con su categoria.
ALTER TABLE producto
ADD COLUMN IF NOT EXISTS categoria_id INT;


-- Agregar fecha y hora a cada venta.
-- TIMESTAMP permite registrar la fecha y hora de la transaccion.
ALTER TABLE ventas
ADD COLUMN IF NOT EXISTS fecha_venta TIMESTAMP;


-- ============================================================
-- PREPARACION DE DATOS DE EJEMPLO
-- ============================================================

-- Insertar tres categorias ilustrativas.
-- ON CONFLICT evita errores si el nombre ya existe,
-- gracias a la restriccion UNIQUE de la columna nombre.
INSERT INTO categorias (nombre) VALUES
('Categoria A'), ('Categoria B'), ('Categoria C')
ON CONFLICT (nombre) DO NOTHING;


-- Asignar categorias a los primeros cinco productos.
-- CASE permite definir una categoria diferente segun el ID.
-- Las subconsultas obtienen el ID real de cada categoria.
-- WHERE limita la actualizacion a productos sin categoria
-- y con ID entre 1 y 5.
-- Esta asignacion es de ejemplo y debe adaptarse al negocio.
UPDATE producto
SET categoria_id = CASE producto_id
    WHEN 1 THEN (SELECT categoria_id FROM categorias WHERE nombre = 'Categoria A')
    WHEN 2 THEN (SELECT categoria_id FROM categorias WHERE nombre = 'Categoria B')
    WHEN 3 THEN (SELECT categoria_id FROM categorias WHERE nombre = 'Categoria A')
    WHEN 4 THEN (SELECT categoria_id FROM categorias WHERE nombre = 'Categoria C')
    WHEN 5 THEN (SELECT categoria_id FROM categorias WHERE nombre = 'Categoria B')
END
WHERE categoria_id IS NULL AND producto_id BETWEEN 1 AND 5;


-- Crear la clave foranea entre producto y categorias si no existe.
-- Una clave foranea garantiza que la categoria asignada a un
-- producto exista en la tabla categorias.
-- pg_constraint consulta las restricciones registradas por PostgreSQL.
-- conrelid verifica que la restriccion pertenezca a producto.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_producto_categoria'
          AND conrelid = 'producto'::regclass
    ) THEN
        ALTER TABLE producto
        ADD CONSTRAINT fk_producto_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id);
    END IF;
END $$;


-- Asignar fechas ficticias a las ventas que no tengan fecha.
-- CURRENT_TIMESTAMP obtiene la fecha y hora actuales.
-- INTERVAL '1 day' representa un dia.
-- Se generan fechas de ejemplo para poder probar la consulta 3.
-- IMPORTANTE: estas fechas no representan transacciones reales.
-- Si se dispone de fechas reales, deben conservarse y utilizarse.
UPDATE ventas
SET fecha_venta = CURRENT_TIMESTAMP - (ventas_id * INTERVAL '1 day')
WHERE fecha_venta IS NULL;


-- ============================================================
-- 1. FACTURACION POR CATEGORIA
--
-- PROBLEMA DE NEGOCIO:
-- Identificar que categorias generan mayor facturacion y
-- cuantas unidades se vendieron en cada una.
--
-- UTILIDAD:
-- Permite comparar el rendimiento comercial de las categorias,
-- orientar promociones y detectar cuales generan mas ingresos.
--
-- NOTA:
-- Se calcula facturacion estimada, no rentabilidad real,
-- porque no contamos con los costos de los productos.
-- El umbral de $50.000 es ilustrativo y puede ajustarse.
-- ============================================================

SELECT
    cat.nombre AS categoria, -- Nombre de la categoria analizada.

    -- Sumar las unidades vendidas de todos los productos
    -- pertenecientes a cada categoria.
    SUM(v.cantidad) AS unidades_vendidas,

    -- Calcular la facturacion estimada multiplicando la cantidad
    -- vendida por el precio actual del producto y sumando los
    -- importes de todas las ventas de la categoria.
    SUM(v.cantidad * p.precio_producto) AS ingreso_total

FROM ventas v

-- Relacionar cada venta con su producto para obtener el precio.
JOIN producto p ON v.producto_id = p.producto_id

-- Relacionar cada producto con su categoria para agrupar ventas.
JOIN categorias cat ON p.categoria_id = cat.categoria_id

-- Agrupar por categoria para calcular los totales de cada una.
GROUP BY cat.categoria_id, cat.nombre

-- Mostrar solamente las categorias cuya facturacion estimada
-- supera los $50.000. HAVING filtra resultados agregados.
HAVING SUM(v.cantidad * p.precio_producto) > 50000

-- Ordenar las categorias desde la mayor hasta la menor facturacion.
ORDER BY ingreso_total DESC;


-- ============================================================
-- 2. CLIENTES SIN COMPRAS
--
-- PROBLEMA DE NEGOCIO:
-- Identificar clientes registrados que nunca realizaron una
-- compra para orientar campanas de bienvenida y seguimiento.
--
-- UTILIDAD:
-- Permite detectar clientes que todavia no se convirtieron
-- en compradores y planificar acciones comerciales especificas.
-- ============================================================

SELECT
    c.clientes_id, -- Identificador unico del cliente.
    c.email AS cliente, -- Mostrar el email como nombre del cliente.
    c.edad, -- Edad registrada del cliente.

    -- COUNT cuenta las ventas asociadas al cliente.
    -- Si no tiene ventas, devuelve 0 porque no cuenta valores NULL.
    COUNT(v.ventas_id) AS cantidad_compras

FROM clientes c

-- LEFT JOIN conserva todos los clientes, incluso aquellos
-- que no tienen ventas asociadas. En esos casos, los campos
-- de ventas aparecen como NULL.
LEFT JOIN ventas v ON c.clientes_id = v.clientes_id

-- Agrupar por cliente para contar sus ventas individualmente.
GROUP BY c.clientes_id, c.email, c.edad

-- Conservar solamente los clientes cuyo conteo de ventas es cero.
-- HAVING permite filtrar usando el resultado de COUNT.
HAVING COUNT(v.ventas_id) = 0

-- Ordenar los clientes encontrados por su identificador.
ORDER BY c.clientes_id;


-- ============================================================
-- 3. PRODUCTO MAS COMPRADO POR CLIENTE
--
-- PROBLEMA DE NEGOCIO:
-- Identificar el producto del que cada cliente compro mas
-- unidades y consultar la fecha de su ultima transaccion.
--
-- UTILIDAD:
-- Permite personalizar recomendaciones, crear promociones
-- relacionadas con los productos preferidos y analizar habitos
-- de compra para mejorar la fidelizacion de los clientes.
--
-- CRITERIO DE DESEMPATE:
-- Si dos productos tienen la misma cantidad de unidades
-- compradas por un cliente, se prioriza el producto con menor ID.
-- ============================================================

-- WITH crea una consulta temporal llamada resumen.
-- Primero calculamos las unidades por cliente y producto;
-- despues seleccionamos el producto que ocupa la primera posicion.
WITH resumen AS (
    SELECT
        c.clientes_id, -- ID del cliente.
        c.email AS cliente, -- Email del cliente.
        p.producto_id, -- ID del producto comprado.

        -- Sumar todas las unidades que cada cliente compro
        -- de cada producto, incluso en distintas transacciones.
        SUM(v.cantidad) AS unidades_compradas,

        -- MAX(v.fecha_venta) obtiene la fecha mas reciente
        -- dentro de cada grupo cliente-producto.
        -- El MAX externo con OVER calcula la fecha mas reciente
        -- entre todos los productos comprados por ese cliente.
        -- PARTITION BY reinicia el calculo para cada cliente.
        MAX(MAX(v.fecha_venta)) OVER (
            PARTITION BY c.clientes_id
        ) AS ultima_transaccion,

        -- ROW_NUMBER asigna una posicion a cada producto
        -- dentro de las compras de cada cliente.
        -- PARTITION BY separa los productos por cliente.
        -- ORDER BY prioriza la mayor cantidad de unidades;
        -- si hay empate, prioriza el menor ID de producto.
        ROW_NUMBER() OVER (
            PARTITION BY c.clientes_id
            ORDER BY SUM(v.cantidad) DESC, p.producto_id
        ) AS posicion

    FROM clientes c

    -- Relacionar clientes con sus transacciones.
    -- JOIN incluye solamente clientes que tienen ventas.
    JOIN ventas v ON c.clientes_id = v.clientes_id

    -- Relacionar cada venta con el producto correspondiente.
    JOIN producto p ON v.producto_id = p.producto_id

    -- Agrupar por cliente y producto para sumar todas las
    -- unidades compradas de cada producto.
    GROUP BY c.clientes_id, c.email, p.producto_id
)

-- Mostrar solamente el producto que quedo primero para cada cliente.
SELECT
    cliente,
    producto_id,
    unidades_compradas,
    ultima_transaccion
FROM resumen

-- posicion = 1 selecciona el producto mas comprado por cliente.
WHERE posicion = 1

-- Ordenar el resultado alfabeticamente por email del cliente.
ORDER BY cliente;


