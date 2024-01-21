-- Exam Q: Should the engineering team work on the search function, and if so, how should they modify it?


-- 1. What percentage of sessions are the search functionality and auto-search features used?
SELECT date_trunc('week', session_start) as Week, 
  COUNT(CASE WHEN auto > 0 THEN session_id ELSE NULL END) * 100 / COUNT(*) as autocomplete,
  COUNT(CASE WHEN search > 0  THEN session_id ELSE NULL END) * 100 / COUNT(*)as search
FROM
  (
  SELECT session_id, session_start, COUNT(CASE WHEN event_name = 'search_autocomplete' THEN user_id ELSE NULL END) AS auto,
    COUNT(CASE WHEN event_name = 'search_run' THEN user_id ELSE NULL END) AS search
  FROM
    (
      SELECT e.user_id, e.occurred_at, e.event_type, e.event_name, session.session_id, session.session_start
      FROM tutorial.yammer_events e
      JOIN 
        (
          SELECT user_id, session_id, MIN(occurred_at) AS session_start, MAX(occurred_at) AS session_end
          FROM 
            (
              SELECT user_id, occurred_at,
                (CASE WHEN since_last <= INTERVAL '10 minutes' THEN LAG(id) OVER (PARTITION BY user_id ORDER BY occurred_at) ELSE id END) AS session_id
              FROM 
                (
                  SELECT user_id, occurred_at, row_number() over () AS id,
                    occurred_at - LAG(occurred_at ,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS since_last,
                    LEAD(occurred_at, 1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS till_next
                  FROM tutorial.yammer_events 
                  WHERE event_type = 'engagement'
                ) events_before_after
              WHERE since_last IS NULL OR since_last >= INTERVAL '10 minutes' OR till_next >= interval '10 minutes' OR till_next IS NULL
            ) sessions_start_end
          GROUP BY user_id, session_id
        ) session
      ON (session.user_id = e.user_id  AND e.occurred_at >= session.session_start AND e.occurred_at <= session.session_end)
      WHERE e.event_type = 'engagement'
    ) event_session
    GROUP BY session_id, session_start
  ) search_events_only
GROUP BY Week
  
  
-- 2. Within a session, how often is the search functionality used?
SELECT num_search_runs, COUNT(*) AS num_sessions
FROM 
  (
      SELECT session_id, COUNT(CASE WHEN event_name = 'search_run' THEN 1 ELSE NULL END) AS num_search_runs
      FROM tutorial.yammer_events e
      JOIN 
        (
          SELECT user_id, session_id, MIN(occurred_at) AS session_start, MAX(occurred_at) AS session_end
          FROM 
            (
              SELECT user_id, occurred_at,
                (CASE WHEN since_last <= INTERVAL '10 minutes' THEN LAG(id) OVER (PARTITION BY user_id ORDER BY occurred_at) ELSE id END) AS session_id
              FROM 
                (
                  SELECT user_id, occurred_at, row_number() over () AS id,
                    occurred_at - LAG(occurred_at ,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS since_last,
                    LEAD(occurred_at, 1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS till_next
                  FROM tutorial.yammer_events 
                  WHERE event_type = 'engagement'
                ) events_before_after
              WHERE since_last IS NULL OR since_last >= INTERVAL '10 minutes' OR till_next >= interval '10 minutes' OR till_next IS NULL
            ) sessions_start_end
          GROUP BY user_id, session_id
        ) session
      ON (session.user_id = e.user_id  AND e.occurred_at >= session.session_start AND e.occurred_at <= session.session_end)
      WHERE e.event_type = 'engagement'
      GROUP BY session_id 
  ) session_searches
WHERE num_search_runs > 0
GROUP BY num_search_runs


-- 3. For the users that started a search run, how often do they click the results?
SELECT 
  SUM(CASE WHEN click_results_in_session = 0 THEN number_of_sessions END) AS Did_not_click,
  SUM(CASE WHEN click_results_in_session > 0 THEN number_of_sessions END) AS Did_click
FROM 
  (
    SELECT click_results_in_session, COUNT(*) AS number_of_sessions
    FROM
      (
        SELECT events.user_id, sessions.session_id,
          COUNT(CASE WHEN event_name = 'search_run' THEN 1 ELSE NULL END) AS searches_in_session,
          COUNT(CASE WHEN event_name ILIKE 'search\_click\_result\__' THEN 1 ELSE NULL END) AS click_results_in_session
        FROM tutorial.yammer_events events
        JOIN 
          (
            SELECT user_id, session_id, MAX(occurred_at) AS session_end, MIN(occurred_at) AS session_start
            FROM
              (
                SELECT user_id, 
                CASE WHEN time_since_last <= INTERVAL '10 minutes' THEN LAG(id) OVER (PARTITION BY user_id ORDER BY occurred_at) ELSE id END AS session_id,
                time_since_last,
                time_till_next,
                occurred_at
                FROM 
                  (
                    SELECT user_id, occurred_at, ROW_NUMBER() OVER () AS id,
                      occurred_at - LAG(occurred_at, 1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS time_since_last,
                      LEAD(occurred_at, 1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS time_till_next
                    FROM tutorial.yammer_events 
                    WHERE event_type = 'engagement'
                  ) session_time_differences
                WHERE time_since_last >= INTERVAL '10 minutes' OR time_since_last IS NULL OR time_till_next >= INTERVAL '10 minutes' OR time_till_next IS NULL
                ORDER BY user_id, session_id
              ) sessions_start_end
            GROUP BY user_id, session_id
          ) sessions 
        ON sessions.user_id = events.user_id AND events.occurred_at >= sessions.session_start AND events.occurred_at <= sessions.session_end 
        WHERE events.event_type = 'engagement'
        GROUP BY events.user_id, sessions.session_id
      ) search_and_clicks
    WHERE searches_in_session > 0
    GROUP BY click_results_in_session
  ) click_results

-- 4. When a result is clicked, which position does it sit?
SELECT 
  SUM(click_1) AS first_result,
  SUM(click_2) AS second_result,
  SUM(click_3) AS third_result,
  SUM(click_4) AS fourth_result,
  SUM(click_5) AS fifth_result,
  SUM(click_6) AS sixth_result,
  SUM(click_7) AS seventh_result,
  SUM(click_8) AS eighth_result,
  SUM(click_9) AS ninth_result,
  SUM(click_10) AS tenth_result
FROM 
  (
    SELECT session_id, session_start, 
    COUNT(DISTINCT CASE WHEN event_name = 'search_run' THEN user_id END) AS Search_run,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_1' THEN user_id END) AS Click_1,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_2' THEN user_id END) AS Click_2,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_3' THEN user_id END) AS Click_3,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_4' THEN user_id END) AS Click_4,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_5' THEN user_id END) AS Click_5,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_6' THEN user_id END) AS Click_6,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_7' THEN user_id END) AS Click_7,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_8' THEN user_id END) AS Click_8,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_9' THEN user_id END) AS Click_9,
    COUNT(DISTINCT CASE WHEN event_name = 'search_click_result_10' THEN user_id END) AS Click_10
  FROM
    (
      SELECT e.user_id, e.occurred_at, e.event_type, e.event_name, session.session_id, session.session_start
      FROM tutorial.yammer_events e
      JOIN 
        (
          SELECT user_id, session_id, MIN(occurred_at) AS session_start, MAX(occurred_at) AS session_end
          FROM 
            (
              SELECT user_id, occurred_at,
                (CASE WHEN since_last <= INTERVAL '10 minutes' THEN LAG(id) OVER (PARTITION BY user_id ORDER BY occurred_at) ELSE id END) AS session_id
              FROM 
                (
                  SELECT user_id, occurred_at, row_number() over () AS id,
                    occurred_at - LAG(occurred_at ,1) OVER (PARTITION BY user_id ORDER BY occurred_at) AS since_last,
                    LEAD(occurred_at, 1) OVER (PARTITION BY user_id ORDER BY occurred_at) - occurred_at AS till_next
                  FROM tutorial.yammer_events 
                  WHERE event_type = 'engagement'
                ) events_before_after
              WHERE since_last IS NULL OR since_last >= INTERVAL '10 minutes' OR till_next >= interval '10 minutes' OR till_next IS NULL
            ) sessions_start_end
          GROUP BY user_id, session_id
        ) session
      ON (session.user_id = e.user_id  AND e.occurred_at >= session.session_start AND e.occurred_at <= session.session_end)
      WHERE e.event_type = 'engagement'
    ) event_session
    GROUP BY session_id, session_start
  ) search_accuracy
