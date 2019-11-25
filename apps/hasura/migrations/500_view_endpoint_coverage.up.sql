-- 500: Endpoint Coverage View
--    :PROPERTIES:
--    :header-args:sql-mode+: :tangle ../apps/hasura/migrations/500_view_endpoint_coverage.up.sql
--    :END:
--    developed in [[file:explorations/ticket_50_endpoint_coverage.org][ticket 50: endpoint coverage]] 
--    sped up in  [[file:tickets/73_explain_analyze_improve.org][ticket 73: explain, analyze, improve]] 
--    #+NAME: Endpoint Coverage View

CREATE OR REPLACE VIEW endpoint_coverage AS
  WITH tested as (
    SELECT DISTINCT
      job, operation_id,useragent
      FROM
          audit_event ae 
     WHERE ae.useragent like 'e2e.test%'
  ), hit as(
    SELECT DISTINCT
      job,
      operation_id
      FROM audit_event
  )
  select distinct
    bjs.job_timestamp::date as date, 
    ao.bucket as bucket,
    ao.job as job,
    ao.operation_id as operation_id,
    ao.level,
    ao.category,
    ao.k8s_group as group,
    ao.k8s_kind as kind,
    ao.k8s_version as version,
    exists(select 1 from tested t where t.operation_id = ao.operation_id and t.job = ao.job and t.useragent like '%[Conformance]%') as conformance_tested,
    exists(select 1 from tested t where t.operation_id = ao.operation_id and t.job = ao.job) as tested,
    exists(select 1 from hit h where  h.operation_id = ao.operation_id and h.job = ao.job) as hit
    from api_operation_material ao 
    JOIN bucket_job_swagger bjs on (ao.bucket = bjs.bucket AND ao.job = bjs.job)
     WHERE ao.deprecated IS false
    ;
