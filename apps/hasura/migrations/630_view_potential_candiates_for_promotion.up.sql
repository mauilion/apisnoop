-- 630: Potential Candidates for Promotion
--    :PROPERTIES:
--    :header-args:sql-mode+: :tangle ../apps/hasura/migrations/630_view_potential_candiates_for_promotion.up.sql
--    :END:
--    This view shows not-yet-conformance tests with an above average focus on the endpoints they hit, not-yet-conformant stable endpoints with a small number of tests that hit them, and where these two meet.  By looking at this combination, you can see tests that are likely written specifically for the endpoint they hit, and by promoting this test you'd add a new GA endpoint to conformance.
   
--    #+NAME: Possible Candidates for Promotion 

CREATE OR REPLACE VIEW "public"."possible_candidates_for_promotion" AS
  WITH tests as (
    SELECT DISTINCT
      COUNT(distinct operation_id) FILTER(where useragent = audit_event.useragent) as distinct_endpoints,
      split_part(useragent, '--', 2) as test,
      useragent
      FROM
          audit_event
     WHERE
           useragent LIKE 'e2e.test%'
       AND job != 'live'
     GROUP BY useragent
  ), stable_endpoints AS (
  SELECT
       COUNT(distinct ae.useragent) FILTER(where ae.operation_id = ae.operation_id) as distinct_tests,
         ae.operation_id
         FROM
         audit_event ae
         JOIN endpoint_coverage ec on (ae.operation_id = ec.operation_id)
         WHERE
         useragent LIKE 'e2e.test%'
         AND ae.job != 'live'
         AND ec.level = 'stable'
         AND ec.conformance_tested is false
         GROUP BY ae.operation_id
  )

  (SELECT DISTINCT
    audit_event.operation_id,
    test
    FROM tests
      JOIN
      audit_event on (audit_event.useragent = tests.useragent)
    WHERE distinct_endpoints < 14
    AND test not like '%[Conformance]%'
  )
    INTERSECT
  (SELECT DISTINCT
    stable_endpoints.operation_id,
    split_part(ae.useragent, '--', 2) as test
    FROM
        stable_endpoints
        JOIN
        audit_event ae on (ae.operation_id = stable_endpoints.operation_id)
        WHERE distinct_tests < 10
         AND ae.useragent like 'e2e.test%')
       ORDER BY test
         ;
