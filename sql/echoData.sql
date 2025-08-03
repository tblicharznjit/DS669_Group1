CREATE TABLE echoData AS
SELECT ROW_ID
  , subject_id, hadm_id
  , chartdate
  , CASE 
      WHEN ne.text REGEXP 'Date/Time: \\[\\*\\*[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}\\*\\*\\] at [0-9]{1,2}:[0-9]{2}'
      THEN 
        CASE 
          WHEN REGEXP_REPLACE(ne.text, '.*Date/Time: \\[\\*\\*([0-9]{4}-[0-9]{1,2}-[0-9]{1,2})\\*\\*\\] at ([0-9]{1,2}:[0-9]{2}).*', '\\1 \\2:00') REGEXP '^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{2}:[0-9]{2}$'
          THEN STR_TO_DATE(
            REGEXP_REPLACE(ne.text, '.*Date/Time: \\[\\*\\*([0-9]{4}-[0-9]{1,2}-[0-9]{1,2})\\*\\*\\] at ([0-9]{1,2}:[0-9]{2}).*', '\\1 \\2:00'),
            '%Y-%m-%d %H:%i:%s'
          )
          ELSE DATE_ADD(chartdate, INTERVAL 12 HOUR)
        END
      ELSE DATE_ADD(chartdate, INTERVAL 12 HOUR)
    END AS charttime
  , CASE 
      WHEN ne.text REGEXP '.*Indication: ([^\\n\\r]+).*' 
      THEN REGEXP_REPLACE(ne.text, '.*Indication: ([^\\n\\r]+).*', '\\1') 
      ELSE NULL 
    END as Indication
  , CASE 
      WHEN ne.text REGEXP '.*Height: \\(in\\) ([0-9]+).*' 
      THEN CAST(REGEXP_REPLACE(ne.text, '.*Height: \\(in\\) ([0-9]+).*', '\\1') as DECIMAL(10,2)) 
      ELSE NULL 
    END as Height
  , CASE 
      WHEN ne.text REGEXP '.*Weight \\(lb\\): ([0-9]+).*' 
      THEN CAST(REGEXP_REPLACE(ne.text, '.*Weight \\(lb\\): ([0-9]+).*', '\\1') as DECIMAL(10,2)) 
      ELSE NULL 
    END as Weight
  , CASE 
      WHEN ne.text REGEXP '.*BSA \\(m2\\): ([0-9\\.]+).*' 
      THEN CAST(REGEXP_REPLACE(ne.text, '.*BSA \\(m2\\): ([0-9\\.]+).*', '\\1') as DECIMAL(10,2)) 
      ELSE NULL 
    END as BSA 
  , CASE 
      WHEN ne.text REGEXP '.*BP \\(mm Hg\\): ([^\\n\\r]+).*' 
      THEN REGEXP_REPLACE(ne.text, '.*BP \\(mm Hg\\): ([^\\n\\r]+).*', '\\1') 
      ELSE NULL 
    END as BP 
  , CASE 
      WHEN ne.text REGEXP '.*BP \\(mm Hg\\): ([0-9]+)/[0-9]+.*' 
      THEN CAST(REGEXP_REPLACE(ne.text, '.*BP \\(mm Hg\\): ([0-9]+)/[0-9]+.*', '\\1') as DECIMAL(10,2)) 
      ELSE NULL 
    END as BPSys 
  , CASE 
      WHEN ne.text REGEXP '.*BP \\(mm Hg\\): [0-9]+/([0-9]+).*' 
      THEN CAST(REGEXP_REPLACE(ne.text, '.*BP \\(mm Hg\\): [0-9]+/([0-9]+).*', '\\1') as DECIMAL(10,2)) 
      ELSE NULL 
    END as BPDias 
  , CASE 
      WHEN ne.text REGEXP '.*HR \\(bpm\\): ([0-9]+).*' 
      THEN CAST(REGEXP_REPLACE(ne.text, '.*HR \\(bpm\\): ([0-9]+).*', '\\1') as DECIMAL(10,2)) 
      ELSE NULL 
    END as HR
  , CASE 
      WHEN ne.text REGEXP '.*Status: ([^\\n\\r]+).*' 
      THEN REGEXP_REPLACE(ne.text, '.*Status: ([^\\n\\r]+).*', '\\1') 
      ELSE NULL 
    END as Status
  , CASE 
      WHEN ne.text REGEXP '.*Test: ([^\\n\\r]+).*' 
      THEN REGEXP_REPLACE(ne.text, '.*Test: ([^\\n\\r]+).*', '\\1') 
      ELSE NULL 
    END as Test
  , CASE 
      WHEN ne.text REGEXP '.*Doppler: ([^\\n\\r]+).*' 
      THEN REGEXP_REPLACE(ne.text, '.*Doppler: ([^\\n\\r]+).*', '\\1') 
      ELSE NULL 
    END as Doppler
  , CASE 
      WHEN ne.text REGEXP '.*Contrast: ([^\\n\\r]+).*' 
      THEN REGEXP_REPLACE(ne.text, '.*Contrast: ([^\\n\\r]+).*', '\\1') 
      ELSE NULL 
    END as Contrast
  , CASE 
      WHEN ne.text REGEXP '.*Technical Quality: ([^\\n\\r]+).*' 
      THEN REGEXP_REPLACE(ne.text, '.*Technical Quality: ([^\\n\\r]+).*', '\\1') 
      ELSE NULL 
    END as TechnicalQuality
FROM noteevents ne
WHERE category = 'Echo';