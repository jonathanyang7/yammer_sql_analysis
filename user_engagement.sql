-- Exam Q: What drove the fall in user engagement over the period 2014-07-28 to 2014-08-04 
-- 1. Is this driven by active users or new users?
SELECT
  DATE_TRUNC('day', created_at) AS Date,
  COUNT(DISTINCT(created_at)) AS Created_Accounts,
  COUNT(DISTINCT(activated_at)) AS Activated_Accounts
FROM tutorial.yammer_users
WHERE created_at BETWEEN '2014-07-01' AND '2014-09-01'
GROUP BY Date 


-- 2. Driven by a certain company?
SELECT
  DATE_TRUNC('week', occurred_at) AS Date,
  c.company_id,
  COUNT(DISTINCT(e.user_id)) AS No_Users
FROM tutorial.yammer_events e
  JOIN (
    SELECT
      user_id,
      company_id
    FROM tutorial.yammer_users
    WHERE state = 'active'
  ) AS c ON c.user_id = e.user_id
WHERE e.event_type = 'engagement' AND e.event_name = 'login' AND e.occurred_at >= '2014-01-01'
GROUP BY Date, c.company_id
HAVING COUNT(DISTINCT(e.user_id)) > 1 
  

-- 3. Did a cohort of users stop using Yammer?
SELECT
  DATE_TRUNC('week', e.occurred_at) AS Date,
  c.Cohort,
  COUNT(DISTINCT(e.user_id)) AS Active_Accounts
FROM tutorial.yammer_events e
  JOIN (
    SELECT
      user_id,
      MIN((DATE('2014-08-04') - DATE(activated_at)) / (365 / 12)) AS Cohort
    FROM tutorial.yammer_users
    WHERE state = 'active' AND created_at >= '2014-01-01'
    GROUP BY user_id
  ) AS c ON c.user_id = e.user_id
WHERE
  e.event_type = 'engagement'
  AND e.event_name = 'login'
  AND e.occurred_at >= '2014-01-01'
GROUP BY Date, c.Cohort
  

-- 4. Are the users concentrated in a certain country?
SELECT
  DATE_TRUNC('week', occurred_at) AS Date,
  COUNT(
    DISTINCT CASE
      WHEN location IN (
        'Indonesia',
        'Korea',
        'Singapore',
        'Saudi Arabia',
        'Israel',
        'Malaysia',
        'Hong Kong',
        'Philippines',
        'Turkey',
        'United Arab Emirates',
        'Taiwan',
        'Thailand',
        'India',
        'Iran',
        'Japan',
        'Iraq',
        'Russia',
        'Pakistan'
      ) THEN user_id
    END
  ) AS Asia,
  COUNT(
    DISTINCT CASE
      WHEN location IN (
        'Venezuela',
        'Colombia',
        'Argentina',
        'Chile',
        'Brazil'
      ) THEN user_id
    END
  ) AS South_America,
  COUNT(
    DISTINCT CASE
      WHEN location IN (
        'Sweden',
        'Ireland',
        'Portugal',
        'Finland',
        'France',
        'Netherlands',
        'Spain',
        'Belgium',
        'Italy',
        'United Kingdom',
        'Germany',
        'Greece',
        'Denmark',
        'Switzerland',
        'Norway',
        'Austria',
        'Poland'
      ) THEN user_id
    END
  ) AS Europe,
  COUNT(DISTINCT CASE WHEN location IN ('United States', 'Canada', 'Mexico') THEN user_id END) AS North_America,
  COUNT(DISTINCT CASE WHEN location IN ('Nigeria', 'Egypt', 'South Africa') THEN user_id END) AS Africa,
  COUNT(DISTINCT CASE WHEN location = 'Australia' THEN user_id END) AS Australia
FROM tutorial.yammer_events
WHERE occurred_at >= '2014-01-01'
GROUP BY Date 
  

-- 5. Do the users use the same type of device?
SELECT
  DATE_TRUNC('week', occurred_at) AS Date,
  COUNT(
    DISTINCT(
      CASE
        WHEN device IN (
          'dell inspiron desktop',
          'acer aspire desktop',
          'hp pavilion desktop'
        ) THEN user_id
      END
    )
  ) AS Desktop,
  COUNT(
    DISTINCT(
      CASE
        WHEN device IN (
          'amazon fire phone',
          'nexus 10',
          'ipad mini',
          'samsumg galaxy tablet',
          'iphone 5',
          'nexus 7',
          'kindle fire',
          'iphone 5s',
          'nexus 5',
          'htc one',
          'iphone 4s',
          'samsung galaxy note',
          'nokia lumia 635',
          'ipad air',
          'samsung galaxy s4'
        ) THEN user_id
      END
    )
  ) AS Phone,
  COUNT(
    DISTINCT(
      CASE
        WHEN device NOT IN (
          'dell inspiron desktop',
          'acer aspire desktop',
          'hp pavilion desktop',
          'amazon fire phone',
          'nexus 10',
          'ipad mini',
          'samsumg galaxy tablet',
          'iphone 5',
          'nexus 7',
          'kindle fire',
          'iphone 5s',
          'nexus 5',
          'htc one',
          'iphone 4s',
          'samsung galaxy note',
          'nokia lumia 635',
          'ipad air',
          'samsung galaxy s4'
        ) THEN user_id
      END
    )
  ) AS Laptop
FROM tutorial.yammer_events
WHERE occurred_at >= '2014-01-01'
GROUP BY Date
  

-- 6. Why is engagement for long-term users bad?
SELECT
  DATE_TRUNC('week', occurred_at) AS Date,
  COUNT(DISTINCT(CASE WHEN ACTION = 'sent_weekly_digest' THEN user_id END)) AS Sent_Weekly_Digest,
  COUNT(DISTINCT(CASE WHEN ACTION = 'sent_reengagement_email' THEN user_id END)) AS Sent_Reengage_Email,
  COUNT(DISTINCT(CASE WHEN ACTION = 'email_open' THEN user_id END)) AS OPEN,
  COUNT(DISTINCT(CASE WHEN ACTION = 'email_clickthrough' THEN user_id END)) AS Click_Through
FROM tutorial.yammer_emails
GROUP BY Date

