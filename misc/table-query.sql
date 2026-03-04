WITH
cpu AS (
    SELECT
        service,
        avg(cpu_core_avg) AS cpu_cores
    FROM (
        SELECT
            label('_service') AS service,
            toStartOfInterval(dt, INTERVAL '60 second') AS time,
            avgMerge(rate_avg) AS cpu_core_avg
        FROM remote(t510758_lisisoft_debian_collector_metrics)
        WHERE
            dt BETWEEN toDateTime64('2026-03-03 21:35:31.632000', 6) AND toDateTime64('2026-03-04 00:35:31.632000', 6)
            
            AND name = 'container_resources_cpu_usage_seconds_total'
        GROUP BY service, time
    )
    GROUP BY service
),
mem AS (
    SELECT
        service,
        avg(memory_avg) AS memory_bytes
    FROM (
        SELECT
            label('_service') AS service,
            toStartOfInterval(dt, INTERVAL '60 second') AS time,
            avgMerge(value_avg) AS memory_avg
        FROM remote(t510758_lisisoft_debian_collector_metrics)
        WHERE
            dt BETWEEN toDateTime64('2026-03-03 21:35:31.632000', 6) AND toDateTime64('2026-03-04 00:35:31.632000', 6)
            
            AND name = 'container_resources_memory_rss_bytes'
        GROUP BY service, time
    )
    GROUP BY service
),
containers AS (
    SELECT
        label('_service') AS service,
        uniqExact(label('_container')) AS container_count
    FROM remote(t510758_lisisoft_debian_collector_metrics)
    WHERE
        dt BETWEEN toDateTime64('2026-03-03 21:35:31.632000', 6) AND toDateTime64('2026-03-04 00:35:31.632000', 6)
        
    GROUP BY service
),
services AS (
    SELECT DISTINCT service FROM (
        SELECT service FROM cpu
        UNION ALL
        SELECT service FROM mem
        UNION ALL
        SELECT service FROM containers
    )
),
main AS (
    SELECT
        concat('[', s.service, '](/team/0/dashboards/go/service?vs%5Bservice%5D=', encodeURLComponent(s.service), ')') AS `Service`,
        round(c.cpu_cores, 2) AS `CPU usage`,
        m.memory_bytes AS `Memory usage`
    FROM services s
    LEFT JOIN cpu c ON c.service = s.service
    LEFT JOIN mem m ON m.service = s.service
    WHERE s.service IS NOT NULL
),
has_rows AS (SELECT count() AS c FROM main),
hosts_count AS (
    SELECT uniqExact(label('_host')) AS cnt
    FROM remote(t510758_lisisoft_debian_collector_metrics)
    WHERE dt BETWEEN toDateTime64('2026-03-03 21:35:31.632000', 6) AND toDateTime64('2026-03-04 00:35:31.632000', 6)
    
)

SELECT `Service`, `CPU usage`, `Memory usage`
FROM
(
    -- Header line when showing data for all hosts
    SELECT
        -1 AS _sort,
        'Showing services and data for all hosts. Select a specific host above in the select near the top of the page.' AS `Service`,
        0 AS `CPU usage`,
        0 AS `Memory usage`
    FROM hosts_count
    WHERE cnt > 1

    UNION ALL

    -- Normal data rows
    SELECT
        0 AS _sort,
        `Service`,
        `CPU usage`,
        `Memory usage`
    FROM main
    WHERE (SELECT c FROM has_rows) > 0
)
ORDER BY _sort, isNull(`CPU usage`) ASC, `CPU usage` DESC
FORMAT JSONEachRowWithProgress
SETTINGS max_result_rows = 500000
