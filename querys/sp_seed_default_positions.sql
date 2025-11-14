-- NO USADO

-- Seed de posiciones por defecto (grilla) para nodos de planta interna (ODFs/Nodos)
IF OBJECT_ID('dbo.sp_seed_default_positions') IS NULL
  EXEC('CREATE PROCEDURE dbo.sp_seed_default_positions AS SET NOCOUNT ON;');
GO
ALTER PROCEDURE dbo.sp_seed_default_positions
  @col_sep FLOAT = 240.0,
  @row_sep FLOAT = 180.0,
  @cols    INT   = 6
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH missing AS (
    SELECT n.id AS node_id,
           ROW_NUMBER() OVER (ORDER BY n.id) AS rn
    FROM dbo.nodo n
    WHERE NOT EXISTS (SELECT 1 FROM dbo.graph_node_position p WHERE p.node_id = n.id)
  ),
  grid AS (
    SELECT node_id,
           (rn-1) % @cols AS col,
           (rn-1) / @cols AS fil
    FROM missing
  )
  INSERT INTO dbo.graph_node_position(node_id, x, y)
  SELECT node_id,
         @col_sep * col AS x,
         @row_sep * fil AS y
  FROM grid;
END
GO
