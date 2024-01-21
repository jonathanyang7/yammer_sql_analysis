-- Exam Q: What drove the fall in user engagement over the period 2014-07-28 to 2014-08-04 


-- 1. Is this driven by active users or new users?

-- 1a. Did the number of created and activated accounts change over the period?
SELECT
  DATE_TRUNC('day', created_at) AS Date,
  COUNT(DISTINCT created_at) AS Created,
  COUNT(DISTINCT activated_at) AS Activated
FROM tutorial.yammer_users
WHERE created_at BETWEEN '2014-07-01' AND '2014-08-10'
GROUP BY Date 

-- 1b. Did the number of active users change over the period?
SELECT DATE_TRUNC('week',occurred_at) AS Week,
  COUNT(DISTINCT CASE WHEN event_type = 'engagement' THEN user_id END) AS Active_Users
FROM tutorial.yammer_events
WHERE occurred_at <= '2014-08-31'
GROUP BY Week

  
-- 2. Is the decline due to current users within a particular subset of companies?
SELECT
  DATE_TRUNC('week', occurred_at) AS Week,
  companies.company_id,
  COUNT(DISTINCT events.user_id) AS No_Users
FROM tutorial.yammer_events events
  JOIN (
    SELECT
      user_id,
      company_id
    FROM tutorial.yammer_users
    WHERE state = 'active'
  ) AS companies ON companies.user_id = events.user_id
WHERE e.event_type = 'engagement' AND e.event_name = 'login' AND e.occurred_at <= '2014-08-10'
GROUP BY Week, companies.company_id
HAVING COUNT(DISTINCT events.user_id) > 1 -- omitting one user companies

  
-- 3. Is the decline due to current users in a particular geography?
SELECT
  DATE_TRUNC('week', occurred_at) AS Week,
  COUNT(DISTINCT CASE WHEN location IN (
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
      ) THEN user_id END) AS Asia,
  COUNT(DISTINCT CASE WHEN location IN (
        'Venezuela',
        'Colombia',
        'Argentina',
        'Chile',
        'Brazil'
      ) THEN user_id END) AS South_America,
  COUNT(DISTINCT CASE WHEN location IN (
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
      ) THEN user_id END) AS Europe,
  COUNT(DISTINCT CASE WHEN location IN ('United States', 'Canada', 'Mexico') THEN user_id END) AS North_America,
  COUNT(DISTINCT CASE WHEN location IN ('Nigeria', 'Egypt', 'South Africa') THEN user_id END) AS Africa,
  COUNT(DISTINCT CASE WHEN location = 'Australia' THEN user_id END) AS Australia
FROM tutorial.yammer_events
WHERE occurred_at BETWEEN '2014-07-01' AND '2014-08-10'
GROUP BY Week 
  

-- 4a. Is the decline due to current users of a particular device?
SELECT
  DATE_TRUNC('week', occurred_at) AS Week,
  COUNT(DISTINCT CASE WHEN device IN (
          'dell inspiron desktop',
          'acer aspire desktop',
          'hp pavilion desktop'
        ) THEN user_id END) AS Desktop,
  COUNT(DISTINCT CASE WHEN device IN (
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
        ) THEN user_id END) AS Phone,
  COUNT(DISTINCT CASE WHEN device NOT IN (
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
        ) THEN user_id END) AS Laptop
FROM tutorial.yammer_events
WHERE occurred_at BETWEEN '2014-07-01' AND '2014-08-10'
GROUP BY Week

  
-- 4b. Are the mobile problems localised to iOS or Android devices?
SELECT DATE_TRUNC('week', occurred_at) AS Week,
COUNT (DISTINCT CASE WHEN device IN (
          'amazon fire phone', 
          'nexus 10',
          'samsumg galaxy tablet',
          'nexus 7',
          'kindle fire',
          'nexus 5',
          'htc one',
          'samsung galaxy note',
          'nokia lumia 635',
          'samsung galaxy s4') THEN user_id END) AS Android_Devices,
COUNT (DISTINCT CASE WHEN device IN ('ipad mini', 'iphone 5', 'iphone 5s', 'iphone 4s', 'ipad air') THEN user_id END) AS iOS_Devices
FROM tutorial.yammer_events
WHERE occurred_at BETWEEN '2014-07-01' AND '2014-08-10'
GROUP BY Week


-- 5. How does cohort age affect the usage of Yammer?
SELECT
  DATE_TRUNC('week', e.occurred_at) AS Week,
  cohort.Cohort,
  COUNT(DISTINCT e.user_id) AS Active_Accounts
FROM tutorial.yammer_events e
  JOIN (
    SELECT
      user_id,
      MIN((DATE('2014-09-01') - DATE(activated_at)) / (365 / 12)) AS Cohort
    FROM tutorial.yammer_users
    WHERE state = 'active'
    GROUP BY user_id
  ) AS cohort ON cohort.user_id = e.user_id
WHERE e.event_type = 'engagement' AND e.event_name = 'login' AND e.occurred_at BETWEEN '2014-01-01' AND '2014-09-01'
GROUP BY Week, cohort.Cohort 

  
-- 6. Why is engagement for long-term users bad?
SELECT
  DATE_TRUNC('week', occurred_at) AS Week,
  COUNT(DISTINCT CASE WHEN ACTION = 'sent_weekly_digest' THEN user_id END) AS Sent_Weekly_Digest,
  COUNT(DISTINCT CASE WHEN ACTION = 'sent_reengagement_email' THEN user_id END) AS Sent_Reengage_Email,
  COUNT(DISTINCT CASE WHEN ACTION = 'email_open' THEN user_id END) AS Open,
  COUNT(DISTINCT CASE WHEN ACTION = 'email_clickthrough' THEN user_id END) AS Click_Through
FROM tutorial.yammer_emails
GROUP BY Week
