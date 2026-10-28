# Pre-entrega Módulo 4: Consultas multicapa para análisis de negocio

## Descripción del proyecto

Este proyecto forma parte de la pre-entrega del Módulo 4 y tiene como objetivo aplicar consultas SQL en PostgreSQL para obtener información relevante para la toma de decisiones de negocio.

A partir de una base de datos de clientes, productos y ventas, se desarrollan consultas que permiten analizar la facturación por categoría, identificar clientes que todavía no realizaron compras y conocer los productos más comprados por cada cliente.

Además, se amplía la estructura original de la base de datos para incorporar categorías de productos y fechas de venta, necesarias para realizar los análisis solicitados.

## Objetivos

- Analizar la facturación estimada y las unidades vendidas por categoría.
- Identificar clientes registrados que no tienen compras asociadas.
- Determinar el producto con mayor cantidad de unidades compradas por cada cliente.
- Consultar la fecha de la última transacción de cada cliente.
- Aplicar agrupaciones, funciones de agregación, subconsultas y funciones de ventana en PostgreSQL.

## Tecnologías utilizadas

- **PostgreSQL:** sistema de gestión de bases de datos relacionales.
- **SQL:** lenguaje utilizado para crear, modificar y consultar los datos.
- **Git y GitHub:** control de versiones y publicación del proyecto.

## Estructura de la base de datos

El proyecto utiliza tres tablas principales y una tabla adicional para clasificar los productos.

| Tabla | Descripción |
|---|---|
| `clientes` | Almacena el identificador, email y edad de los clientes. |
| `producto` | Contiene los productos, su stock, precio y categoría asociada. |
| `ventas` | Registra las ventas, los clientes, los productos, las cantidades y las fechas de transacción. |
| `categorias` | Permite clasificar los productos para realizar análisis comerciales. |

### Relaciones entre tablas

- Un cliente puede tener múltiples ventas.
- Un producto puede aparecer en múltiples ventas.
- Una categoría puede estar asociada a múltiples productos.
- Cada venta se relaciona con un cliente y un producto mediante sus identificadores.

Para incorporar estas relaciones se utilizan claves primarias y claves foráneas, que permiten identificar registros y mantener la integridad de los datos.

## Consultas desarrolladas

### 1. Facturación por categoría

**Problema de negocio:** identificar qué categorías generan mayor facturación y cuántas unidades se vendieron en cada una.

La consulta relaciona las tablas de ventas, productos y categorías. Mediante `SUM()` calcula las unidades vendidas y la facturación estimada de cada categoría.

Se utiliza `GROUP BY` para agrupar los resultados por categoría, `HAVING` para filtrar aquellas cuya facturación supera el umbral definido y `ORDER BY` para ordenar los resultados de mayor a menor facturación.

**Aplicación en el negocio:** permite comparar el desempeño comercial de las categorías y orientar decisiones relacionadas con promociones y estrategias de venta.

> La consulta calcula facturación estimada utilizando el precio actual de los productos. No representa rentabilidad neta, ya que no se incluyen costos ni otros gastos.

### 2. Clientes sin compras

**Problema de negocio:** identificar clientes registrados que todavía no realizaron ninguna compra.

La consulta utiliza `LEFT JOIN` para conservar todos los clientes, incluso cuando no tienen ventas asociadas. Luego, mediante `COUNT()` y `HAVING`, selecciona aquellos cuyo número de ventas es cero.

**Aplicación en el negocio:** permite detectar clientes que todavía no se convirtieron en compradores y planificar acciones de seguimiento, campañas de bienvenida o promociones iniciales.

### 3. Producto más comprado por cliente

**Problema de negocio:** determinar qué producto compró cada cliente en mayor cantidad y consultar la fecha de su última transacción.

La consulta utiliza una expresión de tabla común (`WITH`) para organizar los resultados intermedios. Con `SUM()` calcula las unidades compradas por cliente y producto; con `ROW_NUMBER()` establece un ranking individual para cada cliente.

También utiliza funciones de ventana para obtener la fecha más reciente de transacción de cada cliente. En caso de empate entre productos, se prioriza el producto con el identificador menor.

**Aplicación en el negocio:** facilita la personalización de recomendaciones, la creación de promociones y el análisis de los hábitos de compra de los clientes.

## Conceptos de SQL aplicados

- `CREATE TABLE`: creación de tablas.
- `ALTER TABLE`: modificación de la estructura existente.
- `INSERT INTO`: inserción de registros.
- `UPDATE`: actualización de datos.
- `PRIMARY KEY` y `FOREIGN KEY`: definición de relaciones e integridad referencial.
- `JOIN` y `LEFT JOIN`: combinación de información entre tablas.
- `GROUP BY`: agrupación de registros para realizar cálculos.
- `SUM()` y `COUNT()`: funciones de agregación.
- `MAX()`: obtención de valores máximos, como la fecha más reciente.
- `HAVING`: filtrado de grupos según resultados agregados.
- `WITH`: organización de consultas mediante expresiones de tabla comunes.
- `ROW_NUMBER()` y `OVER (PARTITION BY ...)`: clasificación de resultados dentro de cada cliente.
- Subconsultas y `CASE`: búsqueda de identificadores y asignación condicional de categorías.

## Preparación y ejecución

1. Crear o seleccionar una base de datos PostgreSQL.
2. Ejecutar previamente el script de creación y carga de las tablas `clientes`, `producto` y `ventas`.
3. Ejecutar `pre-entrega-modulo4.sql`, que incorpora la estructura adicional, prepara los datos de ejemplo y ejecuta las tres consultas.
4. Revisar los resultados obtenidos y verificar que existan categorías asignadas y fechas de venta cargadas.

### Consideraciones sobre los datos

Las categorías y las fechas incorporadas durante la preparación son datos de ejemplo para desarrollar y probar las consultas.

La asignación de categorías está preparada para los productos con identificadores del 1 al 5. Si la base contiene otros productos, será necesario asignarles categorías según corresponda.

Las fechas generadas automáticamente son ficticias y no deben interpretarse como un historial real de transacciones.

## Conclusión

Este trabajo demuestra cómo utilizar SQL para transformar datos relacionales en información útil para el análisis comercial.

A través de las consultas desarrolladas se pueden comparar resultados por categoría, detectar clientes sin compras y analizar las preferencias de compra individuales. De esta manera, se aplican conceptos fundamentales de PostgreSQL a situaciones habituales de análisis de negocio.

---

**Autor:** [Tu nombre]

**Repositorio:** [Enlace al repositorio de GitHub]
