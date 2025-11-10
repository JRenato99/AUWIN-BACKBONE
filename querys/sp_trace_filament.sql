-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.sp_trace_filament') AND type = 'P')
BEGIN 
    EXEC('CREATE PROCEDURE dbo.sp_trace_filament
    @start_fiber_id NVARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ''Stub version, please alter procedure'' AS info;
END')
END
GO

-- Ahora usamos ALTER para asegurar la versión correcta
ALTER PROCEDURE dbo.sp_trace_filament
  @start_fiber_id NVARCHAR(64)
AS
BEGIN
  SET NOCOUNT ON;

  -- Graph traversal en T-SQL: recorremos splices conectados.
  ;WITH RECURSIVE_TRACE AS (
    -- seed
    SELECT 
      0 AS hop,
      CAST(NULL AS NVARCHAR(64)) AS via_splice_id,
      CAST(NULL AS NVARCHAR(64)) AS via_mufa_id,
      CAST(NULL AS NVARCHAR(64)) AS via_pole_id,
      f.id AS fiber_id,
      f.cable_id,
      f.filament_no
    FROM dbo.fiber_filament f
    WHERE f.id = @start_fiber_id

    UNION ALL

    -- hop a través de splice: A->B y B->A
    SELECT
      rt.hop + 1,
      sp.splice_id,
      sp.mufa_id,
      sp.pole_id,
      CASE WHEN sp.a_fiber_filament_id = rt.fiber_id THEN sp.b_fiber_filament_id ELSE sp.a_fiber_filament_id END,
      ff.cable_id,
      ff.filament_no
    FROM RECURSIVE_TRACE rt
    JOIN dbo.vw_fiber_splice sp
      ON sp.a_fiber_filament_id = rt.fiber_id
      OR sp.b_fiber_filament_id = rt.fiber_id
    JOIN dbo.fiber_filament ff
      ON ff.id = CASE WHEN sp.a_fiber_filament_id = rt.fiber_id THEN sp.b_fiber_filament_id ELSE sp.a_fiber_filament_id END
    WHERE rt.hop < 200  -- límite de seguridad
  )
  SELECT *
  FROM RECURSIVE_TRACE
  OPTION (MAXRECURSION 200);
END



