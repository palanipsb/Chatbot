DROP VIEW COMMENTS_GROUPS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW COMMENTS_GROUPS
(
   GROUP_ID,
   GROUP_NAME
)
AS
   SELECT "GROUP_ID", "GROUP_NAME" FROM QUERY_GROUPS;


DROP VIEW COMMENTS_GROUP_MEMBERS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW COMMENTS_GROUP_MEMBERS
(
   WRK_ID,
   GROUP_ID,
   CAN_UPDATE,
   DEFAULT_GROUP
)
AS
   SELECT "WRK_ID",
          "GROUP_ID",
          "CAN_UPDATE",
          "DEFAULT_GROUP"
     FROM QUERY_GROUP_MEMBERS
    WHERE can_update = 1 AND default_group = 1;


DROP VIEW DRUG_STATUS_FOR_EXPIRATION;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW DRUG_STATUS_FOR_EXPIRATION
(
   ID,
   NAME,
   SUBCLASS,
   LOCATION_TYPE,
   MODIFIED,
   MODIFIED_AT,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP
)
AS
   SELECT "ID",
          "NAME",
          "SUBCLASS",
          "LOCATION_TYPE",
          "MODIFIED",
          "MODIFIED_AT",
          "CREATED_BY_USER",
          "CREATED_TIMESTAMP",
          "MODIFIED_BY_USER",
          "MODIFIED_TIMESTAMP"
     FROM DRUG_STATUS
    WHERE id IN
             ('KitStatus_ONSTOCK',
              'KitStatus_ORDERED',
              'KitStatus_SENT',
              'KitStatus_RECEIVED',
              'KitStatus_EXPIRING_SOON');


DROP VIEW FIELD_COUNT;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW FIELD_COUNT
(
   FORM,
   MODULE,
   LOOP_NAME,
   FIELDS
)
AS
   SELECT f.form,
          f.module,
          NULL AS loop_name,
          (SELECT COUNT (*)
             FROM FIELD_DESCR
            WHERE form = f.form AND module IS NULL AND loop_name IS NULL)
             AS fields
     FROM FIELD_DESCR f
    WHERE f.module IS NULL AND f.loop_name IS NULL
   UNION
   SELECT f.form,
          f.module,
          f.loop_name,
          (SELECT COUNT (*)
             FROM FIELD_DESCR
            WHERE     form = f.form
                  AND module IS NULL
                  AND loop_name = f.loop_name)
             AS fields
     FROM FIELD_DESCR f
    WHERE f.module IS NULL AND f.loop_name IS NOT NULL
   UNION
   SELECT f.form,
          f.module,
          NULL AS loop_name,
          (SELECT COUNT (*)
             FROM FIELD_DESCR
            WHERE form = f.form AND module = f.module AND loop_name IS NULL)
             AS fields
     FROM FIELD_DESCR f
    WHERE f.module IS NOT NULL AND f.loop_name IS NULL
   UNION
   SELECT f.form,
          f.module,
          f.loop_name,
          (SELECT COUNT (*)
             FROM FIELD_DESCR
            WHERE     form = f.form
                  AND module = f.module
                  AND loop_name = f.loop_name)
             AS fields
     FROM FIELD_DESCR f
    WHERE f.module IS NOT NULL AND f.loop_name IS NOT NULL
   ORDER BY form, module, loop_name;


DROP VIEW FIELD_COUNT2;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW FIELD_COUNT2
(
   PAT_ID,
   FORM,
   PAGE,
   MODULE,
   LOOP_NAME,
   FIELDS1,
   FIELDS2
)
AS
     SELECT DISTINCT
            pat_id,
            f.form,
            page,
            f.module,
            f.loop_name,
            (SELECT CASE
                       WHEN MAX (counter) IS NULL THEN c.fields
                       ELSE c.fields * (1 + MAX (counter))
                    END
               FROM data
              WHERE     pat_id = u.pat_id
                    AND form = f.form
                    AND page = u.page
                    AND field IN
                           (SELECT field
                              FROM field_descr
                             WHERE     (   (module IS NULL AND f.module IS NULL)
                                        OR module = f.module)
                                   AND (   (    loop_name IS NULL
                                            AND f.loop_name IS NULL)
                                        OR loop_name = f.loop_name)
                                   AND form = f.form))
               AS fields1,
            (SELECT COUNT (*)
               FROM data
              WHERE     pat_id = u.pat_id
                    AND form = u.form
                    AND page = u.page
                    AND field IN
                           (SELECT field
                              FROM field_descr
                             WHERE     (   (module IS NULL AND f.module IS NULL)
                                        OR module = f.module)
                                   AND (   (    loop_name IS NULL
                                            AND f.loop_name IS NULL)
                                        OR loop_name = f.loop_name)
                                   AND form = f.form))
               AS fields2
       FROM data u, field_descr f, FIELD_COUNT c
      WHERE     u.form(+) = F.FORM
            AND f.form = c.form
            AND (   (f.module IS NULL AND c.module IS NULL)
                 OR f.module = c.module)
            AND (   (f.loop_name IS NULL AND c.loop_name IS NULL)
                 OR f.loop_name = c.loop_name)
   ORDER BY pat_id,
            form,
            page,
            module;


DROP VIEW FIELD_VALUE_LABELS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW FIELD_VALUE_LABELS
(
   ID,
   FIELD,
   FORM,
   VALUE,
   LABEL
)
AS
   SELECT f.ID,
          f.FIELD,
          f.FORM,
          DECODE (f.LABEL, NULL, s.VALUE, f.VALUE) AS VALUE,
          DECODE (f.LABEL, NULL, s.LABEL, f.LABEL) AS LABEL
     FROM FIELD_VALLAB f LEFT JOIN VAL_SETS s ON f.VALUE = s.VAL_SET;


DROP VIEW FIELD_VALUE_LABELS_TEXT;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW FIELD_VALUE_LABELS_TEXT
(
   FIELD,
   FORM,
   VALUE,
   LABEL,
   LABELTEXT
)
AS
   SELECT fvl."FIELD",
          fvl."FORM",
          fvl."VALUE",
          fvl."LABEL",
          (SELECT DISTINCT str.en
             FROM strings str
            WHERE REPLACE (fvl.label, '#', '') = str.str_id)
             AS labeltext
     FROM (SELECT f.field,
                  f.form,
                  DECODE (f.label, NULL, s.VALUE, f.VALUE) AS VALUE,
                  DECODE (f.label, NULL, s.label, f.label) AS label
             FROM field_vallab f, val_sets s
            WHERE f.VALUE = s.val_set(+)) fvl;


DROP VIEW SPT_SI_RECIPIENT;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW SPT_SI_RECIPIENT
(
   EVENT,
   EMAIL
)
AS
   SELECT event, email FROM SI_RECIPIENT;


DROP VIEW VIEW_DEMO_PATIENT;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW VIEW_DEMO_PATIENT
(
   PAT_ID,
   DEMO
)
AS
   SELECT p.pat_id, s.demo
     FROM ADM_ICRF4_IF.sites s, USR_PAT p
    WHERE p.sit_id = s.sit_id;


DROP VIEW VIEW_SESSIONS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW VIEW_SESSIONS
(
   WRK_ID,
   SESSION_ID,
   LOGGED_IN,
   LOGGED_OUT,
   LOGOUT_REASON,
   HOW_LONG
)
AS
   SELECT login.wrk_id,
          login.session_id,
          login.action_date AS logged_in,
          LOGOUT.action_date AS logged_out,
          LOGOUT.reason AS logout_reason,
          (LOGOUT.action_date - login.action_date) * 1440 AS how_long
     FROM (SELECT *
             FROM LOGINS
            WHERE action = 'login') login,
          (SELECT *
             FROM LOGINS
            WHERE action = 'logout') LOGOUT
    WHERE login.session_id = LOGOUT.session_id;


DROP VIEW VIEW_USERS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW VIEW_USERS
(
   WEBAPP,
   WRK_ID,
   CENTER,
   SIT_ID,
   DEMO,
   CENTER_DISABLED,
   WORKER_DISABLED,
   ROL_ID,
   LANG_ID,
   FNAME,
   LNAME,
   CITY,
   ZIP,
   CNTRY_ID,
   ORG_ID,
   PHONE,
   MPHONE,
   FAX,
   EMAIL,
   TIME_DIF,
   MI_FNAME,
   MI_LNAME,
   MI_CITY,
   MI_ZIP,
   MI_CNTRY_ID,
   MI_ORG_ID,
   MI_PHONE,
   MI_MPHONE,
   MI_FAX,
   MI_EMAIL,
   MI_TIME_DIF
)
AS
     SELECT w.webapp,
            w.wrk_id,
            s1.site,
            s1.sit_id,
            s2.demo,
            s2.disabled,
            w.disabled,
            w.rol_id,
            w.lang_id,
            u.fname,
            u.lname,
            u.CITY,
            u.ZIP,
            u.CNTRY_ID,
            u.ORG_ID,
            u.PHONE,
            u.MPHONE,
            u.FAX,
            u.EMAIL,
            u.TIME_DIFF_HOUR,
            u2.fname,
            u2.lname,
            u2.CITY,
            u2.ZIP,
            u2.CNTRY_ID,
            u2.ORG_ID,
            u2.PHONE,
            u2.MPHONE,
            u2.FAX,
            u2.EMAIL,
            u2.TIME_DIFF_HOUR
       FROM ADM_ICRF4_IF.workers w,
            ADM_ICRF4_IF.users u,
            ADM_ICRF4_IF.workers w2,
            ADM_ICRF4_IF.users u2,
            ADM_ICRF4_IF.sites s1,
            ADM_ICRF4_IF.sites s2
      WHERE     w.usr_id = u.usr_id
            AND w.sit_id = s1.sit_id(+)
            AND s1.mwrk_id(+) IS NOT NULL
            AND w2.wrk_id = s1.mwrk_id
            AND w2.usr_id = u2.usr_id
            AND w.sit_id = s2.sit_id
            AND w.webapp = 'P90020903'
   ORDER BY s1.SITE;


DROP VIEW VIEW_USR_BLOCKS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW VIEW_USR_BLOCKS
(
   CENTER,
   SIT_ID,
   DEMO,
   DISABLED,
   BLOCK_NO,
   DEMO_BLOCK
)
AS
     SELECT s.site,
            s.sit_id,
            s.demo,
            s.disabled,
            b.block_no,
            b.demo
       FROM usr_blocks b, ADM_ICRF4_IF.sites s
      WHERE     s.SIT_ID = b.SIT_ID
            AND s.sit_id IN (SELECT sit_id
                               FROM ADM_ICRF4_IF.workers w
                              WHERE w.webapp = 'P90020903')
   ORDER BY s.SITE, b.block_no;


DROP VIEW VIEW_USR_NUMBERS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW VIEW_USR_NUMBERS
(
   CENTER,
   SIT_ID,
   DEMO,
   DISABLED,
   BLOCK_NO,
   DEMO_BLOCK,
   PAT_NO,
   TREATMENT_GROUP,
   IN_USE
)
AS
     SELECT s.site,
            s.sit_id,
            s.demo,
            s.disabled,
            b.block_no,
            b.demo,
            n.pat_no,
            n.TREATMENT_GROUP,
            n.in_use
       FROM usr_blocks b, numbers n, ADM_ICRF4_IF.sites s
      WHERE     s.SIT_ID = b.SIT_ID
            AND b.block_no = n.block_no
            AND s.sit_id IN (SELECT sit_id
                               FROM ADM_ICRF4_IF.workers w
                              WHERE w.webapp = 'P90020903')
   ORDER BY s.SITE, b.block_no, n.pat_no;


DROP VIEW VIEW_ZOMBIE_SESSIONS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW VIEW_ZOMBIE_SESSIONS
(
   WRK_ID,
   SESSION_ID,
   ACTION,
   ACTION_DATE
)
AS
   SELECT wrk_id,
          session_id,
          action,
          action_date
     FROM LOGINS
    WHERE session_id NOT IN (SELECT session_id FROM VIEW_SESSIONS);


DROP VIEW V_AGE;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_AGE
(
   PAT_ID,
   AGE
)
AS
   SELECT pat_id AS pat_id, VALUE AS age
     FROM data
    WHERE     field = 'AGE'
          AND 1 = (SELECT VALUE
                     FROM setting_values
                    WHERE setting_id = 'AGE_VIEW')
   UNION ALL
   SELECT pat_id AS pat_id, VALUE AS age
     FROM data
    WHERE     field = 'AGE_CALC'
          AND 0 = (SELECT VALUE
                     FROM setting_values
                    WHERE setting_id = 'AGE_VIEW');


DROP VIEW V_DEL_VISITS;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DEL_VISITS
(
   ID,
   PAT_ID,
   FORM,
   FIELD,
   VALUE
)
AS
     SELECT pk.data_id,
            pat.pat_id,
            TO_NUMBER (fo.form) form,
            vd.field,
            val.VALUE
       FROM (SELECT primary_key, old_value field
               FROM audit_trail
              WHERE     column_name = 'FIELD'
                    AND old_value IN ('VISDAY', 'VISYEA', 'VISMON')
                    AND table_name = 'DATA'
                    AND operation = 'd') vd,
            (SELECT primary_key, old_value VALUE
               FROM audit_trail
              WHERE     column_name = 'VALUE'
                    AND table_name = 'DATA'
                    AND operation = 'd') val,
            (SELECT primary_key data_id
               FROM audit_trail
              WHERE     table_name = 'DATA'
                    AND column_name = 'ID'
                    AND operation = 'd') pk,
            (SELECT primary_key, old_value pat_id
               FROM audit_trail
              WHERE     table_name = 'DATA'
                    AND column_name = 'PAT_ID'
                    AND operation = 'd') pat,
            (SELECT primary_key, old_value form
               FROM audit_trail
              WHERE     column_name = 'FORM'
                    AND table_name = 'DATA'
                    AND operation = 'd') fo
      WHERE     vd.primary_key = val.primary_key
            AND vd.primary_key = pk.data_id
            AND vd.primary_key = fo.primary_key
            AND vd.primary_key = pat.primary_key
   ORDER BY pat_id, form, data_id;


DROP VIEW V_DISPVISIT_SEQ;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DISPVISIT_SEQ
(
   SEQ,
   SCHEDULE_ID,
   VISIT_ID,
   NAME,
   DESCR,
   FORM,
   INSTANCE
)
AS
   SELECT     TO_NUMBER (
                 (CASE
                     WHEN SUBSTR (visit_id, LENGTH (visit_id) - 2, 3) = 'RND'
                     THEN
                        '004'
                     ELSE
                           SUBSTR (visit_id, LENGTH (visit_id) - 4, 2)
                        || SUBSTR (visit_id, LENGTH (visit_id) - 1, 2)
                  END))
            * 100
          + TO_NUMBER (
               CASE
                  WHEN SUBSTR (visit_id, 1, 1) = 'U'
                  THEN
                     SUBSTR (visit_id, 2, 1)
                  ELSE
                     '0'
               END)
             seq,
          v.SCHEDULE_ID,
          v.VISIT_ID,
          v.NAME,
          v.DESCR,
          v.FORM,
          v.INSTANCE
     FROM VISIT_INFO v
    WHERE FORM IN (2, 3, 4)
   UNION ALL
   SELECT     TO_NUMBER (
                 (CASE
                     WHEN SUBSTR (visit_id, LENGTH (visit_id) - 2, 3) = 'RND'
                     THEN
                        '004'
                     ELSE
                           SUBSTR (visit_id, LENGTH (visit_id) - 4, 2)
                        || SUBSTR (visit_id, LENGTH (visit_id) - 1, 2)
                  END))
            * 100
          + TO_NUMBER (
               CASE
                  WHEN SUBSTR (visit_id, 1, 1) = 'U'
                  THEN
                     SUBSTR (visit_id, 2, 1)
                  ELSE
                     '0'
               END)
             seq,
          v.SCHEDULE_ID,
          v.VISIT_ID,
          v.NAME,
          v.DESCR,
          v.FORM,
          v.INSTANCE
     FROM VISIT_INFO v
    WHERE FORM IN (5, 6);


DROP VIEW V_DRUG_ADDRESS_TYPE;

/* Formatted on 9/18/2024 9:22:06 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_ADDRESS_TYPE
(
   ID,
   NAME
)
AS
   SELECT CAST (a.TYPE_ID AS VARCHAR2 (40)) AS id, a.TYPE_NAME AS NAME
     FROM ADMIN_IF.ADDRESS_TYPE a
    WHERE PRJ_ID = 'P90020903';


DROP VIEW V_DRUG_BATCH_COUNT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_BATCH_COUNT
(
   ID,
   LOCATION_ID,
   COUNTRY_ID,
   BATCH_ID,
   KIT_TYPE_ID,
   EXPIRATION_DATE,
   TOTALCOUNT
)
AS
     SELECT    location_id
            || '#'
            || country_id
            || '#'
            || batch_id
            || '#'
            || kit_type_id
            || '#'
            || TO_CHAR (expiration_date, 'dd-Mon-YYYY')
               AS id,
            location_id,
            country_id,
            batch_id,
            kit_type_id,
            expiration_date,
            LISTAGG (NAME || '-' || countkits, ',')
               WITHIN GROUP (ORDER BY NAME)
               AS totalcount
       FROM (  SELECT loc.id AS location_id,
                      dr.country_id AS country_id,
                      kit.batch_id,
                      kit.kit_type_id,
                      typ.NAME,
                      kit.expiration_date,
                      COUNT (DISTINCT kit.id) AS countkits
                 FROM drug_kit kit
                      INNER JOIN v_drug_location loc
                         ON loc.id = kit.location_id
                      INNER JOIN drug_kit_type typ
                         ON typ.id = kit.unbl_kit_type_id
                      LEFT JOIN drug_country_release dr
                         ON     dr.unbl_kit_type_id = KIT.UNBL_KIT_TYPE_ID
                            AND DR.PREQ_ID = kit.batch_id
                WHERE     kit.status_id = 'KitStatus_ONSTOCK'
                      AND kit.sort_key BETWEEN DR.MIN_RANGE AND dr.max_range
             GROUP BY loc.id,
                      dr.country_id,
                      kit.batch_id,
                      kit.kit_type_id,
                      typ.NAME,
                      kit.expiration_date) a
   GROUP BY location_id,
            country_id,
            batch_id,
            kit_type_id,
            expiration_date;


DROP VIEW V_DRUG_BATCH_COUNT_DEPOT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_BATCH_COUNT_DEPOT
(
   ID,
   LOCATION_ID,
   COUNTRY_ID,
   BATCH_ID,
   KIT_TYPE_ID,
   EXPIRATION_DATE,
   TOTALCOUNT
)
AS
     SELECT    location_id
            || '#'
            || country_id
            || '#'
            || batch_id
            || '#'
            || kit_type_id
            || '#'
            || TO_CHAR (expiration_date, 'dd-Mon-YYYY')
               AS id,
            location_id,
            country_id,
            batch_id,
            kit_type_id,
            expiration_date,
            LISTAGG (NAME || '-' || countkits, ',')
               WITHIN GROUP (ORDER BY NAME)
               AS totalcount
       FROM (  SELECT loc.id AS location_id,
                      loc.country_id AS country_id,
                      kit.batch_id,
                      kit.kit_type_id,
                      typ.NAME,
                      kit.expiration_date,
                      COUNT (DISTINCT kit.id) AS countkits
                 FROM drug_kit kit
                      INNER JOIN v_drug_location loc
                         ON loc.id = kit.location_id
                      INNER JOIN drug_kit_type typ
                         ON typ.id = kit.unbl_kit_type_id
                WHERE     kit.status_id = 'KitStatus_ONSTOCK'
                      AND loc.subclass = 'Warehouse'
             GROUP BY loc.id,
                      loc.country_id,
                      kit.batch_id,
                      kit.kit_type_id,
                      typ.NAME,
                      kit.expiration_date) a
   GROUP BY location_id,
            country_id,
            batch_id,
            kit_type_id,
            expiration_date;


DROP VIEW V_DRUG_BLINDED_EXPECTED_QTY;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_BLINDED_EXPECTED_QTY
(
   KIT_TYPE_ID,
   REQUESTED_QTY,
   SHIPMENT_ID
)
AS
     SELECT NVL (KT.ID, KT.BLINDED_KIT_TYPE_ID) AS KIT_TYPE_ID,
            SUM (QTY.REQUESTED_QTY) AS REQUESTED_QTY,
            QTY.SHIPMENT_ID
       FROM DRUG_EXPECTED_QTY QTY, DRUG_KIT_TYPE KT
      WHERE QTY.UNBLINDED_KIT_TYPE_ID = KT.ID
   GROUP BY NVL (KT.ID, KT.BLINDED_KIT_TYPE_ID), QTY.SHIPMENT_ID;


DROP VIEW V_DRUG_BLINDING_LEVEL;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_BLINDING_LEVEL
(
   ID,
   VALUE
)
AS
   SELECT 'IS_OPEN_LABEL' AS ID, BLINDING_LEVEL AS VALUE
     FROM ADMIN_IF.PROJECTS
    WHERE PRJ_ID = 'P90020903';


DROP VIEW V_DRUG_CNTRY_RELEASE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_CNTRY_RELEASE
(
   ID,
   KIT_ID,
   COUNTRY_ID,
   PREQ_ID,
   UNBL_KIT_TYPE_ID
)
AS
   SELECT K.ID || '#' || R.COUNTRY_ID || '#' || R.PREQ_ID AS ID,
          K.ID AS KIT_ID,
          R.COUNTRY_ID,
          R.PREQ_ID,
          R.UNBL_KIT_TYPE_ID
     FROM    DRUG_COUNTRY_RELEASE R
          INNER JOIN
             DRUG_KIT K
          ON     R.UNBL_KIT_TYPE_ID = K.UNBL_KIT_TYPE_ID
             AND K.SORT_KEY BETWEEN R.MIN_RANGE AND R.MAX_RANGE;


DROP VIEW V_DRUG_CNTRY_RELEASE_GUI;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_CNTRY_RELEASE_GUI
(
   ID,
   PREQ_ID,
   UNBL_KIT_TYPE_ID,
   COUNTRY_ID,
   COUNTRY,
   COUNTRY_AND_ID,
   PREQ_NUMBER,
   DU_DESCRIPTION,
   DU_TYPE,
   DU_DOSE,
   MIN_RANGE,
   MAX_RANGE,
   DU_COUNT,
   CREATED_TIMESTAMP
)
AS
   SELECT cr.ID,
          cr.PREQ_ID,
          cr.UNBL_KIT_TYPE_ID,
          cr.COUNTRY_ID,
          c.LONG_NAME COUNTRY,
          cr.COUNTRY_ID || ' - ' || c.LONG_NAME COUNTRY_AND_ID,
          b.NAME PREQ_NUMBER,
          t.DESCRIPTION DU_DESCRIPTION,
          t.NAME DU_TYPE,
          t.DOSE DU_DOSE,
          cr.MIN_RANGE,
          cr.MAX_RANGE,
          cr.DU_COUNT,
          cr.created_timestamp
     FROM DRUG_COUNTRY_RELEASE cr
          LEFT JOIN DRUG_BATCH b
             ON cr.PREQ_ID = b.ID
          LEFT JOIN DRUG_KIT_TYPE t
             ON cr.UNBL_KIT_TYPE_ID = t.ID
          LEFT JOIN V_DRUG_COUNTRY c
             ON cr.COUNTRY_ID = c.ID;


DROP VIEW V_DRUG_COHORT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_COHORT
(
   ID,
   NAME
)
AS
   SELECT ID, NAME FROM DRUG_COHORT;


DROP VIEW V_DRUG_COUNTRY;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_COUNTRY
(
   ID,
   NAME,
   DGT2CODE,
   LONG_NAME
)
AS
     SELECT c.DGT3CODE AS ID,
            c.DGT3CODE AS name,
            c.DGT2CODE,
            c.name AS long_name
       FROM ADMIN_IF.COUNTRY_SELECTION c
      WHERE c.PRJ_ID IN (SELECT ID FROM V_DRUG_PROJECT)
   GROUP BY c.DGT3CODE, c.DGT2CODE, c.name;


DROP VIEW V_DRUG_COUNTRY_REGION;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_COUNTRY_REGION
(
   ID,
   COUNTRY_ID,
   NAME,
   LONG_NAME,
   REGION
)
AS
   SELECT ID || '/' || 'USA/Canada' ID,
          ID COUNTRY_ID,
          NAME,
          LONG_NAME,
          'USA/Canada' REGION
     FROM V_DRUG_COUNTRY
    WHERE ID IN ('USA', 'CAN')
   UNION ALL
   SELECT ID || '/' || 'ROW/Canada' ID,
          ID COUNTRY_ID,
          NAME,
          LONG_NAME,
          'ROW/Canada' REGION
     FROM V_DRUG_COUNTRY
    WHERE ID != 'USA';


DROP VIEW V_DRUG_CP_RELATION;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_CP_RELATION
(
   LOCATION_ID,
   CHILD_LOCATION_ID
)
AS
   SELECT g.grp_id AS location_id, s.obj_id AS child_location_id
     FROM ADMIN_IF.SUPERVISION s, ADMIN_IF.groups g, V_DRUG_PROJECT p
    WHERE s.sbj_id = g.grp_id AND g.prj_id = p.id AND g.cat_id = 13;


DROP VIEW V_DRUG_CP_STATUS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_CP_STATUS
(
   LOCATION_ID,
   STATUS_ID
)
AS
   SELECT X.GRP_ID AS LOCATION_ID,
          CASE
             WHEN X.ACTIVE > 0 THEN 'LocationStatus_ACTIVE'
             WHEN X.CLOSED > 0 AND X.ACTIVE = 0 THEN 'LocationStatus_CLOSED'
             ELSE 'LocationStatus_NOTSET'
          END
             STATUS_ID
     FROM (  SELECT C.GRP_ID,
                    SUM (
                       CASE
                          WHEN L.STATUS_ID = 'LocationStatus_NOTSET' THEN 1
                          ELSE 0
                       END)
                       AS NOTSET,
                    SUM (
                       CASE
                          WHEN L.STATUS_ID = 'LocationStatus_CLOSED' THEN 1
                          ELSE 0
                       END)
                       AS CLOSED,
                    SUM (
                       CASE
                          WHEN L.STATUS_ID = 'LocationStatus_ACTIVE' THEN 1
                          ELSE 0
                       END)
                       AS ACTIVE,
                    COUNT (CP.CHILD_LOCATION_ID) AS SITECOUNT
               FROM (SELECT G.GRP_ID
                       FROM    ADMIN_IF.groups g
                            INNER JOIN
                               V_DRUG_PROJECT p
                            ON g.prj_id = p.id
                      WHERE g.cat_id = 13) C
                    LEFT JOIN V_DRUG_CP_RELATION CP
                       ON C.GRP_ID = CP.LOCATION_ID
                    LEFT JOIN DRUG_LOCATION L
                       ON CP.CHILD_LOCATION_ID = L.ID
           GROUP BY C.GRP_ID) X;


DROP VIEW V_DRUG_DISPENSE_MATRIX;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_DISPENSE_MATRIX
(
   ID,
   SCHEDULE_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   VISIT_DESC,
   TREATMENTARM_ID,
   TREATMENT_ARM_DESCR,
   TREATMENT_ARM_NAME,
   TREATMENT_ARM_DOSE,
   DOSE,
   TREATMENT_ARM_STATUS_ID,
   QUANTITY_SELECTED,
   QUANTITY_TO_DISPENSE,
   QUANTITY_TO_PROJECT,
   UNBL_KIT_TYPE,
   UNBL_KIT_TYPE_ID,
   KIT_TYPE_NAME,
   KIT_TYPE_DESCR,
   KIT_TYPE_UNBL_DESCR,
   REGION
)
AS
   SELECT m.ID,
          vs.SCHEDULE_ID,
          vs.VISIT_ID,
          vs.FORM,
          vs.INSTANCE,
          m.VISIT_DESC,
          m.TREATMENTARM_ID,
          t.DESCRIPTION TREATMENT_ARM_DESCR,
          t.NAME TREATMENT_ARM_NAME,
          t.DOSE TREATMENT_ARM_DOSE,
          m.DOSE DOSE,
          t.STATUS_ID TREATMENT_ARM_STATUS_ID,
          m.QUANTITY_SELECTED,
          m.QUANTITY_TO_DISPENSE,
          m.QUANTITY_TO_PROJECT,
          m.UNBL_KIT_TYPE,
          kt.ID UNBL_KIT_TYPE_ID,
          kt.NAME KIT_TYPE_NAME,
          kt.DESCRIPTION KIT_TYPE_DESCR,
          ktd.BLINDED_DESCR KIT_TYPE_UNBL_DESCR,
          m.REGION
     FROM DRUG_DISPENSE_MATRIX m
          INNER JOIN VISIT_INFO vs
             ON m.VISIT_DESC = vs.NAME
          INNER JOIN DRUG_TREATMENTARM t
             ON t.ID = m.TREATMENTARM_ID AND vs.SCHEDULE_ID = 'ARM' || t.NAME
          INNER JOIN DRUG_KIT_TYPE kt
             ON kt.NAME = m.UNBL_KIT_TYPE
          INNER JOIN DRUG_KIT_TYPE_DESCRS ktd
             ON kt.ID = ktd.UNBL_KIT_TYPE_ID;


DROP VIEW V_DRUG_DISPENSE_MATRIX_COUNTRY;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_DISPENSE_MATRIX_COUNTRY
(
   SCHEDULE_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   VISIT_DESC,
   TREATMENTARM_ID,
   TREATMENT_ARM_DESCR,
   TREATMENT_ARM_NAME,
   TREATMENT_ARM_DOSE,
   DOSE,
   TREATMENT_ARM_STATUS_ID,
   QUANTITY_SELECTED,
   QUANTITY_TO_DISPENSE,
   QUANTITY_TO_PROJECT,
   UNBL_KIT_TYPE,
   UNBL_KIT_TYPE_ID,
   KIT_TYPE_NAME,
   KIT_TYPE_DESCR,
   KIT_TYPE_UNBL_DESCR,
   COUNTRY_ID,
   COUNTRY_NAME
)
AS
   SELECT DISTINCT SCHEDULE_ID,
                   VISIT_ID,
                   FORM,
                   INSTANCE,
                   VISIT_DESC,
                   TREATMENTARM_ID,
                   TREATMENT_ARM_DESCR,
                   TREATMENT_ARM_NAME,
                   TREATMENT_ARM_DOSE,
                   DOSE,
                   TREATMENT_ARM_STATUS_ID,
                   QUANTITY_SELECTED,
                   QUANTITY_TO_DISPENSE,
                   QUANTITY_TO_PROJECT,
                   UNBL_KIT_TYPE,
                   UNBL_KIT_TYPE_ID,
                   KIT_TYPE_NAME,
                   KIT_TYPE_DESCR,
                   KIT_TYPE_UNBL_DESCR,
                   cr.COUNTRY_ID,
                   cr.LONG_NAME AS COUNTRY_NAME
     FROM    V_DRUG_DISPENSE_MATRIX m
          INNER JOIN
             V_DRUG_COUNTRY_REGION cr
          ON cr.REGION = m.REGION;


DROP VIEW V_DRUG_DISPENSE_MATRIX_DOSE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_DISPENSE_MATRIX_DOSE
(
   ID,
   SCHEDULE_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   VISIT_DESC,
   TREATMENTARM_ID,
   TREATMENT_ARM_DESCR,
   TREATMENT_ARM_NAME,
   TREATMENT_ARM_DOSE,
   TREATMENT_ARM_STATUS_ID,
   QUANTITY_SELECTED,
   QUANTITY_TO_DISPENSE,
   QUANTITY_TO_PROJECT,
   UNBL_KIT_TYPE,
   UNBL_KIT_TYPE_ID,
   KIT_TYPE_NAME,
   KIT_TYPE_DESCR,
   KIT_TYPE_UNBL_DESCR,
   COUNTRY_ID,
   COUNTRY_NAME,
   DOSE,
   DOSE_NAME,
   DOSE_ID
)
AS
   SELECT    COUNTRY_ID
          || '#'
          || VISIT_ID
          || '#'
          || TREATMENTARM_ID
          || '#'
          || UNBL_KIT_TYPE
          || '#'
          || QUANTITY_SELECTED
             ID,
          SCHEDULE_ID,
          VISIT_ID,
          FORM,
          INSTANCE,
          VISIT_DESC,
          TREATMENTARM_ID,
          TREATMENT_ARM_DESCR,
          TREATMENT_ARM_NAME,
          TREATMENT_ARM_DOSE,
          TREATMENT_ARM_STATUS_ID,
          QUANTITY_SELECTED,
          QUANTITY_TO_DISPENSE,
          QUANTITY_TO_PROJECT,
          UNBL_KIT_TYPE,
          UNBL_KIT_TYPE_ID,
          KIT_TYPE_NAME,
          KIT_TYPE_DESCR,
          KIT_TYPE_UNBL_DESCR,
          COUNTRY_ID,
          COUNTRY_NAME,
          DOSE,
          dc.NAME DOSE_NAME,
          dc.ID DOSE_ID
     FROM    V_DRUG_DISPENSE_MATRIX_COUNTRY m
          LEFT JOIN
             DRUG_DOSE_CUSTOM dc
          ON     INSTR (dc.NAME, m.DOSE) > 0
             AND (CASE WHEN m.UNBL_KIT_TYPE = '1' THEN dc.id ELSE '100' END) =
                    dc.ID;


DROP VIEW V_DRUG_DISPENSE_VISITS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_DISPENSE_VISITS
(
   PAT_ID,
   VISIT_DATE,
   EARLIEST_VISIT_DATE,
   LATEST_VISIT_DATE,
   VISIT_DATE_TYPE,
   VISIT_ID,
   VISIT_SEQ_NO
)
AS
   SELECT "PAT_ID",
          "VISIT_DATE",
          "EARLIEST_VISIT_DATE",
          "LATEST_VISIT_DATE",
          "VISIT_DATE_TYPE",
          "VISIT_ID",
          "VISIT_SEQ_NO"
     FROM V_DYNAMIC_VISIT_SCHEDULE;


DROP VIEW V_DRUG_EDC_FACTOR_VALUE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_EDC_FACTOR_VALUE
(
   NAME,
   VALUE,
   DESCRIPTION,
   RATIO,
   MODIFIED_AT,
   MODIFIED
)
AS
   SELECT 'SITE' AS NAME,
          NAME AS VALUE,
          NAME AS DESCRIPTION,
          TO_NUMBER (NULL) AS RATIO,
          TO_TIMESTAMP ('01.01.1900', 'DD.MM.YYYY') MODIFIED_AT,
          'Initial' MODIFIED
     FROM V_DRUG_LOCATION
    WHERE     SUBCLASS = 'Site'
          AND 'SITE' IN (SELECT NAME FROM DRUG_FACTOR)
          AND PROJECT_ID IN (SELECT ID
                               FROM V_DRUG_PROJECT
                              WHERE IS_CURRENT = 1);


DROP VIEW V_DRUG_ENVIRONMENT_ATTRIBUTES;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_ENVIRONMENT_ATTRIBUTES
(
   ID,
   KEY,
   STR_VALUE,
   LONG_VALUE,
   DATE_VALUE
)
AS
   SELECT ID,
          KEY,
          STR_VALUE,
          LONG_VALUE,
          DATE_VALUE
     FROM ADMIN_IF.ENVIRONMENT_ATTRIBUTES;


DROP VIEW V_DRUG_FACTOR_AT_RANDOM_DATE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_FACTOR_AT_RANDOM_DATE
(
   PAT_ID,
   NAME,
   VALUE
)
AS
   SELECT PAT_ID, NAME, VALUE
     FROM V_DRUG_PATIENT_FACTOR_VALUE
    WHERE PAT_ID NOT IN (SELECT PAT_ID
                           FROM DRUG_RNDNO
                          WHERE PAT_ID IS NOT NULL)
   UNION ALL
   SELECT R.PAT_ID, V.NAME, V.VALUE
     FROM DRUG_RNDNO R, DRUG_RNDNO_FACTOR_VALUE V
    WHERE V.RNDNO_ID = R.ID AND PAT_ID IS NOT NULL;


DROP VIEW V_DRUG_FACTOR_VALUE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_FACTOR_VALUE
(
   ID,
   NAME,
   VALUE,
   DESCRIPTION,
   RATIO,
   MODIFIED_AT,
   MODIFIED
)
AS
   SELECT ID AS ID,
          F.NAME,
          F.VALUE,
          F.DESCRIPTION,
          F.RATIO,
          F.MODIFIED_AT,
          F.MODIFIED
     FROM DRUG_FACTOR_VALUE F
   UNION ALL
   SELECT F.NAME || '_' || F.VALUE AS ID,
          F.NAME,
          F.VALUE,
          F.DESCRIPTION,
          F.RATIO,
          F.MODIFIED_AT,
          F.MODIFIED
     FROM V_DRUG_EDC_FACTOR_VALUE F
    WHERE     (NAME, VALUE) NOT IN
                 (SELECT NAME, VALUE FROM DRUG_FACTOR_VALUE)
          AND F.NAME || '_' || F.VALUE NOT IN
                 (SELECT ID FROM DRUG_FACTOR_VALUE);


DROP VIEW V_DRUG_GLOBAL_ATTRIBUTES;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_GLOBAL_ATTRIBUTES
(
   ID,
   KEY,
   STR_VALUE,
   LONG_VALUE,
   DATE_VALUE
)
AS
   SELECT ID,
          KEY,
          STR_VALUE,
          LONG_VALUE,
          DATE_VALUE
     FROM ADMIN_IF.GLOBAL_ATTRIBUTES;


DROP VIEW V_DRUG_IRB_HISTORY;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_IRB_HISTORY
(
   LOCATION_ID,
   NAME,
   VALUE,
   MODIFIED,
   MODIFIED_AT,
   MODIFIED_AT_UTC
)
AS
     SELECT "LOCATION_ID",
            "NAME",
            "VALUE",
            "MODIFIED",
            "MODIFIED_AT",
            "MODIFIED_AT_UTC"
       FROM (SELECT LOCATION_ID,
                    NAME,
                    VALUE,
                    MODIFIED,
                    MODIFIED_AT,
                    MODIFIED_TIMESTAMP AS MODIFIED_AT_UTC
               FROM DRUG_LOCATION_ATTRIB
             UNION
             SELECT LOCATION_ID,
                    NAME,
                    VALUE,
                    MODIFIED,
                    MODIFIED_AT,
                    MODIFIED_TIMESTAMP AS MODIFIED_AT_UTC
               FROM DRUG_AUDIT_LOCATION_ATTRIB)
   ORDER BY LOCATION_ID, MODIFIED_AT DESC;


DROP VIEW V_DRUG_KITCNT_BATCH;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_KITCNT_BATCH
(
   BATCH_NUMBER,
   KITTYPE,
   KITTYPE_DESC,
   EXPIRATION_DATE,
   TOTALCOUNT,
   KIT_LOCATION,
   LOCATION_ID
)
AS
     SELECT db.name AS BATCH_NUMBER,
            b.name AS KITTYPE,
            b.description AS KITTYPE_DESC,
            a.expiration_date,
            COUNT (*) AS TOTALCOUNT,
            loc.name AS KIT_LOCATION,
            a.LOCATION_ID
       FROM DRUG_KIT a
            INNER JOIN DRUG_STATUS_FOR_EXPIRATION de
               ON a.status_id = de.id
            INNER JOIN V_DRUG_LOCATION loc
               ON loc.id = a.location_id
            JOIN DRUG_BATCH db
               ON A.BATCH_ID = db.id
            LEFT JOIN (SELECT id, name, description FROM DRUG_KIT_TYPE) b
               ON a.unbl_kit_type_id = b.id
      WHERE db.blocked = 0
   GROUP BY db.name,
            b.name,
            b.description,
            a.Location_id,
            loc.name,
            a.expiration_date;


DROP VIEW V_DRUG_KIT_TYPE_UNBL_DESCR;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_KIT_TYPE_UNBL_DESCR
(
   UNBL_KIT_TYPE_ID,
   KIT_TYPE_NAME,
   UNBLINDED_DESCR,
   BLINDED_DESCR
)
AS
   SELECT UNBL_KIT_TYPE_ID,
          t.NAME KIT_TYPE_NAME,
          t.DESCRIPTION UNBLINDED_DESCR,
          (CASE
              WHEN t.BLINDED_KIT_TYPE_ID IS NULL THEN t.DESCRIPTION
              ELSE d.BLINDED_DESCR
           END)
             BLINDED_DESCR
     FROM    DRUG_KIT_TYPE t
          INNER JOIN
             DRUG_KIT_TYPE_DESCRS d
          ON t.ID = d.UNBL_KIT_TYPE_ID;


DROP VIEW V_DRUG_LAST_DISP_KIT_PROJ;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_LAST_DISP_KIT_PROJ
(
   PAT_ID,
   VISIT_ID,
   UNBL_KIT_TYPE_ID,
   QUANTITY
)
AS
   SELECT q.pat_id,
          q.visit_id,
          q.unbl_kit_type_id,
          CASE
             WHEN     (q.unbl_kit_type_id =
                          '8a81a1f87d28db10017d28e8d3ed0010')
                  AND ( (SELECT COUNT (*)
                           FROM DATA
                          WHERE     pat_id = q.pat_id
                                AND field = 'RSP_ENCO_DOSE'
                                AND VALUE = '-1') >= 1)
             THEN
                0
             WHEN     (q.unbl_kit_type_id =
                          '8a81a1f87d28db10017d28ebf43b0013')
                  AND ( (SELECT COUNT (*)
                           FROM DATA
                          WHERE     pat_id = q.pat_id
                                AND field = 'RSP_PEMB_DOSE'
                                AND VALUE = 'Permanently Discontinued') >= 1)
             THEN
                0
             WHEN     (q.unbl_kit_type_id IN
                          ('8a81a1f87d28db10017d28ebf4430015',
                           '8a81a1f87d28db10017d28ecbc7f0018'))
                  AND ( (SELECT COUNT (*)
                           FROM DATA
                          WHERE     pat_id = q.pat_id
                                AND field = 'RSP_CETU_DOSE'
                                AND VALUE = '-1') >= 1)
             THEN
                0
             ELSE
                q.quantity
          END
             AS quantity
     FROM    V_DRUG_LAST_DISP_KIT_QUANT q
          INNER JOIN
             VISIT_INFO i
          ON i.VISIT_ID = q.VISIT_ID;


DROP VIEW V_DRUG_LAST_DISP_KIT_QUANT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_LAST_DISP_KIT_QUANT
(
   PAT_ID,
   VISIT_ID,
   UNBL_KIT_TYPE_ID,
   QUANTITY
)
AS
   SELECT pat_id,
          visit_id,
          unbl_kit_type_id,
          quantity
     FROM (  SELECT k1.pat_id,
                    k1.visit_id,
                    k1.unbl_kit_type_id,
                    COUNT (*) Quantity,
                    MIN (topRnk) latestVisitRank
               FROM    DRUG_KIT k1
                    INNER JOIN
                       V_PAT_KITDISP_SEQ a
                    ON     a.visit_id = k1.visit_id
                       AND a.pat_id = k1.pat_id
                       AND k1.UNBL_KIT_TYPE_ID = a.UNBL_KIT_TYPE_ID
              WHERE     topRnk = 1
                    AND recall_date IS NULL
                    AND dispense_date IS NOT NULL
           GROUP BY k1.pat_id, k1.visit_id, k1.unbl_kit_type_id) b;


DROP VIEW V_DRUG_LOCATION;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_LOCATION
(
   ID,
   NAME,
   GRP_NUMBER,
   LOCAL_DATE_TIME,
   COUNTRY_ID,
   MODIFIED,
   MODIFIED_AT,
   STATUS_ID,
   ENROLMENT_CATEGORY_ID,
   LOCATION_SEQ_NUMBER,
   SUBCLASS,
   PROJECT_ID
)
AS
   SELECT s.id,
          g.name AS name,
          g.grp_number AS grp_number,
          g.local_date_time AS local_date_time,
          g.country_ID AS COUNTRY_ID,
          s.MODIFIED,
          s.MODIFIED_AT,
          CASE
             WHEN g.cat_id IN (10, 11)
             THEN
                s.status_id
             ELSE
                (SELECT status_id
                   FROM V_DRUG_CP_STATUS
                  WHERE location_id = g.grp_id)
          END
             AS STATUS_ID,
          CASE
             WHEN     (SELECT COUNT (*)
                         FROM V_DRUG_PROJECT
                        WHERE     PARENT_PRJ_ID IS NOT NULL
                              AND IS_CURRENT = 1
                              AND ID = 'P90020903') = 1
                  AND p.PARENT_PRJ_ID IS NOT NULL
                  AND p.IS_CURRENT = 0
             THEN
                NULL
             ELSE
                s.ENROLMENT_CATEGORY_ID
          END
             AS ENROLMENT_CATEGORY_ID,
          s.LOCATION_SEQ_NUMBER,
          CASE
             WHEN g.cat_id = 10 THEN 'Site'
             WHEN g.cat_id = 11 THEN 'Warehouse'
             WHEN g.cat_id = 13 THEN 'CentralPharmacy'
          END
             AS subclass,
          g.prj_id AS project_id
     FROM drug_location s, ADMIN_IF.groups g, V_DRUG_PROJECT p
    WHERE s.id = g.grp_id AND g.prj_id = p.id
   UNION ALL
   SELECT CAST (g.GRP_ID AS VARCHAR2 (40)) AS id,
          g.name AS name,
          g.grp_number AS grp_number,
          g.local_date_time AS local_date_time,
          g.country_ID AS COUNTRY_ID,
          CAST (g.modified_by AS VARCHAR2 (40)) AS MODIFIED,
          g.modified AS modified_at,
          CASE
             WHEN g.cat_id IN (10, 11)
             THEN
                st.id
             ELSE
                (SELECT status_id
                   FROM V_DRUG_CP_STATUS
                  WHERE location_id = g.grp_id)
          END
             AS STATUS_ID,
          NULL AS ENROLMENT_CATEGORY_ID,
          NULL AS LOCATION_SEQ_NUMBER,
          CASE
             WHEN g.cat_id = 10 THEN 'Site'
             WHEN g.cat_id = 11 THEN 'Warehouse'
             WHEN g.cat_id = 13 THEN 'CentralPharmacy'
          END
             AS subclass,
          g.prj_id AS project_id
     FROM ADMIN_IF.groups g, DRUG_STATUS st
    WHERE     g.env_id = 1
          AND g.grp_id NOT IN (SELECT id FROM drug_location)
          AND st.id = 'LocationStatus_NOTSET'
          AND g.cat_id IN (10, 11, 13)
          AND g.prj_id IN (SELECT ID FROM V_DRUG_PROJECT);


DROP VIEW V_DRUG_LOCATIONS_FOR_WORKER;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_LOCATIONS_FOR_WORKER
(
   WORKER_ID,
   LOCATION_ID
)
AS
   SELECT TO_CHAR (W.WRK_ID), TO_CHAR (G.GRP_ID)
     FROM (    SELECT CONNECT_BY_ROOT S.SBJ_ID SBJ, S.OBJ_ID OBJ
                 FROM ADMIN_IF.SUPERVISION S
           CONNECT BY PRIOR S.OBJ_ID = S.SBJ_ID) H_SUPERVISION,
          ADMIN_IF.WORKERS W,
          ADMIN_IF.GROUPS G
    WHERE OBJ = G.GRP_ID AND W.GRP_ID = SBJ AND G.CAT_ID IN (10, 11, 13)
   UNION
   SELECT TO_CHAR (W.WRK_ID), TO_CHAR (G.GRP_ID)
     FROM ADMIN_IF.WORKERS W, ADMIN_IF.GROUPS G
    WHERE W.GRP_ID = G.GRP_ID AND G.CAT_ID IN (10, 11, 13);


DROP VIEW V_DRUG_LOCATION_ADDRESS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_LOCATION_ADDRESS
(
   ID,
   LOCATION_ID,
   FNAME,
   MNAME,
   LNAME,
   TITLE,
   ORGANISATION,
   STREET,
   CITY,
   STATE,
   ZIP,
   COUNTRY_ID,
   PHONE,
   MPHONE,
   FAX,
   EMAIL,
   NOTES
)
AS
   SELECT CAST (a.id AS VARCHAR2 (40)) AS ID,
          CAST (a.GRP_ID AS VARCHAR2 (40)) AS LOCATION_ID,
          a.FNAME,
          a.MNAME,
          a.LNAME,
          a.TITLE,
          a.ORGANISATION,
          a.STREET,
          a.CITY,
          a.STATE,
          a.ZIP,
          CAST (a.COUNTRY_ID AS CHAR (3)) COUNTRY_ID,
          a.PHONE,
          a.MPHONE,
          a.FAX,
          a.EMAIL,
          a.NOTES
     FROM ADMIN_IF.ADDRESS a;


DROP VIEW V_DRUG_LOCATION_IRB;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_LOCATION_IRB
(
   IRB_EXPIRATION_DATE,
   IRB_EXPIRED,
   IRB_TRANSACTION,
   ID,
   NAME,
   GRP_NUMBER,
   CENTER_NO,
   LOCATION_ID,
   LOCAL_DATE_TIME,
   COUNTRY_ID,
   MODIFIED,
   MODIFIED_AT,
   STATUS_ID,
   ENROLMENT_CATEGORY_ID,
   LOCATION_SEQ_NUMBER,
   SUBCLASS,
   PROJECT_ID
)
AS
   SELECT TO_DATE (LA.VALUE, 'dd-Mon-yyyy') IRB_EXPIRATION_DATE,
          CASE
             WHEN TRUNC (LOCAL_DATE_TIME) <
                     TRUNC (TO_DATE (LA.VALUE, 'dd-Mon-yyyy'))
             THEN
                0
             ELSE
                1
          END
             IRB_EXPIRED,
          LT.VALUE IRB_TRANSACTION,
          l.ID,
          l.NAME,
          l.GRP_NUMBER,
          SUBSTR (l.NAME, 0, 4) CENTER_NO,
          SUBSTR (l.NAME, 5, 3) LOCATION_ID,
          l.LOCAL_DATE_TIME,
          l.COUNTRY_ID,
          l.MODIFIED,
          l.MODIFIED_AT,
          l.STATUS_ID,
          l.ENROLMENT_CATEGORY_ID,
          l.LOCATION_SEQ_NUMBER,
          l.SUBCLASS,
          l.PROJECT_ID
     FROM V_DRUG_LOCATION l
          LEFT JOIN DRUG_LOCATION_ATTRIB LA
             ON l.ID = LA.LOCATION_ID AND LA.NAME = 'IRB_EXPIRATION_DATE'
          LEFT JOIN DRUG_LOCATION_ATTRIB LT
             ON l.ID = LT.LOCATION_ID AND LT.NAME = 'IRB_TRANSACTION'
    WHERE l.SUBCLASS != 'Warehouse';


DROP VIEW V_DRUG_LOCATION_RELATION;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_LOCATION_RELATION
(
   FROM_LOCATION_ID,
   TO_LOCATION_ID
)
AS
   WITH projgrps
        AS (SELECT g1.grp_id,
                   g1.iwrs_obj_id,
                   p1.is_current,
                   CASE
                      WHEN g1.cat_id = 12 THEN 0
                      WHEN g1.cat_id IN (10, 11, 13) THEN 1
                      ELSE NULL
                   END
                      is_location
              FROM    adm_icrf3.GROUPS g1
                   INNER JOIN
                      v_drug_project p1
                   ON g1.prj_id = p1.id
             WHERE g1.env_id = 1),
        projsuper
        AS (SELECT *
              FROM adm_icrf3.supervision s1
             WHERE EXISTS
                      (SELECT NULL
                         FROM projgrps pg
                        WHERE pg.grp_id = s1.sbj_id))
   SELECT from_location_id, to_location_id
     FROM (SELECT g.grp_id from_location_id, to_location_id
             FROM (    SELECT CONNECT_BY_ROOT sbj_id sbj,
                              s.obj_id obj,
                              g1.grp_id to_location_id
                         FROM    projsuper s
                              INNER JOIN
                                 projgrps g1
                              ON s.obj_id = g1.grp_id
                        WHERE NOT EXISTS
                                 (SELECT NULL
                                    FROM v_drug_cp_relation
                                   WHERE g1.grp_id = child_location_id)
                   START WITH s.sbj_id IN
                                 (SELECT iwrs_obj_id
                                    FROM projgrps
                                   WHERE     is_location = 1
                                         AND iwrs_obj_id IS NOT NULL)
                   CONNECT BY PRIOR s.obj_id = s.sbj_id) t_result
                  INNER JOIN projgrps g
                     ON t_result.sbj = g.iwrs_obj_id
                  INNER JOIN projgrps g2
                     ON t_result.to_location_id = g2.grp_id
            WHERE g2.is_location = 1
           UNION
           SELECT g1.grp_id from_location, g2.grp_id to_location
             FROM    projgrps g1
                  INNER JOIN
                     projgrps g2
                  ON g1.iwrs_obj_id = g2.grp_id
            WHERE     g1.is_location = 1
                  AND g2.is_location = 1
                  AND NOT EXISTS
                         (SELECT NULL
                            FROM v_drug_cp_relation
                           WHERE g2.grp_id = child_location_id))
    WHERE EXISTS
             (SELECT NULL
                FROM projgrps g6
               WHERE     g6.is_current = 1
                     AND (   from_location_id = g6.grp_id
                          OR to_location_id = g6.grp_id));


DROP VIEW V_DRUG_LOC_KIT_ONSTOCK_CNT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_LOC_KIT_ONSTOCK_CNT
(
   LOCATION_ID,
   LOCATION_NAME,
   UNBL_KIT_TYPE_ID,
   ONSTOCK_CNT
)
AS
     SELECT loc.id AS LOCATION_ID,
            loc.name AS LOCATION_NAME,
            UNBL_KIT_TYPE_ID,
            COUNT (DISTINCT dk.id) AS ONSTOCK_CNT
       FROM    DRUG_KIT dk
            INNER JOIN
               V_DRUG_LOCATION loc
            ON dk.location_id = loc.id AND loc.subclass = 'Warehouse'
      WHERE dk.status_id = 'KitStatus_ONSTOCK'
   GROUP BY unbl_kit_type_id, loc.id, loc.name;


DROP VIEW V_DRUG_MAP_ADDRESS_TYPE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_MAP_ADDRESS_TYPE
(
   ADDRESS_TYPE_ID,
   ADDRESS_ID
)
AS
   SELECT CAST (a.address_type_id AS VARCHAR2 (40)) AS address_type_id,
          a.address_id AS address_id
     FROM ADMIN_IF.MAP_ADDRESS_TYPE a;


DROP VIEW V_DRUG_OPEN_LOCATION;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_OPEN_LOCATION (LOCATION_ID)
AS
   SELECT TO_NUMBER (L.ID) AS LOCATION_ID
     FROM V_DRUG_LOCATION L
    WHERE L.STATUS_ID IN ('LocationStatus_ACTIVE');


DROP VIEW V_DRUG_PARAMETERS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_PARAMETERS
(
   PARAMETER_GROUP,
   PARAMETER_ID,
   PARAMETER_NAME
)
AS
   SELECT 'VISIBLE_KIT_TYPE' AS PARAMETER_GROUP,
          ID AS PARAMETER_ID,
          NAME AS PARAMETER_NAME
     FROM DRUG_KIT_TYPE
    WHERE BLINDED_KIT_TYPE_ID IS NULL
   UNION ALL
   SELECT 'UNBLINDED_KIT_TYPE' AS PARAMETER_GROUP,
          ID AS PARAMETER_ID,
          NAME AS PARAMETER_NAME
     FROM DRUG_KIT_TYPE
    WHERE SUBCLASS = 'UnblindedKitType'
   UNION ALL
   SELECT 'COHORT' AS PARAMETER_GROUP,
          ID AS PARAMETER_ID,
          NAME AS PARAMETER_NAME
     FROM DRUG_COHORT;


DROP VIEW V_DRUG_PATIENT_FACTOR_VALUE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_PATIENT_FACTOR_VALUE
(
   PAT_ID,
   NAME,
   VALUE
)
AS
   SELECT dat.PAT_ID AS PAT_ID, strat.NAME AS NAME, strat.VALUE AS VALUE
     FROM    data dat
          INNER JOIN
             DRUG_FACTOR_VALUE strat
          ON strat.VALUE = dat.VALUE AND dat.field = 'STRATA';


DROP VIEW V_DRUG_PAT_CETUX_DOSE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_PAT_CETUX_DOSE
(
   ID,
   PAT_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   DOSE_ID,
   ACTIVE_DOSE_NAME,
   DOSE,
   DISPENSE
)
AS
   SELECT r.PAT_ID || '#' || info.VISIT_ID AS ID,
          r.PAT_ID AS PAT_ID,
          info.VISIT_ID AS VISIT_ID,
          info.FORM AS FORM,
          info.INSTANCE AS INSTANCE,
          CASE WHEN R.TREATMENTARM_ID = 1 THEN '6' ELSE 'N/A' END AS DOSE_ID,
          CASE WHEN R.TREATMENTARM_ID = 1 THEN ds.name ELSE 'N/A' END
             AS ACTIVE_DOSE_NAME,
          CASE WHEN R.TREATMENTARM_ID = 1 THEN 'Active' ELSE 'N/A' END
             AS DOSE,
          0 AS DISPENSE
     FROM VISIT_INFO info
          INNER JOIN DRUG_RNDNO r
             ON r.PAT_ID IS NOT NULL
          LEFT JOIN DRUG_dose_custom ds
             ON ds.id = 6
    WHERE INFO.VISIT_ID = 'AC01D01'
   UNION ALL
   SELECT dat.PAT_ID || '#' || info.VISIT_ID AS ID,
          dat.PAT_ID AS PAT_id,
          info.VISIT_ID AS VISIT_ID,
          info.FORM AS FORM,
          info.INSTANCE AS INSTANCE,
          LAST.VALUE AS DOSE_ID,
          DS.NAME AS ACTIVE_DOSE_NAME,
          CASE WHEN R.TREATMENTARM_ID = 1 THEN dose.NAME ELSE 'N/A' END
             AS DOSE,
          CASE WHEN dose.NAME LIKE '%mg%' THEN 1 ELSE 0 END AS DISPENSE
     FROM DATA dat
          INNER JOIN drug_rndno r
             ON dat.pat_id = r.pat_id
          INNER JOIN DRUG_dose_custom dose
             ON dose.id = dat.VALUE
          INNER JOIN VISIT_INFO info
             ON info.FORM = dat.FORM AND dat.PAGE = info.INSTANCE
          INNER JOIN DATA LAST
             ON     LAST.PAT_ID = dat.PAT_ID
                AND LAST.FORM = dat.FORM
                AND LAST.PAGE = dat.PAGE
                AND LAST.FIELD = 'RSP_ACTV_CETU_DOSE'
          LEFT JOIN DRUG_dose_custom ds
             ON ds.id = LAST.VALUE
    WHERE     dat.FIELD = 'RSP_CETU_DOSE'
          AND dat.FORM IN (3, 4)
          AND INFO.VISIT_ID != 'AC01D01';


DROP VIEW V_DRUG_PAT_ENCO_DOSE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_PAT_ENCO_DOSE
(
   ID,
   PAT_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   DOSE_ID,
   ACTIVE_DOSE_NAME,
   DOSE,
   DISPENSE
)
AS
   SELECT r.PAT_ID || '#' || info.VISIT_ID AS ID,
          r.PAT_ID AS PAT_ID,
          info.VISIT_ID AS VISIT_ID,
          info.FORM AS FORM,
          info.INSTANCE AS INSTANCE,
          CASE WHEN R.TREATMENTARM_ID = 1 THEN '3' ELSE 'N/A' END AS DOSE_ID,
          CASE WHEN R.TREATMENTARM_ID = 1 THEN ds.name ELSE 'N/A' END
             AS ACTIVE_DOSE_NAME,
          CASE WHEN R.TREATMENTARM_ID = 1 THEN 'Active' ELSE 'N/A' END
             AS DOSE,
          0 AS DISPENSE
     FROM VISIT_INFO info
          INNER JOIN DRUG_RNDNO r
             ON r.PAT_ID IS NOT NULL
          LEFT JOIN DRUG_dose_custom ds
             ON ds.id = 3
    WHERE INFO.VISIT_ID = 'AC01D01'
   UNION ALL
   SELECT dat.PAT_ID || '#' || info.VISIT_ID AS ID,
          dat.PAT_ID AS PAT_id,
          info.VISIT_ID AS VISIT_ID,
          info.FORM AS FORM,
          info.INSTANCE AS INSTANCE,
          LAST.VALUE AS DOSE_ID,
          DS.NAME AS ACTIVE_DOSE_NAME,
          CASE WHEN R.TREATMENTARM_ID = 1 THEN dose.NAME ELSE 'N/A' END
             AS DOSE,
          CASE WHEN dose.NAME LIKE '%mg' THEN 1 ELSE 0 END AS DISPENSE
     FROM DATA dat
          INNER JOIN drug_rndno r
             ON dat.pat_id = r.pat_id
          INNER JOIN DRUG_dose_custom dose
             ON dose.id = dat.VALUE
          INNER JOIN VISIT_INFO info
             ON info.FORM = dat.FORM AND dat.PAGE = info.INSTANCE
          INNER JOIN DATA LAST
             ON     LAST.PAT_ID = dat.PAT_ID
                AND LAST.FORM = dat.FORM
                AND LAST.PAGE = dat.PAGE
                AND LAST.FIELD = 'RSP_ACTV_ENCO_DOSE'
          LEFT JOIN DRUG_dose_custom ds
             ON ds.id = LAST.VALUE
    WHERE     dat.FIELD = 'RSP_ENCO_DOSE'
          AND dat.FORM IN (3, 4)
          AND INFO.VISIT_ID != 'AC01D01';


DROP VIEW V_DRUG_PAT_PEMBRO_DOSESTATUS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_PAT_PEMBRO_DOSESTATUS
(
   ID,
   PAT_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   DOSE_STATUS,
   DISPENSE
)
AS
   SELECT dat.PAT_ID || '#' || info.VISIT_ID AS ID,
          dat.PAT_ID AS PAT_ID,
          info.VISIT_ID AS VISIT_ID,
          info.FORM AS FORM,
          info.INSTANCE AS INSTANCE,
          dat.VALUE AS DOSE_STATUS,
          CASE WHEN dat.VALUE = 'Active' THEN 1 ELSE 0 END AS DISPENSE
     FROM    DATA dat
          INNER JOIN
             VISIT_INFO info
          ON     info.FORM = dat.FORM
             AND info.INSTANCE = dat.PAGE
             AND dat.FIELD = 'RSP_PEMB_DOSE'
    WHERE info.FORM IN (3, 4, 5, 6);


DROP VIEW V_DRUG_PROJECT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_PROJECT
(
   ID,
   NAME,
   SPONSOR_PRJ_ID,
   PROTOCOL,
   IS_PARENT,
   BLINDING_LEVEL,
   PARENT_PRJ_ID,
   IS_CURRENT
)
AS
   SELECT PRJ_ID AS ID,
          PRJ_ID AS NAME,
          S_PRJ_ID AS SPONSOR_PRJ_ID,
          PROTOCOL,
          IS_PARENT,
          BLINDING_LEVEL,
          PARENT_PRJ_ID,
          CASE WHEN PRJ_ID = 'P90020903' THEN 1 ELSE 0 END AS IS_CURRENT
     FROM ADMIN_IF.PROJECTS
    WHERE    PRJ_ID = 'P90020903'
          OR PARENT_PRJ_ID = 'P90020903'
          OR PRJ_ID = (SELECT PARENT_PRJ_ID
                         FROM ADMIN_IF.PROJECTS
                        WHERE PRJ_ID = 'P90020903')
          OR PRJ_ID IN (SELECT PRJ_ID
                          FROM ADMIN_IF.PROJECTS
                         WHERE PARENT_PRJ_ID = (SELECT PARENT_PRJ_ID
                                                  FROM ADMIN_IF.PROJECTS
                                                 WHERE PRJ_ID = 'P90020903'));


DROP VIEW V_DRUG_PROJECTION_DISP_MATRIX;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_PROJECTION_DISP_MATRIX
(
   SCHEDULE_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   TREATMENTARM_ID,
   QUANTITY_TO_DISPENSE,
   QUANTITY_TO_PROJECT,
   UNBL_KIT_TYPE_ID,
   COUNTRY_ID
)
AS
   SELECT DISTINCT SCHEDULE_ID,
                   VISIT_ID,
                   FORM,
                   INSTANCE,
                   TREATMENTARM_ID,
                   QUANTITY_TO_DISPENSE,
                   QUANTITY_TO_PROJECT,
                   UNBL_KIT_TYPE_ID,
                   cr.COUNTRY_ID
     FROM    V_DRUG_DISPENSE_MATRIX m
          INNER JOIN
             V_DRUG_COUNTRY_REGION cr
          ON cr.REGION = m.REGION;


DROP VIEW V_DRUG_PROJECT_ATTRIB_VALUES;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_PROJECT_ATTRIB_VALUES
(
   ID,
   KEY,
   STR_VALUE
)
AS
   SELECT ID, KEY, STR_VALUE
     FROM ADMIN_IF.PROJECT_ATTRIBUTE_VALUES
    WHERE PRJ_ID = 'P90020903';


DROP VIEW V_DRUG_REQUESTED_KIT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_REQUESTED_KIT
(
   PAT_ID,
   PAT_NO,
   SCR_NO,
   KIT_TYPE_NAME,
   VISIT_ID,
   KIT_ID,
   KIT_NAME,
   BATCH_NAME,
   KIT_STATUS,
   DISPENSE_DATE,
   BLOCKED,
   COUNT,
   EXPIRATION_DATE,
   RECALL_DATE,
   VERIFICATION_STATUS,
   REPLACED
)
AS
   SELECT p.pat_id,
          p.pat_no,
          p.scr_no,
          t.name AS kit_type_name,
          k.visit_id AS visit_id,
          k.id AS kit_id,
          k.name AS kit_name,
          b.name AS batch_name,
          CASE WHEN k.quarantined = 1 THEN 'QUARANTINED' ELSE s.name END
             AS kit_status,
          k.dispense_date,
          b.blocked,
          k.COUNT,
          k.expiration_date,
          k.recall_date,
          vs.name AS VERIFICATION_STATUS,
          (SELECT CASE WHEN MAX (ID) IS NULL THEN 0 ELSE 1 END
             FROM DRUG_KIT
            WHERE REPLACES_KIT_ID = k.ID)
             REPLACED
     FROM drug_kit k,
          drug_batch b,
          drug_kit_type t,
          usr_pat p,
          drug_status s,
          drug_status vs
    WHERE     k.batch_id = b.id
          AND k.pat_id = p.pat_id
          AND k.kit_type_id = t.id
          AND k.status_id = s.id
          AND k.verification_status_id = vs.id;


DROP VIEW V_DRUG_ROLEPRMLIST;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_ROLEPRMLIST
(
   ROL_ID,
   PRM_ID
)
AS
   SELECT ROL_ID, PRM_ID FROM ADM_ICRF4_IF.ROLEPRMLIST;


DROP VIEW V_DRUG_ROLES;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_ROLES
(
   ID,
   NAME,
   DESCRIPTION,
   DISABLED,
   PRJ_ID
)
AS
   SELECT ROL_ID AS ID,
          ROL_ID AS NAME,
          DESCR AS DESCRIPTION,
          DISABLED AS DISABLED,
          PRJ_ID AS PRJ_ID
     FROM ADM_ICRF4_IF.ROLES
    WHERE PRJ_ID IN (SELECT ID FROM V_DRUG_PROJECT);


DROP VIEW V_DRUG_SCHED_UNSCHED_REL;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_SCHED_UNSCHED_REL
(
   ID,
   SCHEDULE_VISIT_ID,
   UNSCHEDULE_VISIT_ID_1,
   UNSCHEDULE_VISIT_ID_2
)
AS
   SELECT VISIT_ID AS ID,
          VISIT_ID AS SCHEDULE_VISIT_ID,
          UNSCHED1 AS UNSCHEDULE_VISIT_ID_1,
          UNSCHED2 AS UNSCHEDULE_VISIT_ID_2
     FROM V_SCHED_UNSCHDED_REL;


DROP VIEW V_DRUG_STRATA_AGG;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_STRATA_AGG
(
   RNDNO_ID,
   NAME_BLOCKED,
   DESCRIPTION_BLOCKED,
   NAME_STRATA,
   DESCRIPTION_STRATA
)
AS
     SELECT A.RNDNO_ID,
            LISTAGG (
               CASE WHEN F.FACTOR_TYPE = 'Blocked' THEN V.VALUE ELSE NULL END,
               ',')
            WITHIN GROUP (ORDER BY V.NAME)
               AS NAME_BLOCKED,
            LISTAGG (
               CASE
                  WHEN F.FACTOR_TYPE = 'Blocked' THEN V.DESCRIPTION
                  ELSE NULL
               END,
               ',')
            WITHIN GROUP (ORDER BY V.NAME)
               AS DESCRIPTION_BLOCKED,
            LISTAGG (
               CASE WHEN F.FACTOR_TYPE = 'Strata' THEN V.VALUE ELSE NULL END,
               ',')
            WITHIN GROUP (ORDER BY V.NAME)
               AS NAME_STRATA,
            LISTAGG (
               CASE
                  WHEN F.FACTOR_TYPE = 'Strata' THEN V.DESCRIPTION
                  ELSE NULL
               END,
               ',')
            WITHIN GROUP (ORDER BY V.NAME)
               AS DESCRIPTION_STRATA
       FROM DRUG_RNDNO_FACTOR_VALUE A, DRUG_FACTOR F, V_DRUG_FACTOR_VALUE V
      WHERE A.NAME = V.NAME AND A.VALUE = V.VALUE AND A.NAME = F.NAME
   GROUP BY RNDNO_ID;


DROP VIEW V_DRUG_TOTAL_KITCNT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_TOTAL_KITCNT
(
   SETTING_VALUE,
   TOTAL_KITS_USED,
   TOTAL_KITS
)
AS
   SELECT NVL ( (SELECT TO_NUMBER (VALUE)
                   FROM Setting_values
                  WHERE setting_id = 'NOTIF_TRIGGER_KITS_USED'),
               0)
             AS SETTING_VALUE,
          (SELECT COUNT (*)
             FROM DRUG_KIT
            WHERE STATUS_ID IN
                     ('KitStatus_DISPOSED',
                      'KitStatus_DAMAGED',
                      'KitStatus_EXPIRED',
                      'KitStatus_DISPENSED',
                      'KitStatus_EXPIRING_SOON'))
             AS TOTAL_KITS_USED,
          (SELECT COUNT (*) FROM DRUG_KIT) AS TOTAL_KITS
     FROM DUAL;


DROP VIEW V_DRUG_TRACK_LABELED;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_TRACK_LABELED
(
   ID,
   SHIPMENT_ID,
   KIT_ID
)
AS
   SELECT SHIPMENT_ID || ID AS ID, SHIPMENT_ID, ID AS KIT_ID
     FROM DRUG_KIT
    WHERE NAME IS NOT NULL AND SHIPMENT_ID IS NOT NULL
   UNION
   SELECT SHIPMENT_ID || KIT_ID AS ID, SHIPMENT_ID, KIT_ID
     FROM DRUG_TRACK_STATS_LBLD;


DROP VIEW V_DRUG_TRACK_LABELED_CUSTOM;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_TRACK_LABELED_CUSTOM
(
   ID,
   SHIPMENT_ID,
   KIT_ID
)
AS
   SELECT SHIPMENT_ID || ID AS ID, SHIPMENT_ID, ID AS KIT_ID
     FROM DRUG_KIT
    WHERE NAME IS NOT NULL AND SHIPMENT_ID IS NOT NULL
   UNION
   SELECT ID, SHIPMENT_ID, KIT_ID
     FROM (SELECT ROW_NUMBER ()
                  OVER (PARTITION BY KIT_ID ORDER BY CREATED_TIMESTAMP DESC)
                     AS RNO,
                  SHIPMENT_ID || KIT_ID AS ID,
                  SHIPMENT_ID,
                  KIT_ID
             FROM DRUG_TRACK_STATS_LBLD
            WHERE KIT_ID NOT IN (SELECT ID
                                   FROM DRUG_KIT
                                  WHERE SHIPMENT_ID IS NOT NULL)) TAB
    WHERE RNO = 1;


DROP VIEW V_DRUG_TRACK_SHIPMENT_FOR_KIT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_TRACK_SHIPMENT_FOR_KIT
(
   ID,
   KIT_ID,
   SHIPMENT_ID
)
AS
   SELECT SHIPMENT_ID || ':' || KIT_ID AS ID, KIT_ID, SHIPMENT_ID
     FROM (SELECT KIT_ID,
                  SHIPMENT_ID,
                  PRIORITY,
                  MIN (PRIORITY) OVER (PARTITION BY KIT_ID) MIN_PRIORITY
             FROM (SELECT ID KIT_ID, SHIPMENT_ID, 1 AS PRIORITY
                     FROM DRUG_KIT
                    WHERE SHIPMENT_ID IS NOT NULL AND NAME IS NOT NULL
                   UNION ALL
                   SELECT TR.KIT_ID, TR.SHIPMENT_ID, 2 AS PRIORITY
                     FROM (SELECT TR.*,
                                  REQUEST_DATE,
                                  ROW_NUMBER ()
                                  OVER (
                                     PARTITION BY KIT_ID
                                     ORDER BY
                                        REQUEST_DATE DESC,
                                        SHIP.CREATED_TIMESTAMP DESC)
                                     AS MAX_REQUEST_DATE_POSITION,
                                  SHIP.FROM_LOCATION_ID,
                                  SHIP.TO_LOCATION_ID
                             FROM DRUG_TRACK_STATS_LBLD TR,
                                  DRUG_SHIPMENT SHIP
                            WHERE TR.SHIPMENT_ID = SHIP.ID) TR,
                          V_DRUG_LOCATION FROM_LOCATION,
                          V_DRUG_LOCATION TO_LOCATION
                    WHERE     1 = TR.MAX_REQUEST_DATE_POSITION
                          AND TR.FROM_LOCATION_ID = FROM_LOCATION.ID
                          AND TR.TO_LOCATION_ID = TO_LOCATION.ID
                          AND NOT (    FROM_LOCATION.SUBCLASS = 'Warehouse'
                                   AND TO_LOCATION.SUBCLASS = 'Warehouse')))
    WHERE PRIORITY = MIN_PRIORITY;


DROP VIEW V_DRUG_TRACK_UNLABELED;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_TRACK_UNLABELED
(
   ID,
   BATCH_ID,
   SHIPMENT_ID,
   KIT_TYPE_ID,
   KIT_AMOUNT,
   COUNT
)
AS
     SELECT    BATCH_ID
            || SHIPMENT_ID
            || KIT_TYPE_ID
            || CASE WHEN COUNT IS NULL THEN '' ELSE TO_CHAR (COUNT) END
               AS ID,
            BATCH_ID,
            SHIPMENT_ID,
            KIT_TYPE_ID,
            SUM (KIT_AMOUNT) AS KIT_AMOUNT,
            COUNT
       FROM (SELECT BATCH_ID,
                    SHIPMENT_ID,
                    KIT_TYPE_ID,
                    KIT_AMOUNT,
                    COUNT
               FROM DRUG_TRACK_STATS_UNLBLD
             UNION ALL
               SELECT BATCH_ID,
                      SHIPMENT_ID,
                      KIT_TYPE_ID,
                      COUNT (*) AS KIT_AMOUNT,
                      COUNT
                 FROM DRUG_KIT
                WHERE NAME IS NULL AND SHIPMENT_ID IS NOT NULL
             GROUP BY BATCH_ID,
                      SHIPMENT_ID,
                      KIT_TYPE_ID,
                      COUNT)
   GROUP BY BATCH_ID,
            SHIPMENT_ID,
            KIT_TYPE_ID,
            COUNT;


DROP VIEW V_DRUG_USER;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_USER
(
   ID,
   TITLE,
   FNAME,
   MNAME,
   LNAME,
   EMAIL,
   DISABLED
)
AS
   SELECT USR_ID AS ID,
          TITLE,
          FNAME,
          MNAME,
          LNAME,
          EMAIL,
          DISABLED
     FROM ADMIN_IF.USERS;


DROP VIEW V_DRUG_WITHDRAWN_PATS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_WITHDRAWN_PATS
(
   PAT_ID,
   SIT_ID,
   CREATED,
   CREATED_BY,
   MODIFIED,
   MODIFIED_BY,
   SIGNED,
   INCLUDED,
   SCR_NO,
   PAT_NO,
   INITIALS,
   BIRTHDATE,
   WITHDRAWN_DATE,
   RANDOM_DATE,
   STATUS,
   STATUS_TS,
   MODIFIED_TIMESTAMP,
   MODIFIED_BY_USER,
   CREATED_TIMESTAMP,
   CREATED_BY_USER,
   PP_ID
)
AS
   SELECT p."PAT_ID",
          p."SIT_ID",
          p."CREATED",
          p."CREATED_BY",
          p."MODIFIED",
          p."MODIFIED_BY",
          p."SIGNED",
          p."INCLUDED",
          p."SCR_NO",
          p."PAT_NO",
          p."INITIALS",
          p."BIRTHDATE",
          p."WITHDRAWN_DATE",
          p."RANDOM_DATE",
          p."STATUS",
          p."STATUS_TS",
          p."MODIFIED_TIMESTAMP",
          p."MODIFIED_BY_USER",
          p."CREATED_TIMESTAMP",
          p."CREATED_BY_USER",
          p."PP_ID"
     FROM drug_rndno r, usr_pat p
    WHERE r.pat_no = p.pat_no AND r.status_id = 'RndNoStatus_WITHDRAWN';


DROP VIEW V_DRUG_WORKER;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DRUG_WORKER
(
   ID,
   PROJECT,
   LOCATION_ID,
   FNAME,
   MNAME,
   LNAME,
   EMAIL,
   LANG_ID,
   LOGIN,
   UNBLINDING_KEY,
   SYSTEM_USER_FLAG,
   ROL_ID,
   USR_ID,
   DISABLED
)
AS
   SELECT TO_CHAR (wrk_id) AS id,
          webapp AS project,
          l.id AS location_id,
          u.fname,
          u.mname,
          u.lname,
          u.email,
          w.lang_id,
          w.login,
          w.unblinding_key,
          w.system_user_flag,
          w.rol_id,
          w.usr_id,
          w.disabled
     FROM ADMIN_IF.workers w,
          ADMIN_IF.users u,
          V_DRUG_LOCATION l,
          ADMIN_IF.groups s
    WHERE     w.usr_id = u.usr_id
          AND s.prj_id IN (SELECT ID FROM V_DRUG_PROJECT)
          AND w.grp_id = l.id(+)
          AND w.grp_id = s.grp_id
          AND s.env_id = 1;


DROP VIEW V_DUPCHECKFIELDS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DUPCHECKFIELDS
(
   FIELD,
   DOB_FORMAT,
   COUNTRY_ID
)
AS
     SELECT field, DOB_FORMAT, location_id AS country_id
       FROM (SELECT field, DOB_FORMAT, location_id
               FROM (    SELECT REGEXP_SUBSTR (value1,
                                               '[^,]+',
                                               1,
                                               LEVEL)
                                   AS field
                           FROM (SELECT VALUE AS value1
                                   FROM SETTING_VALUES
                                  WHERE Setting_id = 'DUP_CHECK_FIELDS')
                     CONNECT BY REGEXP_SUBSTR (value1,
                                               '[^,]+',
                                               1,
                                               LEVEL)
                                   IS NOT NULL) a,
                    (SELECT VALUE AS DOB_FORMAT, location_id
                       FROM SETTING_VALUES
                      WHERE Setting_id = 'DOB_FORMAT') b)
      WHERE (   (field NOT IN ('DOBMON', 'DOBDAY'))
             OR (field = 'DOBMON' AND DOB_FORMAT >= 2)
             OR (field = 'DOBDAY' AND DOB_FORMAT = 3))
   ORDER BY field ASC;


DROP VIEW V_DYNAMIC_VISIT_SCHEDULE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_DYNAMIC_VISIT_SCHEDULE
(
   ID,
   PAT_ID,
   VISIT_ID,
   VISIT_DATE,
   EARLIEST_VISIT_DATE,
   LATEST_VISIT_DATE,
   VISIT_SEQ_NO,
   VISIT_DATE_TYPE
)
AS
   SELECT vs.ID,
          vs.PAT_ID,
          vs.VISIT_ID,
          vs.VISIT_DATE,
          vs.EARLIEST_VISIT_DATE,
          vs.LATEST_VISIT_DATE,
          vs.VISIT_NO "VISIT_SEQ_NO",
          CASE
             WHEN vs.VISIT_STATE IS NOT NULL
             THEN
                vs.VISIT_STATE
             WHEN     vs.LATEST_VISIT_DATE IS NOT NULL
                  AND t.LOCAL_DATE <= vs.LATEST_VISIT_DATE
             THEN
                'PLANNED'
             WHEN     vs.LATEST_VISIT_DATE IS NOT NULL
                  AND t.LOCAL_DATE > vs.LATEST_VISIT_DATE
             THEN
                'MISSING'
             ELSE
                NULL
          END
             "VISIT_DATE_TYPE"
     FROM DYNAMIC_VISIT_SCHEDULE vs
          JOIN USR_PAT u
             ON u.PAT_ID = vs.PAT_ID
          JOIN V_LOCAL_TIME t
             ON u.SIT_ID = t.GRP_ID;


DROP VIEW V_EDC_VISITS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_EDC_VISITS
(
   ID,
   NAME,
   DESCR
)
AS
   SELECT DISTINCT VISIT_ID "ID", NAME, DESCR FROM VISIT_INFO;


DROP VIEW V_IRB_DATA;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_IRB_DATA
(
   SIT_ID,
   NAME,
   GRP_NUMBER,
   INDEXNO,
   "DATE",
   EXTENSION
)
AS
     SELECT r.SIT_ID,
            r.NAME,
            r.GRP_NUMBER,
            r.INDEXNO,
            TO_DATE (
               MAX (
                  CASE
                     WHEN a.KEY LIKE 'IRB_EXP_DATE:%' THEN VALUE
                     ELSE NULL
                  END),
               'DD-Mon-YYYY',
               'NLS_DATE_LANGUAGE=AMERICAN')
               "DATE",
            MAX (
               CASE
                  WHEN a.KEY LIKE 'IRB_EXP_EXTENSION:%' THEN VALUE
                  ELSE NULL
               END)
               "EXTENSION"
       FROM V_IRB_ROWS r, ADMIN_IF.SITE_ATTRIBUTE_VALUES a
      WHERE     r.SIT_ID = a.SIT_ID
            AND TO_CHAR (r.INDEXNO) = REGEXP_REPLACE (KEY, '.*:', '')
   GROUP BY r.SIT_ID,
            r.INDEXNO,
            r.NAME,
            r.GRP_NUMBER
   ORDER BY r.GRP_NUMBER, r.INDEXNO;


DROP VIEW V_IRB_EXPIRATION;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_IRB_EXPIRATION
(
   SIT_ID,
   NAME,
   GRP_NUMBER,
   VALID_UNTIL
)
AS
   SELECT d.SIT_ID,
          NAME,
          GRP_NUMBER,
          "DATE" + DECODE (EXTENSION, NULL, 0, EXTENSION) "VALID_UNTIL"
     FROM V_IRB_DATA d,
          (  SELECT SIT_ID, MAX (INDEXNO) "MAXINDEX"
               FROM V_IRB_ROWS
           GROUP BY SIT_ID) r
    WHERE d.SIT_ID = r.SIT_ID AND d.INDEXNO = r.MAXINDEX;


DROP VIEW V_IRB_INDEX;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_IRB_INDEX
(
   GRP_ID,
   NAME,
   GRP_NUMBER,
   CURRENT_DATE_KEY,
   CURRENT_EXTENSION_KEY
)
AS
     SELECT g.GRP_ID,
            g.NAME,
            g.GRP_NUMBER,
            'IRB_EXP_DATE:' || NVL (MAX (r.MAXINDEX + 1), 0) "CURRENT_DATE_KEY",
            MAX (
               CASE
                  WHEN r.MAXINDEX = d.INDEXNO AND d.EXTENSION IS NULL
                  THEN
                     'IRB_EXP_EXTENSION:' || r.MAXINDEX
                  ELSE
                     NULL
               END)
               "CURRENT_EXTENSION_KEY"
       FROM (  SELECT SIT_ID, MAX (INDEXNO) "MAXINDEX"
                 FROM V_IRB_ROWS
             GROUP BY SIT_ID) r,
            V_IRB_DATA d,
            ADMIN_IF.GROUPS g
      WHERE     g.GRP_ID = d.SIT_ID(+)
            AND g.GRP_ID = r.SIT_ID(+)
            AND g.PRJ_ID = 'P90020903'
            AND g.CAT_ID = 10
   GROUP BY g.GRP_ID, g.NAME, g.GRP_NUMBER
   ORDER BY GRP_NUMBER;


DROP VIEW V_IRB_ROWS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_IRB_ROWS
(
   SIT_ID,
   NAME,
   GRP_NUMBER,
   INDEXNO
)
AS
   SELECT a.SIT_ID,
          g.NAME,
          g.GRP_NUMBER,
          TO_NUMBER (REGEXP_REPLACE (KEY, '.*:', '')) "INDEXNO"
     FROM ADMIN_IF.GROUPS g, ADMIN_IF.SITE_ATTRIBUTE_VALUES a
    WHERE     g.GRP_ID = a.SIT_ID
          AND g.PRJ_ID = 'P90020903'
          AND KEY LIKE 'IRB_EXP_DATE%';


DROP VIEW V_LABR_SET_PARAMS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_LABR_SET_PARAMS
(
   SET_NAME,
   SET_LABEL,
   SET_DESCR,
   PARAM,
   PARAM_LABEL,
   PARAM_DESCR,
   UNIT,
   UNIT_LABEL,
   UNIT_DESCR
)
AS
     SELECT s.SET_NAME,
            s.LABEL AS SET_LABEL,
            s.DESCR AS SET_DESCR,
            sp.PARAM,
            sp.LABEL AS PARAM_LABEL,
            sp.DESCR AS PARAM_DESCR,
            g.UNIT,
            u.LABEL UNIT_LABEL,
            u.DESCR AS UNIT_DESCR
       FROM LABR_SET_DESCR s,
            LABR_SET_PARAMS sp,
            LABR_UNIT_GROUPS g,
            LABR_UNITS u
      WHERE     s.SET_NAME = sp.SET_NAME
            AND sp.UNIT_GROUP = g.UNIT_GROUP
            AND u.UNIT = g.UNIT
   ORDER BY s.SET_NAME, sp.PARAM, g.UNIT;


DROP VIEW V_LOCAL_TIME;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_LOCAL_TIME
(
   CAT_ID,
   GRP_ID,
   NAME,
   "SYSDATE",
   TIMEZONE_ID,
   LOCAL_DATETIME,
   LOCAL_DATE,
   LOCAL_MS
)
AS
   SELECT CAT_ID,
          GRP_ID,
          NAME,
          SYSDATE "SYSDATE",
          TIMEZONE TIMEZONE_ID,
          LOCAL_DATE_TIME "LOCAL_DATETIME",
          TRUNC (LOCAL_DATE_TIME) "LOCAL_DATE",
              EXTRACT (
                 DAY FROM (  SYS_EXTRACT_UTC (
                                CAST (LOCAL_DATE_TIME AS TIMESTAMP))
                           - TO_TIMESTAMP ('1970-01-01', 'YYYY-MM-DD')))
            * 86400000
          + TO_NUMBER (
               TO_CHAR (
                  SYS_EXTRACT_UTC (CAST (LOCAL_DATE_TIME AS TIMESTAMP)),
                  'SSSSSFF3'))
             "LOCAL_MS"
     FROM ADMIN_IF.GROUPS;


DROP VIEW V_LOW_INVENTORY;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_LOW_INVENTORY
(
   LOCATION_ID,
   LOCATION_NAME,
   KIT_TYPE_NAME,
   KIT_TYPE_ID,
   NO_LOC_NO_PAR,
   NO_LOC_WITH_PAR,
   WITH_LOC_NO_PAR,
   WITH_LOC_WITH_PAR,
   SETTING_VALUE
)
AS
   SELECT loc.locationid AS LOCATION_ID,
          loc.locationname AS Location_NAME,
          LOC.kittypename AS KIT_TYPE_NAME,
          loc.kittypeid AS KIT_TYPE_ID,
          set1.VALUE AS NO_LOC_NO_PAR,
          set2.VALUE AS NO_LOC_WITH_PAR,
          set3.VALUE AS WITH_LOC_NO_PAR,
          set4.VALUE AS WITH_LOC_WITH_PAR,
          NVL (NVL (NVL (set4.VALUE, set3.VALUE), set2.VALUE), SET1.VALUE)
             AS SETTING_VALUE
     FROM (SELECT loc1.id AS locationid,
                  loc1.name AS locationname,
                  typ.id AS kittypeid,
                  typ.name AS kittypename
             FROM V_DRUG_LOCATION LOC1, DRUG_KIT_TYPE typ
            WHERE     typ.subclass = 'UnblindedKitType'
                  AND loc1.SUBCLASS = 'Warehouse') loc
          LEFT JOIN (SELECT VALUE
                       FROM SETTING_VALUES
                      WHERE     setting_id = 'WAREHOUSE_LOW_INV'
                            AND PARAMETER_ID IS NULL
                            AND Location_id IS NULL) set1
             ON 1 = 1
          LEFT JOIN (SELECT VALUE, PARAMETER_ID
                       FROM SETTING_VALUES
                      WHERE     setting_id = 'WAREHOUSE_LOW_INV'
                            AND PARAMETER_ID IS NOT NULL
                            AND Location_id IS NULL) set2
             ON set2.PARAMETER_ID = loc.kittypeid
          LEFT JOIN (SELECT VALUE, LOCATION_ID
                       FROM SETTING_VALUES
                      WHERE     setting_id = 'WAREHOUSE_LOW_INV'
                            AND PARAMETER_ID IS NULL
                            AND Location_id IS NOT NULL) set3
             ON LOC.locationid = set3.location_id
          LEFT JOIN (SELECT VALUE, location_id, PARAMETER_ID
                       FROM SETTING_VALUES
                      WHERE     setting_id = 'WAREHOUSE_LOW_INV'
                            AND PARAMETER_ID IS NOT NULL
                            AND Location_id IS NOT NULL) set4
             ON     set4.PARAMETER_ID = loc.kittypeid
                AND LOC.locationid = set4.location_id;


DROP VIEW V_PAT_DISPENSE_KIT_QTY;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_DISPENSE_KIT_QTY
(
   PAT_ID,
   VISIT_ID,
   FORM,
   PAGE,
   KIT_TYPE_NAME,
   KIT_TYPE_ID,
   QTY
)
AS
   SELECT d.pat_id,
          vf.visit_id,
          d.FORM,
          D.page,
          VD.KIT_TYPE_NAME,
          vd.id AS kit_type_id,
          VD.QUANTITY_TO_DISPENSE AS qty
     FROM data d
          INNER JOIN drug_rndno r
             ON R.PAT_ID = d.pat_id
          INNER JOIN (SELECT DISTINCT V.DOSE_ID,
                                      V.TREATMENTARM_ID,
                                      V.UNBL_KIT_TYPE AS KIT_TYPE_NAME,
                                      V.QUANTITY_TO_DISPENSE,
                                      V.UNBL_KIT_TYPE_ID AS id
                        FROM V_DRUG_DISPENSE_MATRIX_DOSE v
                       WHERE dose_id != 4) vd
             ON     d.VALUE = VD.DOSE_ID
                AND VD.TREATMENTARM_ID = R.TREATMENTARM_ID
          INNER JOIN data dat
             ON     dat.pat_id = d.pat_id
                AND d.FORM = dat.FORM
                AND d.page = dat.page
          INNER JOIN visit_info vf
             ON VF.FORM = D.FORM AND VF.INSTANCE = d.page
    WHERE     R.TREATMENTARM_ID = 1
          AND ( (MOD (D.PAGE, 3) = 0 AND d.FORM = 3) OR d.FORM = 4)
          AND DAT.FIELD = 'RSP_ENCO_DOSE'
          AND d.field = 'RSP_ACTV_ENCO_DOSE'
          AND dat.VALUE > 0
   UNION ALL
   SELECT d.pat_id,
          vi.visit_id,
          d.FORM,
          d.page,
          kt.name,
          KT.ID AS kit_type_id,
          4 AS qty
     FROM data d
          INNER JOIN visit_info vi
             ON vi.FORM = d.FORM AND VI.INSTANCE = d.page
          INNER JOIN drug_kit_type kt
             ON KT.NAME = 2
    WHERE d.FIELD = 'RSP_PEMBRO_RESTART_CONT' AND d.VALUE = '1'
   UNION ALL
   SELECT d.PAT_ID,
          v.VISIT_ID,
          d.FORM,
          d.page,
          k.KIT_TYPE_NAME AS kit_type_name,
          k.kit_type_id,
          TO_NUMBER (d.VALUE) AS qty
     FROM DATA d
          INNER JOIN VISIT_INFO v
             ON d.FORM = v.FORM AND d.PAGE = v.INSTANCE
          INNER JOIN (SELECT kt.ID AS KIT_TYPE_ID,
                             kt.NAME AS KIT_TYPE_NAME,
                             (CASE
                                 WHEN kt.NAME = '3' THEN 'RSP_CETU_QTY_3'
                                 WHEN kt.NAME = '4' THEN 'RSP_CETU_QTY_4'
                              END)
                                AS DATA_FIELD
                        FROM DRUG_KIT_TYPE kt
                       WHERE     subclass = 'UnblindedKitType'
                             AND kt.name IN (3, 4)) k
             ON k.DATA_FIELD = d.FIELD;


DROP VIEW V_PAT_DOSE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_DOSE
(
   PAT_ID,
   VISIT_ID,
   DOSE_ID
)
AS
     SELECT d.PAT_ID, v.VISIT_ID, ds.ID AS dose_id
       FROM DATA d
            INNER JOIN VISIT_INFO v
               ON d.FORM = v.FORM AND d.PAGE = v.INSTANCE AND d.FIELD = 'DOSE'
            INNER JOIN DRUG_DOSE ds
               ON ds.name = d.VALUE
   GROUP BY d.PAT_ID, v.VISIT_ID, ds.id;


DROP VIEW V_PAT_DYNAMIC_VISIT_SCHEDULE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_DYNAMIC_VISIT_SCHEDULE
(
   ID,
   PAT_ID,
   VISIT_ID,
   VISIT_DATE,
   EARLIEST_VISIT_DATE,
   LATEST_VISIT_DATE,
   VISIT_NO,
   VALUE,
   VISIT_STATE,
   VISIT_ENTERED
)
AS
     SELECT v.PAT_ID || '.' || v.VISIT_ID "ID",
            v.PAT_ID,
            v.VISIT_ID,
            CASE
               WHEN v.D_VISIT IS NOT NULL THEN v.D_VISIT
               ELSE PLANNED_VISIT
            END
               "VISIT_DATE",
            CASE
               WHEN v.D_VISIT IS NOT NULL THEN v.D_VISIT
               ELSE PLANNED_VISIT - v.TOLERANCE_SOFT_MIN
            END
               "EARLIEST_VISIT_DATE",
            CASE
               WHEN v.D_VISIT IS NOT NULL THEN v.D_VISIT
               ELSE PLANNED_VISIT + v.TOLERANCE_SOFT_MAX
            END
               "LATEST_VISIT_DATE",
            v.VISIT_NO,
            dd.VALUE,
            CASE
               WHEN (dd.VALUE IS NOT NULL AND v.D_VISIT IS NOT NULL)
               THEN
                  'DONE'
               WHEN     v.D_VISIT IS NULL
                    AND d.SPEC_VALUE IN (SELECT SPEC_VALUE
                                           FROM DATA_SPEC_VALUES
                                          WHERE NAME = 'ND')
               THEN
                  'SKIPPED'
               ELSE
                  NULL
            END
               "VISIT_STATE",
            CASE
               WHEN (v.D_VISIT IS NOT NULL)
               THEN
                  'ENTERED'
               WHEN     v.D_VISIT IS NULL
                    AND d.SPEC_VALUE IN (SELECT SPEC_VALUE
                                           FROM DATA_SPEC_VALUES
                                          WHERE NAME = 'ND')
               THEN
                  'SKIPPED'
               ELSE
                  NULL
            END
               "VISIT_ENTERED"
       FROM V_PAT_PLANNED v
            JOIN USR_PAT u
               ON     u.PAT_ID = v.PAT_ID
                  AND (   u.WITHDRAWN_DATE IS NULL
                       OR (DECODE (v.D_VISIT,
                                   NULL, v.PLANNED_VISIT - TOLERANCE_SOFT_MIN,
                                   v.D_VISIT) < u.WITHDRAWN_DATE))
            JOIN VISIT_INFO i
               ON i.SCHEDULE_ID = v.SCHEDULE_ID AND i.VISIT_ID = v.VISIT_ID
            LEFT JOIN DATA d
               ON     v.PAT_ID = d.PAT_ID
                  AND d.FIELD = 'VISYEA'
                  AND d.COUNTER = 0
                  AND d.FORM = i.FORM
                  AND d.PAGE = i.INSTANCE
            LEFT JOIN PSTAT_VIS ps
               ON ps.SCHEDULE_ID = v.SCHEDULE_ID AND ps.VISIT_ID = v.VISIT_ID
            LEFT JOIN DATA dd
               ON     v.PAT_ID = dd.PAT_ID
                  AND dd.FIELD = ps.FIELD
                  AND dd.COUNTER = 0
                  AND dd.FORM = i.FORM
                  AND dd.PAGE = i.INSTANCE
   ORDER BY PAT_ID, v.VISIT_NO;


DROP VIEW V_PAT_KITDISP_SEQ;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_KITDISP_SEQ
(
   PAT_ID,
   VISIT_ID,
   UNBL_KIT_TYPE_ID,
   VISITSEQUENCE,
   TOPRNK
)
AS
     SELECT pat_id,
            k.visit_id,
            k.UNBL_KIT_TYPE_ID,
            visitsequence,
            RANK ()
            OVER (PARTITION BY pat_id, k.UNBL_KIT_TYPE_ID
                  ORDER BY visitsequence DESC)
               AS topRnk
       FROM    DRUG_KIT k
            INNER JOIN
               V_SCHED_UNSCHED_SEQ seq
            ON seq.visit_id = k.visit_id
      WHERE     pat_id IS NOT NULL
            AND recall_date IS NULL
            AND dispense_date IS NOT NULL
   GROUP BY pat_id,
            k.visit_id,
            k.UNBL_KIT_TYPE_ID,
            visitsequence
   ORDER BY k.UNBL_KIT_TYPE_ID, visitsequence DESC;


DROP VIEW V_PAT_PLANNED;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_PLANNED
(
   SCHEDULE_ID,
   PAT_ID,
   SCR_NO,
   SIT_ID,
   VISIT_NO,
   VISIT_ID,
   C_VISIT,
   DURATION,
   TOLERANCE_SOFT_MIN,
   TOLERANCE_SOFT_MAX,
   TOLERANCE_HARD_MIN,
   TOLERANCE_HARD_MAX,
   REF_VISIT_ID,
   REF_VISIT_NO,
   REF_VISIT,
   D_VISIT,
   PLANNED_VISIT
)
AS
     SELECT v."SCHEDULE_ID",
            v."PAT_ID",
            v."SCR_NO",
            v."SIT_ID",
            v."VISIT_NO",
            v."VISIT_ID",
            v."C_VISIT",
            v."DURATION",
            v."TOLERANCE_SOFT_MIN",
            v."TOLERANCE_SOFT_MAX",
            v."TOLERANCE_HARD_MIN",
            v."TOLERANCE_HARD_MAX",
            v."REF_VISIT_ID",
            v."REF_VISIT_NO",
            v."REF_VISIT",
            TO_DATE (v.C_VISIT, 'DD.MM.YYYY') "D_VISIT",
            CASE
               WHEN visit_no <= 1 OR v.C_VISIT IS NOT NULL
               THEN
                  CALC_VISIT_DATE (v.SCHEDULE_ID,
                                   v.REF_VISIT,
                                   v.REF_VISIT_NO,
                                   v.VISIT_NO)
               ELSE
                  CALC_VISIT_DATE (v.SCHEDULE_ID,
                                   maxvisitdate,
                                   maxvisitno,
                                   v.VISIT_NO)
            END
               "PLANNED_VISIT"
       FROM    V_PAT_VISITS_REF v
            LEFT JOIN
               (SELECT VISIT_ID,
                       PAT_ID AS maxpatid,
                       MAX_VISIT_NO AS maxvisitno,
                       TO_DATE (C_VISIT, 'dd.mm.yyyy') AS maxvisitdate
                  FROM (SELECT VISIT_ID,
                               MAX (VISIT_NO) OVER (PARTITION BY PAT_ID)
                                  MAX_VISIT_NO,
                               VISIT_NO,
                               PAT_ID,
                               C_VISIT
                          FROM v_pat_visits
                         WHERE C_VISIT IS NOT NULL)
                 WHERE MAX_VISIT_NO = VISIT_NO) p
            ON v.pat_id = p.maxpatid
   ORDER BY v.PAT_ID, v.VISIT_NO;


DROP VIEW V_PAT_SCHEDULE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_SCHEDULE
(
   PAT_ID,
   SCR_NO,
   PAT_NO,
   SIT_ID,
   SCHEDULE_ID,
   VISIT_ID,
   VISIT_NO,
   DURATION,
   DURATION_UNIT,
   TOLERANCE_SOFT_MIN,
   TOLERANCE_SOFT_MAX,
   TOLERANCE_HARD_MIN,
   TOLERANCE_HARD_MAX,
   TOLERANCE_SOFT,
   TOLERANCE_HARD,
   TOLERANCE_UNIT,
   REF_VISIT_ID,
   NAME,
   DESCR,
   FORM,
   INSTANCE,
   COUNTER
)
AS
   SELECT p.PAT_ID,
          p.SCR_NO,
          p.PAT_NO,
          p.SIT_ID,
          p.SCHEDULE_ID,
          s.VISIT_ID,
          s.VISIT_NO,
          s.DURATION,
          s.DURATION_UNIT,
          s.TOLERANCE_SOFT_MIN,
          s.TOLERANCE_SOFT_MAX,
          s.TOLERANCE_HARD_MIN,
          s.TOLERANCE_HARD_MAX,
          CASE
             WHEN s.TOLERANCE_SOFT_MIN <> s.TOLERANCE_SOFT_MAX
             THEN
                '-' || s.TOLERANCE_SOFT_MIN || '/+' || s.TOLERANCE_SOFT_MAX
             ELSE
                TO_CHAR (s.TOLERANCE_SOFT_MIN)
          END
             "TOLERANCE_SOFT",
          CASE
             WHEN s.TOLERANCE_HARD_MIN <> s.TOLERANCE_HARD_MAX
             THEN
                '-' || s.TOLERANCE_HARD_MIN || '/+' || s.TOLERANCE_HARD_MAX
             ELSE
                TO_CHAR (s.TOLERANCE_HARD_MIN)
          END
             "TOLERANCE_HARD",
          s.TOLERANCE_UNIT,
          s.REF_VISIT_ID,
          i.NAME,
          i.DESCR,
          i.FORM,
          i.INSTANCE,
          i.COUNTER
     FROM VISIT_SCHEDULE s, VISIT_INFO i, V_PAT_SCHEDULE_IMPL p
    WHERE     p.SCHEDULE_ID = s.SCHEDULE_ID
          AND p.SCHEDULE_ID = i.SCHEDULE_ID
          AND s.VISIT_ID = i.VISIT_ID;


DROP VIEW V_PAT_SCHEDULE_IMPL;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_SCHEDULE_IMPL
(
   PAT_ID,
   SCR_NO,
   PAT_NO,
   SIT_ID,
   SCHEDULE_ID
)
AS
   SELECT PAT.PAT_ID,
          SCR_NO,
          pat.PAT_NO,
          SIT_ID,
          CASE
             WHEN dat1.VALUE IS NULL THEN 'DEFAULT'
             WHEN vt.name = 'A' THEN 'ARMA'
             WHEN vt.name = 'B' THEN 'ARMB'
          END
             "SCHEDULE_ID"
     FROM USR_PAT pat
          LEFT JOIN DATA dat1
             ON pat.pat_id = dat1.pat_id AND dat1.Field = 'RND_DATE'
          LEFT JOIN DRUG_RNDNO R
             ON pat.PAT_ID = R.PAT_ID
          LEFT JOIN DRUG_TREATMENTARM vt
             ON R.TREATMENTARM_ID = vt.ID;


DROP VIEW V_PAT_SITE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_SITE
(
   PAT_ID,
   SCR_NO,
   SITE_ID,
   SITE_NAME,
   COUNTRY_ID,
   LOCAL_DATE_TIME
)
AS
   SELECT u.pat_id,
          u.scr_no,
          l.id site_id,
          l.name site_name,
          l.country_id,
          l.local_date_time
     FROM usr_pat u INNER JOIN v_drug_location l ON l.id = u.sit_id;


DROP VIEW V_PAT_STATUS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_STATUS
(
   PAT_ID,
   VISIT_NO,
   SCR_NO,
   SIT_ID,
   STATUS,
   STATUS_TS,
   SUBSTATUS,
   SUBSTATUS_TS
)
AS
   SELECT u.PAT_ID,
          v.VISIT_NO,
          u.SCR_NO,
          u.SIT_ID,
          CASE
             WHEN u.WITHDRAWN_DATE IS NOT NULL AND dsc.VALUE IS NULL
             THEN
                'Unblinded'
             ELSE
                v.STATUS
          END
             "STATUS",
          CASE
             WHEN u.WITHDRAWN_DATE IS NOT NULL
             THEN
                TO_CHAR (WITHDRAWN_DATE, 'dd-Mon-yyyy HH24:MI:SS')
             ELSE
                v.STATUS_TS
          END
             "STATUS_TS",
          SUBSTATUS,
          SUBSTATUS_TS
     FROM V_PAT_STATUS_IMPL v
          INNER JOIN USR_PAT u
             ON v.PAT_ID = u.PAT_ID
          LEFT JOIN DATA dsc
             ON dsc.PAT_ID = u.PAT_ID AND dsc.FIELD = 'DSC_DATE';


DROP VIEW V_PAT_STATUS_IMPL;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_STATUS_IMPL
(
   PAT_ID,
   VISIT_NO,
   SCR_NO,
   SIT_ID,
   STATUS,
   STATUS_TS,
   SUBSTATUS,
   SUBSTATUS_TS
)
AS
   SELECT DISTINCT
          m.PAT_ID,
          m.VISIT_NO,
          u.SCR_NO,
          u.SIT_ID,
          CASE WHEN f.STATUS IS NOT NULL THEN f.STATUS ELSE p.STATUS END
             "STATUS",
          CASE
             WHEN f.STATUS IS NOT NULL
             THEN
                (SELECT VALUE
                   FROM DATA d
                  WHERE     d.PAT_ID = m.PAT_ID
                        AND d.FIELD = mf.FIELD
                        AND d.FORM = fi.FORM
                        AND d.PAGE = fi.INSTANCE
                        AND d.COUNTER = fi.COUNTER)
             ELSE
                (SELECT VALUE
                   FROM DATA d
                  WHERE     d.PAT_ID = m.PAT_ID
                        AND d.FIELD = mm.FIELD
                        AND d.FORM = sm.FORM
                        AND d.PAGE = sm.INSTANCE
                        AND d.COUNTER = sm.COUNTER)
          END
             "STATUS_TS",
          s.NAME "SUBSTATUS",
          (SELECT VALUE
             FROM DATA d
            WHERE     d.PAT_ID = m.PAT_ID
                  AND d.FIELD = p.FIELD
                  AND d.FORM = s.FORM
                  AND d.PAGE = s.INSTANCE
                  AND d.COUNTER = s.COUNTER)
             "SUBSTATUS_TS"
     FROM V_PSTAT_MAX m
          LEFT JOIN V_PAT_SCHEDULE s
             ON m.PAT_ID = s.PAT_ID AND m.VISIT_NO = s.VISIT_NO
          LEFT JOIN PSTAT_VIS p
             ON s.VISIT_ID = p.VISIT_ID AND s.SCHEDULE_ID = p.SCHEDULE_ID
          LEFT JOIN V_PSTAT_FINAL f
             ON     m.PAT_ID = f.PAT_ID
                AND (p.SCHEDULE_ID IS NULL OR p.SCHEDULE_ID = f.SCHEDULE_ID)
          JOIN USR_PAT u
             ON m.PAT_ID = u.PAT_ID
          LEFT JOIN PSTAT_MAP mm
             ON p.STATUS = mm.STATUS AND p.SCHEDULE_ID = mm.SCHEDULE_ID
          LEFT JOIN VISIT_INFO sm
             ON mm.VISIT_ID = sm.VISIT_ID AND mm.SCHEDULE_ID = sm.SCHEDULE_ID
          LEFT JOIN PSTAT_MAP mf
             ON f.STATUS = mf.STATUS AND f.SCHEDULE_ID = mf.SCHEDULE_ID
          LEFT JOIN VISIT_INFO fi
             ON mf.VISIT_ID = fi.VISIT_ID AND mf.SCHEDULE_ID = fi.SCHEDULE_ID;


DROP VIEW V_PAT_VISITS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_VISITS
(
   PAT_ID,
   SCR_NO,
   PAT_NO,
   SIT_ID,
   VISIT_NO,
   FORM,
   INSTANCE,
   VISIT_ID,
   DURATION,
   DURATION_UNIT,
   TOLERANCE_SOFT_MIN,
   TOLERANCE_SOFT_MAX,
   TOLERANCE_HARD_MIN,
   TOLERANCE_HARD_MAX,
   TOLERANCE_UNIT,
   SCHEDULE_ID,
   REF_VISIT_ID,
   C_VISIT
)
AS
     SELECT s.PAT_ID,
            s.SCR_NO,
            s.PAT_NO,
            s.SIT_ID,
            s.VISIT_NO,
            s.FORM,
            s.INSTANCE,
            s.VISIT_ID,
            s.DURATION,
            s.DURATION_UNIT,
            s.TOLERANCE_SOFT_MIN,
            s.TOLERANCE_SOFT_MAX,
            s.TOLERANCE_HARD_MIN,
            s.TOLERANCE_HARD_MAX,
            s.TOLERANCE_UNIT,
            s.SCHEDULE_ID,
            s.REF_VISIT_ID,
            (CASE
                WHEN     MAX (
                            CASE
                               WHEN d.field = 'VISDAY' THEN VALUE
                               ELSE NULL
                            END)
                            IS NOT NULL
                     AND MAX (
                            CASE
                               WHEN d.field = 'VISMON' THEN VALUE
                               ELSE NULL
                            END)
                            IS NOT NULL
                     AND MAX (
                            CASE
                               WHEN d.field = 'VISYEA' THEN VALUE
                               ELSE NULL
                            END)
                            IS NOT NULL
                THEN
                      MAX (
                         CASE WHEN d.field = 'VISDAY' THEN VALUE ELSE NULL END)
                   || '.'
                   || MAX (
                         CASE WHEN d.field = 'VISMON' THEN VALUE ELSE NULL END)
                   || '.'
                   || MAX (
                         CASE WHEN d.field = 'VISYEA' THEN VALUE ELSE NULL END)
                ELSE
                   NULL
             END)
               "C_VISIT"
       FROM    V_PAT_SCHEDULE s
            LEFT JOIN
               DATA d
            ON     s.PAT_ID = d.PAT_ID
               AND d.FIELD IN ('VISDAY', 'VISMON', 'VISYEA')
               AND s.INSTANCE = d.PAGE
               AND s.FORM = d.FORM
   GROUP BY s.PAT_ID,
            s.SCR_NO,
            s.PAT_NO,
            s.SIT_ID,
            s.VISIT_NO,
            s.FORM,
            s.INSTANCE,
            s.VISIT_ID,
            s.DURATION,
            s.DURATION_UNIT,
            s.TOLERANCE_SOFT_MIN,
            s.TOLERANCE_SOFT_MAX,
            s.TOLERANCE_HARD_MIN,
            s.TOLERANCE_HARD_MAX,
            s.TOLERANCE_UNIT,
            s.SCHEDULE_ID,
            s.REF_VISIT_ID
   ORDER BY s.PAT_ID, VISIT_NO;


DROP VIEW V_PAT_VISITS_REF;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_VISITS_REF
(
   SCHEDULE_ID,
   PAT_ID,
   SCR_NO,
   SIT_ID,
   VISIT_NO,
   VISIT_ID,
   C_VISIT,
   DURATION,
   TOLERANCE_SOFT_MIN,
   TOLERANCE_SOFT_MAX,
   TOLERANCE_HARD_MIN,
   TOLERANCE_HARD_MAX,
   REF_VISIT_ID,
   REF_VISIT_NO,
   REF_VISIT
)
AS
     SELECT v.SCHEDULE_ID,
            v.PAT_ID,
            v.SCR_NO,
            v.SIT_ID,
            v.VISIT_NO,
            v.VISIT_ID,
            v.C_VISIT,
            v.DURATION,
            v.TOLERANCE_SOFT_MIN,
            v.TOLERANCE_SOFT_MAX,
            v.TOLERANCE_HARD_MIN,
            v.TOLERANCE_HARD_MAX,
            r.VISIT_ID "REF_VISIT_ID",
            r.VISIT_NO "REF_VISIT_NO",
            TO_DATE (r.C_VISIT, 'DD.MM.YYYY') "REF_VISIT"
       FROM V_PAT_VISITS v, V_PAT_VISITS r
      WHERE r.PAT_ID(+) = v.PAT_ID AND r.VISIT_ID(+) = v.REF_VISIT_ID
   ORDER BY PAT_ID, VISIT_NO;


DROP VIEW V_PAT_VISIT_INFO;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_VISIT_INFO
(
   PAT_ID,
   SCR_NO,
   PAT_NO,
   VISIT_ID,
   SCHEDULE_ID,
   FORM,
   INSTANCE,
   COUNTER
)
AS
   SELECT PAT_ID,
          SCR_NO,
          PAT_NO,
          i.VISIT_ID,
          i.SCHEDULE_ID,
          FORM,
          INSTANCE,
          COUNTER
     FROM V_PAT_SCHEDULE_IMPL p, VISIT_INFO i
    WHERE p.SCHEDULE_ID = i.SCHEDULE_ID;


DROP VIEW V_PAT_VISIT_KIT_QTY;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_VISIT_KIT_QTY
(
   PAT_ID,
   VISIT_ID,
   KITID_QTY_LIST
)
AS
     SELECT pat_id,
            visit_id,
            LISTAGG (KIT_TYPE_ID || ',' || qty, '|')
               WITHIN GROUP (ORDER BY KIT_TYPE_ID)
               AS KITID_QTY_LIST
       FROM V_PAT_DISPENSE_KIT_QTY
   GROUP BY PAT_ID, VISIT_ID;


DROP VIEW V_PAT_VISIT_WINDOW;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PAT_VISIT_WINDOW
(
   PAT_ID,
   VISIT_ID,
   DURATION,
   TOLERANCE_SOFT_MIN,
   TOLERANCE_SOFT_MAX,
   TOLERANCE_HARD_MIN,
   TOLERANCE_HARD_MAX,
   C_VISIT,
   PLANNED,
   MIN_SOFT,
   MAX_SOFT,
   CUR_SOFT_WINDOW,
   COMPLETED_SOFT_WINDOW,
   COMBINED_SOFT_WINDOW,
   OUT_OF_SOFT_WINDOW,
   MIN_HARD,
   MAX_HARD,
   CUR_HARD_WINDOW,
   COMPLETED_HARD_WINDOW,
   COMBINED_HARD_WINDOW,
   OUT_OF_HARD_WINDOW
)
AS
   SELECT v.PAT_ID,
          v.VISIT_ID,
          v.DURATION,
          v.TOLERANCE_SOFT_MIN,
          v.TOLERANCE_SOFT_MAX,
          v.TOLERANCE_HARD_MIN,
          v.TOLERANCE_HARD_MAX,
          v.C_VISIT,
          v.PLANNED_VISIT "PLANNED",
          v.PLANNED_VISIT - TOLERANCE_SOFT_MIN "MIN_SOFT",
          v.PLANNED_VISIT + TOLERANCE_SOFT_MAX "MAX_SOFT",
          CASE
             WHEN    T.LOCAL_DATE < v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                  OR T.LOCAL_DATE > v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
             THEN
                'Today is out of the visit window'
             WHEN     T.LOCAL_DATE >= v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                  AND T.LOCAL_DATE <= v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
             THEN
                'Today is inside the visit window'
             ELSE
                NULL
          END
             "CUR_SOFT_WINDOW",
          CASE
             WHEN    v.D_VISIT < v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                  OR v.D_VISIT > v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
             THEN
                'Patient is out of the visit window'
             WHEN     v.D_VISIT >= v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                  AND v.D_VISIT <= v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
             THEN
                'Patient is inside the visit window'
             ELSE
                NULL
          END
             "COMPLETED_SOFT_WINDOW",
          CASE
             WHEN C_VISIT IS NULL
             THEN
                CASE
                   WHEN    T.LOCAL_DATE <
                              v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                        OR T.LOCAL_DATE >
                              v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
                   THEN
                      'Patient is out of the visit window'
                   WHEN     T.LOCAL_DATE >=
                               v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                        AND T.LOCAL_DATE <=
                               v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
                   THEN
                      'Patient is inside the visit window'
                   ELSE
                      NULL
                END
             ELSE
                CASE
                   WHEN    v.D_VISIT < v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                        OR v.D_VISIT > v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
                   THEN
                      'Patient is out of the visit window'
                   WHEN     v.D_VISIT >= v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                        AND v.D_VISIT <= v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
                   THEN
                      'Patient is inside the visit window'
                   ELSE
                      NULL
                END
          END
             "COMBINED_SOFT_WINDOW",
          CASE
             WHEN C_VISIT IS NULL
             THEN
                CASE
                   WHEN    T.LOCAL_DATE <
                              v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                        OR T.LOCAL_DATE >
                              v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
                   THEN
                      1
                   ELSE
                      NULL
                END
             ELSE
                CASE
                   WHEN    v.D_VISIT < v.PLANNED_VISIT - TOLERANCE_SOFT_MIN
                        OR v.D_VISIT > v.PLANNED_VISIT + TOLERANCE_SOFT_MAX
                   THEN
                      1
                   ELSE
                      NULL
                END
          END
             "OUT_OF_SOFT_WINDOW",
          v.PLANNED_VISIT - TOLERANCE_HARD_MIN "MIN_HARD",
          v.PLANNED_VISIT + TOLERANCE_HARD_MAX "MAX_HARD",
          CASE
             WHEN    T.LOCAL_DATE < v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                  OR T.LOCAL_DATE > v.PLANNED_VISIT + TOLERANCE_HARD_MAX
             THEN
                'Today is out of the visit window'
             WHEN     T.LOCAL_DATE >= v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                  AND T.LOCAL_DATE <= v.PLANNED_VISIT + TOLERANCE_HARD_MAX
             THEN
                'Today is inside the visit window'
             ELSE
                NULL
          END
             "CUR_HARD_WINDOW",
          CASE
             WHEN    v.D_VISIT < v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                  OR v.D_VISIT > v.PLANNED_VISIT + TOLERANCE_HARD_MAX
             THEN
                'Patient is out of the visit window'
             WHEN     v.D_VISIT >= v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                  AND v.D_VISIT <= v.PLANNED_VISIT + TOLERANCE_HARD_MAX
             THEN
                'Patient is inside the visit window'
             ELSE
                NULL
          END
             "COMPLETED_HARD_WINDOW",
          CASE
             WHEN C_VISIT IS NULL
             THEN
                CASE
                   WHEN    T.LOCAL_DATE <
                              v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                        OR T.LOCAL_DATE >
                              v.PLANNED_VISIT + TOLERANCE_HARD_MAX
                   THEN
                      'Patient is out of the visit window'
                   WHEN     T.LOCAL_DATE >=
                               v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                        AND T.LOCAL_DATE <=
                               v.PLANNED_VISIT + TOLERANCE_HARD_MAX
                   THEN
                      'Patient is inside the visit window'
                   ELSE
                      NULL
                END
             ELSE
                CASE
                   WHEN    v.D_VISIT < v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                        OR v.D_VISIT > v.PLANNED_VISIT + TOLERANCE_HARD_MAX
                   THEN
                      'Patient is out of the visit window'
                   WHEN     v.D_VISIT >= v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                        AND v.D_VISIT <= v.PLANNED_VISIT + TOLERANCE_HARD_MAX
                   THEN
                      'Patient is inside the visit window'
                   ELSE
                      NULL
                END
          END
             "COMBINED_HARD_WINDOW",
          CASE
             WHEN C_VISIT IS NULL
             THEN
                CASE
                   WHEN    T.LOCAL_DATE <
                              v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                        OR T.LOCAL_DATE >
                              v.PLANNED_VISIT + TOLERANCE_HARD_MAX
                   THEN
                      1
                   ELSE
                      NULL
                END
             ELSE
                CASE
                   WHEN    v.D_VISIT < v.PLANNED_VISIT - TOLERANCE_HARD_MIN
                        OR v.D_VISIT > v.PLANNED_VISIT + TOLERANCE_HARD_MAX
                   THEN
                      1
                   ELSE
                      NULL
                END
          END
             "OUT_OF_HARD_WINDOW"
     FROM V_PAT_PLANNED v, V_LOCAL_TIME t
    WHERE v.SIT_ID = t.GRP_ID;


DROP VIEW V_PERMISSIONS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PERMISSIONS
(
   ID,
   NAME
)
AS
   SELECT PRM_ID AS ID, PRM_ID AS NAME
     FROM ADMIN_IF.PERMISSIONS
    WHERE PRJ_ID IS NULL OR PRJ_ID = 'P90020903';


DROP VIEW V_PSCR_CNTRY_CAP_APR;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PSCR_CNTRY_CAP_APR
(
   COUNTRY_ID,
   CAP,
   PERCENTAGE
)
AS
   SELECT COUNTRY_ID,
          cntry_site_settingval (COUNTRY_ID, 'CNTRY_PSCR_CAP', 'COUNTRY')
             AS CAP,
          PERCENTAGE
     FROM (SELECT a.COUNTRY_ID, PERCENTAGE
             FROM (  SELECT loc.Country_id, '100' AS PERCENTAGE
                       FROM    usr_pat u
                            JOIN
                               v_drug_location loc
                            ON loc.id = u.sit_id
                   GROUP BY loc.Country_id) a);


DROP VIEW V_PSCR_COUNT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PSCR_COUNT
(
   COUNTRY_ID,
   SITE_ID,
   SITE_CNT
)
AS
     SELECT loc.country_id,
            loc.id AS site_id,
            COUNT (DISTINCT usr.pat_id) site_cnt
       FROM usr_pat usr
            INNER JOIN v_drug_location loc
               ON loc.id = usr.sit_id
            INNER JOIN data d
               ON d.pat_id = usr.pat_id
            INNER JOIN pstat_vis v
               ON v.FIELD = d.FIELD
      WHERE v.VISIT_ID = 'PSCR'
   GROUP BY loc.country_id, loc.id;


DROP VIEW V_PSCR_PROJ_CAP_APR;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PSCR_PROJ_CAP_APR
(
   CAP,
   PERCENTAGE
)
AS
   SELECT (SELECT VALUE AS value1
             FROM SETTING_VALUES
            WHERE Setting_id = 'PRJ_PSCR_CAP')
             AS cap,
          '100' PERCENTAGE
     FROM DUAL;


DROP VIEW V_PSCR_SITE_CAP_APR;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PSCR_SITE_CAP_APR
(
   LOC_ID,
   CAP,
   PERCENTAGE
)
AS
   SELECT ID AS LOC_ID,
          cntry_site_settingval (id, 'SITE_PSCR_CAP', 'SITE') AS CAP,
          PERCENTAGE
     FROM (SELECT a.id, PERCENTAGE
             FROM (  SELECT loc.id, '100' AS PERCENTAGE
                       FROM    usr_pat u
                            JOIN
                               v_drug_location loc
                            ON loc.id = u.sit_id
                   GROUP BY loc.id) a);


DROP VIEW V_PSTAT_FINAL;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PSTAT_FINAL
(
   PAT_ID,
   STATUS,
   SCHEDULE_ID
)
AS
   SELECT d.PAT_ID, m.STATUS, m.SCHEDULE_ID
     FROM PSTAT_MAP m, VISIT_INFO i, DATA d
    WHERE     m.VISIT_ID = i.VISIT_ID
          AND m.FINAL = 1
          AND d.FIELD = m.FIELD
          AND d.FORM = i.FORM
          AND d.PAGE = i.INSTANCE
          AND d.COUNTER = i.COUNTER;


DROP VIEW V_PSTAT_MAX;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_PSTAT_MAX
(
   PAT_ID,
   VISIT_NO
)
AS
     SELECT s.PAT_ID,
            MAX (CASE WHEN d.VALUE IS NOT NULL THEN VISIT_NO ELSE NULL END)
               "VISIT_NO"
       FROM V_PAT_SCHEDULE s
            INNER JOIN PSTAT_VIS p
               ON s.SCHEDULE_ID = p.SCHEDULE_ID
            LEFT JOIN DATA d
               ON     d.PAT_ID = s.PAT_ID
                  AND d.FORM = s.FORM
                  AND d.PAGE = s.INSTANCE
                  AND d.COUNTER = s.COUNTER
                  AND d.FIELD = p.FIELD
   GROUP BY s.PAT_ID;


DROP VIEW V_REPORT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT
(
   PAT_ID,
   UBRSP_OOW,
   URSP_ENCORA_RESTART_CONT,
   RECRUIT_IDENTIFICATION,
   UPMB_RSTRT,
   STRATA1,
   ETHNICITY,
   URSPVIS,
   DSCREASON,
   RSP_OOW,
   RNDELIGIBILTY,
   CTX_HLD,
   RSP_ENCORA_RESTART_CONT,
   UPMB_HLD,
   RSPCRF_LABEL,
   RSP_ENCORA_225MG,
   RNDVIS,
   SCFVIS,
   RNDCRF_LABEL,
   RSP_CETUX_300MG,
   PMB_HLD,
   URSP_ENCORA_150MG,
   SCRVIS,
   CTX_RSTRT,
   URSP_OOW,
   DELVIS,
   BRSPVIS,
   DSCCRF_LABEL,
   URSP_CETUX_400MG,
   SCFREASON,
   UCTX_RSTRT,
   UBPMB_HLD,
   RSPVIS,
   RSP_ENCORA_150MG,
   DSCVIS,
   BPMB_HLD,
   URSP_ENCORA_300MG,
   GENDER,
   URSP_ENCORA_225MG,
   URSP_CETUX_300MG,
   AGE,
   RSP_CETU_QTY_4,
   RSP_CETU_QTY_3,
   RECRUIT_LEARN,
   RND_COHORT,
   PMB_RSTRT,
   PSCRVIS,
   SCRAGE,
   BRSP_OOW,
   RSP_ENCORA_HOLD_DISC,
   URSP_ENCORA_HOLD_DISC,
   URSP_CETU_QTY_3,
   RSP_ENCORA_300MG,
   URSP_CETU_QTY_4,
   UBPMB_RSTRT,
   UCTX_HLD,
   RSP_CETUX_400MG,
   RACE,
   BPMB_RSTRT,
   SCFCRF_LABEL,
   RSP_CETUX_500MG,
   UBRSPVIS,
   URSP_CETUX_500MG
)
AS
     SELECT PAT_ID,
            MAX (
               CASE
                  WHEN FIELD = 'UBRSP_OOW' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "UBRSP_OOW",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_ENCORA_RESTART_CONT' AND FORM = 386
                  THEN
                     VALUE
                  ELSE
                     NULL
               END)
               "URSP_ENCORA_RESTART_CONT",
            MAX (
               CASE
                  WHEN FIELD = 'RECRUIT_IDENTIFICATION' AND FORM = 2 THEN VALUE
                  ELSE NULL
               END)
               "RECRUIT_IDENTIFICATION",
            MAX (
               CASE
                  WHEN FIELD = 'UPMB_RSTRT' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "UPMB_RSTRT",
            MAX (
               CASE
                  WHEN FIELD = 'STRATA1' AND FORM = 2 THEN VALUE
                  ELSE NULL
               END)
               "STRATA1",
            MAX (
               CASE
                  WHEN FIELD = 'ETHNICITY' AND FORM = 1 THEN VALUE
                  ELSE NULL
               END)
               "ETHNICITY",
            MAX (
               CASE
                  WHEN FIELD = 'URSPVIS' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSPVIS",
            MAX (
               CASE
                  WHEN FIELD = 'DSCREASON' AND FORM = 4 THEN VALUE
                  ELSE NULL
               END)
               "DSCREASON",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_OOW' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_OOW",
            MAX (
               CASE
                  WHEN FIELD = 'RNDELIGIBILTY' AND FORM = 2 THEN VALUE
                  ELSE NULL
               END)
               "RNDELIGIBILTY",
            MAX (
               CASE
                  WHEN FIELD = 'CTX_HLD' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "CTX_HLD",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_ENCORA_RESTART_CONT' AND FORM = 128
                  THEN
                     VALUE
                  ELSE
                     NULL
               END)
               "RSP_ENCORA_RESTART_CONT",
            MAX (
               CASE
                  WHEN FIELD = 'UPMB_HLD' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "UPMB_HLD",
            MAX (
               CASE
                  WHEN FIELD = 'RSPCRF_LABEL' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "RSPCRF_LABEL",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_ENCORA_225MG' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_ENCORA_225MG",
            MAX (
               CASE WHEN FIELD = 'RNDVIS' AND FORM = 2 THEN VALUE ELSE NULL END)
               "RNDVIS",
            MAX (
               CASE WHEN FIELD = 'SCFVIS' AND FORM = 3 THEN VALUE ELSE NULL END)
               "SCFVIS",
            MAX (
               CASE
                  WHEN FIELD = 'RNDCRF_LABEL' AND FORM = 2 THEN VALUE
                  ELSE NULL
               END)
               "RNDCRF_LABEL",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_CETUX_300MG' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_CETUX_300MG",
            MAX (
               CASE
                  WHEN FIELD = 'PMB_HLD' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "PMB_HLD",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_ENCORA_150MG' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_ENCORA_150MG",
            MAX (
               CASE WHEN FIELD = 'SCRVIS' AND FORM = 1 THEN VALUE ELSE NULL END)
               "SCRVIS",
            MAX (
               CASE
                  WHEN FIELD = 'CTX_RSTRT' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "CTX_RSTRT",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_OOW' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_OOW",
            MAX (
               CASE WHEN FIELD = 'DELVIS' AND FORM = 5 THEN VALUE ELSE NULL END)
               "DELVIS",
            MAX (
               CASE
                  WHEN FIELD = 'BRSPVIS' AND FORM = 42 THEN VALUE
                  ELSE NULL
               END)
               "BRSPVIS",
            MAX (
               CASE
                  WHEN FIELD = 'DSCCRF_LABEL' AND FORM = 4 THEN VALUE
                  ELSE NULL
               END)
               "DSCCRF_LABEL",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_CETUX_400MG' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_CETUX_400MG",
            MAX (
               CASE
                  WHEN FIELD = 'SCFREASON' AND FORM = 5 THEN VALUE
                  ELSE NULL
               END)
               "SCFREASON",
            MAX (
               CASE
                  WHEN FIELD = 'UCTX_RSTRT' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "UCTX_RSTRT",
            MAX (
               CASE
                  WHEN FIELD = 'UBPMB_HLD' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "UBPMB_HLD",
            MAX (
               CASE
                  WHEN FIELD = 'RSPVIS' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSPVIS",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_ENCORA_150MG' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_ENCORA_150MG",
            MAX (
               CASE WHEN FIELD = 'DSCVIS' AND FORM = 4 THEN VALUE ELSE NULL END)
               "DSCVIS",
            MAX (
               CASE
                  WHEN FIELD = 'BPMB_HLD' AND FORM = 42 THEN VALUE
                  ELSE NULL
               END)
               "BPMB_HLD",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_ENCORA_300MG' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_ENCORA_300MG",
            MAX (
               CASE WHEN FIELD = 'GENDER' AND FORM = 1 THEN VALUE ELSE NULL END)
               "GENDER",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_ENCORA_225MG' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_ENCORA_225MG",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_CETUX_300MG' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_CETUX_300MG",
            MAX (CASE WHEN FIELD = 'AGE' AND FORM = 0 THEN VALUE ELSE NULL END)
               "AGE",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_CETU_QTY_4' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_CETU_QTY_4",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_CETU_QTY_3' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_CETU_QTY_3",
            MAX (
               CASE
                  WHEN FIELD = 'RECRUIT_LEARN' AND FORM = 2 THEN VALUE
                  ELSE NULL
               END)
               "RECRUIT_LEARN",
            MAX (
               CASE
                  WHEN FIELD = 'RND_COHORT' AND FORM = 2 THEN VALUE
                  ELSE NULL
               END)
               "RND_COHORT",
            MAX (
               CASE
                  WHEN FIELD = 'PMB_RSTRT' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "PMB_RSTRT",
            MAX (
               CASE
                  WHEN FIELD = 'PSCRVIS' AND FORM = 0 THEN VALUE
                  ELSE NULL
               END)
               "PSCRVIS",
            MAX (
               CASE WHEN FIELD = 'SCRAGE' AND FORM = 1 THEN VALUE ELSE NULL END)
               "SCRAGE",
            MAX (
               CASE
                  WHEN FIELD = 'BRSP_OOW' AND FORM = 42 THEN VALUE
                  ELSE NULL
               END)
               "BRSP_OOW",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_ENCORA_HOLD_DISC' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_ENCORA_HOLD_DISC",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_ENCORA_HOLD_DISC' AND FORM = 386
                  THEN
                     VALUE
                  ELSE
                     NULL
               END)
               "URSP_ENCORA_HOLD_DISC",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_CETU_QTY_3' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_CETU_QTY_3",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_ENCORA_300MG' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_ENCORA_300MG",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_CETU_QTY_4' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_CETU_QTY_4",
            MAX (
               CASE
                  WHEN FIELD = 'UBPMB_RSTRT' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "UBPMB_RSTRT",
            MAX (
               CASE
                  WHEN FIELD = 'UCTX_HLD' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "UCTX_HLD",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_CETUX_400MG' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_CETUX_400MG",
            MAX (
               CASE WHEN FIELD = 'RACE' AND FORM = 1 THEN VALUE ELSE NULL END)
               "RACE",
            MAX (
               CASE
                  WHEN FIELD = 'BPMB_RSTRT' AND FORM = 42 THEN VALUE
                  ELSE NULL
               END)
               "BPMB_RSTRT",
            MAX (
               CASE
                  WHEN FIELD = 'SCFCRF_LABEL' AND FORM = 5 THEN VALUE
                  ELSE NULL
               END)
               "SCFCRF_LABEL",
            MAX (
               CASE
                  WHEN FIELD = 'RSP_CETUX_500MG' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "RSP_CETUX_500MG",
            MAX (
               CASE
                  WHEN FIELD = 'UBRSPVIS' AND FORM = 128 THEN VALUE
                  ELSE NULL
               END)
               "UBRSPVIS",
            MAX (
               CASE
                  WHEN FIELD = 'URSP_CETUX_500MG' AND FORM = 386 THEN VALUE
                  ELSE NULL
               END)
               "URSP_CETUX_500MG"
       FROM DATA
   GROUP BY PAT_ID;


DROP VIEW V_REPORT_ADDENDUM;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_ADDENDUM
(
   PAT_ID,
   SCR_NO,
   VISIT_ID,
   CONTENT
)
AS
     SELECT u.PAT_ID,
            u.SCR_NO,
            i.VISIT_ID,
            MAX (
               CASE
                  WHEN VISIT_ID = 'PSCR' THEN ''
                  WHEN VISIT_ID = 'SCR' THEN ''
                  WHEN VISIT_ID = 'RND' THEN ''
                  WHEN VISIT_ID = 'SCF' THEN ''
                  WHEN VISIT_ID = 'DSC' THEN ''
                  WHEN VISIT_ID = 'DEL' THEN ''
                  WHEN VISIT_ID = 'PSCR' THEN ''
                  WHEN VISIT_ID = 'SCR' THEN ''
                  WHEN VISIT_ID = 'RND' THEN ''
                  WHEN VISIT_ID = 'SCF' THEN ''
                  WHEN VISIT_ID = 'DSC' THEN ''
                  WHEN VISIT_ID = 'DEL' THEN ''
                  WHEN VISIT_ID = 'AC01D01' THEN ''
                  WHEN VISIT_ID = 'AC01D15' THEN ''
                  WHEN VISIT_ID = 'AC01D29' THEN ''
                  WHEN VISIT_ID = 'AC02D01' THEN ''
                  WHEN VISIT_ID = 'AC02D15' THEN ''
                  WHEN VISIT_ID = 'AC02D29' THEN ''
                  WHEN VISIT_ID = 'AC03D01' THEN ''
                  WHEN VISIT_ID = 'AC03D15' THEN ''
                  WHEN VISIT_ID = 'AC03D29' THEN ''
                  WHEN VISIT_ID = 'AC04D01' THEN ''
                  WHEN VISIT_ID = 'AC04D15' THEN ''
                  WHEN VISIT_ID = 'AC04D29' THEN ''
                  WHEN VISIT_ID = 'AC05D01' THEN ''
                  WHEN VISIT_ID = 'AC05D15' THEN ''
                  WHEN VISIT_ID = 'AC05D29' THEN ''
                  WHEN VISIT_ID = 'AC06D01' THEN ''
                  WHEN VISIT_ID = 'AC06D15' THEN ''
                  WHEN VISIT_ID = 'AC06D29' THEN ''
                  WHEN VISIT_ID = 'AC07D01' THEN ''
                  WHEN VISIT_ID = 'AC07D15' THEN ''
                  WHEN VISIT_ID = 'AC07D29' THEN ''
                  WHEN VISIT_ID = 'AC08D01' THEN ''
                  WHEN VISIT_ID = 'AC08D15' THEN ''
                  WHEN VISIT_ID = 'AC08D29' THEN ''
                  WHEN VISIT_ID = 'AC09D01' THEN ''
                  WHEN VISIT_ID = 'AC09D15' THEN ''
                  WHEN VISIT_ID = 'AC09D29' THEN ''
                  WHEN VISIT_ID = 'AC10D01' THEN ''
                  WHEN VISIT_ID = 'AC10D15' THEN ''
                  WHEN VISIT_ID = 'AC10D29' THEN ''
                  WHEN VISIT_ID = 'AC11D01' THEN ''
                  WHEN VISIT_ID = 'AC11D15' THEN ''
                  WHEN VISIT_ID = 'AC11D29' THEN ''
                  WHEN VISIT_ID = 'AC12D01' THEN ''
                  WHEN VISIT_ID = 'AC12D15' THEN ''
                  WHEN VISIT_ID = 'AC12D29' THEN ''
                  WHEN VISIT_ID = 'AC13D01' THEN ''
                  WHEN VISIT_ID = 'AC13D15' THEN ''
                  WHEN VISIT_ID = 'AC13D29' THEN ''
                  WHEN VISIT_ID = 'AC14D01' THEN ''
                  WHEN VISIT_ID = 'AC14D15' THEN ''
                  WHEN VISIT_ID = 'AC14D29' THEN ''
                  WHEN VISIT_ID = 'AC15D01' THEN ''
                  WHEN VISIT_ID = 'AC15D15' THEN ''
                  WHEN VISIT_ID = 'AC15D29' THEN ''
                  WHEN VISIT_ID = 'AC16D01' THEN ''
                  WHEN VISIT_ID = 'AC16D15' THEN ''
                  WHEN VISIT_ID = 'AC16D29' THEN ''
                  WHEN VISIT_ID = 'AC17D01' THEN ''
                  WHEN VISIT_ID = 'AC17D15' THEN ''
                  WHEN VISIT_ID = 'AC17D29' THEN ''
                  WHEN VISIT_ID = 'AC18D01' THEN ''
                  WHEN VISIT_ID = 'AC18D15' THEN ''
                  WHEN VISIT_ID = 'AC18D29' THEN ''
                  WHEN VISIT_ID = 'AC19D01' THEN ''
                  WHEN VISIT_ID = 'AC19D15' THEN ''
                  WHEN VISIT_ID = 'AC19D29' THEN ''
                  WHEN VISIT_ID = 'AC20D01' THEN ''
                  WHEN VISIT_ID = 'AC20D15' THEN ''
                  WHEN VISIT_ID = 'AC20D29' THEN ''
                  WHEN VISIT_ID = 'AC21D01' THEN ''
                  WHEN VISIT_ID = 'AC21D15' THEN ''
                  WHEN VISIT_ID = 'AC21D29' THEN ''
                  WHEN VISIT_ID = 'AC22D01' THEN ''
                  WHEN VISIT_ID = 'AC22D15' THEN ''
                  WHEN VISIT_ID = 'AC22D29' THEN ''
                  WHEN VISIT_ID = 'AC23D01' THEN ''
                  WHEN VISIT_ID = 'AC23D15' THEN ''
                  WHEN VISIT_ID = 'AC23D29' THEN ''
                  WHEN VISIT_ID = 'AC24D01' THEN ''
                  WHEN VISIT_ID = 'AC24D15' THEN ''
                  WHEN VISIT_ID = 'AC24D29' THEN ''
                  WHEN VISIT_ID = 'AC25D01' THEN ''
                  WHEN VISIT_ID = 'AC25D15' THEN ''
                  WHEN VISIT_ID = 'AC25D29' THEN ''
                  WHEN VISIT_ID = 'AC26D01' THEN ''
                  WHEN VISIT_ID = 'AC26D15' THEN ''
                  WHEN VISIT_ID = 'AC26D29' THEN ''
                  WHEN VISIT_ID = 'AC27D01' THEN ''
                  WHEN VISIT_ID = 'AC27D15' THEN ''
                  WHEN VISIT_ID = 'AC27D29' THEN ''
                  WHEN VISIT_ID = 'AC28D01' THEN ''
                  WHEN VISIT_ID = 'AC28D15' THEN ''
                  WHEN VISIT_ID = 'AC28D29' THEN ''
                  WHEN VISIT_ID = 'AC29D01' THEN ''
                  WHEN VISIT_ID = 'AC29D15' THEN ''
                  WHEN VISIT_ID = 'AC29D29' THEN ''
                  WHEN VISIT_ID = 'AC30D01' THEN ''
                  WHEN VISIT_ID = 'AC30D15' THEN ''
                  WHEN VISIT_ID = 'AC30D29' THEN ''
                  WHEN VISIT_ID = 'AC31D01' THEN ''
                  WHEN VISIT_ID = 'AC31D15' THEN ''
                  WHEN VISIT_ID = 'AC31D29' THEN ''
                  WHEN VISIT_ID = 'AC32D01' THEN ''
                  WHEN VISIT_ID = 'AC32D15' THEN ''
                  WHEN VISIT_ID = 'AC32D29' THEN ''
                  WHEN VISIT_ID = 'AC33D01' THEN ''
                  WHEN VISIT_ID = 'AC33D15' THEN ''
                  WHEN VISIT_ID = 'AC33D29' THEN ''
                  WHEN VISIT_ID = 'AC34D01' THEN ''
                  WHEN VISIT_ID = 'AC34D15' THEN ''
                  WHEN VISIT_ID = 'AC34D29' THEN ''
                  WHEN VISIT_ID = 'AC35D01' THEN ''
                  WHEN VISIT_ID = 'AC35D15' THEN ''
                  WHEN VISIT_ID = 'AC35D29' THEN ''
                  WHEN VISIT_ID = 'AC36D01' THEN ''
                  WHEN VISIT_ID = 'AC36D15' THEN ''
                  WHEN VISIT_ID = 'AC36D29' THEN ''
                  WHEN VISIT_ID = 'AC37D01' THEN ''
                  WHEN VISIT_ID = 'AC37D15' THEN ''
                  WHEN VISIT_ID = 'AC37D29' THEN ''
                  WHEN VISIT_ID = 'AC38D01' THEN ''
                  WHEN VISIT_ID = 'AC38D15' THEN ''
                  WHEN VISIT_ID = 'AC38D29' THEN ''
                  WHEN VISIT_ID = 'AC39D01' THEN ''
                  WHEN VISIT_ID = 'AC39D15' THEN ''
                  WHEN VISIT_ID = 'AC39D29' THEN ''
                  WHEN VISIT_ID = 'AC40D01' THEN ''
                  WHEN VISIT_ID = 'AC40D15' THEN ''
                  WHEN VISIT_ID = 'AC40D29' THEN ''
                  WHEN VISIT_ID = 'AC41D01' THEN ''
                  WHEN VISIT_ID = 'AC41D15' THEN ''
                  WHEN VISIT_ID = 'AC41D29' THEN ''
                  WHEN VISIT_ID = 'AC42D01' THEN ''
                  WHEN VISIT_ID = 'AC42D15' THEN ''
                  WHEN VISIT_ID = 'AC42D29' THEN ''
                  WHEN VISIT_ID = 'AC43D01' THEN ''
                  WHEN VISIT_ID = 'AC43D15' THEN ''
                  WHEN VISIT_ID = 'AC43D29' THEN ''
                  WHEN VISIT_ID = 'U1AC01D01' THEN ''
                  WHEN VISIT_ID = 'U2AC01D01' THEN ''
                  WHEN VISIT_ID = 'U1AC01D15' THEN ''
                  WHEN VISIT_ID = 'U2AC01D15' THEN ''
                  WHEN VISIT_ID = 'U1AC01D29' THEN ''
                  WHEN VISIT_ID = 'U2AC01D29' THEN ''
                  WHEN VISIT_ID = 'U1AC02D01' THEN ''
                  WHEN VISIT_ID = 'U2AC02D01' THEN ''
                  WHEN VISIT_ID = 'U1AC02D15' THEN ''
                  WHEN VISIT_ID = 'U2AC02D15' THEN ''
                  WHEN VISIT_ID = 'U1AC02D29' THEN ''
                  WHEN VISIT_ID = 'U2AC02D29' THEN ''
                  WHEN VISIT_ID = 'U1AC03D01' THEN ''
                  WHEN VISIT_ID = 'U2AC03D01' THEN ''
                  WHEN VISIT_ID = 'U1AC03D15' THEN ''
                  WHEN VISIT_ID = 'U2AC03D15' THEN ''
                  WHEN VISIT_ID = 'U1AC03D29' THEN ''
                  WHEN VISIT_ID = 'U2AC03D29' THEN ''
                  WHEN VISIT_ID = 'U1AC04D01' THEN ''
                  WHEN VISIT_ID = 'U2AC04D01' THEN ''
                  WHEN VISIT_ID = 'U1AC04D15' THEN ''
                  WHEN VISIT_ID = 'U2AC04D15' THEN ''
                  WHEN VISIT_ID = 'U1AC04D29' THEN ''
                  WHEN VISIT_ID = 'U2AC04D29' THEN ''
                  WHEN VISIT_ID = 'U1AC05D01' THEN ''
                  WHEN VISIT_ID = 'U2AC05D01' THEN ''
                  WHEN VISIT_ID = 'U1AC05D15' THEN ''
                  WHEN VISIT_ID = 'U2AC05D15' THEN ''
                  WHEN VISIT_ID = 'U1AC05D29' THEN ''
                  WHEN VISIT_ID = 'U2AC05D29' THEN ''
                  WHEN VISIT_ID = 'U1AC06D01' THEN ''
                  WHEN VISIT_ID = 'U2AC06D01' THEN ''
                  WHEN VISIT_ID = 'U1AC06D15' THEN ''
                  WHEN VISIT_ID = 'U2AC06D15' THEN ''
                  WHEN VISIT_ID = 'U1AC06D29' THEN ''
                  WHEN VISIT_ID = 'U2AC06D29' THEN ''
                  WHEN VISIT_ID = 'U1AC07D01' THEN ''
                  WHEN VISIT_ID = 'U2AC07D01' THEN ''
                  WHEN VISIT_ID = 'U1AC07D15' THEN ''
                  WHEN VISIT_ID = 'U2AC07D15' THEN ''
                  WHEN VISIT_ID = 'U1AC07D29' THEN ''
                  WHEN VISIT_ID = 'U2AC07D29' THEN ''
                  WHEN VISIT_ID = 'U1AC08D01' THEN ''
                  WHEN VISIT_ID = 'U2AC08D01' THEN ''
                  WHEN VISIT_ID = 'U1AC08D15' THEN ''
                  WHEN VISIT_ID = 'U2AC08D15' THEN ''
                  WHEN VISIT_ID = 'U1AC08D29' THEN ''
                  WHEN VISIT_ID = 'U2AC08D29' THEN ''
                  WHEN VISIT_ID = 'U1AC09D01' THEN ''
                  WHEN VISIT_ID = 'U2AC09D01' THEN ''
                  WHEN VISIT_ID = 'U1AC09D15' THEN ''
                  WHEN VISIT_ID = 'U2AC09D15' THEN ''
                  WHEN VISIT_ID = 'U1AC09D29' THEN ''
                  WHEN VISIT_ID = 'U2AC09D29' THEN ''
                  WHEN VISIT_ID = 'U1AC10D01' THEN ''
                  WHEN VISIT_ID = 'U2AC10D01' THEN ''
                  WHEN VISIT_ID = 'U1AC10D15' THEN ''
                  WHEN VISIT_ID = 'U2AC10D15' THEN ''
                  WHEN VISIT_ID = 'U1AC10D29' THEN ''
                  WHEN VISIT_ID = 'U2AC10D29' THEN ''
                  WHEN VISIT_ID = 'U1AC11D01' THEN ''
                  WHEN VISIT_ID = 'U2AC11D01' THEN ''
                  WHEN VISIT_ID = 'U1AC11D15' THEN ''
                  WHEN VISIT_ID = 'U2AC11D15' THEN ''
                  WHEN VISIT_ID = 'U1AC11D29' THEN ''
                  WHEN VISIT_ID = 'U2AC11D29' THEN ''
                  WHEN VISIT_ID = 'U1AC12D01' THEN ''
                  WHEN VISIT_ID = 'U2AC12D01' THEN ''
                  WHEN VISIT_ID = 'U1AC12D15' THEN ''
                  WHEN VISIT_ID = 'U2AC12D15' THEN ''
                  WHEN VISIT_ID = 'U1AC12D29' THEN ''
                  WHEN VISIT_ID = 'U2AC12D29' THEN ''
                  WHEN VISIT_ID = 'U1AC13D01' THEN ''
                  WHEN VISIT_ID = 'U2AC13D01' THEN ''
                  WHEN VISIT_ID = 'U1AC13D15' THEN ''
                  WHEN VISIT_ID = 'U2AC13D15' THEN ''
                  WHEN VISIT_ID = 'U1AC13D29' THEN ''
                  WHEN VISIT_ID = 'U2AC13D29' THEN ''
                  WHEN VISIT_ID = 'U1AC14D01' THEN ''
                  WHEN VISIT_ID = 'U2AC14D01' THEN ''
                  WHEN VISIT_ID = 'U1AC14D15' THEN ''
                  WHEN VISIT_ID = 'U2AC14D15' THEN ''
                  WHEN VISIT_ID = 'U1AC14D29' THEN ''
                  WHEN VISIT_ID = 'U2AC14D29' THEN ''
                  WHEN VISIT_ID = 'U1AC15D01' THEN ''
                  WHEN VISIT_ID = 'U2AC15D01' THEN ''
                  WHEN VISIT_ID = 'U1AC15D15' THEN ''
                  WHEN VISIT_ID = 'U2AC15D15' THEN ''
                  WHEN VISIT_ID = 'U1AC15D29' THEN ''
                  WHEN VISIT_ID = 'U2AC15D29' THEN ''
                  WHEN VISIT_ID = 'U1AC16D01' THEN ''
                  WHEN VISIT_ID = 'U2AC16D01' THEN ''
                  WHEN VISIT_ID = 'U1AC16D15' THEN ''
                  WHEN VISIT_ID = 'U2AC16D15' THEN ''
                  WHEN VISIT_ID = 'U1AC16D29' THEN ''
                  WHEN VISIT_ID = 'U2AC16D29' THEN ''
                  WHEN VISIT_ID = 'U1AC17D01' THEN ''
                  WHEN VISIT_ID = 'U2AC17D01' THEN ''
                  WHEN VISIT_ID = 'U1AC17D15' THEN ''
                  WHEN VISIT_ID = 'U2AC17D15' THEN ''
                  WHEN VISIT_ID = 'U1AC17D29' THEN ''
                  WHEN VISIT_ID = 'U2AC17D29' THEN ''
                  WHEN VISIT_ID = 'U1AC18D01' THEN ''
                  WHEN VISIT_ID = 'U2AC18D01' THEN ''
                  WHEN VISIT_ID = 'U1AC18D15' THEN ''
                  WHEN VISIT_ID = 'U2AC18D15' THEN ''
                  WHEN VISIT_ID = 'U1AC18D29' THEN ''
                  WHEN VISIT_ID = 'U2AC18D29' THEN ''
                  WHEN VISIT_ID = 'U1AC19D01' THEN ''
                  WHEN VISIT_ID = 'U2AC19D01' THEN ''
                  WHEN VISIT_ID = 'U1AC19D15' THEN ''
                  WHEN VISIT_ID = 'U2AC19D15' THEN ''
                  WHEN VISIT_ID = 'U1AC19D29' THEN ''
                  WHEN VISIT_ID = 'U2AC19D29' THEN ''
                  WHEN VISIT_ID = 'U1AC20D01' THEN ''
                  WHEN VISIT_ID = 'U2AC20D01' THEN ''
                  WHEN VISIT_ID = 'U1AC20D15' THEN ''
                  WHEN VISIT_ID = 'U2AC20D15' THEN ''
                  WHEN VISIT_ID = 'U1AC20D29' THEN ''
                  WHEN VISIT_ID = 'U2AC20D29' THEN ''
                  WHEN VISIT_ID = 'U1AC21D01' THEN ''
                  WHEN VISIT_ID = 'U2AC21D01' THEN ''
                  WHEN VISIT_ID = 'U1AC21D15' THEN ''
                  WHEN VISIT_ID = 'U2AC21D15' THEN ''
                  WHEN VISIT_ID = 'U1AC21D29' THEN ''
                  WHEN VISIT_ID = 'U2AC21D29' THEN ''
                  WHEN VISIT_ID = 'U1AC22D01' THEN ''
                  WHEN VISIT_ID = 'U2AC22D01' THEN ''
                  WHEN VISIT_ID = 'U1AC22D15' THEN ''
                  WHEN VISIT_ID = 'U2AC22D15' THEN ''
                  WHEN VISIT_ID = 'U1AC22D29' THEN ''
                  WHEN VISIT_ID = 'U2AC22D29' THEN ''
                  WHEN VISIT_ID = 'U1AC23D01' THEN ''
                  WHEN VISIT_ID = 'U2AC23D01' THEN ''
                  WHEN VISIT_ID = 'U1AC23D15' THEN ''
                  WHEN VISIT_ID = 'U2AC23D15' THEN ''
                  WHEN VISIT_ID = 'U1AC23D29' THEN ''
                  WHEN VISIT_ID = 'U2AC23D29' THEN ''
                  WHEN VISIT_ID = 'U1AC24D01' THEN ''
                  WHEN VISIT_ID = 'U2AC24D01' THEN ''
                  WHEN VISIT_ID = 'U1AC24D15' THEN ''
                  WHEN VISIT_ID = 'U2AC24D15' THEN ''
                  WHEN VISIT_ID = 'U1AC24D29' THEN ''
                  WHEN VISIT_ID = 'U2AC24D29' THEN ''
                  WHEN VISIT_ID = 'U1AC25D01' THEN ''
                  WHEN VISIT_ID = 'U2AC25D01' THEN ''
                  WHEN VISIT_ID = 'U1AC25D15' THEN ''
                  WHEN VISIT_ID = 'U2AC25D15' THEN ''
                  WHEN VISIT_ID = 'U1AC25D29' THEN ''
                  WHEN VISIT_ID = 'U2AC25D29' THEN ''
                  WHEN VISIT_ID = 'U1AC26D01' THEN ''
                  WHEN VISIT_ID = 'U2AC26D01' THEN ''
                  WHEN VISIT_ID = 'U1AC26D15' THEN ''
                  WHEN VISIT_ID = 'U2AC26D15' THEN ''
                  WHEN VISIT_ID = 'U1AC26D29' THEN ''
                  WHEN VISIT_ID = 'U2AC26D29' THEN ''
                  WHEN VISIT_ID = 'U1AC27D01' THEN ''
                  WHEN VISIT_ID = 'U2AC27D01' THEN ''
                  WHEN VISIT_ID = 'U1AC27D15' THEN ''
                  WHEN VISIT_ID = 'U2AC27D15' THEN ''
                  WHEN VISIT_ID = 'U1AC27D29' THEN ''
                  WHEN VISIT_ID = 'U2AC27D29' THEN ''
                  WHEN VISIT_ID = 'U1AC28D01' THEN ''
                  WHEN VISIT_ID = 'U2AC28D01' THEN ''
                  WHEN VISIT_ID = 'U1AC28D15' THEN ''
                  WHEN VISIT_ID = 'U2AC28D15' THEN ''
                  WHEN VISIT_ID = 'U1AC28D29' THEN ''
                  WHEN VISIT_ID = 'U2AC28D29' THEN ''
                  WHEN VISIT_ID = 'U1AC29D01' THEN ''
                  WHEN VISIT_ID = 'U2AC29D01' THEN ''
                  WHEN VISIT_ID = 'U1AC29D15' THEN ''
                  WHEN VISIT_ID = 'U2AC29D15' THEN ''
                  WHEN VISIT_ID = 'U1AC29D29' THEN ''
                  WHEN VISIT_ID = 'U2AC29D29' THEN ''
                  WHEN VISIT_ID = 'U1AC30D01' THEN ''
                  WHEN VISIT_ID = 'U2AC30D01' THEN ''
                  WHEN VISIT_ID = 'U1AC30D15' THEN ''
                  WHEN VISIT_ID = 'U2AC30D15' THEN ''
                  WHEN VISIT_ID = 'U1AC30D29' THEN ''
                  WHEN VISIT_ID = 'U2AC30D29' THEN ''
                  WHEN VISIT_ID = 'U1AC31D01' THEN ''
                  WHEN VISIT_ID = 'U2AC31D01' THEN ''
                  WHEN VISIT_ID = 'U1AC31D15' THEN ''
                  WHEN VISIT_ID = 'U2AC31D15' THEN ''
                  WHEN VISIT_ID = 'U1AC31D29' THEN ''
                  WHEN VISIT_ID = 'U2AC31D29' THEN ''
                  WHEN VISIT_ID = 'U1AC32D01' THEN ''
                  WHEN VISIT_ID = 'U2AC32D01' THEN ''
                  WHEN VISIT_ID = 'U1AC32D15' THEN ''
                  WHEN VISIT_ID = 'U2AC32D15' THEN ''
                  WHEN VISIT_ID = 'U1AC32D29' THEN ''
                  WHEN VISIT_ID = 'U2AC32D29' THEN ''
                  WHEN VISIT_ID = 'U1AC33D01' THEN ''
                  WHEN VISIT_ID = 'U2AC33D01' THEN ''
                  WHEN VISIT_ID = 'U1AC33D15' THEN ''
                  WHEN VISIT_ID = 'U2AC33D15' THEN ''
                  WHEN VISIT_ID = 'U1AC33D29' THEN ''
                  WHEN VISIT_ID = 'U2AC33D29' THEN ''
                  WHEN VISIT_ID = 'U1AC34D01' THEN ''
                  WHEN VISIT_ID = 'U2AC34D01' THEN ''
                  WHEN VISIT_ID = 'U1AC34D15' THEN ''
                  WHEN VISIT_ID = 'U2AC34D15' THEN ''
                  WHEN VISIT_ID = 'U1AC34D29' THEN ''
                  WHEN VISIT_ID = 'U2AC34D29' THEN ''
                  WHEN VISIT_ID = 'U1AC35D01' THEN ''
                  WHEN VISIT_ID = 'U2AC35D01' THEN ''
                  WHEN VISIT_ID = 'U1AC35D15' THEN ''
                  WHEN VISIT_ID = 'U2AC35D15' THEN ''
                  WHEN VISIT_ID = 'U1AC35D29' THEN ''
                  WHEN VISIT_ID = 'U2AC35D29' THEN ''
                  WHEN VISIT_ID = 'U1AC36D01' THEN ''
                  WHEN VISIT_ID = 'U2AC36D01' THEN ''
                  WHEN VISIT_ID = 'U1AC36D15' THEN ''
                  WHEN VISIT_ID = 'U2AC36D15' THEN ''
                  WHEN VISIT_ID = 'U1AC36D29' THEN ''
                  WHEN VISIT_ID = 'U2AC36D29' THEN ''
                  WHEN VISIT_ID = 'U1AC37D01' THEN ''
                  WHEN VISIT_ID = 'U2AC37D01' THEN ''
                  WHEN VISIT_ID = 'U1AC37D15' THEN ''
                  WHEN VISIT_ID = 'U2AC37D15' THEN ''
                  WHEN VISIT_ID = 'U1AC37D29' THEN ''
                  WHEN VISIT_ID = 'U2AC37D29' THEN ''
                  WHEN VISIT_ID = 'U1AC38D01' THEN ''
                  WHEN VISIT_ID = 'U2AC38D01' THEN ''
                  WHEN VISIT_ID = 'U1AC38D15' THEN ''
                  WHEN VISIT_ID = 'U2AC38D15' THEN ''
                  WHEN VISIT_ID = 'U1AC38D29' THEN ''
                  WHEN VISIT_ID = 'U2AC38D29' THEN ''
                  WHEN VISIT_ID = 'U1AC39D01' THEN ''
                  WHEN VISIT_ID = 'U2AC39D01' THEN ''
                  WHEN VISIT_ID = 'U1AC39D15' THEN ''
                  WHEN VISIT_ID = 'U2AC39D15' THEN ''
                  WHEN VISIT_ID = 'U1AC39D29' THEN ''
                  WHEN VISIT_ID = 'U2AC39D29' THEN ''
                  WHEN VISIT_ID = 'U1AC40D01' THEN ''
                  WHEN VISIT_ID = 'U2AC40D01' THEN ''
                  WHEN VISIT_ID = 'U1AC40D15' THEN ''
                  WHEN VISIT_ID = 'U2AC40D15' THEN ''
                  WHEN VISIT_ID = 'U1AC40D29' THEN ''
                  WHEN VISIT_ID = 'U2AC40D29' THEN ''
                  WHEN VISIT_ID = 'U1AC41D01' THEN ''
                  WHEN VISIT_ID = 'U2AC41D01' THEN ''
                  WHEN VISIT_ID = 'U1AC41D15' THEN ''
                  WHEN VISIT_ID = 'U2AC41D15' THEN ''
                  WHEN VISIT_ID = 'U1AC41D29' THEN ''
                  WHEN VISIT_ID = 'U2AC41D29' THEN ''
                  WHEN VISIT_ID = 'U1AC42D01' THEN ''
                  WHEN VISIT_ID = 'U2AC42D01' THEN ''
                  WHEN VISIT_ID = 'U1AC42D15' THEN ''
                  WHEN VISIT_ID = 'U2AC42D15' THEN ''
                  WHEN VISIT_ID = 'U1AC42D29' THEN ''
                  WHEN VISIT_ID = 'U2AC42D29' THEN ''
                  WHEN VISIT_ID = 'U1AC43D01' THEN ''
                  WHEN VISIT_ID = 'U2AC43D01' THEN ''
                  WHEN VISIT_ID = 'U1AC43D15' THEN ''
                  WHEN VISIT_ID = 'U2AC43D15' THEN ''
                  WHEN VISIT_ID = 'U1AC43D29' THEN ''
                  WHEN VISIT_ID = 'U2AC43D29' THEN ''
                  WHEN VISIT_ID = 'PSCR' THEN ''
                  WHEN VISIT_ID = 'SCR' THEN ''
                  WHEN VISIT_ID = 'RND' THEN ''
                  WHEN VISIT_ID = 'SCF' THEN ''
                  WHEN VISIT_ID = 'DSC' THEN ''
                  WHEN VISIT_ID = 'DEL' THEN ''
                  WHEN VISIT_ID = 'BC01D01' THEN ''
                  WHEN VISIT_ID = 'BC02D01' THEN ''
                  WHEN VISIT_ID = 'BC03D01' THEN ''
                  WHEN VISIT_ID = 'BC04D01' THEN ''
                  WHEN VISIT_ID = 'BC05D01' THEN ''
                  WHEN VISIT_ID = 'BC06D01' THEN ''
                  WHEN VISIT_ID = 'BC07D01' THEN ''
                  WHEN VISIT_ID = 'BC08D01' THEN ''
                  WHEN VISIT_ID = 'BC09D01' THEN ''
                  WHEN VISIT_ID = 'BC10D01' THEN ''
                  WHEN VISIT_ID = 'BC11D01' THEN ''
                  WHEN VISIT_ID = 'BC12D01' THEN ''
                  WHEN VISIT_ID = 'BC13D01' THEN ''
                  WHEN VISIT_ID = 'BC14D01' THEN ''
                  WHEN VISIT_ID = 'BC15D01' THEN ''
                  WHEN VISIT_ID = 'BC16D01' THEN ''
                  WHEN VISIT_ID = 'BC17D01' THEN ''
                  WHEN VISIT_ID = 'BC18D01' THEN ''
                  WHEN VISIT_ID = 'BC19D01' THEN ''
                  WHEN VISIT_ID = 'BC20D01' THEN ''
                  WHEN VISIT_ID = 'BC21D01' THEN ''
                  WHEN VISIT_ID = 'BC22D01' THEN ''
                  WHEN VISIT_ID = 'BC23D01' THEN ''
                  WHEN VISIT_ID = 'BC24D01' THEN ''
                  WHEN VISIT_ID = 'BC25D01' THEN ''
                  WHEN VISIT_ID = 'BC26D01' THEN ''
                  WHEN VISIT_ID = 'BC27D01' THEN ''
                  WHEN VISIT_ID = 'BC28D01' THEN ''
                  WHEN VISIT_ID = 'BC29D01' THEN ''
                  WHEN VISIT_ID = 'BC30D01' THEN ''
                  WHEN VISIT_ID = 'BC31D01' THEN ''
                  WHEN VISIT_ID = 'BC32D01' THEN ''
                  WHEN VISIT_ID = 'BC33D01' THEN ''
                  WHEN VISIT_ID = 'BC34D01' THEN ''
                  WHEN VISIT_ID = 'BC35D01' THEN ''
                  WHEN VISIT_ID = 'BC36D01' THEN ''
                  WHEN VISIT_ID = 'BC37D01' THEN ''
                  WHEN VISIT_ID = 'BC38D01' THEN ''
                  WHEN VISIT_ID = 'BC39D01' THEN ''
                  WHEN VISIT_ID = 'BC40D01' THEN ''
                  WHEN VISIT_ID = 'BC41D01' THEN ''
                  WHEN VISIT_ID = 'BC42D01' THEN ''
                  WHEN VISIT_ID = 'BC43D01' THEN ''
                  WHEN VISIT_ID = 'U1BC01D01' THEN ''
                  WHEN VISIT_ID = 'U2BC01D01' THEN ''
                  WHEN VISIT_ID = 'U1BC02D01' THEN ''
                  WHEN VISIT_ID = 'U2BC02D01' THEN ''
                  WHEN VISIT_ID = 'U1BC03D01' THEN ''
                  WHEN VISIT_ID = 'U2BC03D01' THEN ''
                  WHEN VISIT_ID = 'U1BC04D01' THEN ''
                  WHEN VISIT_ID = 'U2BC04D01' THEN ''
                  WHEN VISIT_ID = 'U1BC05D01' THEN ''
                  WHEN VISIT_ID = 'U2BC05D01' THEN ''
                  WHEN VISIT_ID = 'U1BC06D01' THEN ''
                  WHEN VISIT_ID = 'U2BC06D01' THEN ''
                  WHEN VISIT_ID = 'U1BC07D01' THEN ''
                  WHEN VISIT_ID = 'U2BC07D01' THEN ''
                  WHEN VISIT_ID = 'U1BC08D01' THEN ''
                  WHEN VISIT_ID = 'U2BC08D01' THEN ''
                  WHEN VISIT_ID = 'U1BC09D01' THEN ''
                  WHEN VISIT_ID = 'U2BC09D01' THEN ''
                  WHEN VISIT_ID = 'U1BC10D01' THEN ''
                  WHEN VISIT_ID = 'U2BC10D01' THEN ''
                  WHEN VISIT_ID = 'U1BC11D01' THEN ''
                  WHEN VISIT_ID = 'U2BC11D01' THEN ''
                  WHEN VISIT_ID = 'U1BC12D01' THEN ''
                  WHEN VISIT_ID = 'U2BC12D01' THEN ''
                  WHEN VISIT_ID = 'U1BC13D01' THEN ''
                  WHEN VISIT_ID = 'U2BC13D01' THEN ''
                  WHEN VISIT_ID = 'U1BC14D01' THEN ''
                  WHEN VISIT_ID = 'U2BC14D01' THEN ''
                  WHEN VISIT_ID = 'U1BC15D01' THEN ''
                  WHEN VISIT_ID = 'U2BC15D01' THEN ''
                  WHEN VISIT_ID = 'U1BC16D01' THEN ''
                  WHEN VISIT_ID = 'U2BC16D01' THEN ''
                  WHEN VISIT_ID = 'U1BC17D01' THEN ''
                  WHEN VISIT_ID = 'U2BC17D01' THEN ''
                  WHEN VISIT_ID = 'U1BC18D01' THEN ''
                  WHEN VISIT_ID = 'U2BC18D01' THEN ''
                  WHEN VISIT_ID = 'U1BC19D01' THEN ''
                  WHEN VISIT_ID = 'U2BC19D01' THEN ''
                  WHEN VISIT_ID = 'U1BC20D01' THEN ''
                  WHEN VISIT_ID = 'U2BC20D01' THEN ''
                  WHEN VISIT_ID = 'U1BC21D01' THEN ''
                  WHEN VISIT_ID = 'U2BC21D01' THEN ''
                  WHEN VISIT_ID = 'U1BC22D01' THEN ''
                  WHEN VISIT_ID = 'U2BC22D01' THEN ''
                  WHEN VISIT_ID = 'U1BC23D01' THEN ''
                  WHEN VISIT_ID = 'U2BC23D01' THEN ''
                  WHEN VISIT_ID = 'U1BC24D01' THEN ''
                  WHEN VISIT_ID = 'U2BC24D01' THEN ''
                  WHEN VISIT_ID = 'U1BC25D01' THEN ''
                  WHEN VISIT_ID = 'U2BC25D01' THEN ''
                  WHEN VISIT_ID = 'U1BC26D01' THEN ''
                  WHEN VISIT_ID = 'U2BC26D01' THEN ''
                  WHEN VISIT_ID = 'U1BC27D01' THEN ''
                  WHEN VISIT_ID = 'U2BC27D01' THEN ''
                  WHEN VISIT_ID = 'U1BC28D01' THEN ''
                  WHEN VISIT_ID = 'U2BC28D01' THEN ''
                  WHEN VISIT_ID = 'U1BC29D01' THEN ''
                  WHEN VISIT_ID = 'U2BC29D01' THEN ''
                  WHEN VISIT_ID = 'U1BC30D01' THEN ''
                  WHEN VISIT_ID = 'U2BC30D01' THEN ''
                  WHEN VISIT_ID = 'U1BC31D01' THEN ''
                  WHEN VISIT_ID = 'U2BC31D01' THEN ''
                  WHEN VISIT_ID = 'U1BC32D01' THEN ''
                  WHEN VISIT_ID = 'U2BC32D01' THEN ''
                  WHEN VISIT_ID = 'U1BC33D01' THEN ''
                  WHEN VISIT_ID = 'U2BC33D01' THEN ''
                  WHEN VISIT_ID = 'U1BC34D01' THEN ''
                  WHEN VISIT_ID = 'U2BC34D01' THEN ''
                  WHEN VISIT_ID = 'U1BC35D01' THEN ''
                  WHEN VISIT_ID = 'U2BC35D01' THEN ''
                  WHEN VISIT_ID = 'U1BC36D01' THEN ''
                  WHEN VISIT_ID = 'U2BC36D01' THEN ''
                  WHEN VISIT_ID = 'U1BC37D01' THEN ''
                  WHEN VISIT_ID = 'U2BC37D01' THEN ''
                  WHEN VISIT_ID = 'U1BC38D01' THEN ''
                  WHEN VISIT_ID = 'U2BC38D01' THEN ''
                  WHEN VISIT_ID = 'U1BC39D01' THEN ''
                  WHEN VISIT_ID = 'U2BC39D01' THEN ''
                  WHEN VISIT_ID = 'U1BC40D01' THEN ''
                  WHEN VISIT_ID = 'U2BC40D01' THEN ''
                  WHEN VISIT_ID = 'U1BC41D01' THEN ''
                  WHEN VISIT_ID = 'U2BC41D01' THEN ''
                  WHEN VISIT_ID = 'U1BC42D01' THEN ''
                  WHEN VISIT_ID = 'U2BC42D01' THEN ''
                  WHEN VISIT_ID = 'U1BC43D01' THEN ''
                  WHEN VISIT_ID = 'U2BC43D01' THEN ''
                  ELSE NULL
               END)
               "CONTENT"
       FROM DATA d,
            USR_PAT u,
            VISIT_INFO i,
            V_PAT_SCHEDULE_IMPL im
      WHERE     u.PAT_ID = d.PAT_ID
            AND d.FORM = i.FORM
            AND d.PAGE = i.INSTANCE
            AND d.COUNTER = i.COUNTER
            AND u.PAT_ID = im.PAT_ID
   GROUP BY u.PAT_ID,
            u.SCR_NO,
            i.VISIT_ID,
            i.FORM,
            i.INSTANCE
   ORDER BY SCR_NO, i.FORM, i.INSTANCE;


DROP VIEW V_REPORT_ALL_VISITS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_ALL_VISITS
(
   PAT_ID,
   VISIT_ID,
   VISIT_DATE,
   NAME,
   FORM,
   PAGE
)
AS
   SELECT pat_id,
          visit_id,
          CASE
             WHEN     visday IS NOT NULL
                  AND vismon IS NOT NULL
                  AND visyea IS NOT NULL
             THEN
                TO_DATE (visday || '/' || vismon || '/' || visyea,
                         'DD.MM.YYYY')
             ELSE
                NULL
          END
             AS visit_date,
          name,
          FORM,
          PAGE
     FROM (  SELECT d.pat_id,
                    d.Form,
                    d.page,
                    info.visit_id,
                    info.name,
                    MAX (
                       CASE
                          WHEN d.field IN
                                  ('VISDAY',
                                   'SCFVISDAY',
                                   'DSCVISDAY',
                                   'DELVISDAY')
                          THEN
                             d.VALUE
                          ELSE
                             NULL
                       END)
                       AS visday,
                    MAX (
                       CASE
                          WHEN d.field IN
                                  ('VISMON',
                                   'SCFVISMON',
                                   'DSCVISMON',
                                   'DELVISMON')
                          THEN
                             d.VALUE
                          ELSE
                             NULL
                       END)
                       AS vismon,
                    MAX (
                       CASE
                          WHEN d.field IN
                                  ('VISYEA',
                                   'SCFVISYEA',
                                   'DSCVISYEA',
                                   'DELVISYEA')
                          THEN
                             d.VALUE
                          ELSE
                             NULL
                       END)
                       AS visyea
               FROM data d, data d2, visit_info info
              WHERE     d.pat_id = d2.pat_id
                    AND d.FORM = d2.FORm
                    AND d.page = d2.page
                    AND info.FORM = d2.FORM
                    AND info.instance = d2.PAGE
                    AND d.FIELD IN
                           ('VISDAY',
                            'VISMON',
                            'VISYEA',
                            'SCFVISYEA',
                            'SCFVISDAY',
                            'SCFVISMON',
                            'DSCVISYEA',
                            'DSCVISMON',
                            'DSCVISDAY',
                            'DELVISYEA',
                            'DELVISMON',
                            'DELVISDAY')
                    AND d2.FIELD IN
                           ('PSCR_DATE',
                            'SCR_DATE',
                            'SCF_DATE',
                            'DSC_DATE',
                            'RND_DATE',
                            'RSP_DATE',
                            'DEL_DATE')
           GROUP BY d.pat_id,
                    d.Form,
                    D.page,
                    info.visit_id,
                    info.name);


DROP VIEW V_REPORT_COUNTRY_RELEASE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_COUNTRY_RELEASE
(
   COUTRY,
   GRP_ID,
   WAREHOUSE,
   DU_COUNT,
   KIT_DESCR,
   SEQ_RANGE,
   EXPIRATION_DATE,
   DU_RANGE,
   PREQ_LOT,
   PREQ_STATUS,
   DATE_ENTERED,
   DATE_RELEASED,
   USR_NAME
)
AS
   SELECT country.long_name AS COUTRY,
          l.grp_id,
          L.NAME AS warehouse,
          a.DU_COUNT,
          a.KIT_DESCR,
          a.SEQ_RANGE,
          a.expiration_date,
          cr1.du_name AS du_range,
          b.name AS preq_lot,
          CASE
             WHEN B.BLOCKED = 0 THEN 'Not Blocked'
             WHEN B.BLOCKED = 1 THEN 'Blocked'
             ELSE NULL
          END
             PREQ_STATUS,
          TO_CHAR (
             CAST (
                FROM_TZ (a.CREATED_TIMESTAMP, 'UTC') AT TIME ZONE CON.VALUE AS DATE),
             'DD-Mon-YYYY',
             'NLS_DATE_LANGUAGE=AMERICAN')
             AS Date_Entered,
          TO_CHAR (
             CAST (
                FROM_TZ (a.MODIFIED_AT, 'US/Eastern') AT TIME ZONE CON.VALUE AS DATE),
             'DD-Mon-YYYY',
             'NLS_DATE_LANGUAGE=AMERICAN')
             AS Date_Released,
          REPLACE (
             TRIM (
                U.TITLE || ' ' || U.FNAME || ' ' || U.MNAME || ' ' || U.LNAME),
             '  ',
             ' ')
             USR_NAME
     FROM v_drug_country country
          INNER JOIN (  SELECT CR.ID,
                               CR.DU_COUNT,
                               CR.KIT_DESCR,
                               CR.MIN_RANGE || '-' || CR.MAX_RANGE AS SEQ_RANGE,
                               CR.COUNTRY_ID,
                               CR.PREQ_ID,
                               CR.MODIFIED,
                               CR.CREATED_TIMESTAMP,
                               CR.MODIFIED_AT,
                               expiration_date AS expiration_date
                          FROM    drug_COUNTRY_RELEASE cr
                               INNER JOIN
                                  drug_kit km
                               ON    CR.MIN_RANGE = KM.SORT_KEY
                                  OR CR.MAX_RANGE = km.SORT_KEY
                      GROUP BY CR.ID,
                               CR.DU_COUNT,
                               CR.KIT_DESCR,
                               CR.MIN_RANGE,
                               CR.MAX_RANGE,
                               CR.COUNTRY_ID,
                               CR.PREQ_ID,
                               CR.MODIFIED,
                               CR.CREATED_TIMESTAMP,
                               CR.MODIFIED_AT,
                               expiration_date) a
             ON a.country_id = country.id
          INNER JOIN (SELECT cr.id,
                             kit.name || ' - ' || kitmax.name AS du_name
                        FROM drug_country_release cr
                             INNER JOIN DRUG_KIT kit
                                ON cr.MIN_RANGE = kit.SORT_KEY
                             INNER JOIN DRUG_KIT kitmax
                                ON cr.Max_RANGE = kitmax.SORT_KEY) cr1
             ON a.id = cr1.id
          LEFT JOIN drug_batch b
             ON a.PREQ_ID = B.ID
          LEFT JOIN ADMIN_IF.groups l
             ON     a.COUNTRY_ID = L.country_id
                AND L.cat_id = 11
                AND l.prj_id = 'P90020903'
          LEFT JOIN drug_configuration con
             ON CON.NAME = 'TimeZone'
          LEFT JOIN ADM_icrf3.WORKERS W
             ON W.WRK_ID = a.MODIFIED
          LEFT JOIN ADM_icrf3.USERS U
             ON W.USR_ID = U.USR_ID;


DROP VIEW V_REPORT_CUSTOM_PATDATA;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_CUSTOM_PATDATA
(
   PAT_ID,
   PAT_NO,
   ETHNICITY,
   RACE,
   GENDER,
   STRATA,
   ENCO_DOSE_STATUS,
   CETU_DOSE_STATUS,
   ENCO_ACTIVE_DOSE,
   CETU_ACTIVE_DOSE,
   PEMB,
   TREATMENT_ARM
)
AS
   SELECT u.pat_id,
          R.PAT_NO,
          d3.ETHNICITY,
          d3.RACE,
          d3.GENDER,
          f.description STRATA,
          dos.ENCO_DOSE_STATUS AS ENCO_DOSE_STATUS,
          dos.CETU_DOSE_STATUS AS CETU_DOSE_STATUS,
          dos.ENCO_ACTIVE_DOSE AS ENCO_ACTIVE_DOSE,
          CETU_ACTIVE_DOSE,
          PEMB,
          ARM.DESCRIPTION AS treatment_arm
     FROM usr_pat u
          LEFT JOIN drug_rndno r
             ON r.pat_id = u.pat_id
          LEFT JOIN drug_treatmentarm arm
             ON R.TREATMENTARM_ID = arm.id
          LEFT JOIN drug_rndno_factor_value dr
             ON dr.rndno_id = r.id AND dr.name = 'STRATA'
          LEFT JOIN drug_factor_value f
             ON f.VALUE = dr.VALUE AND f.name = dr.name
          LEFT JOIN (  SELECT d.pat_id,
                              CASE
                                 WHEN MAX (
                                         CASE
                                            WHEN d.FIELD = 'SCR_DATE' THEN 1
                                            ELSE 0
                                         END) = 1
                                 THEN
                                    MAX (
                                       CASE
                                          WHEN d.field = 'ETHNICITY'
                                          THEN
                                             str.en
                                       END)
                              END
                                 AS ETHNICITY,
                              CASE
                                 WHEN MAX (
                                         CASE
                                            WHEN d.FIELD = 'SCR_DATE' THEN 1
                                            ELSE 0
                                         END) = 1
                                 THEN
                                    MAX (
                                       CASE
                                          WHEN d.field = 'RACE' THEN str.en
                                       END)
                              END
                                 AS RACE,
                              CASE
                                 WHEN MAX (
                                         CASE
                                            WHEN d.FIELD = 'SCR_DATE' THEN 1
                                            ELSE 0
                                         END) = 1
                                 THEN
                                    MAX (
                                       CASE
                                          WHEN d.field = 'GENDER' THEN str.en
                                       END)
                              END
                                 AS GENDER
                         FROM data d
                              LEFT JOIN field_value_labels l
                                 ON     l.FORM = d.FORM
                                    AND d.VALUE = l.VALUE
                                    AND d.field = l.field
                              LEFT JOIN strings str
                                 ON l.label = '#' || str.str_id || '#'
                        WHERE d.field IN
                                 ('ETHNICITY',
                                  'RACE',
                                  'GENDER',
                                  'RND_DATE',
                                  'SCR_DATE')
                     GROUP BY d.pat_id) d3
             ON d3.pat_id = u.pat_id
          LEFT JOIN (SELECT a.*,
                            RANK ()
                            OVER (PARTITION BY a.pat_id
                                  ORDER BY a.VISIT_SEQ_NO DESC)
                               AS toprank
                       FROM (SELECT pat_id,
                                    ENCO_DOSE_STATUS,
                                    CETU_DOSE_STATUS,
                                    ENCO_ACTIVE_DOSE,
                                    CETU_ACTIVE_DOSE,
                                    PEMB,
                                    seq AS VISIT_SEQ_NO
                               FROM    V_REPORT_PAT_DOSE d
                                    INNER JOIN
                                       V_DISPVISIT_SEQ s
                                    ON d.visit_id = s.visit_id) a) dos
             ON dos.pat_id = u.pat_id AND dos.toprank = 1;


DROP VIEW V_REPORT_CUSTOM_PATTRIB;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_CUSTOM_PATTRIB
(
   PAT_ID,
   STATUS,
   AGE,
   YOB,
   PSCR_DATE,
   SCR_DATE,
   SCF_DATE,
   DSC_DATE,
   RND_DATE,
   CMP_DATE
)
AS
     SELECT a.pat_id,
            b.status,
            MAX (AGE) AS Age,
            MAX (YOB) AS YOB,
            MAX (CASE WHEN a.visit_id = 'PSCR' THEN a.visit_date END)
               AS PSCR_DATE,
            MAX (CASE WHEN a.visit_id = 'SCR' THEN a.visit_date END)
               AS scr_date,
            MAX (CASE WHEN a.visit_id = 'SCF' THEN a.visit_date END)
               AS SCF_DATE,
            MAX (CASE WHEN a.visit_id = 'DSC' THEN a.visit_date END)
               AS DSC_DATE,
            MAX (CASE WHEN a.visit_id = 'RND' THEN a.visit_date END)
               AS RND_DATE,
            MAX (CASE WHEN a.visit_id = 'CMP' THEN a.visit_date END)
               AS CMP_DATE
       FROM (SELECT pat_id,
                    CASE
                       WHEN     visday IS NOT NULL
                            AND vismon IS NOT NULL
                            AND visyea IS NOT NULL
                       THEN
                          TO_DATE (visday || '/' || vismon || '/' || visyea,
                                   'DD.MM.YYYY')
                       ELSE
                          NULL
                    END
                       AS visit_date,
                    AGE,
                    YOB,
                    visit_id,
                    descr,
                    FORM,
                    PAGE
               FROM (  SELECT d.pat_id,
                              d.Form,
                              d.page,
                              info.visit_id,
                              info.descr,
                              MAX (
                                 CASE
                                    WHEN d.field IN
                                            ('VISDAY', 'SCFVISDAY', 'DSCVISDAY')
                                    THEN
                                       d.VALUE
                                    ELSE
                                       NULL
                                 END)
                                 AS visday,
                              MAX (
                                 CASE
                                    WHEN d.field IN
                                            ('VISMON', 'SCFVISMON', 'DSCVISMON')
                                    THEN
                                       d.VALUE
                                    ELSE
                                       NULL
                                 END)
                                 AS vismon,
                              MAX (
                                 CASE
                                    WHEN d.field IN
                                            ('VISYEA', 'SCFVISYEA', 'DSCVISYEA')
                                    THEN
                                       d.VALUE
                                    ELSE
                                       NULL
                                 END)
                                 AS visyea,
                              CASE
                                 WHEN MAX (
                                         CASE
                                            WHEN d2.FIELD = 'SCR_DATE' THEN 1
                                            ELSE 0
                                         END) = 1
                                 THEN
                                    MAX (
                                       CASE WHEN d.field = 'AGE' THEN d.VALUE END)
                              END
                                 AS AGE,
                              MAX (CASE WHEN d.FIELD = 'DOBYEA' THEN d.VALUE END)
                                 AS YOB
                         FROM data d, data d2, visit_info info
                        WHERE     d.pat_id = d2.pat_id
                              AND d.FORM = d2.FORm
                              AND d.page = d2.page
                              AND info.FORM = d2.FORM
                              AND info.instance = d2.PAGE
                              AND d.field IN
                                     ('AGE',
                                      'DOBYEA',
                                      'VISDAY',
                                      'VISMON',
                                      'VISYEA',
                                      'SCFVISYEA',
                                      'SCFVISDAY',
                                      'SCFVISMON',
                                      'DSCVISYEA',
                                      'DSCVISMON',
                                      'DSCVISDAY',
                                      'SCR_DATE')
                              AND d2.FIELD IN
                                     ('PSCR_DATE',
                                      'SCR_DATE',
                                      'SCF_DATE',
                                      'DSC_DATE',
                                      'RND_DATE',
                                      'RSP_DATE')
                     GROUP BY d.pat_id,
                              d.Form,
                              d.page,
                              info.visit_id,
                              info.descr)) a,
            usr_pat b
      WHERE a.pat_id = b.pat_id
   GROUP BY a.pat_id, b.status;


DROP VIEW V_REPORT_DU_CNTYRLS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_DU_CNTYRLS
(
   ID,
   COUNTRIES_RELEASED
)
AS
     SELECT ID,
            LISTAGG (COUNTRIES_RELEASED, ', ')
               WITHIN GROUP (ORDER BY COUNTRIES_RELEASED)
               AS COUNTRIES_RELEASED
       FROM (  SELECT K.ID, DC.LONG_NAME AS COUNTRIES_RELEASED
                 FROM DRUG_KIT K
                      INNER JOIN DRUG_BATCH B
                         ON K.BATCH_ID = B.ID
                      INNER JOIN DRUG_COUNTRY_RELEASE CR
                         ON     K.SORT_KEY BETWEEN CR.MIN_RANGE AND CR.MAX_RANGE
                            AND K.UNBL_KIT_TYPE_ID = CR.UNBL_KIT_TYPE_ID
                            AND CR.PREQ_ID = B.ID
                      INNER JOIN V_DRUG_COUNTRY DC
                         ON CR.COUNTRY_ID = DC.ID
             GROUP BY K.ID, DC.LONG_NAME)
   GROUP BY ID;


DROP VIEW V_REPORT_DU_INITIAL_DEPOT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_DU_INITIAL_DEPOT
(
   ID,
   SHIPMENT_NAME,
   TOPRANK,
   INITIAL_DEPOT,
   GRP_NUMBER
)
AS
   SELECT "ID",
          "SHIPMENT_NAME",
          "TOPRANK",
          "INITIAL_DEPOT",
          "GRP_NUMBER"
     FROM (SELECT TL.KIT_ID AS id,
                  s.name AS shipment_name,
                  RANK ()
                  OVER (PARTITION BY TL.KIT_ID
                        ORDER BY S.CREATED_TIMESTAMP ASC)
                     AS toprank,
                  l.name AS initial_depot,
                  L.GRP_NUMBER
             FROM V_DRUG_TRACK_LABELED tl
                  INNER JOIN drug_shipment s
                     ON s.id = TL.SHIPMENT_ID
                  INNER JOIN v_drug_location l
                     ON S.FROM_LOCATION_ID = l.id)
    WHERE toprank = 1;


DROP VIEW V_REPORT_LAST_DISP_VISIT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_LAST_DISP_VISIT
(
   PAT_ID,
   VISIT_ID,
   LAST_DISP_VIS_DATE,
   LAST_DISP_VIS,
   ROW_NUM
)
AS
   SELECT "PAT_ID",
          "VISIT_ID",
          "LAST_DISP_VIS_DATE",
          "LAST_DISP_VIS",
          "ROW_NUM"
     FROM (SELECT pat_id,
                  visit_id,
                  visit_date AS LAST_DISP_VIS_DATE,
                  name AS LAST_DISP_VIS,
                  ROW_NUMBER ()
                     OVER (PARTITION BY pat_id ORDER BY VISIT_SEQ_NO DESC)
                     row_num
             FROM (SELECT pat_id,
                          CASE
                             WHEN     visday IS NOT NULL
                                  AND vismon IS NOT NULL
                                  AND visyea IS NOT NULL
                             THEN
                                TO_DATE (
                                   visday || '/' || vismon || '/' || visyea,
                                   'DD.MM.YYYY')
                             ELSE
                                NULL
                          END
                             AS visit_date,
                          visit_id,
                          name,
                          FORM,
                          PAGE,
                          VISIT_SEQ_NO
                     FROM (  SELECT d.pat_id,
                                    d.Form,
                                    d.page,
                                    info.visit_id,
                                    info.name,
                                    MAX (
                                       CASE
                                          WHEN d.field IN ('VISDAY')
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       AS visday,
                                    MAX (
                                       CASE
                                          WHEN d.field IN ('VISMON')
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       AS vismon,
                                    MAX (
                                       CASE
                                          WHEN d.field IN ('VISYEA')
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       AS visyea,
                                    INFO.SEQ VISIT_SEQ_NO
                               FROM data d, V_DISPVISIT_SEQ info, data dat
                              WHERE     d.FORM IN (3, 4, 5, 6)
                                    AND d.FIELD IN
                                           ('VISDAY', 'VISMON', 'VISYEA')
                                    AND info.FORM = d.FORM
                                    AND info.instance = d.PAGE
                                    AND d.pat_id = dat.pat_id
                                    AND d.FORM = dat.FORM
                                    AND d.page = dat.page
                                    AND dat.field LIKE 'KIT_%_QTY'
                                    AND dat.VALUE > 0
                           GROUP BY d.pat_id,
                                    d.Form,
                                    d.page,
                                    info.visit_id,
                                    info.name,
                                    info.seq)))
    WHERE row_num = 1;


DROP VIEW V_REPORT_LAST_VISIT;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_LAST_VISIT
(
   PAT_ID,
   VISIT_ID,
   LAST_VIS_DATE,
   LAST_VIS,
   ROW_NUM
)
AS
   SELECT "PAT_ID",
          "VISIT_ID",
          "LAST_VIS_DATE",
          "LAST_VIS",
          "ROW_NUM"
     FROM (SELECT pat_id,
                  visit_id,
                  visit_date AS LAST_VIS_DATE,
                  name AS LAST_VIS,
                  ROW_NUMBER ()
                     OVER (PARTITION BY pat_id ORDER BY VISIT_SEQ_NO DESC)
                     row_num
             FROM (SELECT pat_id,
                          CASE
                             WHEN     visday IS NOT NULL
                                  AND vismon IS NOT NULL
                                  AND visyea IS NOT NULL
                             THEN
                                TO_DATE (
                                   visday || '/' || vismon || '/' || visyea,
                                   'DD.MM.YYYY')
                             ELSE
                                NULL
                          END
                             AS visit_date,
                          visit_id,
                          name,
                          FORM,
                          PAGE,
                          VISIT_SEQ_NO
                     FROM (  SELECT d.pat_id,
                                    d.Form,
                                    d.page,
                                    info.visit_id,
                                    info.name,
                                    MAX (
                                       CASE
                                          WHEN d.field IN
                                                  ('VISDAY',
                                                   'SCFVISDAY',
                                                   'DSCVISDAY',
                                                   'DELVISDAY')
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       AS visday,
                                    MAX (
                                       CASE
                                          WHEN d.field IN
                                                  ('VISMON',
                                                   'SCFVISMON',
                                                   'DSCVISMON',
                                                   'DELVISMON')
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       AS vismon,
                                    MAX (
                                       CASE
                                          WHEN d.field IN
                                                  ('VISYEA',
                                                   'SCFVISYEA',
                                                   'DSCVISYEA',
                                                   'DELVISYEA')
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       AS visyea,
                                    (CASE
                                        WHEN info.visit_id IN ('SCR')
                                        THEN
                                           1
                                        WHEN info.visit_id IN ('RND')
                                        THEN
                                           4
                                        WHEN info.visit_id IN
                                                ('SCF', 'DEL', 'DSC')
                                        THEN
                                           d.FORM * 1000 + d.page
                                        WHEN d.FORM IN (3, 4, 5, 6)
                                        THEN
                                           seq
                                        ELSE
                                           0
                                     END)
                                       AS VISIT_SEQ_NO
                               FROM data d,
                                    data d2,
                                    visit_info info,
                                    V_DISPVISIT_SEQ sq
                              WHERE     d.pat_id = d2.pat_id
                                    AND d.FORM = d2.FORM
                                    AND d.PAGE = d2.PAGE
                                    AND d.FIELD IN
                                           ('VISDAY',
                                            'VISMON',
                                            'VISYEA',
                                            'SCFVISYEA',
                                            'SCFVISDAY',
                                            'SCFVISMON',
                                            'DSCVISYEA',
                                            'DSCVISMON',
                                            'DSCVISDAY',
                                            'DELVISYEA',
                                            'DELVISMON',
                                            'DELVISDAY')
                                    AND d2.FIELD IN
                                           ('PSCR_DATE',
                                            'SCR_DATE',
                                            'RND_DATE',
                                            'SCR_DATE',
                                            'DSC_DATE',
                                            'RSP_DATE')
                                    AND d.FORM = info.FORM
                                    AND d.PAGE = info.instance
                                    AND d.FORM = sq.FORM(+)
                                    AND d.page = sq.instance(+)
                           GROUP BY d.pat_id,
                                    d.Form,
                                    d.page,
                                    info.visit_id,
                                    info.name,
                                    sq.seq)))
    WHERE row_num = 1;


DROP VIEW V_REPORT_LOCATION_ADDRESS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_LOCATION_ADDRESS
(
   LOCATION_ID,
   AMBADDRESS,
   FROADDRESS
)
AS
     SELECT location_id,
            MAX (AmbAddress) AS AmbAddress,
            MAX (froaddress) AS FroAddress
       FROM (SELECT a.location_id,
                    CASE
                       WHEN address_type_id = 1
                       THEN
                             fname
                          || ' '
                          || mname
                          || ' '
                          || lname
                          || CHR (13)
                          || CHR (10)
                          || 'Title: '
                          || title
                          || CHR (13)
                          || CHR (10)
                          || 'Organization: '
                          || organisation
                          || CHR (13)
                          || CHR (10)
                          || Street
                          || CHR (13)
                          || CHR (10)
                          || city
                          || ','
                          || state
                          || ', '
                          || zip
                          || CHR (13)
                          || CHR (10)
                          || a.country_id
                          || CHR (13)
                          || CHR (10)
                          || 'Phone: '
                          || phone
                          || CHR (13)
                          || CHR (10)
                          || 'Mobile: '
                          || mphone
                          || CHR (13)
                          || CHR (10)
                          || 'Fax: '
                          || fax
                          || CHR (13)
                          || CHR (10)
                          || 'Email: '
                          || email
                          || CHR (13)
                          || CHR (10)
                          || 'Notes: '
                          || notes
                    END
                       AS AmbAddress,
                    CASE
                       WHEN address_type_id = 0
                       THEN
                             fname
                          || ' '
                          || mname
                          || ' '
                          || lname
                          || CHR (13)
                          || CHR (10)
                          || 'Title: '
                          || title
                          || CHR (13)
                          || CHR (10)
                          || 'Organization: '
                          || organisation
                          || CHR (13)
                          || CHR (10)
                          || Street
                          || CHR (13)
                          || CHR (10)
                          || city
                          || ','
                          || state
                          || ', '
                          || zip
                          || CHR (13)
                          || CHR (10)
                          || a.country_id
                          || CHR (13)
                          || CHR (10)
                          || 'Phone: '
                          || phone
                          || CHR (13)
                          || CHR (10)
                          || 'Mobile: '
                          || mphone
                          || CHR (13)
                          || CHR (10)
                          || 'Fax: '
                          || fax
                          || CHR (13)
                          || CHR (10)
                          || 'Email: '
                          || email
                          || CHR (13)
                          || CHR (10)
                          || 'Notes: '
                          || notes
                    END
                       AS FroAddress
               FROM v_drug_location_address a
                    INNER JOIN v_drug_location l
                       ON l.id = A.LOCATION_ID
                    INNER JOIN v_drug_map_address_type m
                       ON M.ADDRESS_ID = a.id)
   GROUP BY location_id;


DROP VIEW V_REPORT_LOCATION_IRB;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_LOCATION_IRB
(
   LOCATION_ID,
   IRB_EXPIRATION_DATE,
   IRB_GRANTED,
   IRB_EXTENSION,
   IRB_EXTENSION_DATE
)
AS
     SELECT location_id,
            MAX (
               CASE
                  WHEN a.name = 'IRB_EXPIRATION_DATE' THEN a.VALUE
                  ELSE NULL
               END)
               AS IRB_EXPIRATION_DATE,
            CASE
               WHEN MAX (
                       CASE
                          WHEN a.name = 'IRB_EXTENSION' THEN a.VALUE
                          ELSE NULL
                       END)
                       IS NOT NULL
               THEN
                  'Yes'
               ELSE
                  'No'
            END
               AS IRB_GRANTED,
            MAX (CASE WHEN a.name = 'IRB_EXTENSION' THEN a.VALUE ELSE NULL END)
               AS IRB_EXTENSION,
            MAX (
               CASE
                  WHEN a.name = 'IRB_EXTENSION'
                  THEN
                     TO_CHAR (
                        CAST (
                           FROM_TZ (a.MODIFIED_AT, 'EST')
                              AT TIME ZONE CON.VALUE AS DATE),
                        'DD-Mon-YYYY',
                        'NLS_DATE_LANGUAGE=AMERICAN')
                  ELSE
                     NULL
               END)
               AS IRB_EXTENSION_DATE
       FROM    (SELECT *
                  FROM (SELECT location_id,
                               name,
                               VALUE,
                               modified_at,
                               RANK ()
                               OVER (PARTITION BY location_id, name
                                     ORDER BY modified_at DESC)
                                  AS toprank
                          FROM V_DRUG_IRB_HISTORY)
                 WHERE     name IN ('IRB_EXPIRATION_DATE', 'IRB_EXTENSION')
                       AND toprank = 1) a
            INNER JOIN
               drug_configuration con
            ON CON.NAME = 'TimeZone'
   GROUP BY location_id;


DROP VIEW V_REPORT_PAT_DOSE;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_PAT_DOSE
(
   PAT_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   ENCO_DOSE_STATUS,
   CETU_DOSE_STATUS,
   ENCO_ACTIVE_DOSE,
   CETU_ACTIVE_DOSE,
   PEMB
)
AS
   SELECT dat.PAT_ID AS PAT_id,
          info.VISIT_ID AS VISIT_ID,
          info.FORM AS FORM,
          info.INSTANCE AS INSTANCE,
          CASE
             WHEN TO_NUMBER (enco) > 0 THEN 'Active'
             WHEN TO_NUMBER (enco) = 0 THEN 'Hold'
             WHEN TO_NUMBER (enco) = -1 THEN 'Permanently Discontinued'
          END
             AS ENCO_DOSE_STATUS,
          CASE
             WHEN TO_NUMBER (cetu) > 0 THEN 'Active'
             WHEN TO_NUMBER (cetu) = 0 THEN 'Hold'
             WHEN TO_NUMBER (cetu) = -1 THEN 'Permanently Discontinued'
          END
             AS CETU_DOSE_STATUS,
          dose_enco.name AS enco_active_Dose,
          dose_cetu.name AS cetu_active_Dose,
          PEMB
     FROM (SELECT *
             FROM (SELECT d.pat_id,
                          d.FORM,
                          d.page,
                          d.VALUE,
                          d.field
                     FROM DATA d
                    WHERE d.form IN (3, 4, 5, 6)) PIVOT (MIN (VALUE)
                                                  FOR field
                                                  IN  ('RSP_ENCO_DOSE' ENCO,
                                                      'RSP_CETU_DOSE' CETU,
                                                      'RSP_PEMB_DOSE' PEMB,
                                                      'RSP_ACTV_ENCO_DOSE' ENCO_ACTIVE,
                                                      'RSP_ACTV_CETU_DOSE' CETU_ACTIVE,
                                                      'RSP_DATE' RSP))) dat
          INNER JOIN VISIT_INFO info
             ON info.FORM = dat.FORM AND dat.PAGE = info.INSTANCE
          LEFT JOIN DRUG_dose_custom dose_enco
             ON dose_enco.id = ENCO_ACTIVE
          LEFT JOIN DRUG_dose_custom dose_cetu
             ON dose_cetu.id = CETU_ACTIVE
    WHERE RSP IS NOT NULL;


DROP VIEW V_REPORT_PERM_VISITS;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_PERM_VISITS
(
   ID,
   NAME,
   DESCR
)
AS
   SELECT DISTINCT visit_id AS ID, name, descr
     FROM visit_info
    WHERE instance = 0 AND counter = 0;


DROP VIEW V_REPORT_STANDARD;

/* Formatted on 9/18/2024 9:22:07 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD
(
   PAT_ID,
   DOB_DATE,
   DOB_YEAR,
   AGE_MONTH,
   AGE_YEARS,
   RESCR_DATE,
   TRTEND_DATE,
   TRTEND_DESCR
)
AS
     SELECT pat_id,
            MAX (CASE WHEN field = 'DOB_DATE' THEN date_value ELSE NULL END)
               AS DOB_DATE,
            MAX (
               CASE
                  WHEN field = 'DOB_DATE' THEN EXTRACT (YEAR FROM date_value)
                  ELSE NULL
               END)
               AS DOB_YEAR,
            MAX (
               CASE
                  WHEN field = 'DOB_DATE'
                  THEN
                     FLOOR (TRUNC (MONTHS_BETWEEN (SYSDATE, date_value)))
                  ELSE
                     NULL
               END)
               AS AGE_MONTH,
            MAX (
               CASE
                  WHEN field = 'DOB_DATE'
                  THEN
                     FLOOR (TRUNC (MONTHS_BETWEEN (SYSDATE, date_value)) / 12)
                  ELSE
                     NULL
               END)
               AS AGE_YEARS,
            MAX (CASE WHEN field = 'RESCR_DATE' THEN date_value ELSE NULL END)
               AS RESCR_DATE,
            MAX (CASE WHEN field = 'TRTEND_DATE' THEN date_value ELSE NULL END)
               AS TRTEND_DATE,
            MAX (CASE WHEN field = 'TRTEND_DESCR' THEN VALUE ELSE NULL END)
               AS TRTEND_DESCR
       FROM (  SELECT pat_id,
                      r.id AS field,
                      NULL AS VALUE,
                      CASE
                         WHEN MAX (d.field) LIKE '%YEA' AND MAX (VALUE) IS NULL
                         THEN
                            NULL
                         ELSE
                            TO_DATE (
                                  MAX (
                                     CASE
                                        WHEN d.field LIKE '%DAY' THEN VALUE
                                        ELSE '01'
                                     END)
                               || '.'
                               || MAX (
                                     CASE
                                        WHEN d.field LIKE '%MON' THEN VALUE
                                        ELSE '01'
                                     END)
                               || '.'
                               || MAX (
                                     CASE
                                        WHEN d.field LIKE '%YEA' THEN VALUE
                                        ELSE '01'
                                     END),
                               'DD.MM.YYYY')
                      END
                         AS date_value,
                      MAX (modified_by) AS modified_by
                 FROM report_standard r, data d
                WHERE     (   d.field = r.field || 'DAY'
                           OR d.field = r.field || 'MON'
                           OR d.field = r.field || 'YEA')
                      AND r.form = d.form
                      AND r.page = d.page
                      AND r.counter = d.counter
                      AND r.isdate = 1
             GROUP BY pat_id, r.id, SUBSTR (d.field, 0, LENGTH (d.field) - 3)
             UNION ALL
             SELECT pat_id,
                    r.id AS field,
                    CASE WHEN s.en IS NOT NULL THEN s.en ELSE d.VALUE END
                       AS VALUE,
                    NULL AS date_value,
                    modified_by
               FROM report_standard r,
                    data d,
                    field_value_labels f,
                    field_descr fd,
                    data_spec_values sp,
                    strings s
              WHERE     r.field = d.field
                    AND r.form = d.form
                    AND r.page = d.page
                    AND r.counter = d.counter
                    AND r.isdate = 0
                    AND d.form = f.form(+)
                    AND d.field = f.field(+)
                    AND d.VALUE = f.VALUE(+)
                    AND f.label = '#' || str_id(+) || '#'
                    AND d.form = fd.form(+)
                    AND d.field = fd.field(+)
                    AND d.spec_value = sp.spec_value(+))
   GROUP BY pat_id;


DROP VIEW V_REPORT_STANDARD_AUDIT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_AUDIT
(
   PAT_ID,
   MODIFIED_AT,
   MODIFIED,
   LABEL_REPORT,
   VALUE,
   VISIT_ID,
   REASON
)
AS
   SELECT pat_id,
          TO_DATE (
             TO_CHAR (
                NVL (
                   CAST (
                      FROM_TZ (
                         CAST (
                            SYS_EXTRACT_UTC (
                               FROM_TZ (CAST (d.modified AS TIMESTAMP),
                                        'EST')) AS TIMESTAMP),
                         'UTC')
                         AT TIME ZONE grp.timezone AS TIMESTAMP),
                   d.modified),
                'DD-MON-YYYY HH24:MI:SS',
                'NLS_DATE_LANGUAGE=AMERICAN'),
             'dd-Mon-yyyy HH24:MI:SS',
             'NLS_DATE_LANGUAGE =AMERICAN')
             AS modified_at,
          TRIM (
                TITLE
             || ' '
             || TRIM (FNAME || ' ' || TRIM (MNAME || ' ' || LNAME)))
             AS modified,
          label_report,
          CASE WHEN s.en IS NOT NULL THEN s.en ELSE d.VALUE END AS VALUE,
          visit_id,
          reason
     FROM (SELECT fd.pat_id,
                  fd.field,
                  fd.form,
                  fd.flow_number,
                  fd.label_report,
                  fd.val_set,
                  d.VALUE,
                  d.reason,
                  d.modified,
                  d.modified_by,
                  v.visit_id
             FROM (SELECT u.pat_id,
                          fd.field,
                          fd.form,
                          fd.flow_number,
                          fd.label_report,
                          fd.val_set
                     FROM field_descr fd, (SELECT pat_id FROM usr_pat) u
                    WHERE    fd.label_report IS NOT NULL
                          OR field LIKE 'INF%'
                          OR field IN ('INITIALS', 'RACE', 'AGE')) fd,
                  v_pat_schedule_impl p,
                  data_audit d,
                  visit_info v
            WHERE     fd.pat_id = p.pat_id
                  AND fd.pat_id = d.pat_id
                  AND fd.field = d.field
                  AND fd.form = d.form
                  AND d.form = v.form
                  AND d.page = v.instance
                  AND d.counter = v.counter
                  AND p.schedule_id = v.schedule_id) d,
          strings s,
          val_sets vs,
          adm_icrf4_if.workers w,
          adm_icrf4_if.users u,
          admin_if.groups grp
    WHERE     d.modified_by = w.wrk_id
          AND w.usr_id = u.usr_id
          AND d.val_set = vs.val_set(+)
          AND d.VALUE = vs.VALUE(+)
          AND vs.label = '#' || str_id(+) || '#'
          AND w.sit_id = grp.grp_id;


DROP VIEW V_REPORT_STANDARD_CONFIRMATION;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_CONFIRMATION
(
   PAT_ID,
   VISIT_ID,
   LABEL_REPORT,
   FLOW_NUMBER,
   VALUE,
   DATE_VALUE
)
AS
     SELECT pat_id,
            visit_id,
            label_report,
            MIN (d.flow_number) AS flow_number,
            CASE
               WHEN COUNT (label_report) = 1
               THEN
                  NVL (MAX (s.en), MAX (d.VALUE))
               ELSE
                  LISTAGG (s.en, ', ') WITHIN GROUP (ORDER BY s.en)
            END
               AS VALUE,
            CASE
               WHEN     MAX (CASE WHEN field LIKE '%DAY' THEN d.VALUE END)
                           IS NOT NULL
                    AND MAX (CASE WHEN field LIKE '%MON' THEN d.VALUE END)
                           IS NOT NULL
                    AND MAX (CASE WHEN field LIKE '%YEA' THEN d.VALUE END)
                           IS NOT NULL
               THEN
                  TO_DATE (
                        MAX (CASE WHEN field LIKE '%DAY' THEN d.VALUE END)
                     || '.'
                     || MAX (CASE WHEN field LIKE '%MON' THEN d.VALUE END)
                     || '.'
                     || MAX (CASE WHEN field LIKE '%YEA' THEN d.VALUE END),
                     'DD.MM.YYYY')
            END
               AS date_value
       FROM (SELECT d.pat_id,
                    d.field,
                    d.form,
                    d.flow_number,
                    d.label_report,
                    d.val_set,
                    d.VALUE,
                    v.visit_id
               FROM (SELECT fd.pat_id,
                            fd.field,
                            fd.form,
                            fd.flow_number,
                            fd.label_report,
                            fd.val_set,
                            d.VALUE,
                            d.counter,
                            d.page,
                            p.schedule_id
                       FROM (SELECT u.pat_id,
                                    fd.field,
                                    fd.form,
                                    fd.flow_number,
                                    fd.label_report,
                                    fd.val_set
                               FROM field_descr fd,
                                    (SELECT pat_id FROM usr_pat) u
                              WHERE fd.label_report IS NOT NULL) fd,
                            v_pat_schedule_impl p,
                            data d
                      WHERE     fd.pat_id = p.pat_id
                            AND fd.pat_id = d.pat_id(+)
                            AND fd.field = d.field(+)
                            AND fd.form = d.form(+)) d,
                    visit_info v
              WHERE     d.form = v.form(+)
                    AND d.page = v.instance(+)
                    AND d.counter = v.counter(+)
                    AND d.schedule_id = v.schedule_id(+)) d,
            strings s,
            val_sets vs
      WHERE     d.val_set = vs.val_set(+)
            AND d.VALUE = vs.VALUE(+)
            AND vs.label = '#' || str_id(+) || '#'
   GROUP BY pat_id, visit_id, label_report
   UNION
   SELECT td.pat_id,
          'RND' VISIT_ID,
          'Treatment Arm' LABEL_REPORT,
          31 FLOW_NUMBER,
          a.DESCRIPTION VALUE,
          NULL DATE_VALUE
     FROM    DRUG_RNDNO td
          INNER JOIN
             drug_treatmentarm a
          ON td.treatmentarm_id = a.id
    WHERE td.VISIT_ID = 'RND'
   UNION
   SELECT r.pat_id,
          'RND' VISIT_ID,
          'Randomization Number' LABEL_REPORT,
          30 FLOW_NUMBER,
          TO_CHAR (r.PAT_NO) VALUE,
          NULL DATE_VALUE
     FROM DRUG_RNDNO r
    WHERE r.PAT_ID IS NOT NULL
   UNION
   SELECT r.pat_id,
          v.visit_id,
          'Encorafenib Previous Dose Level' Label_report,
          40 FLOWNUMBER,
          GET_DOSE_DISPLAY ('ENCO_DOSE',
                            r.pat_id,
                            v.FORM,
                            v.page)
             AS VALUE,
          NULL DATE_VALUE
     FROM drug_rndno r
          INNER JOIN V_REPORT_ALL_VISITS v
             ON r.pat_id = v.pat_id AND v.FORM IN (3, 4)
          INNER JOIN V_REPORT_PAT_DOSE pdose
             ON     r.pat_id = pdose.pat_id
                AND v.visit_id = pdose.visit_id
                AND PDOSE.ENCO_DOSE_STATUS != 'Permanently Discontinued'
   UNION
   SELECT r.pat_id,
          v.visit_id,
          'Cetuximab Previous Dose Level' Label_report,
          41 FLOWNUMBER,
          GET_DOSE_DISPLAY ('CETU_DOSE',
                            r.pat_id,
                            v.FORM,
                            v.page)
             AS VALUE,
          NULL DATE_VALUE
     FROM drug_rndno r
          INNER JOIN V_REPORT_ALL_VISITS v
             ON r.pat_id = v.pat_id AND v.FORM IN (3, 4)
          INNER JOIN V_REPORT_PAT_DOSE pdose
             ON     r.pat_id = pdose.pat_id
                AND v.visit_id = pdose.visit_id
                AND PDOSE.CETU_DOSE_STATUS != 'Permanently Discontinued';


DROP VIEW V_REPORT_STANDARD_CONF_VSCHED;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_CONF_VSCHED
(
   PAT_ID,
   VISIT,
   FORM,
   INSTANCE,
   COUNTER,
   VISIT_DATE,
   VISIT_DATE_STRING,
   TOLERANCE_SOFT
)
AS
   SELECT w.pat_id,
          v.name AS visit,
          v.form,
          v.instance,
          v.counter,
          planned AS visit_date,
          TO_CHAR (planned, 'DD-Mon-YYYY', 'NLS_DATE_LANGUAGE = AMERICAN')
             AS visit_date_string,
          tolerance_soft_max AS tolerance_soft
     FROM V_PAT_VISIT_WINDOW w, v_pat_schedule_impl p, visit_info v
    WHERE     w.pat_id = p.pat_id
          AND p.schedule_id = v.schedule_id
          AND w.planned IS NOT NULL
          AND w.visit_id = v.visit_id;


DROP VIEW V_REPORT_STANDARD_LOCATION;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_LOCATION
(
   NAME,
   ID,
   RE_ACTIVATION,
   LATEST_ACTIVATION,
   EARLIEST_ACTIVATION,
   CLOSURE_DATE,
   REPL_COUNT
)
AS
   SELECT b."NAME",
          b."ID",
          b."RE_ACTIVATION",
          b."LATEST_ACTIVATION",
          b."EARLIEST_ACTIVATION",
          b."CLOSURE" AS closure_date,
          CASE WHEN k.REPL_COUNT IS NULL THEN 0 ELSE k.REPL_COUNT END
             AS REPL_COUNT
     FROM (SELECT DISTINCT
                  name,
                  id,
                  CASE
                     WHEN SUM (
                             CASE
                                WHEN     status_id = 'LocationStatus_ACTIVE'
                                     AND unchanged_status = 0
                                THEN
                                   1
                                ELSE
                                   0
                             END)
                          OVER (PARTITION BY id) = 1
                     THEN
                        NULL
                     ELSE
                        MAX (
                           CASE
                              WHEN     status_id = 'LocationStatus_ACTIVE'
                                   AND unchanged_status = 0
                              THEN
                                 modified_at
                              ELSE
                                 NULL
                           END)
                        OVER (PARTITION BY id)
                  END
                     Re_activation,
                  MAX (
                     CASE
                        WHEN status_id = 'LocationStatus_ACTIVE'
                        THEN
                           modified_at
                        ELSE
                           NULL
                     END)
                  OVER (PARTITION BY id)
                     latest_activation,
                  MIN (
                     CASE
                        WHEN status_id = 'LocationStatus_ACTIVE'
                        THEN
                           modified_at
                        ELSE
                           NULL
                     END)
                  OVER (PARTITION BY id)
                     earliest_activation,
                  MAX (
                     CASE
                        WHEN status_id = 'LocationStatus_CLOSED'
                        THEN
                           modified_at
                        ELSE
                           NULL
                     END)
                  OVER (PARTITION BY id)
                     closure
             FROM (SELECT TO_DATE (
                             TO_CHAR (
                                NVL (
                                   CAST (
                                      FROM_TZ (
                                         CAST (
                                            SYS_EXTRACT_UTC (
                                               FROM_TZ (
                                                  CAST (
                                                     b.modified_at AS TIMESTAMP),
                                                  'EST')) AS TIMESTAMP),
                                         'UTC')
                                         AT TIME ZONE grp.grp_tzname AS TIMESTAMP),
                                   b.modified_at),
                                'DD-MON-YYYY HH24:MI:SS',
                                'NLS_DATE_LANGUAGE=AMERICAN'),
                             'dd-Mon-yyyy HH24:MI:SS',
                             'NLS_DATE_LANGUAGE =AMERICAN')
                             AS modified_at,
                          b.modified,
                          b.status_id,
                          b.id,
                          b.from_audit,
                          v.name,
                          CASE
                             WHEN b.status_id =
                                     LAG (
                                        b.status_id)
                                     OVER (PARTITION BY b.id
                                           ORDER BY b.modified_at)
                             THEN
                                1
                             ELSE
                                0
                          END
                             AS unchanged_status
                     FROM (SELECT modified_at,
                                  modified,
                                  status_id,
                                  id,
                                  0 AS from_audit
                             FROM drug_location
                           UNION ALL
                           SELECT modified_at,
                                  modified,
                                  status_id,
                                  id,
                                  1 AS from_audit
                             FROM drug_audit_location) b,
                          v_drug_location v,
                          adm_icrf3.groups grp
                    WHERE b.id = v.id AND v.id = grp.grp_id)) b,
          (  SELECT location_id, COUNT (id) AS REPL_COUNT
               FROM drug_kit
              WHERE replaces_kit_id IS NOT NULL
           GROUP BY location_id) k
    WHERE b.id = k.location_id(+);


DROP VIEW V_REPORT_STANDARD_LOC_CUSTOM;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_LOC_CUSTOM
(
   NAME,
   ID,
   RE_ACTIVATION,
   EARLIEST_ACTIVATION,
   CLOSURE_DATE
)
AS
   SELECT b."NAME",
          b."ID",
          b."RE_ACTIVATION",
          b."EARLIEST_ACTIVATION",
          b."CLOSURE" AS closure_date
     FROM (SELECT DISTINCT
                  name,
                  id,
                  CASE
                     WHEN SUM (
                             CASE
                                WHEN     status_id = 'LocationStatus_ACTIVE'
                                     AND unchanged_status = 0
                                THEN
                                   1
                                ELSE
                                   0
                             END)
                          OVER (PARTITION BY id) = 1
                     THEN
                        NULL
                     ELSE
                        MAX (
                           CASE
                              WHEN     status_id = 'LocationStatus_ACTIVE'
                                   AND unchanged_status = 0
                              THEN
                                 modified_at
                              ELSE
                                 NULL
                           END)
                        OVER (PARTITION BY id)
                  END
                     Re_activation,
                  MAX (
                     CASE
                        WHEN status_id = 'LocationStatus_ACTIVE'
                        THEN
                           modified_at
                        ELSE
                           NULL
                     END)
                  OVER (PARTITION BY id)
                     latest_activation,
                  MIN (
                     CASE
                        WHEN status_id = 'LocationStatus_ACTIVE'
                        THEN
                           modified_at
                        ELSE
                           NULL
                     END)
                  OVER (PARTITION BY id)
                     earliest_activation,
                  MAX (
                     CASE
                        WHEN status_id = 'LocationStatus_CLOSED'
                        THEN
                           modified_at
                        ELSE
                           NULL
                     END)
                  OVER (PARTITION BY id)
                     closure
             FROM (SELECT TO_DATE (
                             TO_CHAR (
                                NVL (
                                   CAST (
                                      FROM_TZ (
                                         CAST (
                                            SYS_EXTRACT_UTC (
                                               FROM_TZ (
                                                  CAST (
                                                     b.modified_at AS TIMESTAMP),
                                                  'EST')) AS TIMESTAMP),
                                         'UTC')
                                         AT TIME ZONE grp.grp_tzname AS TIMESTAMP),
                                   b.modified_at),
                                'DD-MON-YYYY HH24:MI:SS',
                                'NLS_DATE_LANGUAGE=AMERICAN'),
                             'dd-Mon-yyyy HH24:MI:SS',
                             'NLS_DATE_LANGUAGE =AMERICAN')
                             AS modified_at,
                          b.modified,
                          b.status_id,
                          b.id,
                          b.from_audit,
                          v.name,
                          CASE
                             WHEN b.status_id =
                                     LAG (
                                        b.status_id)
                                     OVER (PARTITION BY b.id
                                           ORDER BY b.modified_at)
                             THEN
                                1
                             ELSE
                                0
                          END
                             AS unchanged_status
                     FROM (SELECT modified_at,
                                  modified,
                                  status_id,
                                  id,
                                  0 AS from_audit
                             FROM drug_location
                           UNION ALL
                           SELECT modified_at,
                                  modified,
                                  status_id,
                                  id,
                                  1 AS from_audit
                             FROM drug_audit_location) b,
                          v_drug_location v,
                          adm_icrf3.groups grp
                    WHERE b.id = v.id AND v.id = grp.grp_id)) b;


DROP VIEW V_REPORT_STANDARD_LOC_HISTORY;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_LOC_HISTORY
(
   NAME,
   ID,
   STATUS_ID,
   MODIFIED_AT,
   FROM_AUDIT,
   RE_ACTIVATION,
   LATEST_ACTIVATION,
   EARLIEST_ACTIVATION,
   LATEST_DEACTIVATION,
   EARLIEST_DEACTIVATION
)
AS
   SELECT name,
          id,
          status_id,
          modified_at,
          from_audit,
          CASE
             WHEN SUM (
                     CASE
                        WHEN status_id = 'LocationStatus_ACTIVE' THEN 1
                        ELSE 0
                     END)
                  OVER (PARTITION BY id) = 1
             THEN
                NULL
             ELSE
                MAX (
                   CASE
                      WHEN status_id = 'LocationStatus_ACTIVE'
                      THEN
                         modified_at
                      ELSE
                         NULL
                   END)
                OVER (PARTITION BY id)
          END
             Re_activation,
          MAX (
             CASE
                WHEN status_id = 'LocationStatus_ACTIVE' THEN modified_at
                ELSE NULL
             END)
          OVER (PARTITION BY id)
             latest_activation,
          MIN (
             CASE
                WHEN status_id = 'LocationStatus_ACTIVE' THEN modified_at
                ELSE NULL
             END)
          OVER (PARTITION BY id)
             earliest_activation,
          MAX (
             CASE
                WHEN status_id = 'LocationStatus_INACTIVE' THEN modified_at
                ELSE NULL
             END)
          OVER (PARTITION BY id)
             latest_deactivation,
          MIN (
             CASE
                WHEN status_id = 'LocationStatus_INACTIVE' THEN modified_at
                ELSE NULL
             END)
          OVER (PARTITION BY id)
             earliest_deactivation
     FROM (SELECT *
             FROM (SELECT b.modified_at,
                          b.modified,
                          b.status_id,
                          b.id,
                          b.from_audit,
                          v.name,
                          CASE
                             WHEN b.status_id =
                                     LAG (
                                        b.status_id)
                                     OVER (PARTITION BY b.id
                                           ORDER BY b.modified_at)
                             THEN
                                1
                             ELSE
                                0
                          END
                             AS unchanged_status
                     FROM (SELECT modified_at,
                                  modified,
                                  status_id,
                                  id,
                                  0 AS from_audit
                             FROM drug_location
                           UNION ALL
                           SELECT modified_at,
                                  modified,
                                  status_id,
                                  id,
                                  1 AS from_audit
                             FROM drug_audit_location) b,
                          v_drug_location v
                    WHERE b.id = v.id) b
            WHERE unchanged_status = 0);


DROP VIEW V_REPORT_STANDARD_LOGIN;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_LOGIN
(
   WRK_ID,
   LAST_LOGIN,
   FIRST_LOGIN,
   LOGIN_AMOUNT
)
AS
   SELECT b.wrk_id,
          TO_DATE (
             TO_CHAR (
                NVL (
                   CAST (
                      FROM_TZ (
                         CAST (
                            SYS_EXTRACT_UTC (
                               FROM_TZ (CAST (last_login AS TIMESTAMP),
                                        'EST')) AS TIMESTAMP),
                         'UTC')
                         AT TIME ZONE grp.grp_tzname AS TIMESTAMP),
                   last_login),
                'DD-MON-YYYY HH24:MI:SS',
                'NLS_DATE_LANGUAGE=AMERICAN'),
             'dd-Mon-yyyy HH24:MI:SS',
             'NLS_DATE_LANGUAGE =AMERICAN')
             AS last_login,
          TO_DATE (
             TO_CHAR (
                NVL (
                   CAST (
                      FROM_TZ (
                         CAST (
                            SYS_EXTRACT_UTC (
                               FROM_TZ (CAST (first_login AS TIMESTAMP),
                                        'EST')) AS TIMESTAMP),
                         'UTC')
                         AT TIME ZONE grp.grp_tzname AS TIMESTAMP),
                   first_login),
                'DD-MON-YYYY HH24:MI:SS',
                'NLS_DATE_LANGUAGE=AMERICAN'),
             'dd-Mon-yyyy HH24:MI:SS',
             'NLS_DATE_LANGUAGE =AMERICAN')
             AS first_login,
          login_amount
     FROM (  SELECT wrk_id,
                    MAX (action_date) AS last_login,
                    MIN (action_date) AS first_login,
                    COUNT (action_date) AS login_amount
               FROM logins
              WHERE action = 'login' AND REASON IS NULL
           GROUP BY wrk_id) b,
          ADMIN_IF.WORKERS wrk,
          ADM_ICRF3.GROUPS grp
    WHERE wrk.wrk_id = b.wrk_id AND grp.grp_id = wrk.grp_id;


DROP VIEW V_REPORT_STANDARD_PATDATA;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_PATDATA
(
   PAT_ID,
   PSCR_DATE,
   ETHNICITY,
   RACE,
   AGE,
   GENDER,
   STRATA,
   CETUX_DOSE,
   CETU_ACTV_DOSE,
   ENCO_DOSE,
   ENCO_ACTV_DOSE,
   PEMBRO_DOSE_STATUS,
   TREATMENT_ARM
)
AS
     SELECT d.PAT_ID,
            MAX (pscr.VISIT_DATE) AS PSCR_DATE,
            CASE
               WHEN MAX (CASE WHEN d.FIELD = 'SCR_DATE' THEN 1 ELSE 0 END) = 1
               THEN
                  MAX (CASE WHEN d.field = 'ETHNICITY' THEN str.en END)
            END
               AS ETHNICITY,
            CASE
               WHEN MAX (CASE WHEN d.FIELD = 'SCR_DATE' THEN 1 ELSE 0 END) = 1
               THEN
                  MAX (CASE WHEN d.field = 'RACE' THEN str.en END)
            END
               AS RACE,
            CASE
               WHEN MAX (CASE WHEN d.FIELD = 'SCR_DATE' THEN 1 ELSE 0 END) = 1
               THEN
                  MAX (CASE WHEN d.field = 'AGE' THEN d.VALUE END)
            END
               AS AGE,
            CASE
               WHEN MAX (CASE WHEN d.FIELD = 'SCR_DATE' THEN 1 ELSE 0 END) = 1
               THEN
                  MAX (CASE WHEN d.field = 'GENDER' THEN str.en END)
            END
               AS GENDER,
            CASE
               WHEN MAX (CASE WHEN d.FIELD = 'RND_DATE' THEN 1 ELSE 0 END) = 1
               THEN
                  MAX (CASE WHEN d.field = 'STRATA' THEN str.en END)
            END
               AS STRATA,
            MAX (dose.CETUX_DOSE) CETUX_DOSE,
            MAX (dose.CETU_ACTV_DOSE) CETU_ACTV_DOSE,
            MAX (dose.ENCO_DOSE) ENCO_DOSE,
            MAX (dose.ENCO_ACTV_DOSE) ENCO_ACTV_DOSE,
            MAX (dose.PEMBRO_DOSE_STATUS) PEMBRO_DOSE_STATUS,
            MAX (ARM.DESCRIPTION) AS TREATMENT_ARM
       FROM DATA d
            LEFT JOIN FIELD_VALUE_LABELS l
               ON d.form = l.form AND d.field = l.field AND d.VALUE = l.VALUE
            LEFT JOIN STRINGS str
               ON l.label = '#' || str.str_id || '#'
            INNER JOIN (SELECT pat_id, form, instance
                          FROM    VISIT_INFO v
                               INNER JOIN
                                  V_PAT_SCHEDULE_IMPL s
                               ON s.schedule_id = v.schedule_id) s
               ON     d.pat_id = s.pat_id
                  AND d.form = s.form
                  AND d.page = s.instance
            LEFT JOIN (SELECT PAT_ID, VISIT_ID, VISIT_DATE
                         FROM V_REPORT_STANDARD_PSTAT1) pscr
               ON pscr.PAT_ID = d.PAT_ID AND pscr.VISIT_ID = 'PSCR'
            LEFT JOIN DRUG_RNDNO r
               ON r.PAT_ID = d.PAT_ID
            LEFT JOIN DRUG_TREATMENTARM arm
               ON R.TREATMENTARM_ID = arm.id
            LEFT JOIN (SELECT v.PAT_ID,
                              ds.ENCO_DOSE_STATUS ENCO_DOSE,
                              ds.ENCO_ACTIVE_DOSE ENCO_ACTV_DOSE,
                              ds.CETU_DOSE_STATUS CETUX_DOSE,
                              ds.CETU_ACTIVE_DOSE CETU_ACTV_DOSE,
                              ds.PEMB PEMBRO_DOSE_STATUS,
                              RANK ()
                              OVER (PARTITION BY v.PAT_ID
                                    ORDER BY v.VISIT_SEQ_NO DESC)
                                 AS toprank
                         FROM    V_REPORT_PAT_DOSE ds
                              LEFT JOIN
                                 V_REPORT_SUBJ_TOTAL_VISITS v
                              ON     ds.PAT_ID = v.pat_id
                                 AND ds.visit_id = v.visit_id) dose
               ON dose.PAT_ID = d.PAT_ID AND dose.TOPRANK = 1
      WHERE d.field IN
               ('ETHNICITY',
                'RACE',
                'AGE',
                'GENDER',
                'STRATA',
                'SCR_DATE',
                'RND_DATE')
   GROUP BY d.PAT_ID;


DROP VIEW V_REPORT_STANDARD_PATTRIB;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_PATTRIB
(
   PAT_ID,
   CURRENT_STATUS,
   BIRTHDATE,
   SCR_DATE,
   SCR_TRANSACT_MOD_BY,
   SCR_TRANSACT_DATE,
   RND_DATE,
   RND_TRANSACT_MOD_BY,
   RND_TRANSACT_DATE,
   WITH_DATE,
   WITH_TRANSACT_MOD_BY,
   WITH_TRANSACT_DATE,
   SCR,
   RND,
   WIT,
   ENR,
   SEX,
   AGE,
   INFDATE,
   CMPDATE,
   DSCDATE,
   SCFDATE,
   CMPREASON,
   DSCREASON,
   SCFREASON,
   WEIGHT
)
AS
   SELECT UP.pat_id,
          CASE
             WHEN pstat.status IS NULL THEN EMPTY_STATUS.status
             ELSE pstat.status
          END
             AS current_status,
          bdate AS birthdate,
          scr_date,
          scr_transact_mod_by,
          scr_transact_date,
          rnd_date,
          rnd_transact_mod_by,
          rnd_transact_date,
          CASE
             WHEN UP.withdrawn_date IS NOT NULL AND with_date IS NULL
             THEN
                UP.withdrawn_date
             ELSE
                with_date
          END
             AS with_date,
          with_transact_mod_by,
          with_transact_date,
          scr,
          rnd,
          wit,
          enr,
          sex,
          age,
          infdate,
          cmpdate,
          dscdate,
          scfdate,
          cmpreason,
          dscreason,
          scfreason,
          weight
     FROM usr_pat UP,
          (SELECT pat_id,
                  CASE
                     WHEN     day IS NOT NULL
                          AND mon IS NOT NULL
                          AND yea IS NOT NULL
                     THEN
                        TO_CHAR (
                           TO_DATE (day || '.' || mon || '.' || yea,
                                    'DD.MM.YYYY'),
                           'DD-Mon-YYYY',
                           'NLS_DATE_LANGUAGE = AMERICAN')
                     WHEN day IS NULL AND mon IS NOT NULL AND yea IS NOT NULL
                     THEN
                        SUBSTR (
                           TO_CHAR (
                              TO_DATE ('01.' || mon || '.' || yea,
                                       'DD.MM.YYYY'),
                              'DD-Mon-YYYY',
                              'NLS_DATE_LANGUAGE = AMERICAN'),
                           4)
                     WHEN day IS NULL AND mon IS NULL AND yea IS NOT NULL
                     THEN
                        SUBSTR (
                           TO_CHAR (TO_DATE ('01.01.' || yea, 'DD.MM.YYYY'),
                                    'DD-Mon-YYYY',
                                    'NLS_DATE_LANGUAGE = AMERICAN'),
                           8)
                  END
                     AS bdate
             FROM (  SELECT UP.pat_id,
                            MAX (CASE WHEN FIELD = 'DOBDAY' THEN VALUE END)
                               AS day,
                            MAX (CASE WHEN FIELD = 'DOBMON' THEN VALUE END)
                               AS mon,
                            MAX (CASE WHEN FIELD = 'DOBYEA' THEN VALUE END)
                               AS yea
                       FROM usr_pat UP, data d
                      WHERE d.field LIKE 'DOB%' AND UP.pat_id = d.pat_id(+)
                   GROUP BY UP.pat_id)) bd,
          (  SELECT pat_id,
                    MAX (CASE WHEN is_screening = 1 THEN visit_date END)
                       AS SCR_DATE,
                    MAX (CASE WHEN is_screening = 1 THEN modified_by END)
                       AS SCR_TRANSACT_MOD_BY,
                    MAX (CASE WHEN is_screening = 1 THEN transact_date END)
                       AS SCR_TRANSACT_DATE,
                    MAX (CASE WHEN is_randomization = 1 THEN visit_date END)
                       AS RND_DATE,
                    MAX (CASE WHEN is_randomization = 1 THEN modified_by END)
                       AS RND_TRANSACT_MOD_BY,
                    MAX (CASE WHEN is_randomization = 1 THEN transact_date END)
                       AS RND_TRANSACT_DATE,
                    MAX (CASE WHEN is_withdrawal = 1 THEN visit_date END)
                       AS WITH_DATE,
                    MAX (CASE WHEN is_withdrawal = 1 THEN modified_by END)
                       AS WITH_TRANSACT_MOD_BY,
                    MAX (CASE WHEN is_withdrawal = 1 THEN transact_date END)
                       AS WITH_TRANSACT_DATE,
                    MAX (is_screening) AS scr,
                    MAX (is_randomization) AS rnd,
                    MAX (is_withdrawal) AS wit,
                    MAX (is_enrollment) AS enr
               FROM v_report_standard_pstat1
           GROUP BY pat_id) d,
          (  SELECT d.pat_id,
                    CASE
                       WHEN MAX (CASE WHEN d.field = 'INFDAY' THEN d.VALUE END)
                               IS NOT NULL
                       THEN
                          (TO_DATE (
                                 MAX (
                                    CASE
                                       WHEN d.field = 'INFDAY' THEN d.VALUE
                                    END)
                              || '.'
                              || MAX (
                                    CASE
                                       WHEN d.field = 'INFMON' THEN d.VALUE
                                    END)
                              || '.'
                              || MAX (
                                    CASE
                                       WHEN d.field = 'INFYEA' THEN d.VALUE
                                    END),
                              'DD.MM.YYYY'))
                    END
                       AS infdate,
                    CASE
                       WHEN     MAX (
                                   CASE
                                      WHEN d.field = 'CMPVISDAY' THEN d.VALUE
                                   END)
                                   IS NOT NULL
                            AND MAX (
                                   CASE
                                      WHEN d.FIELD = 'CMP_DATE' THEN 1
                                      ELSE 0
                                   END) = 1
                       THEN
                          (TO_DATE (
                                 MAX (
                                    CASE
                                       WHEN d.field = 'CMPVISDAY' THEN d.VALUE
                                    END)
                              || '.'
                              || MAX (
                                    CASE
                                       WHEN d.field = 'CMPVISMON' THEN d.VALUE
                                    END)
                              || '.'
                              || MAX (
                                    CASE
                                       WHEN d.field = 'CMPVISYEA' THEN d.VALUE
                                    END),
                              'DD.MM.YYYY'))
                    END
                       AS cmpdate,
                    CASE
                       WHEN     MAX (
                                   CASE
                                      WHEN d.field = 'DSCVISDAY' THEN d.VALUE
                                   END)
                                   IS NOT NULL
                            AND MAX (
                                   CASE
                                      WHEN d.FIELD = 'DSC_DATE' THEN 1
                                      ELSE 0
                                   END) = 1
                       THEN
                          (TO_DATE (
                                 MAX (
                                    CASE
                                       WHEN d.field = 'DSCVISDAY' THEN d.VALUE
                                    END)
                              || '.'
                              || MAX (
                                    CASE
                                       WHEN d.field = 'DSCVISMON' THEN d.VALUE
                                    END)
                              || '.'
                              || MAX (
                                    CASE
                                       WHEN d.field = 'DSCVISYEA' THEN d.VALUE
                                    END),
                              'DD.MM.YYYY'))
                    END
                       AS dscdate,
                    CASE
                       WHEN     MAX (
                                   CASE
                                      WHEN d.field = 'SCFVISDAY' THEN d.VALUE
                                   END)
                                   IS NOT NULL
                            AND MAX (
                                   CASE
                                      WHEN d.FIELD = 'SCF_DATE' THEN 1
                                      ELSE 0
                                   END) = 1
                       THEN
                          (TO_DATE (
                                 MAX (
                                    CASE
                                       WHEN d.field = 'SCFVISDAY' THEN d.VALUE
                                    END)
                              || '.'
                              || MAX (
                                    CASE
                                       WHEN d.field = 'SCFVISMON' THEN d.VALUE
                                    END)
                              || '.'
                              || MAX (
                                    CASE
                                       WHEN d.field = 'SCFVISYEA' THEN d.VALUE
                                    END),
                              'DD.MM.YYYY'))
                    END
                       AS scfdate,
                    MAX (CASE WHEN d.field = 'GENDER' THEN str.en END) AS sex,
                    MAX (
                       CASE
                          WHEN d.field = 'AGE' AND d.FORM = 1 THEN d.VALUE
                       END)
                       AS age,
                    MAX (CASE WHEN d.field = 'WEIGHT' THEN d.VALUE END)
                       AS weight,
                    MAX (CASE WHEN d.field = 'CMPREASON' THEN str.en END)
                       AS cmpreason,
                    MAX (CASE WHEN d.field = 'DSCREASON' THEN str.en END)
                       AS dscreason,
                    MAX (CASE WHEN d.field = 'SCFREASON' THEN str.en END)
                       AS scfreason
               FROM data d,
                    field_value_labels l,
                    strings str,
                    (SELECT pat_id, form, instance
                       FROM visit_info v, v_pat_schedule_impl s
                      WHERE s.schedule_id = v.schedule_id) s
              WHERE     d.pat_id = s.pat_id
                    AND d.form = s.form
                    AND d.page = s.instance
                    AND d.form = l.form(+)
                    AND d.VALUE = l.VALUE(+)
                    AND d.field = l.field(+)
                    AND l.label = '#' || str.str_id(+) || '#'
                    AND d.field IN
                           ('GENDER',
                            'INFDAY',
                            'INFMON',
                            'INFYEA',
                            'AGE',
                            'WEIGHT',
                            'CMPVISDAY',
                            'CMPVISMON',
                            'CMPVISYEA',
                            'DSCVISDAY',
                            'DSCVISMON',
                            'DSCVISYEA',
                            'SCFVISDAY',
                            'SCFVISMON',
                            'SCFVISYEA',
                            'CMPREASON',
                            'DSCREASON',
                            'SCFREASON',
                            'SCF_DATE',
                            'DSC_DATE',
                            'CMP_DATE')
           GROUP BY d.pat_id) ad,
          (SELECT en AS status
             FROM strings
            WHERE str_id = 'EMPTY_STATUS') EMPTY_STATUS,
          V_PAT_STATUS pstat
    WHERE     UP.pat_id = bd.pat_id
          AND UP.pat_id = d.pat_id(+)
          AND UP.pat_id = ad.pat_id
          AND pstat.pat_id = UP.pat_id;


DROP VIEW V_REPORT_STANDARD_PPID;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_PPID
(
   PAT_ID,
   PPID
)
AS
   SELECT pat_id, pp_id AS ppid FROM usr_pat;


DROP VIEW V_REPORT_STANDARD_PSTAT1;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_PSTAT1
(
   PAT_ID,
   VISIT_ID,
   VISIT_NAME,
   STATUS,
   IS_SCREENING,
   IS_RANDOMIZATION,
   IS_DISPENSATION,
   IS_WITHDRAWAL,
   IS_ENROLLMENT,
   REPORT_VISIT_SCHEDULE,
   REPORT_DISPENSED_KITS,
   REPORT_KITS_EXPIRATION_DATE,
   VISIT_DATE,
   MODIFIED_BY,
   TRANSACT_DATE
)
AS
   SELECT b.pat_id,
          b.visit_id,
          b.visit_name,
          b.status,
          b.is_screening,
          b.is_randomization,
          b.is_dispensation,
          b.is_withdrawal,
          b.is_enrollment,
          b.REPORT_VISIT_SCHEDULE,
          b.REPORT_DISPENSED_KITS,
          report_kits_expiration_date,
          CASE WHEN d.VALUE IS NOT NULL THEN b.visit_date END visit_date,
          d.modified_by,
          TO_DATE (SUBSTR (d.VALUE, 1, 20),
                   'DD-Mon-YYYY HH24:MI:SS',
                   'NLS_DATE_LANGUAGE=AMERICAN')
             AS transact_date
     FROM (SELECT pat_id,
                  visit_id,
                  visit_name,
                  schedule_id,
                  status,
                  field,
                  form,
                  page,
                  counter,
                  IS_SCREENING,
                  IS_RANDOMIZATION,
                  IS_DISPENSATION,
                  IS_WITHDRAWAL,
                  IS_ENROLLMENT,
                  REPORT_VISIT_SCHEDULE,
                  REPORT_DISPENSED_KITS,
                  report_kits_expiration_date,
                  CASE
                     WHEN     visday IS NOT NULL
                          AND vismon IS NOT NULL
                          AND visyea IS NOT NULL
                     THEN
                        TO_DATE (visday || '.' || vismon || '.' || visyea,
                                 'DD.MM.YYYY')
                     ELSE
                        NULL
                  END
                     AS visit_date,
                  modified_by
             FROM (  SELECT d.pat_id,
                            b.visit_id,
                            b.visit_name,
                            b.schedule_id,
                            MAX (b.status) AS status,
                            MAX (b.field) AS field,
                            MAX (b.form) AS form,
                            MAX (b.instance) AS page,
                            MAX (b.counter) AS counter,
                            MAX (IS_SCREENING) AS IS_SCREENING,
                            MAX (IS_RANDOMIZATION) AS IS_RANDOMIZATION,
                            MAX (IS_DISPENSATION) IS_DISPENSATION,
                            MAX (IS_WITHDRAWAL) IS_WITHDRAWAL,
                            MAX (IS_ENROLLMENT) IS_ENROLLMENT,
                            MAX (REPORT_VISIT_SCHEDULE) REPORT_VISIT_SCHEDULE,
                            MAX (REPORT_DISPENSED_KITS) REPORT_DISPENSED_KITS,
                            MAX (report_kits_expiration_date)
                               report_kits_expiration_date,
                            MAX (CASE WHEN d.field = 'VISDAY' THEN d.VALUE END)
                               AS visday,
                            MAX (CASE WHEN d.field = 'VISMON' THEN d.VALUE END)
                               AS vismon,
                            MAX (CASE WHEN d.field = 'VISYEA' THEN d.VALUE END)
                               AS visyea,
                            MAX (modified_by) modified_by
                       FROM (SELECT v.visit_id,
                                    v.name AS visit_name,
                                    v.schedule_id,
                                    v.field,
                                    v.form,
                                    v.instance,
                                    v.counter,
                                    v.status,
                                    v.is_randomization,
                                    v.is_screening,
                                    v.is_dispensation,
                                    v.is_withdrawal,
                                    v.is_enrollment,
                                    v.report_visit_schedule,
                                    v.report_dispensed_kits,
                                    v.report_kits_expiration_date,
                                    UP.pat_id,
                                    UP.current_status
                               FROM v_report_standard_visit_status v,
                                    (SELECT UP.pat_id,
                                            UP.status AS current_status,
                                            v.schedule_id
                                       FROM usr_pat UP, v_pat_schedule_impl v
                                      WHERE UP.pat_id = v.pat_id) UP
                              WHERE UP.schedule_id = v.schedule_id) b,
                            data d
                      WHERE     b.pat_id = d.pat_id
                            AND b.form = d.form
                            AND b.instance = d.page
                            AND b.counter = d.counter
                            AND (   d.field IN ('VISDAY', 'VISMON', 'VISYEA')
                                 OR d.field = b.field)
                   GROUP BY d.pat_id,
                            b.visit_id,
                            b.visit_name,
                            b.schedule_id)) b,
          data d
    WHERE     b.pat_id = d.pat_id(+)
          AND b.field = d.field(+)
          AND b.form = d.form(+)
          AND b.page = d.page(+)
          AND b.counter = d.counter(+);


DROP VIEW V_REPORT_STANDARD_RECRUIT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_RECRUIT
(
   PAT_ID,
   SIT_ID,
   SCREENED,
   RANDOMIZED,
   BASE_DATE
)
AS
   SELECT UP.pat_id,
          sit_id,
          CASE WHEN is_screening = 1 THEN 1 END AS screened,
          CASE WHEN is_randomization = 1 THEN 1 END AS randomized,
          visit_date AS base_date
     FROM v_report_standard_pstat1 s, (SELECT pat_id, sit_id FROM usr_pat) UP
    WHERE     s.pat_id = UP.pat_id
          AND (s.is_screening = 1 OR s.is_randomization = 1);


DROP VIEW V_REPORT_STANDARD_RECRUIT_C;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_RECRUIT_C
(
   BASE_DATE,
   C_RANDOMIZED,
   C_SCREENED
)
AS
   SELECT base_date,
          SUM (
             randomized)
          OVER (ORDER BY base_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             AS c_randomized,
          SUM (
             screened)
          OVER (ORDER BY base_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             AS c_screened
     FROM (  SELECT SUM (screened) AS screened,
                    SUM (randomized) AS randomized,
                    base_date
               FROM V_REPORT_STANDARD_RECRUIT
           GROUP BY base_date
           ORDER BY base_date);


DROP VIEW V_REPORT_STANDARD_SETTING;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_SETTING
(
   LOC_ID,
   PARAMETER_GROUP,
   PARAMETER_ID,
   DND,
   DNC_SITE,
   DNC_WH,
   DNS_SITE,
   DNS_WH
)
AS
     SELECT LOCATION_ID AS LOC_ID,
            PARAMETER_GROUP,
            PARAMETER_ID,
            MAX (
               CASE
                  WHEN b.setting_id = 'DO_NOT_DISPENSE'
                  THEN
                     TO_NUMBER (b.VALUE)
                  ELSE
                     NULL
               END)
               AS DND,
            MAX (
               CASE
                  WHEN b.setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                  THEN
                     TO_NUMBER (b.VALUE)
                  ELSE
                     NULL
               END)
               AS DNC_SITE,
            MAX (
               CASE
                  WHEN b.setting_id = 'OFFSET_DO_NOT_COUNT_WAREHOUSE'
                  THEN
                     TO_NUMBER (b.VALUE)
                  ELSE
                     NULL
               END)
               AS DNC_WH,
            MAX (
               CASE
                  WHEN b.setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                  THEN
                     TO_NUMBER (b.VALUE)
                  ELSE
                     NULL
               END)
               AS DNS_SITE,
            MAX (
               CASE
                  WHEN b.setting_id = 'OFFSET_DO_NOT_SHIP_WAREHOUSE'
                  THEN
                     TO_NUMBER (b.VALUE)
                  ELSE
                     NULL
               END)
               AS DNS_Wh
       FROM (  SELECT DISTINCT
                      sv.SETTING_ID,
                      DECODE (ss.HIERARCHICAL || ss.HIERARCHY_LEVEL,
                              '1COUNTRY', si.COUNTRY_ID,
                              si.GRP_ID)
                         "LOCATION_ID",
                      si.GRP_ID "SIT_ID",
                      p.PARAMETER_GROUP,
                      p.PARAMETER_ID,
                      si.NAME,
                      ss.HIERARCHICAL,
                      ss.HIERARCHY_LEVEL,
                      CASE
                         WHEN NOT EXISTS
                                     (SELECT *
                                        FROM SETTING
                                       WHERE     SETTING_ID = sv.SETTING_ID
                                             AND PARAMETER_GROUP IS NOT NULL)
                         THEN
                            CASE
                               WHEN NOT EXISTS
                                           (SELECT *
                                              FROM SETTING_VALUES
                                             WHERE     SETTING_ID = sv.SETTING_ID
                                                   AND LOCATION_ID =
                                                          DECODE (
                                                             ss.HIERARCHY_LEVEL,
                                                             'COUNTRY', si.COUNTRY_ID,
                                                             'SITE', si.GRP_ID,
                                                             'WAREHOUSE', si.GRP_ID,
                                                             'SITE_AND_WAREHOUSE', si.GRP_ID))
                               THEN
                                  MAX (
                                     CASE
                                        WHEN sv.LOCATION_ID IS NULL
                                        THEN
                                              VALUE
                                           || DECODE (UNIT,
                                                      NULL, NULL,
                                                      ' ' || UNIT)
                                        ELSE
                                           NULL
                                     END)
                               ELSE
                                  MAX (
                                     CASE
                                        WHEN sv.LOCATION_ID =
                                                DECODE (
                                                   ss.HIERARCHY_LEVEL,
                                                   'COUNTRY', si.COUNTRY_ID,
                                                   'SITE', si.GRP_ID,
                                                   'WAREHOUSE', si.GRP_ID,
                                                   'SITE_AND_WAREHOUSE', si.GRP_ID)
                                        THEN
                                              VALUE
                                           || DECODE (UNIT,
                                                      NULL, NULL,
                                                      ' ' || UNIT)
                                        ELSE
                                           NULL
                                     END)
                            END
                         ELSE
                            CASE
                               WHEN EXISTS
                                       (SELECT *
                                          FROM SETTING_VALUES
                                         WHERE     SETTING_ID = sv.SETTING_ID
                                               AND LOCATION_ID =
                                                      DECODE (
                                                         ss.HIERARCHY_LEVEL,
                                                         'COUNTRY', si.COUNTRY_ID,
                                                         'SITE', si.GRP_ID,
                                                         'WAREHOUSE', si.GRP_ID,
                                                         'SITE_AND_WAREHOUSE', si.GRP_ID)
                                               AND (   PARAMETER_ID =
                                                          p.PARAMETER_ID
                                                    OR PARAMETER_ID IS NULL))
                               THEN
                                  MAX (
                                     CASE
                                        WHEN     sv.LOCATION_ID =
                                                    DECODE (
                                                       ss.HIERARCHY_LEVEL,
                                                       'COUNTRY', si.COUNTRY_ID,
                                                       'SITE', si.GRP_ID,
                                                       'WAREHOUSE', si.GRP_ID,
                                                       'SITE_AND_WAREHOUSE', si.GRP_ID)
                                             AND ss.PARAMETER_GROUP =
                                                    p.PARAMETER_GROUP
                                             AND (   sv.PARAMETER_ID =
                                                        p.PARAMETER_ID
                                                  OR sv.PARAMETER_ID IS NULL)
                                        THEN
                                              VALUE
                                           || DECODE (UNIT,
                                                      NULL, NULL,
                                                      ' ' || UNIT)
                                        ELSE
                                           NULL
                                     END)
                               ELSE
                                  CASE
                                     WHEN EXISTS
                                             (SELECT *
                                                FROM SETTING_VALUES
                                               WHERE     SETTING_ID =
                                                            sv.SETTING_ID
                                                     AND (PARAMETER_ID =
                                                             p.PARAMETER_ID))
                                     THEN
                                        MAX (
                                           CASE
                                              WHEN     sv.LOCATION_ID IS NULL
                                                   AND ss.PARAMETER_GROUP =
                                                          p.PARAMETER_GROUP
                                                   AND (sv.PARAMETER_ID =
                                                           p.PARAMETER_ID)
                                              THEN
                                                    VALUE
                                                 || DECODE (UNIT,
                                                            NULL, NULL,
                                                            ' ' || UNIT)
                                              ELSE
                                                 NULL
                                           END)
                                     ELSE
                                        MAX (
                                           CASE
                                              WHEN     sv.LOCATION_ID IS NULL
                                                   AND ss.PARAMETER_GROUP =
                                                          p.PARAMETER_GROUP
                                                   AND (sv.PARAMETER_ID IS NULL)
                                              THEN
                                                    VALUE
                                                 || DECODE (UNIT,
                                                            NULL, NULL,
                                                            ' ' || UNIT)
                                              ELSE
                                                 NULL
                                           END)
                                  END
                            END
                      END
                         "VALUE"
                 FROM SETTING_VALUES sv,
                      SETTING ss,
                      ADMIN_IF.GROUPS si,
                      V_DRUG_PARAMETERS p,
                      V_DRUG_LOCATION l
                WHERE     si.GRP_ID = l.ID
                      AND si.cat_id IN (10, 11, 13)
                      AND sv.SETTING_ID = ss.SETTING_ID
                      AND p.parameter_group = 'VISIBLE_KIT_TYPE'
             GROUP BY sv.SETTING_ID,
                      si.GRP_ID,
                      si.NAME,
                      p.PARAMETER_GROUP,
                      p.PARAMETER_ID,
                      ss.SETTING_ID,
                      si.COUNTRY_ID,
                      ss.HIERARCHY_LEVEL,
                      ss.HIERARCHICAL) b
   GROUP BY LOCATION_ID, PARAMETER_GROUP, PARAMETER_ID
   ORDER BY LOCATION_ID, PARAMETER_GROUP, PARAMETER_ID;


DROP VIEW V_REPORT_STANDARD_SHIPMENT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_SHIPMENT
(
   ID,
   ASS_STATUS,
   ASS_DATE,
   ASS_COMMENT,
   SHIPMENT_TYPE,
   SHIPMENT_TRACKINGNO,
   SHIPMENT_FILL_TYPE,
   FOREIGN_SHIPMENT_ID,
   SHIPMENT_COMMENTS,
   IS_IN_TEMP_RANGE,
   IS_MONITOR_OK,
   MAX_TEMP,
   MIN_TEMP,
   AVG_TEMP,
   SKIP_TEMP_VALIDATION,
   NON_DRUG_ORDER,
   KIT_COUNT
)
AS
   SELECT a.shipment_id AS id,
          a.ass_status,
          s.acknowledgement_date AS ass_date,
          a.ass_comment,
          a.shipment_type,
          a.shipment_trackingno,
          a.shipment_fill_type,
          a.foreign_shipment_id,
          a.shipment_comments,
          a.is_in_temp_range,
          a.is_monitor_ok,
          a.max_temp,
          a.min_temp,
          a.avg_temp,
          a.skip_temp_validation,
          a.non_drug_order,
          NVL (s.kit_count, 0) + NVL (s2.kit_count, 0) AS kit_count
     FROM (  SELECT a.shipment_id,
                    MAX (
                       CASE
                          WHEN a.name = 'STATUS_ASSESSMENT' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS ASS_STATUS,
                    MAX (
                       CASE
                          WHEN a.name = 'ASSESSMENT_COMMENT' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS ASS_COMMENT,
                    MAX (
                       CASE
                          WHEN a.name = 'SHIPMENT_TYPE' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS SHIPMENT_TYPE,
                    MAX (
                       CASE
                          WHEN a.name = 'TrackingNo' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS SHIPMENT_TRACKINGNO,
                    MAX (
                       CASE
                          WHEN a.name = 'FILL_TYPE' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS SHIPMENT_FILL_TYPE,
                    MAX (
                       CASE
                          WHEN a.name = 'FOREIGN_SHIPMENT_ID' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS FOREIGN_SHIPMENT_ID,
                    MAX (
                       CASE WHEN a.name = 'Comments' THEN a.VALUE ELSE NULL END)
                       AS SHIPMENT_COMMENTS,
                    MAX (
                       CASE
                          WHEN a.name = 'IS_TEMP_IN_RANGE' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS IS_IN_TEMP_RANGE,
                    MAX (
                       CASE
                          WHEN a.name = 'IS_MONITOR_OK' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS IS_MONITOR_OK,
                    MAX (
                       CASE
                          WHEN a.name = 'MAX_TEMPERATURE' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS MAX_TEMP,
                    MAX (
                       CASE
                          WHEN a.name = 'MIN_TEMPERATURE' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS MIN_TEMP,
                    MAX (
                       CASE
                          WHEN a.name = 'AVG_TEMPERATURE' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS AVG_TEMP,
                    MAX (
                       CASE
                          WHEN a.name = 'SKIP_TEMP_VALIDATION' THEN a.VALUE
                          ELSE NULL
                       END)
                       AS SKIP_TEMP_VALIDATION,
                    MAX (
                       CASE WHEN a.name = 'NON_DRUG_SHIPMENT' THEN 1 ELSE 0 END)
                       AS NON_DRUG_ORDER,
                    MAX (a.modified_at) AS modified_at
               FROM drug_shipment_attrib a
           GROUP BY a.shipment_id) a,
          drug_shipment s,
          adm_icrf3.groups grp,
          (  SELECT shipment_id, COUNT (kit_id) AS kit_count
               FROM v_drug_track_labeled
           GROUP BY shipment_id) s,
          (  SELECT shipment_id, SUM (kit_amount) AS kit_count
               FROM v_drug_track_unlabeled
           GROUP BY shipment_id) s2
    WHERE     s.id = a.shipment_id
          AND s.to_location_id = grp.grp_id
          AND a.shipment_id = s.shipment_id(+)
          AND a.shipment_id = s2.shipment_id(+);


DROP VIEW V_REPORT_STANDARD_STAT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_STAT
(
   STAT,
   VALUE
)
AS
   SELECT 'Total Screened Patients' AS stat,
          TO_CHAR (COUNT (pat_id)) AS VALUE
     FROM usr_pat
    WHERE status = 'SCREENED'
   UNION ALL
   SELECT 'Total Randomized Patients' AS stat,
          TO_CHAR (COUNT (pat_id)) AS VALUE
     FROM usr_pat
    WHERE status = 'SCREENED'
   UNION ALL
   SELECT 'Total Sites' AS stat, TO_CHAR (COUNT (id)) AS VALUE
     FROM v_drug_location
    WHERE subclass = 'Site'
   UNION ALL
   SELECT 'Total Active Sites' AS stat, TO_CHAR (COUNT (id)) AS VALUE
     FROM v_drug_location
    WHERE subclass = 'Site' AND status_id = 'LocationStatus_ACTIVE'
   UNION ALL
   SELECT 'Total Inactive Sites' AS stat, TO_CHAR (COUNT (id)) AS VALUE
     FROM v_drug_location
    WHERE subclass = 'Site' AND status_id = 'LocationStatus_INACTIVE';


DROP VIEW V_REPORT_STANDARD_STATUS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_STATUS
(
   PAT_ID,
   STATUS_ID,
   STATUS,
   VALUE,
   SHOW_IN_MAP,
   SHOW_IN_PATIENTS_PIE,
   CURRENT_STATUS,
   CURRENT_STATUS_ID,
   ZERO_COLOR,
   LOW_COLOR,
   LOW_LIMIT,
   MED_COLOR,
   MED_LIMIT,
   HIGH_COLOR,
   LOW_TEXT,
   MED_TEXT,
   HIGH_TEXT
)
AS
   SELECT p.pat_id,
          p.status AS status_id,
          p.status AS status,
          CASE WHEN v.status IS NOT NULL THEN 1 ELSE 0 END AS VALUE,
          MAX (is_screening) OVER (PARTITION BY p.pat_id) AS show_in_map,
          MAX (is_screening) OVER (PARTITION BY p.pat_id)
             AS show_in_patients_pie,
          p.current_status,
          p.current_status AS current_status_id,
          "ZERO_COLOR",
          "LOW_COLOR",
          "LOW_LIMIT",
          "MED_COLOR",
          "MED_LIMIT",
          "HIGH_COLOR",
          "LOW_TEXT",
          "MED_TEXT",
          "HIGH_TEXT"
     FROM (  SELECT pat_id,
                    status,
                    MAX (is_screening) AS is_screening,
                    MAX (is_randomization) AS is_randomization
               FROM v_report_standard_pstat1
           GROUP BY status, pat_id) v,
          (SELECT DISTINCT u.pat_id, u.status AS current_status, v.status
             FROM usr_pat u, v_report_standard_visit_status v) p,
          (SELECT '10724259' AS ZERO_COLOR,
                  '11986147' AS LOW_COLOR,
                  25 AS LOW_LIMIT,
                  '9552320' AS MED_COLOR,
                  100 AS MED_LIMIT,
                  '5940898' AS HIGH_COLOR,
                  'Low' AS LOW_TEXT,
                  'Medium' AS MED_TEXT,
                  'High' AS HIGH_TEXT
             FROM DUAL)
    WHERE p.pat_id = v.pat_id(+) AND p.status = v.status(+);


DROP VIEW V_REPORT_STANDARD_STATUS_CONF;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_STATUS_CONF
(
   ID,
   SUBCLASS,
   NAME,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   LOCATION_TYPE,
   MODIFIED,
   MODIFIED_AT,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP
)
AS
   SELECT id,
          subclass,
          CASE
             WHEN name = 'DAMAGED2' AND subclass = 'KitStatus'
             THEN
                'Damanged2'
             ELSE
                name
          END
             AS name,
          created_by_user,
          created_timestamp,
          location_type,
          modified,
          modified_at,
          modified_by_user,
          modified_timestamp
     FROM drug_status;


DROP VIEW V_REPORT_STANDARD_USER;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_USER
(
   USR_ID,
   USR_LOGIN,
   USR_NAME,
   ORGANISATION,
   STREET,
   CITY,
   STATE,
   ZIP,
   COUNTRY,
   PHONE,
   MPHONE,
   FAX,
   EMAIL,
   PROJECT_DESCR,
   USR_DISABLED,
   USR_DISABLED_STRING,
   WRK_DISABLED,
   WRK_DISABLED_STRING,
   ROLE_DISABLED,
   ROLE_DISABLED_STRING,
   SITE_DISABLED,
   SITE_DISABLED_STRING,
   USR_LOCKED,
   USR_LOCKED_STRING,
   WRK_ID,
   USR_ROLE,
   ROLE_DESCR,
   SITE_ID,
   SITE_NAME,
   MAIN_INV_SITE_USR_NAME,
   SITE_CATEGORY,
   ENVIRONMENT,
   UNBLINDED,
   UNBLINDED_STRING,
   STATUS_PROPAGATE,
   STATUS_PROPERGATE_STRING,
   ACTIVE,
   INACTIVE,
   LOCKED,
   UNLOCKED,
   TRAINING_CONF
)
AS
   SELECT USR_ID,
          USR_LOGIN,
          USR_NAME,
          ORGANISATION,
          STREET,
          CITY,
          STATE,
          ZIP,
          COUNTRY,
          PHONE,
          MPHONE,
          FAX,
          EMAIL,
          PROJECT_DESCR,
          USR_DISABLED,
          USR_DISABLED_STRING,
          WRK_DISABLED,
          WRK_DISABLED_STRING,
          ROLE_DISABLED,
          ROLE_DISABLED_STRING,
          SITE_DISABLED,
          SITE_DISABLED_STRING,
          USR_LOCKED,
          USR_LOCKED_STRING,
          WRK_ID,
          USR_ROLE,
          ROLE_DESCR,
          SITE_ID,
          SITE_NAME,
          MAIN_INV_SITE_USR_NAME,
          SITE_CATEGORY,
          ENVIRONMENT,
          UNBLINDED,
          UNBLINDED_STRING,
          STATUS_PROPAGATE,
          STATUS_PROPERGATE_STRING,
          CASE WHEN STATUS_PROPAGATE = 1 THEN 'Active' ELSE NULL END
             AS active,
          CASE WHEN STATUS_PROPAGATE = 0 THEN 'Inactive' ELSE NULL END
             AS inactive,
          CASE WHEN USR_LOCKED = 1 THEN 'Locked' ELSE NULL END AS locked,
          CASE WHEN USR_LOCKED = 0 THEN 'Unlocked' ELSE NULL END AS unlocked,
          CASE WHEN confirmed IS NOT NULL THEN 'Yes' ELSE 'No' END
             training_conf
     FROM (SELECT U.USR_ID USR_ID,
                  U.LOGIN USR_LOGIN,
                  REPLACE (
                     TRIM (
                           U.TITLE
                        || ' '
                        || U.FNAME
                        || ' '
                        || U.MNAME
                        || ' '
                        || U.LNAME),
                     '  ',
                     ' ')
                     USR_NAME,
                  U.ORG_ID ORGANISATION,
                  U.STREET STREET,
                  U.CITY CITY,
                  U.STATE STATE,
                  U.ZIP ZIP,
                  C.DESCR COUNTRY,
                  U.PHONE,
                  U.MPHONE,
                  U.FAX,
                  U.EMAIL,
                  P.DESCR AS PROJECT_DESCR,
                  U.DISABLED AS USR_DISABLED,
                  CASE WHEN U.DISABLED = 1 THEN 'Disabled' ELSE 'Active' END
                     AS USR_DISABLED_STRING,
                  W.DISABLED AS WRK_DISABLED,
                  CASE
                     WHEN W.DISABLED = 0 OR W.DISABLED = 2 THEN 'Active'
                     ELSE 'Disabled'
                  END
                     AS WRK_DISABLED_STRING,
                  R.DISABLED AS ROLE_DISABLED,
                  CASE WHEN R.DISABLED = 0 THEN 'Disabled' ELSE 'Active' END
                     AS ROLE_DISABLED_STRING,
                  S.DISABLED AS SITE_DISABLED,
                  CASE WHEN S.DISABLED = 0 THEN 'Disabled' ELSE 'Active' END
                     AS SITE_DISABLED_STRING,
                  CASE WHEN U.FAILED_SBM > 4 THEN 1 ELSE 0 END USR_LOCKED,
                  CASE
                     WHEN U.FAILED_SBM > 4 THEN 'Locked'
                     ELSE 'Unlocked'
                  END
                     USR_LOCKED_STRING,
                  W.WRK_ID WRK_ID,
                  W.ROL_ID USR_ROLE,
                  R.DESCR AS ROLE_DESCR,
                  W.SIT_ID SITE_ID,
                  S.SITE SITE_NAME,
                  REPLACE (
                     TRIM (
                           MU.TITLE
                        || ' '
                        || MU.FNAME
                        || ' '
                        || MU.MNAME
                        || ' '
                        || MU.LNAME),
                     '  ',
                     ' ')
                     MAIN_INV_SITE_USR_NAME,
                  CAT.DESCR AS SITE_CATEGORY,
                  e.name AS ENVIRONMENT,
                  CASE
                     WHEN W.ROL_ID =
                             (SELECT ROL_ID
                                FROM ADM_ICRF4_IF.ROLEPRMLIST
                               WHERE     PRM_ID = 'DRUG_UNBLINDED'
                                     AND ROL_ID = W.ROL_ID)
                     THEN
                        1
                     ELSE
                        0
                  END
                     UNBLINDED,
                  CASE
                     WHEN W.ROL_ID =
                             (SELECT ROL_ID
                                FROM ADM_ICRF4_IF.ROLEPRMLIST
                               WHERE     PRM_ID = 'DRUG_UNBLINDED'
                                     AND ROL_ID = W.ROL_ID)
                     THEN
                        'Unblinded'
                     ELSE
                        'Blinded'
                  END
                     UNBLINDED_STRING,
                  CASE
                     WHEN     BITAND (W.DISABLED, 1) = 0
                          AND (W.EXPIRES IS NULL OR W.EXPIRES > SYSDATE)
                          AND U.DISABLED = 0
                          AND (U.EXPIRES IS NULL OR U.EXPIRES > SYSDATE)
                          AND U.FAILED_SBM < 5
                          AND R.DISABLED = 0
                          AND P.DISABLED = 0
                          AND G.DISABLED = 0
                          AND (W.PWDBIRTH IS NULL OR W.PWDBIRTH <= SYSDATE)
                          AND (U.PWDBIRTH IS NULL OR U.PWDBIRTH <= SYSDATE)
                     THEN
                        1
                     ELSE
                        0
                  END
                     STATUS_PROPAGATE,
                  CASE
                     WHEN     BITAND (W.DISABLED, 1) = 0
                          AND (W.EXPIRES IS NULL OR W.EXPIRES > SYSDATE)
                          AND U.DISABLED = 0
                          AND (U.EXPIRES IS NULL OR U.EXPIRES > SYSDATE)
                          AND U.FAILED_SBM < 5
                          AND R.DISABLED = 0
                          AND P.DISABLED = 0
                          AND G.DISABLED = 0
                          AND (W.PWDBIRTH IS NULL OR W.PWDBIRTH <= SYSDATE)
                          AND (U.PWDBIRTH IS NULL OR U.PWDBIRTH <= SYSDATE)
                     THEN
                        'Active'
                     ELSE
                        'Inactive'
                  END
                     STATUS_PROPERGATE_STRING,
                  ct.confirmed
             FROM adm_icrf3.categories cat,
                  admin_IF.environments e,
                  admin_IF.users uu,
                  adm_icrf3.groups g,
                  ADM_ICRF4_IF.USERS U,
                  ADM_ICRF4_IF.WORKERS W,
                  ADM_ICRF4_IF.SITES S,
                  ADM_ICRF4_IF.ROLES r,
                  ADM_ICRF4_IF.PROJECTS p,
                  ADM_ICRF4_IF.WORKERS MW,
                  ADM_ICRF4_IF.USERS MU,
                  adm_icrf4_if.countries c,
                  CONFIRM_TRAINING ct
            WHERE     s.env_id = e.env_id
                  AND s.sit_id = g.grp_id
                  AND g.cat_id = cat.cat_id
                  AND W.USR_ID = U.USR_ID
                  AND W.SIT_ID = S.SIT_ID
                  AND W.ROL_ID = R.ROL_ID
                  AND w.usr_id = uu.usr_id
                  AND p.prj_id = 'P90020903'
                  AND uu.internal = 0
                  AND r.prj_id = p.prj_id
                  AND u.cntry_id = c.cnr_id
                  AND s.MWRK_ID = MW.WRK_ID(+)
                  AND MW.USR_ID = MU.USR_ID(+)
                  AND U.USR_ID = CT.USR_ID(+));


DROP VIEW V_REPORT_STANDARD_VISIT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_VISIT
(
   PAT_ID,
   FIRST_VIS_DATE,
   FIRST_VIS,
   FIRST_VIS_DATE_ID,
   LAST_VIS_DATE,
   LAST_VIS,
   LAST_VIS_DATE_ID,
   FIST_DISP_DATE,
   FIST_DISP_VIS,
   FIST_DISP_VIS_ID,
   LAST_DISP_VIS_DATE,
   LAST_DISP_VIS,
   LAST_DISP_VIS_ID,
   NEXT_PLANED_VIS_DATE,
   NEXT_PLANED_VIS,
   NEXT_PLANED_VIS_ID,
   FIRST_RESUPPLY_VIS_DATE,
   FIRST_RESUPPLY_VIS,
   FIRST_RESUPPLY_VIS_ID
)
AS
     SELECT b.pat_id,
            MAX (
               CASE
                  WHEN b.first_done_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_date
                  ELSE
                     NULL
               END)
               first_vis_date,
            MAX (
               CASE
                  WHEN b.first_done_visit_seq_id = V.visit_seq_no
                  THEN
                     v.form_descr
                  ELSE
                     NULL
               END)
               first_vis,
            MAX (
               CASE
                  WHEN b.first_done_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_id
                  ELSE
                     NULL
               END)
               AS first_vis_date_id,
            MAX (
               CASE
                  WHEN b.last_done_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_date
                  ELSE
                     NULL
               END)
               last_vis_date,
            MAX (
               CASE
                  WHEN b.last_done_visit_seq_id = V.visit_seq_no
                  THEN
                     v.form_descr
                  ELSE
                     NULL
               END)
               last_vis,
            MAX (
               CASE
                  WHEN b.last_done_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_id
                  ELSE
                     NULL
               END)
               AS last_vis_date_id,
            MAX (
               CASE
                  WHEN b.first_disp_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_date
                  ELSE
                     NULL
               END)
               fist_disp_date,
            MAX (
               CASE
                  WHEN b.first_disp_visit_seq_id = V.visit_seq_no
                  THEN
                     v.form_descr
                  ELSE
                     NULL
               END)
               fist_disp_vis,
            MAX (
               CASE
                  WHEN b.first_disp_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_id
                  ELSE
                     NULL
               END)
               fist_disp_vis_id,
            MAX (
               CASE
                  WHEN b.last_disp_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_date
                  ELSE
                     NULL
               END)
               last_disp_vis_date,
            MAX (
               CASE
                  WHEN b.last_disp_visit_seq_id = V.visit_seq_no
                  THEN
                     v.form_descr
                  ELSE
                     NULL
               END)
               last_disp_vis,
            MAX (
               CASE
                  WHEN b.last_disp_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_id
                  ELSE
                     NULL
               END)
               last_disp_vis_id,
            MAX (
               CASE
                  WHEN b.next_planned_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_date
                  ELSE
                     NULL
               END)
               next_planed_vis_date,
            MAX (
               CASE
                  WHEN b.next_planned_visit_seq_id = V.visit_seq_no
                  THEN
                     v.form_descr
                  ELSE
                     NULL
               END)
               next_planed_vis,
            MAX (
               CASE
                  WHEN b.next_planned_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_id
                  ELSE
                     NULL
               END)
               next_planed_vis_id,
            MAX (
               CASE
                  WHEN b.first_rsply_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_date
                  ELSE
                     NULL
               END)
               AS first_resupply_vis_date,
            MAX (
               CASE
                  WHEN b.first_rsply_visit_seq_id = V.visit_seq_no
                  THEN
                     v.form_descr
                  ELSE
                     NULL
               END)
               AS first_resupply_vis,
            MAX (
               CASE
                  WHEN b.first_rsply_visit_seq_id = V.visit_seq_no
                  THEN
                     v.visit_id
                  ELSE
                     NULL
               END)
               AS first_resupply_vis_id
       FROM (SELECT DISTINCT
                    pat_id,
                    MIN (
                       CASE
                          WHEN visit_date_type = 'DONE' THEN visit_seq_no
                          ELSE NULL
                       END)
                    OVER (PARTITION BY pat_id)
                       AS first_done_visit_seq_id,
                    MAX (
                       CASE
                          WHEN visit_date_type = 'DONE' THEN visit_seq_no
                          ELSE NULL
                       END)
                    OVER (PARTITION BY pat_id)
                       AS last_done_visit_seq_id,
                    MIN (
                       CASE
                          WHEN visit_date_type = 'DONE' AND kit_amount > 0
                          THEN
                             visit_seq_no
                          ELSE
                             NULL
                       END)
                    OVER (PARTITION BY pat_id)
                       AS first_disp_visit_seq_id,
                    MAX (
                       CASE
                          WHEN visit_date_type = 'DONE' AND kit_amount > 0
                          THEN
                             visit_seq_no
                          ELSE
                             NULL
                       END)
                    OVER (PARTITION BY pat_id)
                       AS last_disp_visit_seq_id,
                    MIN (
                       CASE
                          WHEN     (   visit_date_type = 'PLANNED'
                                    OR visit_date_type = 'MISSING')
                               AND visit_seq_no > max_done_visit_seq_no
                          THEN
                             visit_seq_no
                          ELSE
                             NULL
                       END)
                    OVER (PARTITION BY pat_id)
                       AS next_planned_visit_seq_id,
                    MIN (
                       CASE
                          WHEN     visit_date_type = 'DONE'
                               AND form IN (3, 4, 5, 6)
                          THEN
                             visit_seq_no
                          ELSE
                             NULL
                       END)
                    OVER (PARTITION BY pat_id)
                       AS first_rsply_visit_seq_id
               FROM (  SELECT b.pat_id,
                              b.visit_id,
                              b.form,
                              b.visit_seq_no,
                              b.visit_date,
                              b.visit_date_type,
                              b.form_descr,
                              COUNT (k.id) AS kit_amount,
                              MAX (
                                 CASE
                                    WHEN visit_date_type = 'DONE'
                                    THEN
                                       visit_seq_no
                                    ELSE
                                       NULL
                                 END)
                              OVER (PARTITION BY b.pat_id)
                                 max_done_visit_seq_no
                         FROM    (SELECT vs.pat_id,
                                         s.form,
                                         vs.visit_id AS visit_id,
                                         vs.visit_date,
                                         vs.visit_date_type,
                                         vs.visit_seq_no,
                                         vs.descr AS form_name,
                                         vs.descr AS form_descr
                                    FROM    V_REPORT_SUBJ_TOTAL_VISITS vs
                                         INNER JOIN
                                            VISIT_INFO s
                                         ON     vs.schedule_id = s.schedule_id
                                            AND vs.visit_id = s.visit_id) b
                              INNER JOIN
                                 drug_kit k
                              ON     b.visit_id = k.visit_id(+)
                                 AND b.pat_id = k.pat_id(+)
                     GROUP BY b.pat_id,
                              b.visit_id,
                              b.form,
                              b.visit_seq_no,
                              b.visit_date,
                              b.form_descr,
                              b.visit_date_type)) b,
            (SELECT vs.pat_id,
                    vs.visit_id,
                    vs.visit_seq_no,
                    vs.visit_date,
                    vs.descr AS form_descr
               FROM V_REPORT_SUBJ_TOTAL_VISITS vs, visit_info s
              WHERE vs.schedule_id = s.schedule_id AND vs.visit_id = s.visit_id) v
      WHERE b.pat_id = v.pat_id(+)
   GROUP BY b.pat_id;


DROP VIEW V_REPORT_STANDARD_VISIT_STATUS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_VISIT_STATUS
(
   VISIT_ID,
   NAME,
   SCHEDULE_ID,
   FIELD,
   FORM,
   INSTANCE,
   COUNTER,
   STATUS,
   IS_RANDOMIZATION,
   IS_SCREENING,
   IS_DISPENSATION,
   IS_WITHDRAWAL,
   IS_ENROLLMENT,
   REPORT_VISIT_SCHEDULE,
   REPORT_DISPENSED_KITS,
   REPORT_KITS_EXPIRATION_DATE
)
AS
   SELECT p.visit_id,
          v.name,
          p.schedule_id,
          field,
          form,
          instance,
          counter,
          status,
          is_randomization,
          is_screening,
          is_dispensation,
          is_withdrawal,
          0 AS is_enrollment,
          report_visit_schedule,
          report_dispensed_kits,
          report_kits_expiration_date
     FROM pstat_vis p, visit_info v
    WHERE p.visit_id = v.visit_id AND p.schedule_id = v.schedule_id
   UNION ALL
   SELECT 'ENR' AS visit_id,
          'Enrollment' AS name,
          v.schedule_id,
          field,
          form,
          instance,
          counter,
          en AS status,
          0,
          0,
          0,
          0,
          1 AS is_enrollment,
          0 AS report_visit_schedule,
          0 AS report_dispensed_kits,
          0 AS report_kits_expiration_date
     FROM visit_info v, strings s, pstat_vis p
    WHERE     v.schedule_id = p.schedule_id
          AND v.visit_id = p.visit_id
          AND v.is_screening = 1
          AND s.str_id = 'EMPTY_STATUS';


DROP VIEW V_REPORT_STANDARD_VIS_KITS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_VIS_KITS
(
   PAT_ID,
   VISIT_ID,
   KITNOS,
   KIT_UNLABELED,
   KIT_UNLABELED_EXP,
   KIT_LABELED,
   KIT_LABELED_EXP,
   RECALL,
   ALL_KITS,
   ALL_KITS_EXP,
   ALL_KITS_EXP_PREQ,
   IS_RND_VISIT,
   UNBL_KT_NAME,
   UNBL_KT_DESCR
)
AS
   SELECT b.pat_id,
          b.visit_id,
          b.kitnos,
          kits.kit_unlabeled,
          kits.kit_unlabeled_exp,
          kits.kit_labeled,
          kits.kit_labeled_exp,
          CASE WHEN b.recall IS NOT NULL THEN 'Yes' ELSE 'No' END AS recall,
          SUBSTR (
                NVL2 (kits.kit_labeled, ', ' || kits.kit_labeled, NULL)
             || NVL2 (kits.kit_unlabeled, ', ' || kits.kit_unlabeled, NULL),
             3)
             AS all_kits,
          SUBSTR (
                NVL2 (kits.kit_labeled_exp,
                      ', ' || kits.kit_labeled_exp,
                      NULL)
             || NVL2 (kits.kit_unlabeled_exp,
                      ', ' || kits.kit_unlabeled_exp,
                      NULL),
             3)
             AS all_kits_exp,
          SUBSTR (
                NVL2 (kits.kit_labeled_exp_preq,
                      ', ' || kits.kit_labeled_exp_preq,
                      NULL)
             || NVL2 (kits.kit_unlabeled_exp,
                      ', ' || kits.kit_unlabeled_exp,
                      NULL),
             3)
             AS all_kits_exp_preq,
          v.is_randomization AS is_rnd_visit,
          kits.unbl_kt_name,
          kits.unbl_kt_descr
     FROM (  SELECT pat_id,
                    visit_id,
                    LISTAGG (kit_unlabeled_exp, ', ')
                       WITHIN GROUP (ORDER BY kit_unlabeled_exp)
                       AS kit_unlabeled_exp,
                    LISTAGG (kit_labeled_exp, ', ')
                       WITHIN GROUP (ORDER BY kit_labeled_exp)
                       AS kit_labeled_exp,
                    LISTAGG (kit_labeled_exp_preq, ', ')
                       WITHIN GROUP (ORDER BY kit_labeled_exp_preq)
                       AS kit_labeled_exp_preq,
                    LISTAGG (kit_unlabeled, ', ')
                       WITHIN GROUP (ORDER BY kit_unlabeled)
                       AS kit_unlabeled,
                    LISTAGG (kit_labeled, ', ')
                       WITHIN GROUP (ORDER BY kit_labeled)
                       AS kit_labeled,
                    LISTAGG (unbl_kt_name, ', ')
                       WITHIN GROUP (ORDER BY unbl_kt_name)
                       AS unbl_kt_name,
                    LISTAGG (unbl_kt_descr, ', ')
                       WITHIN GROUP (ORDER BY unbl_kt_descr)
                       AS unbl_kt_descr
               FROM (  SELECT pat_id,
                              k.visit_id,
                              CASE
                                 WHEN k.name IS NULL
                                 THEN
                                       kt.name
                                    || ' expiration '
                                    || TO_CHAR (k.expiration_date,
                                                'DD-Mon-YYYY',
                                                'NLS_DATE_LANGUAGE=AMERICAN')
                                    || ' (Amount: '
                                    || COUNT (k.id)
                                    || ')'
                              END
                                 AS kit_unlabeled_exp,
                              CASE
                                 WHEN k.name IS NOT NULL
                                 THEN
                                       k.name
                                    || ' expiration '
                                    || TO_CHAR (k.expiration_date,
                                                'DD-Mon-YYYY',
                                                'NLS_DATE_LANGUAGE=AMERICAN')
                              END
                                 AS kit_labeled_exp,
                              CASE
                                 WHEN k.name IS NOT NULL
                                 THEN
                                       k.name
                                    || ' expiration '
                                    || TO_CHAR (k.expiration_date,
                                                'DD-Mon-YYYY',
                                                'NLS_DATE_LANGUAGE=AMERICAN')
                                    || ' PREQ '
                                    || b.name
                              END
                                 AS kit_labeled_exp_preq,
                              NULL AS kit_unlabeled,
                              NULL AS kit_labeled,
                              NULL AS unbl_kt_name,
                              NULL AS unbl_kt_descr,
                              b.name AS preq
                         FROM drug_kit k, drug_kit_type kt, drug_batch b
                        WHERE     k.kit_type_id = kt.id
                              AND k.pat_id IS NOT NULL
                              AND K.BATCH_ID = b.id
                     GROUP BY pat_id,
                              k.visit_id,
                              k.name,
                              kt.name,
                              k.expiration_date,
                              b.name)
           GROUP BY pat_id, visit_id) kits,
          (  SELECT pat_id,
                    visit_id,
                    LISTAGG (name, ', ') WITHIN GROUP (ORDER BY name) AS kitnos,
                    MAX (recall_date) AS recall
               FROM drug_kit
              WHERE visit_id IS NOT NULL
           GROUP BY pat_id, visit_id) b,
          v_pat_schedule_impl s,
          visit_info v
    WHERE     b.pat_id = kits.pat_id(+)
          AND b.visit_id = kits.visit_id(+)
          AND b.pat_id = s.pat_id
          AND b.visit_id = v.visit_id
          AND s.schedule_id = v.schedule_id;


DROP VIEW V_REPORT_STANDARD_VIS_SCHED;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STANDARD_VIS_SCHED
(
   PAT_ID,
   FORM,
   INSTANCE,
   VISIT_DATE,
   LATEST_VISIT_DATE,
   DURATION,
   DURATION_UNIT,
   TOLERANCE_SOFT,
   TOLERANCE_HARD,
   TOLERANCE_UNIT,
   VISIT_DATE_TYPE,
   VISIT_SEQ_NO,
   FORM_NAME,
   FORM_DESCR,
   VISIT_ID,
   OUT_OF_WINDOW_HARD,
   OUT_OF_WINDOW
)
AS
   SELECT vs.pat_id,
          form,
          instance,
          visit_date,
          latest_visit_date,
          s.duration,
          duration_unit,
          s.tolerance_soft,
          s.tolerance_hard,
          tolerance_unit,
          visit_date_type,
          visit_seq_no,
          name AS form_name,
          descr AS form_descr,
          vs.visit_id,
          CASE WHEN w.out_of_hard_window IS NULL THEN 'no' ELSE 'yes' END
             AS out_of_window_hard,
          CASE WHEN w.out_of_soft_window IS NULL THEN 'no' ELSE 'yes' END
             AS out_of_window
     FROM v_dynamic_visit_schedule vs, v_pat_schedule s, v_pat_visit_window w
    WHERE     vs.pat_id = s.pat_id
          AND vs.visit_id = s.visit_id
          AND vs.pat_id = w.pat_id
          AND vs.visit_id = w.visit_id;


DROP VIEW V_REPORT_STUDY_KIT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_KIT
(
   ID,
   FORMULATION,
   POTENCY,
   MID
)
AS
   SELECT "ID",
          "FORMULATION",
          "POTENCY",
          "MID"
     FROM (SELECT kit_id AS id, VALUE, name FROM drug_kit_attrib) PIVOT (MIN (
                                                                            VALUE)
                                                                  FOR name
                                                                  IN  ('Formulation' Formulation,
                                                                      'Potency' Potency,
                                                                      'MID' MID));


DROP VIEW V_REPORT_STUDY_LOCATION;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_LOCATION
(
   ID,
   SCR_STATUS,
   RND_STATUS,
   SHP_STATUS,
   DND,
   DNC_SITE,
   DNS_SITE,
   DNC_WH,
   DNS_WH
)
AS
   SELECT l.id,
          CASE
             WHEN NVL (scrsite.VALUE, scr.VALUE) IN ('1', 'True') THEN 'Open'
             ELSE 'Closed'
          END
             AS scr_status,
          CASE
             WHEN NVL (rndsite.VALUE, rnd.VALUE) IN ('1', 'True') THEN 'Open'
             ELSE 'Closed'
          END
             AS rnd_status,
          CASE
             WHEN NVL (shpsite.VALUE, shp.VALUE) IN ('1', 'True') THEN 'Open'
             ELSE 'Closed'
          END
             AS shp_status,
          NVL (b.VALUE, a.VALUE) DND,
          NVL (b_dnc.VALUE, a_dnc.VALUE) AS DNC_SITE,
          NVL (b_dns.VALUE, a_dns.VALUE) AS DNS_SITE,
          NVL (b_dnc_wh.VALUE, a_dnc_wh.VALUE) AS DNC_WH,
          NVL (b_dns_wh.VALUE, a_dns_wh.VALUE) AS DNS_WH
     FROM V_DRUG_LOCATION l
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'SITE_SCR_OPEN'
                            AND location_id IS NULL) scr
             ON 1 = 1
          LEFT JOIN (SELECT setting_id, VALUE, location_id
                       FROM setting_values
                      WHERE setting_id = 'SITE_SCR_OPEN') scrsite
             ON scrsite.location_id = l.id
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'SITE_RND_OPEN'
                            AND location_id IS NULL) rnd
             ON 1 = 1
          LEFT JOIN (SELECT setting_id, VALUE, location_id
                       FROM setting_values
                      WHERE setting_id = 'SITE_RND_OPEN') rndsite
             ON rndsite.location_id = l.id
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'ACTIVATE_AUTOMATIC_SHIPMENT'
                            AND location_id IS NULL) shp
             ON 1 = 1
          LEFT JOIN (SELECT setting_id, VALUE, location_id
                       FROM setting_values
                      WHERE setting_id = 'ACTIVATE_AUTOMATIC_SHIPMENT') shpsite
             ON shpsite.location_id = l.id
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'DO_NOT_DISPENSE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) a
             ON 1 = 1
          LEFT JOIN setting_values b
             ON b.setting_id = 'DO_NOT_DISPENSE' AND b.LOCATION_ID = l.ID
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) a_dnc
             ON 1 = 1
          LEFT JOIN setting_values b_dnc
             ON     b_dnc.setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                AND b_dnc.LOCATION_ID = l.ID
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL
                            AND parameter_id IS NULL) a_dns
             ON 1 = 1
          LEFT JOIN setting_values b_dns
             ON     b_dns.setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                AND b_dns.LOCATION_ID = l.ID
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_WAREHOUSE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) a_dnc_wh
             ON 1 = 1
          LEFT JOIN setting_values b_dnc_wh
             ON     b_dnc_wh.setting_id = 'OFFSET_DO_NOT_COUNT_WAREHOUSE'
                AND b_dnc_wh.LOCATION_ID = l.ID
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_WAREHOUSE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) a_dns_wh
             ON 1 = 1
          LEFT JOIN setting_values b_dns_wh
             ON     b_dns_wh.setting_id = 'OFFSET_DO_NOT_SHIP_WAREHOUSE'
                AND b_dns_wh.LOCATION_ID = l.ID;


DROP VIEW V_REPORT_STUDY_LOCATION_KIT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_LOCATION_KIT
(
   ID,
   UNBL_KIT_TYPE_ID,
   DND,
   DNC_SITE,
   DNS_SITE,
   DNC_WH,
   DNS_WH
)
AS
   SELECT l.id,
          t.ID UNBL_KIT_TYPE_ID,
          NVL (b.VALUE, a.VALUE) DND,
          NVL (b_dnc.VALUE, a_dnc.VALUE) AS DNC_SITE,
          NVL (b_dns.VALUE, a_dns.VALUE) AS DNS_SITE,
          NVL (b_dnc_wh.VALUE, a_dnc_wh.VALUE) AS DNC_WH,
          NVL (b_dns_wh.VALUE, a_dns_wh.VALUE) AS DNS_WH
     FROM V_DRUG_LOCATION l
          INNER JOIN DRUG_KIT_TYPE t
             ON 1 = 1
          LEFT JOIN (SELECT s.VALUE
                       FROM setting_values s
                      WHERE     s.setting_id = 'DO_NOT_DISPENSE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) a
             ON 1 = 1
          LEFT JOIN setting_values b
             ON     b.setting_id = 'DO_NOT_DISPENSE'
                AND NVL (b.LOCATION_ID, l.ID) = l.ID
                AND b.PARAMETER_ID = t.ID
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) a_dnc
             ON 1 = 1
          LEFT JOIN setting_values b_dnc
             ON     b_dnc.setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                AND NVL (b_dnc.LOCATION_ID, l.ID) = l.ID
                AND b_dnc.PARAMETER_ID = t.ID
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL
                            AND parameter_id IS NULL) a_dns
             ON 1 = 1
          LEFT JOIN setting_values b_dns
             ON     b_dns.setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                AND NVL (b_dns.LOCATION_ID, l.ID) = l.ID
                AND b_dns.PARAMETER_ID = t.ID
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_WAREHOUSE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) a_dnc_wh
             ON 1 = 1
          LEFT JOIN setting_values b_dnc_wh
             ON     b_dnc_wh.setting_id = 'OFFSET_DO_NOT_COUNT_WAREHOUSE'
                AND NVL (b_dnc_wh.LOCATION_ID, l.ID) = l.ID
                AND b_dnc_wh.PARAMETER_ID = t.ID
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_WAREHOUSE'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) a_dns_wh
             ON 1 = 1
          LEFT JOIN setting_values b_dns_wh
             ON     b_dns_wh.setting_id = 'OFFSET_DO_NOT_SHIP_WAREHOUSE'
                AND NVL (b_dns_wh.LOCATION_ID, l.ID) = l.ID
                AND b_dns_wh.PARAMETER_ID = t.ID;


DROP VIEW V_REPORT_STUDY_LOCATION_NS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_LOCATION_NS
(
   ID,
   SCR_STATUS,
   RND_STATUS,
   SHP_STATUS
)
AS
   SELECT grp.grp_id AS ID,
          CASE
             WHEN NVL (scrsite.VALUE, scr.VALUE) IN ('1', 'True') THEN 'Open'
             ELSE 'Closed'
          END
             AS scr_status,
          CASE
             WHEN NVL (rndsite.VALUE, rnd.VALUE) IN ('1', 'True') THEN 'Open'
             ELSE 'Closed'
          END
             AS rnd_status,
          CASE
             WHEN NVL (shpsite.VALUE, shp.VALUE) IN ('1', 'True') THEN 'Open'
             ELSE 'Closed'
          END
             AS shp_status
     FROM admin_if.groups grp
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'SITE_SCR_OPEN'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) scr
             ON 1 = 1
          LEFT JOIN (SELECT setting_id, VALUE, location_id
                       FROM setting_values
                      WHERE     setting_id = 'SITE_SCR_OPEN'
                            AND location_id IS NOT NULL
                            AND parameter_id IS NULL) scrsite
             ON scrsite.location_id = grp.grp_id
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'SITE_RND_OPEN'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) rnd
             ON 1 = 1
          LEFT JOIN (SELECT setting_id, VALUE, location_id
                       FROM setting_values
                      WHERE     setting_id = 'SITE_RND_OPEN'
                            AND location_id IS NOT NULL
                            AND parameter_id IS NULL) rndsite
             ON rndsite.location_id = grp.grp_id
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'ACTIVATE_AUTOMATIC_SHIPMENT'
                            AND location_id IS NULL
                            AND parameter_id IS NULL) shp
             ON 1 = 1
          LEFT JOIN (SELECT setting_id, VALUE, location_id
                       FROM setting_values
                      WHERE     setting_id = 'ACTIVATE_AUTOMATIC_SHIPMENT'
                            AND location_id IS NOT NULL
                            AND parameter_id IS NULL) shpsite
             ON shpsite.location_id = grp.grp_id
    WHERE grp.prj_id = 'P90020903' AND grp.cat_id IN (10, 13);


DROP VIEW V_REPORT_STUDY_LOCATION_NSHIP;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_LOCATION_NSHIP
(
   ID,
   SHP_STATUS
)
AS
   SELECT V.grp_id AS ID,
          CASE
             WHEN NVL (settingsiteauto.VALUE, settingnullauto.VALUE) IN
                     ('1', 'True')
             THEN
                'Open'
             ELSE
                'Closed'
          END
             AS shp_status
     FROM admin_if.groups v
          LEFT JOIN (SELECT VALUE
                       FROM setting_values
                      WHERE     setting_id = 'ACTIVATE_AUTOMATIC_SHIPMENT'
                            AND location_id IS NULL) settingnullauto
             ON 1 = 1
          LEFT JOIN (SELECT VALUE, location_id
                       FROM setting_values
                      WHERE     setting_id = 'ACTIVATE_AUTOMATIC_SHIPMENT'
                            AND location_id IS NOT NULL) settingsiteauto
             ON settingsiteauto.location_id = v.grp_id
    WHERE v.prj_id = 'P90020903' AND cat_id IN (10, 11, 13);


DROP VIEW V_REPORT_STUDY_SHIPDETAILS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_SHIPDETAILS
(
   SHIPMENT_ID,
   SHIPMENT_TYPE,
   SHIPMENT_TRACKINGNO,
   DEVICE_ID,
   CANCEL_DATE,
   ASSESSMENT_COMMENT,
   PENDING_COMMENT,
   ASS_DATE
)
AS
     SELECT a.shipment_id,
            MAX (CASE WHEN a.name = 'SHIPMENT_TYPE' THEN a.VALUE ELSE NULL END)
               AS shipment_type,
            MAX (CASE WHEN a.name = 'TrackingNo' THEN a.VALUE ELSE NULL END)
               AS shipment_trackingno,
            MAX (CASE WHEN a.name = 'DeviceID' THEN a.VALUE ELSE NULL END)
               AS device_id,
            CASE
               WHEN s.status_id = 'ShipmentStatus_CANCELED'
               THEN
                  TO_CHAR (s.modified_at,
                           'DD-Mon-YYYY',
                           'NLS_DATE_LANGUAGE=AMERICAN')
               ELSE
                  NULL
            END
               cancel_date,
            MAX (
               CASE
                  WHEN a.name = 'ASSESSMENT_COMMENT' THEN a.VALUE
                  ELSE NULL
               END)
               AS ASSESSMENT_COMMENT,
            MAX (CASE WHEN a.name = 'Comments' THEN a.VALUE ELSE NULL END)
               AS PENDING_COMMENT,
            s.acknowledgement_date AS ass_date
       FROM    drug_shipment_attrib a
            INNER JOIN
               drug_shipment s
            ON a.shipment_id = s.id
      WHERE a.name IN
               ('SHIPMENT_TYPE',
                'TrackingNo',
                'DeviceID',
                'ASSESSMENT_COMMENT',
                'Comments')
   GROUP BY a.shipment_id,
            s.status_id,
            s.modified_at,
            s.acknowledgement_date;


DROP VIEW V_REPORT_STUDY_SHIPMENT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_SHIPMENT
(
   ID,
   DEVICE_ID,
   CANCEL_DATE
)
AS
   SELECT s.id,
          b.VALUE AS device_id,
          CASE
             WHEN S.STATUS_ID = 'ShipmentStatus_CANCELED'
             THEN
                TO_CHAR (s.modified_at,
                         'DD-Mon-YYYY',
                         'NLS_DATE_LANGUAGE=AMERICAN')
             ELSE
                NULL
          END
             AS cancel_date
     FROM    drug_shipment s
          LEFT JOIN
             drug_shipment_attrib b
          ON S.ID = B.SHIPMENT_ID AND B.NAME = 'DeviceID';


DROP VIEW V_REPORT_STUDY_SHIPMENT_ATTRIB;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_SHIPMENT_ATTRIB
(
   ID,
   NAME,
   SHIP_ASS_COMMENT,
   PENDING_COMMENT
)
AS
   SELECT "ID",
          "NAME",
          "SHIP_ASS_COMMENT",
          "PENDING_COMMENT"
     FROM (SELECT S.ID,
                  S.NAME,
                  A.NAME AS COMMENTS,
                  A.VALUE
             FROM    DRUG_SHIPMENT S
                  LEFT JOIN
                     DRUG_SHIPMENT_ATTRIB A
                  ON S.ID = A.SHIPMENT_ID
            WHERE A.NAME IN ('ASSESSMENT_COMMENT', 'Comments')) PIVOT (MIN (
                                                                          VALUE)
                                                                FOR COMMENTS
                                                                IN  ('ASSESSMENT_COMMENT' SHIP_ASS_COMMENT,
                                                                    'Comments' PENDING_COMMENT));


DROP VIEW V_REPORT_STUDY_SUMMARY;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_STUDY_SUMMARY
(
   COUNTRY,
   SITEID,
   ACTSITE,
   NAME,
   SCREENED,
   RANDOMIZED,
   DISCONTINUED,
   PRESCREENED,
   TOTALPRESCREENED,
   SCREENFAILED,
   CURSCREEN,
   CURRANDOMIZED,
   DELETED,
   CURUNBLINDED
)
AS
     SELECT cnt.long_name AS country,
            sit_id AS SITEID,
            SUM (
               CASE
                  WHEN loc.status_id = 'LocationStatus_ACTIVE' THEN 1
                  ELSE 0
               END)
               AS actSite,
            loc.name,
            SUM (totscr) AS Screened,
            SUM (totrnd) AS Randomized,
            SUM (totaldisc) AS Discontinued,
            SUM (totalprescr) AS PreScreened,
            SUM (totalcurrprescr) AS TotalPreScreened,
            SUM (totalsf) AS ScreenFailed,
            SUM (totalcurrscr) AS CurScreen,
            SUM (totalcurrrnd) AS CurRandomized,
            SUM (totaldeleted) AS Deleted,
            SUM (totalcurrunblinded) AS CurUnblinded
       FROM (  SELECT sit_id,
                      SUM (
                         CASE
                            WHEN status_descr = 'Screened' THEN COUNT
                            ELSE 0
                         END)
                         AS totscr,
                      SUM (
                         CASE
                            WHEN status_descr = 'Randomized' THEN COUNT
                            ELSE 0
                         END)
                         AS totrnd,
                      SUM (
                         CASE
                            WHEN status_descr = 'Discontinued' THEN COUNT
                            ELSE 0
                         END)
                         AS totaldisc,
                      SUM (
                         CASE
                            WHEN status_descr = 'Pre-Screened' THEN COUNT
                            ELSE 0
                         END)
                         AS totalprescr,
                      SUM (
                         CASE
                            WHEN status_descr = 'Total Currently Pre-Screened'
                            THEN
                               COUNT
                            ELSE
                               0
                         END)
                         AS totalcurrprescr,
                      SUM (
                         CASE
                            WHEN status_descr = 'Screen Failed' THEN COUNT
                            ELSE 0
                         END)
                         AS totalsf,
                      SUM (
                         CASE
                            WHEN status_descr = 'Total Currently Screened'
                            THEN
                               COUNT
                            ELSE
                               0
                         END)
                         AS totalcurrscr,
                      SUM (
                         CASE
                            WHEN status_descr = 'Total Currently Randomized'
                            THEN
                               COUNT
                            ELSE
                               0
                         END)
                         AS totalcurrrnd,
                      SUM (
                         CASE WHEN status_descr = 'Deleted' THEN COUNT ELSE 0 END)
                         AS totaldeleted,
                      SUM (
                         CASE
                            WHEN status_descr = 'Total Currently Unblinded'
                            THEN
                               COUNT
                            ELSE
                               0
                         END)
                         AS totalcurrunblinded
                 FROM    (  SELECT 'Screened' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   DAT.PAT_id,
                                   dat.FORM
                              FROM    usr_pat pat
                                   INNER JOIN
                                      data dat
                                   ON dat.pat_id = pat.pat_id
                             WHERE dat.field = 'SCR_DATE'
                          GROUP BY DAT.PAT_id, pat.sit_id, dat.FORM
                          UNION ALL
                            SELECT 'Randomized' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   DAT.PAT_id,
                                   dat.FORM
                              FROM    usr_pat pat
                                   INNER JOIN
                                      data dat
                                   ON dat.pat_id = pat.pat_id
                             WHERE dat.field = 'RND_DATE'
                          GROUP BY DAT.PAT_id, pat.sit_id, dat.FORM
                          UNION ALL
                            SELECT 'Discontinued' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   DAT.PAT_id,
                                   dat.FORM
                              FROM    data dat
                                   INNER JOIN
                                      usr_pat pat
                                   ON pat.pat_id = dat.pat_id
                             WHERE field = 'DSC_DATE'
                          GROUP BY DAT.PAT_id, pat.sit_id, dat.FORM
                          UNION ALL
                            SELECT 'Pre-Screened' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   DAT.PAT_id,
                                   dat.FORM
                              FROM    data dat
                                   INNER JOIN
                                      usr_pat pat
                                   ON pat.pat_id = dat.pat_id
                             WHERE field = 'PSCR_DATE'
                          GROUP BY DAT.PAT_id, pat.sit_id, dat.FORM
                          UNION ALL
                            SELECT 'Total Currently Pre-Screened' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   pat.PAT_id,
                                   1
                              FROM usr_pat pat
                             WHERE status = 'Pre-Screened'
                          GROUP BY pat.PAT_id, pat.sit_id
                          UNION ALL
                            SELECT 'Screen Failed' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   DAT.PAT_id,
                                   dat.FORM
                              FROM    data dat
                                   INNER JOIN
                                      usr_pat pat
                                   ON pat.pat_id = dat.pat_id
                             WHERE field = 'SCF_DATE'
                          GROUP BY DAT.PAT_id, pat.sit_id, dat.FORM
                          UNION ALL
                            SELECT 'Total Currently Screened' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   pat.PAT_id,
                                   0
                              FROM usr_pat pat
                             WHERE status = 'Screened'
                          GROUP BY pat.PAT_id, pat.sit_id
                          UNION ALL
                            SELECT 'Total Currently Randomized' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   pat.PAT_id,
                                   1
                              FROM usr_pat pat
                             WHERE status = 'Randomized'
                          GROUP BY pat.PAT_id, pat.sit_id
                          UNION ALL
                            SELECT 'Deleted' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   DAT.PAT_id,
                                   dat.FORM
                              FROM    data dat
                                   INNER JOIN
                                      usr_pat pat
                                   ON pat.pat_id = dat.pat_id
                             WHERE field = 'DEL_DATE'
                          GROUP BY DAT.PAT_id, pat.sit_id, dat.FORM
                          UNION ALL
                            SELECT 'Total Currently Unblinded' AS status_descr,
                                   1 AS COUNT,
                                   pat.sit_id,
                                   pat.PAT_id,
                                   0
                              FROM    usr_pat pat
                                   LEFT JOIN
                                      data dat
                                   ON     pat.pat_id = dat.pat_id
                                      AND dat.field = 'DSC_DATE'
                             WHERE     pat.WITHDRAWN_DATE IS NOT NULL
                                   AND dat.VALUE IS NULL
                          GROUP BY pat.PAT_id, pat.sit_id, dat.FORM) a
                      INNER JOIN
                         v_drug_location locat
                      ON locat.id = a.sit_id
                WHERE locat.subclass IN ('Site')
             GROUP BY sit_id) subq
            INNER JOIN v_drug_location loc
               ON loc.id = subq.sit_id
            INNER JOIN v_drug_country cnt
               ON CNT.ID = loc.country_id
   GROUP BY cnt.long_name, loc.name, sit_id;


DROP VIEW V_REPORT_SUBJ_TOTAL_VISITS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_SUBJ_TOTAL_VISITS
(
   PAT_ID,
   SCR_NO,
   PAT_NO,
   FORM,
   PAGE,
   VISIT_ID,
   VISIT_DATE,
   OUT_OF_WINDOW,
   VISIT_SEQ_NO,
   VISIT_DATE_TYPE,
   DESCR,
   SCHEDULE_ID
)
AS
   SELECT vd.pat_id,
          '' AS SCR_NO,
          0 AS PAT_NO,
          FORM,
          PAGE,
          vd.visit_id,
          vd.visit_date,
          CASE
             WHEN (   (vd.VISIT_ID LIKE 'U%')
                   OR (vd.visit_id IN ('DSC', 'SCF', 'DEL')))
             THEN
                'N/A'
             ELSE
                CASE WHEN vc.VALUE IS NULL THEN 'No' ELSE VC.VALUE END
          END
             OUT_OF_WINDOW,
          0 AS VISIT_SEQ_NO,
          '' AS VISIT_DATE_TYPE,
          vd.name AS descr,
          '' AS SCHEDULE_ID
     FROM    (SELECT pat_id,
                     visit_id,
                     CASE
                        WHEN     visday IS NOT NULL
                             AND vismon IS NOT NULL
                             AND visyea IS NOT NULL
                        THEN
                           TO_DATE (visday || '/' || vismon || '/' || visyea,
                                    'DD.MM.YYYY')
                        ELSE
                           NULL
                     END
                        AS visit_date,
                     name,
                     FORM,
                     PAGE
                FROM (  SELECT d.pat_id,
                               d.Form,
                               d.page,
                               info.visit_id,
                               info.name,
                               MAX (
                                  CASE
                                     WHEN d.field IN
                                             ('VISDAY',
                                              'SCFVISDAY',
                                              'DSCVISDAY',
                                              'DELVISDAY')
                                     THEN
                                        d.VALUE
                                     ELSE
                                        NULL
                                  END)
                                  AS visday,
                               MAX (
                                  CASE
                                     WHEN d.field IN
                                             ('VISMON',
                                              'SCFVISMON',
                                              'DSCVISMON',
                                              'DELVISMON')
                                     THEN
                                        d.VALUE
                                     ELSE
                                        NULL
                                  END)
                                  AS vismon,
                               MAX (
                                  CASE
                                     WHEN d.field IN
                                             ('VISYEA',
                                              'SCFVISYEA',
                                              'DSCVISYEA',
                                              'DELVISYEA')
                                     THEN
                                        d.VALUE
                                     ELSE
                                        NULL
                                  END)
                                  AS visyea
                          FROM data d, data d2, visit_info info
                         WHERE     d.pat_id = d2.pat_id
                               AND d.FORM = d2.FORm
                               AND d.page = d2.page
                               AND info.FORM = d2.FORM
                               AND info.instance = d2.PAGE
                               AND d.FIELD IN
                                      ('VISDAY',
                                       'VISMON',
                                       'VISYEA',
                                       'SCFVISYEA',
                                       'SCFVISDAY',
                                       'SCFVISMON',
                                       'DSCVISYEA',
                                       'DSCVISMON',
                                       'DSCVISDAY',
                                       'DELVISYEA',
                                       'DELVISMON',
                                       'DELVISDAY')
                               AND d2.FIELD IN
                                      ('PSCR_DATE',
                                       'SCR_DATE',
                                       'SCF_DATE',
                                       'DSC_DATE',
                                       'RND_DATE',
                                       'RSP_DATE',
                                       'DEL_DATE')
                      GROUP BY d.pat_id,
                               d.Form,
                               D.page,
                               info.visit_id,
                               info.name)) vd
          LEFT JOIN
             (SELECT DT.PAT_ID,
                     CASE WHEN VALUE = 1 THEN 'Yes' END AS VALUE,
                     INFO.VISIT_ID
                FROM    DATA DT
                     LEFT JOIN
                        VISIT_INFO INFO
                     ON INFO.FORM = DT.FORM AND INFO.INSTANCE = DT.PAGE
               WHERE INFO.FORM IN (3, 5) AND DT.FIELD = 'OUT_WINDOW') VC
          ON vd.PAT_ID = vc.PAT_ID AND vc.VISIT_ID = vd.VISIT_ID;


DROP VIEW V_REPORT_TOTAL_VISITS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_TOTAL_VISITS
(
   ID,
   PAT_ID,
   VISIT_ID,
   VISIT_DATE,
   EARLIEST_VISIT_DATE,
   LATEST_VISIT_DATE,
   VISIT_SEQ_NO,
   VISIT_DATE_TYPE,
   DESCR,
   NAME,
   SCHEDULE_ID
)
AS
   SELECT v.pat_id || '#' || v.visit_id AS id,
          v.pat_id,
          v.visit_id,
          v.visit AS visit_date,
          CASE
             WHEN vs.EARLIEST_VISIT_DATE IS NOT NULL THEN EARLIEST_VISIT_DATE
             ELSE v.visit
          END
             AS EARLIEST_VISIT_DATE,
          CASE
             WHEN vs.latest_visit_date IS NOT NULL THEN latest_visit_date
             ELSE v.visit
          END
             AS latest_visit_date,
          CASE
             WHEN V.visit_id IN ('SCF', 'DEL', 'DSC')
             THEN
                v.FORM * 1000 + V.page
             WHEN v.visit_id LIKE '%U%'
             THEN
                    (     SUBSTR (v.visit_id, LENGTH (v.visit_id) - 4, 2)
                       || SUBSTR (v.visit_id, LENGTH (v.visit_id) - 1, 2)
                     + 1)
                  * 100
                + SUBSTR (v.visit_id, 2, 1)
             WHEN v.visit_id LIKE 'AC%' OR v.visit_id LIKE 'BC%'
             THEN
                  (     SUBSTR (v.visit_id, LENGTH (v.visit_id) - 4, 2)
                     || SUBSTR (v.visit_id, LENGTH (v.visit_id) - 1, 2)
                   + 1)
                * 100
             ELSE
                VS.VISIT_SEQ_NO
          END
             AS VISIT_SEQ_NO,
          'DONE' AS visit_Date_type,
          VI.NAME AS DESCR,
          VI.NAME AS name,
          S.SCHEDULE_ID
     FROM V_REPORT_VS2_VISITS v
          INNER JOIN V_PAT_SCHEDULE_IMPL s
             ON v.PAT_ID = s.PAT_ID
          LEFT JOIN V_DYNAMIC_VISIT_SCHEDULE vs
             ON v.pat_id = vs.pat_id AND v.visit_id = vs.visit_id
          LEFT JOIN VISIT_INFO vi
             ON v.visit_id = VI.visit_id AND vi.SCHEDULE_ID = s.SCHEDULE_ID;


DROP VIEW V_REPORT_USITE_INVRPT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_USITE_INVRPT
(
   "Site Number",
   MAIN_WORKER,
   "Supplying Warehouse",
   "Country",
   ID,
   "Drug Quarantined",
   "Drug In Transit",
   "Drug Damaged",
   "Drug Missing/Lost",
   "Drug Dispensed",
   "Drug Expired",
   "Drug Received",
   LOT,
   EXPIRATION_DATE,
   DO_NO_DISPENSE,
   DO_NO_COUNT_SITE,
   INITIAL_VALUE,
   MAX_VALUE,
   MIN_VALUE,
   DO_NO_SHIP,
   UK_TYPE,
   BK_TYPE
)
AS
     SELECT grp.name AS "Site Number",
            grp.main_worker AS MAIN_WORKER,
            grpWh.name AS "Supplying Warehouse",
            cntry.LONG_NAME AS "Country",
            TO_CHAR (grp.grp_id) AS ID,
            SUM (
               CASE
                  WHEN (    kt.status_id NOT IN
                               ('KitStatus_EXPIRED', 'KitStatus_EXPIRING_SOON')
                        AND kt.quarantined = 1)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug Quarantined",
            SUM (
               CASE
                  WHEN (kt.status_id = 'KitStatus_SENT' AND kt.quarantined = 0)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug In Transit",
            SUM (
               CASE WHEN (kt.status_id = 'KitStatus_DAMAGED') THEN 1 ELSE 0 END)
               AS "Drug Damaged",
            SUM (
               CASE
                  WHEN (kt.status_id = 'KitStatus_UNAVAILABLE') THEN 1
                  ELSE 0
               END)
               AS "Drug Missing/Lost",
            SUM (
               CASE
                  WHEN (kt.status_id = 'KitStatus_DISPENSED') THEN 1
                  ELSE 0
               END)
               AS "Drug Dispensed",
            SUM (
               CASE
                  WHEN (kt.status_id IN
                           ('KitStatus_EXPIRED', 'KitStatus_EXPIRING_SOON'))
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug Expired",
            SUM (
               CASE
                  WHEN (    kt.status_id = 'KitStatus_RECEIVED'
                        AND kt.quarantined = 0)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug Received",
            b.name AS LOT,
            kt.expiration_date AS EXPIRATION_DATE,
              kt.expiration_date
            - NVL (
                 settingbothdnd.VALUE,
                 NVL (settingsitednd.VALUE,
                      NVL (settingparamdnd.VALUE, settingnulldnd.VALUE)))
               AS DO_NO_DISPENSE,
              kt.expiration_date
            - NVL (
                 settingbothdnc.VALUE,
                 NVL (settingsitednc.VALUE,
                      NVL (settingparamdnc.VALUE, settingnulldnc.VALUE)))
               AS DO_NO_COUNT_SITE,
            conf.INITIAL_VALUE AS INITIAL_VALUE,
            conf.MAX_VALUE AS MAX_VALUE,
            conf.MIN_VALUE AS MIN_VALUE,
              kt.expiration_date
            - NVL (
                 settingbothdns.VALUE,
                 NVL (settingsitedns.VALUE,
                      NVL (settingparamdns.VALUE, settingnulldns.VALUE)))
               AS DO_NO_SHIP,
            typ1.description AS UK_TYPE,
            typ1.name AS BK_TYPE
       FROM admin_if.groups grp
            LEFT JOIN V_DRUG_COUNTRY cntry
               ON (grp.country_id = cntry.ID)
            LEFT JOIN DRUG_KIT kt
               ON grp.grp_ID = kt.LOCATION_ID
            INNER JOIN drug_kit_type typ
               ON kt.KIT_TYPE_ID = typ.ID
            INNER JOIN drug_kit_type typ1
               ON kt.UNBL_KIT_TYPE_ID = typ1.ID
            LEFT JOIN v_drug_location_relation rel
               ON rel.to_location_id = kt.location_id
            LEFT JOIN adm_icrf3.groups grpWh
               ON grpwh.grp_id = rel.from_location_id
            LEFT JOIN drug_batch b
               ON kt.BATCH_ID = b.id
            LEFT JOIN (SELECT VALUE
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                              AND location_id IS NULL
                              AND parameter_id IS NULL) settingnulldns
               ON 1 = 1
            LEFT JOIN (SELECT VALUE, location_id
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                              AND location_id IS NOT NULL
                              AND parameter_id IS NULL) settingsitedns
               ON settingsitedns.location_id = grp.grp_id
            LEFT JOIN (SELECT VALUE, parameter_id
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                              AND location_id IS NULL
                              AND parameter_id IS NOT NULL) settingparamdns
               ON settingparamdns.parameter_id = typ.id
            LEFT JOIN (SELECT VALUE, location_id, parameter_id
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_SITE'
                              AND location_id IS NOT NULL
                              AND parameter_id IS NOT NULL) settingbothdns
               ON     settingbothdns.location_id = grp.grp_id
                  AND settingbothdns.parameter_id = typ.id
            LEFT JOIN (SELECT VALUE
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                              AND location_id IS NULL
                              AND parameter_id IS NULL) settingnulldnc
               ON 1 = 1
            LEFT JOIN (SELECT VALUE, location_id
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                              AND location_id IS NOT NULL
                              AND parameter_id IS NULL) settingsitednc
               ON settingsitednc.location_id = grp.grp_id
            LEFT JOIN (SELECT VALUE, parameter_id
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                              AND location_id IS NULL
                              AND parameter_id IS NOT NULL) settingparamdnc
               ON settingparamdnc.parameter_id = typ.id
            LEFT JOIN (SELECT VALUE, location_id, parameter_id
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_SITE'
                              AND location_id IS NOT NULL
                              AND parameter_id IS NOT NULL) settingbothdnc
               ON     settingbothdnc.location_id = grp.grp_id
                  AND settingbothdnc.parameter_id = typ.id
            LEFT JOIN (SELECT VALUE
                         FROM setting_values
                        WHERE     setting_id = 'DO_NOT_DISPENSE'
                              AND location_id IS NULL
                              AND parameter_id IS NULL) settingnulldnd
               ON 1 = 1
            LEFT JOIN (SELECT VALUE, location_id
                         FROM setting_values
                        WHERE     setting_id = 'DO_NOT_DISPENSE'
                              AND location_id IS NOT NULL
                              AND parameter_id IS NULL) settingsitednd
               ON settingsitednd.location_id = grp.grp_id
            LEFT JOIN (SELECT VALUE, parameter_id
                         FROM setting_values
                        WHERE     setting_id = 'DO_NOT_DISPENSE'
                              AND location_id IS NULL
                              AND parameter_id IS NOT NULL) settingparamdnd
               ON settingparamdnd.parameter_id = typ.id
            LEFT JOIN (SELECT VALUE, location_id, parameter_id
                         FROM setting_values
                        WHERE     setting_id = 'DO_NOT_DISPENSE'
                              AND location_id IS NOT NULL
                              AND parameter_id IS NOT NULL) settingbothdnd
               ON     settingbothdnd.location_id = grp.grp_id
                  AND settingbothdnd.parameter_id = typ.id
            LEFT JOIN DRUG_LOCATION loc
               ON loc.id = grp.grp_id
            LEFT JOIN DRUG_SUPPLY_CONF conf
               ON     conf.ENROLMENT_LEVEL_ID = typ1.ENROLMENT_LEVEL_ID
                  AND conf.ENROLMENT_CATEGORY_ID = loc.ENROLMENT_CATEGORY_ID
      WHERE grp.cat_id IN (10, 13) AND grp.prj_id = 'P90020903'
   GROUP BY grp.name,
            grp.main_worker,
            grpWh.name,
            cntry.LONG_NAME,
            grp.grp_id,
            b.name,
            kt.expiration_date,
            conf.INITIAL_VALUE,
            conf.MIN_VALUE,
            conf.MAX_VALUE,
            typ1.name,
            typ1.description,
            settingnulldnd.VALUE,
            settingparamdnd.VALUE,
            settingsitednd.VALUE,
            settingbothdnd.VALUE,
            settingnulldnc.VALUE,
            settingparamdnc.VALUE,
            settingsitednc.VALUE,
            settingbothdnc.VALUE,
            settingnulldns.VALUE,
            settingparamdns.VALUE,
            settingsitedns.VALUE,
            settingbothdns.VALUE
   ORDER BY grp.name;


DROP VIEW V_REPORT_UWHINVRPT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_UWHINVRPT
(
   ID,
   "Country",
   "Drug Quarantined",
   "Pending Receipt at Depot",
   "Drug Damaged",
   "Drug Missing/Lost",
   "Drug Expired",
   "Drug Available",
   "Warehouse",
   EXPIRATION_DATE,
   DND,
   UK_DESC,
   MANUFACTURING_LOT,
   BK_DESC,
   DNC,
   DNS,
   "Drug In Transit Sub-Warehouse",
   "Drug In Transit to Center"
)
AS
     SELECT loc.grp_id AS ID,
            country.LONG_NAME AS "Country",
            SUM (
               CASE
                  WHEN (    a.status_id NOT IN
                               ('KitStatus_EXPIRED', 'KitStatus_EXPIRING_SOON')
                        AND a.quarantined = 1
                        AND a.location_id = loc.grp_id)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug Quarantined",
            SUM (
               CASE
                  WHEN (    a.status_id = 'KitStatus_SENT'
                        AND a.quarantined = 0
                        AND a.location_id = loc.grp_id)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Pending Receipt at Depot",
            SUM (
               CASE
                  WHEN     (a.status_id = 'KitStatus_DAMAGED')
                       AND a.location_id = loc.grp_id
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug Damaged",
            SUM (
               CASE
                  WHEN (    a.status_id = 'KitStatus_UNAVAILABLE'
                        AND a.location_id = loc.grp_id)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug Missing/Lost",
            SUM (
               CASE
                  WHEN (    a.status_id IN
                               ('KitStatus_EXPIRED', 'KitStatus_EXPIRING_SOON')
                        AND a.location_id = loc.grp_id)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug Expired",
            SUM (
               CASE
                  WHEN (    a.status_id = 'KitStatus_ONSTOCK'
                        AND a.quarantined = 0
                        AND a.location_id = loc.grp_id)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug Available",
            loc.name AS "Warehouse",
            a.expiration_date AS EXPIRATION_DATE,
            CASE
               WHEN settingsitednd.VALUE IS NULL
               THEN
                  a.expiration_date - settingdndnull.VALUE
               ELSE
                  a.expiration_date - settingsitednd.VALUE
            END
               AS DND,
            a.description AS UK_DESC,
            a.batchname AS MANUFACTURING_LOT,
            a.name AS BK_DESC,
            CASE
               WHEN settingsitednc.VALUE IS NULL
               THEN
                  a.expiration_date - settingdncnull.VALUE
               ELSE
                  a.expiration_date - settingsitednc.VALUE
            END
               AS dnc,
            CASE
               WHEN settingsitedns.VALUE IS NULL
               THEN
                  a.expiration_date - settingdnsnull.VALUE
               ELSE
                  a.expiration_date - settingsitedns.VALUE
            END
               AS dns,
            SUM (
               CASE
                  WHEN (    a.status_id = 'KitStatus_SENT'
                        AND a.quarantined = 0
                        AND a.cat_id IN (11)
                        AND a.from_location_id = loc.grp_id)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug In Transit Sub-Warehouse",
            SUM (
               CASE
                  WHEN (    a.status_id = 'KitStatus_SENT'
                        AND a.quarantined = 0
                        AND a.cat_id IN (10, 13)
                        AND a.from_location_id = loc.grp_id)
                  THEN
                     1
                  ELSE
                     0
               END)
               AS "Drug In Transit to Center"
       FROM admin_if.groups loc
            LEFT JOIN v_drug_country country
               ON country.id = loc.country_id
            LEFT JOIN (SELECT dk.name,
                              dk.description,
                              dk.id,
                              batch.name AS batchname,
                              kit.expiration_date AS expiration_date,
                              kit.unbl_kit_type_id,
                              kit.kit_type_id,
                              ship.from_location_id AS from_location_id,
                              kit.status_id,
                              kit.quarantined,
                              toloc.cat_id,
                              kit.location_id location_id,
                              batch.BLOCKED
                         FROM drug_kit kit
                              INNER JOIN drug_kit_type dk
                                 ON dk.ID = kit.unbl_kit_type_id
                              LEFT JOIN drug_batch batch
                                 ON batch.id = kit.batch_id
                              LEFT JOIN drug_SHipment ship
                                 ON ship.id = kit.shipment_id
                              LEFT JOIN adm_icrf3.groups toloc
                                 ON ship.to_location_id = toloc.grp_id) a
               ON (   a.location_id = loc.grp_id
                   OR loc.grp_id = a.from_location_id)
            LEFT JOIN (SELECT VALUE
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_WAREHOUSE'
                              AND location_id IS NULL
                              AND parameter_id IS NULL) settingdnsnull
               ON 1 = 1
            LEFT JOIN (SELECT VALUE, parameter_id, LOCATION_ID
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_SHIP_WAREHOUSE'
                              AND location_id IS NULL
                              AND parameter_id IS NOT NULL) settingsitedns
               ON settingsitedns.parameter_id = a.id
            LEFT JOIN (SELECT VALUE
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_WAREHOUSE'
                              AND location_id IS NULL
                              AND parameter_id IS NULL) settingdncnull
               ON 1 = 1
            LEFT JOIN (SELECT VALUE, parameter_id, LOCATION_ID
                         FROM setting_values
                        WHERE     setting_id = 'OFFSET_DO_NOT_COUNT_WAREHOUSE'
                              AND location_id IS NULL
                              AND parameter_id IS NOT NULL) settingsitednc
               ON settingsitednc.parameter_id = a.id
            LEFT JOIN (SELECT VALUE
                         FROM setting_values
                        WHERE     setting_id = 'DO_NOT_DISPENSE'
                              AND location_id IS NULL
                              AND parameter_id IS NULL) settingdndnull
               ON 1 = 1
            LEFT JOIN (SELECT VALUE, parameter_id, LOCATION_ID
                         FROM setting_values
                        WHERE     setting_id = 'DO_NOT_DISPENSE'
                              AND location_id IS NULL
                              AND parameter_id IS NOT NULL) settingsitednd
               ON settingsitednd.parameter_id = a.id
      WHERE loc.cat_id = 11 AND loc.prj_id = 'P90020903'
   GROUP BY loc.grp_id,
            country.LONG_NAME,
            loc.name,
            a.name,
            a.expiration_date,
            a.description,
            a.batchname,
            settingsitednd.VALUE,
            settingdndnull.VALUE,
            settingsitednc.VALUE,
            settingdncnull.VALUE,
            settingsitedns.VALUE,
            settingdnsnull.VALUE;


DROP VIEW V_REPORT_VIS_DETAILS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_VIS_DETAILS
(
   PAT_ID,
   VISIT_ID,
   OUT_OF_WINDOW,
   DESCR,
   VISIT_DATE
)
AS
   SELECT PAT_ID,
          VISIT_ID,
          OUT_OF_WINDOW,
          DESCR,
          VISIT_DATE
     FROM V_REPORT_SUBJ_TOTAL_VISITS;


DROP VIEW V_REPORT_VS2_VISITS;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_VS2_VISITS
(
   PAT_ID,
   SCR_NO,
   PAT_NO,
   FORM,
   PAGE,
   VISIT_ID,
   VISIT
)
AS
   SELECT a.pat_id,
          a.scr_no,
          a.pat_no,
          a.FORM,
          a.Page,
          a.visit_id,
          CASE
             WHEN a.visit_id IN ('SCF') THEN scfdate
             WHEN a.visit_id = 'DSC' THEN DSCDATE
             ELSE a.visit
          END
             AS visit
     FROM    (  SELECT u.PAT_ID,
                       u.SCR_NO,
                       u.PAT_NO,
                       d.FORM,
                       d.PAGE,
                       vs.visit_id,
                       (CASE
                           WHEN     MAX (
                                       CASE
                                          WHEN d.field = 'VISDAY'
                                          THEN
                                             d.VALUE
                                          WHEN d.field = 'DELVISDAY'
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       IS NOT NULL
                                AND MAX (
                                       CASE
                                          WHEN d.field = 'VISMON'
                                          THEN
                                             d.VALUE
                                          WHEN d.field = 'DELVISMON'
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       IS NOT NULL
                                AND MAX (
                                       CASE
                                          WHEN d.field = 'VISYEA'
                                          THEN
                                             d.VALUE
                                          WHEN d.field = 'DELVISYEA'
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                       IS NOT NULL
                           THEN
                              TO_DATE (
                                    MAX (
                                       CASE
                                          WHEN d.field = 'VISDAY'
                                          THEN
                                             d.VALUE
                                          WHEN d.field = 'DELVISDAY'
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                 || '.'
                                 || MAX (
                                       CASE
                                          WHEN d.field = 'VISMON'
                                          THEN
                                             d.VALUE
                                          WHEN d.field = 'DELVISMON'
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END)
                                 || '.'
                                 || MAX (
                                       CASE
                                          WHEN d.field = 'VISYEA'
                                          THEN
                                             d.VALUE
                                          WHEN d.field = 'DELVISYEA'
                                          THEN
                                             d.VALUE
                                          ELSE
                                             NULL
                                       END),
                                 'dd.MM.yyyy')
                           ELSE
                              NULL
                        END)
                          "VISIT"
                  FROM DATA d,
                       USR_PAT u,
                       visit_info vs,
                       data dat1
                 WHERE     d.PAT_ID = u.PAT_ID
                       AND D.FORM = vs.FORM
                       AND d.page = VS.INSTANCE
                       AND d.pat_id = dat1.pat_id
                       AND d.FORM = dat1.FORM
                       AND D.PAGE = dat1.page
                       AND dat1.field IN
                              ('PSCR_DATE',
                               'SCR_DATE',
                               'RND_DATE',
                               'RSP_DATE',
                               'DSC_DATE',
                               'SCF_DATE',
                               'DEL_DATE')
              GROUP BY u.PAT_ID,
                       u.SCR_NO,
                       u.PAT_NO,
                       d.FORM,
                       d.PAGE,
                       VS.VISIT_ID) a
          INNER JOIN
             V_REPORT_STANDARD_PATTRIB p
          ON a.pat_id = p.pat_id;


DROP VIEW V_REPORT_WH_RECEIPT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_WH_RECEIPT
(
   ID,
   PENDING_RECEIPT,
   KIT_TYPE_ID,
   EXPIRATION_DATE,
   BATCH_ID
)
AS
     SELECT l.id AS ID,
            SUM (
               CASE
                  WHEN (    (KTW.STATUS_ID = 'KitStatus_SENT')
                        AND ktw."QUARANTINED" = 0)
                  THEN
                     (1)
                  ELSE
                     (0)
               END)
               AS PENDING_RECEIPT,
            kt.id AS KIT_TYPE_ID,
            ktw.EXPIRATION_DATE,
            b.id AS BATCH_ID
       FROM "P90020903"."V_DRUG_LOCATION" l
            INNER JOIN drug_kit ktw
               ON KTW.location_id = l.id
            INNER JOIN drug_kit_type kt
               ON ktw.UNBL_KIT_TYPE_ID = KT.ID
            LEFT JOIN drug_batch b
               ON ktw.BATCH_ID = b.id
      WHERE l.subclass = 'Warehouse'
   GROUP BY l.id,
            ktw.EXPIRATION_DATE,
            kt.id,
            b.id;


DROP VIEW V_REPORT_WH_TO_SITEWH;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_REPORT_WH_TO_SITEWH
(
   ID,
   WAREHOUSE,
   COUNTRY,
   DRUG_IN_TRANSIT_SITE,
   DRUG_IN_TRANSIT_WH,
   KIT_TYPE_ID,
   EXPIRATION_DATE,
   BATCH_ID,
   UK_DESC,
   BK_DESC,
   MANUFACTURING_LOT,
   DND,
   DNC,
   DNS
)
AS
     SELECT l.id AS ID,
            l.name AS warehouse,
            c.long_name AS country,
            SUM (
               CASE
                  WHEN     (    (KTW.STATUS_ID = 'KitStatus_SENT')
                            AND ktw."QUARANTINED" = 0)
                       AND DL.SUBCLASS IN ('Site', 'CentralPharmacy')
                  THEN
                     (1)
                  ELSE
                     (0)
               END)
               AS Drug_in_Transit_Site,
            SUM (
               CASE
                  WHEN     (    (KTW.STATUS_ID = 'KitStatus_SENT')
                            AND ktw."QUARANTINED" = 0)
                       AND DL.SUBCLASS IN ('Warehouse')
                  THEN
                     (1)
                  ELSE
                     (0)
               END)
               AS Drug_in_Transit_WH,
            kt.id AS KIT_TYPE_ID,
            ktw.EXPIRATION_DATE,
            b.id AS BATCH_ID,
            KT.DESCRIPTION AS UK_DESC,
            kt.name AS BK_DESC,
            b.name AS MANUFACTURING_LOT,
            (ktw.EXPIRATION_DATE - sl.dnd) AS DND,
            ktw.EXPIRATION_DATE - sl.dnc_site AS DNC,
            ktw.EXPIRATION_DATE - sl.dns_site AS DNS
       FROM (SELECT *
               FROM v_DRUG_LOCATION
              WHERE subclass = 'Warehouse') l
            INNER JOIN v_drug_country c
               ON l.COUNTRY_ID = c.id
            INNER JOIN drug_shipment s
               ON S.FROM_LOCATION_ID = l.ID
            INNER JOIN drug_kit ktw
               ON KTW.SHIPMENT_ID = s.id
            INNER JOIN v_drug_location dl
               ON DL.ID = KTW.LOCATION_ID
            INNER JOIN drug_kit_type kt
               ON ktw.UNBL_KIT_TYPE_ID = KT.ID
            LEFT JOIN drug_batch b
               ON ktw.BATCH_ID = b.id
            LEFT JOIN V_REPORT_STUDY_LOCATION_KIT sl
               ON ktw.LOCATION_ID = sl.id AND kt.ID = sl.UNBL_KIT_TYPE_ID
   GROUP BY l.id,
            ktw.EXPIRATION_DATE,
            kt.id,
            l.name,
            c.long_name,
            kt.description,
            kt.name,
            b.name,
            ktw.EXPIRATION_DATE - sl.dnd,
            ktw.EXPIRATION_DATE - sl.dnc_site,
            ktw.EXPIRATION_DATE - sl.dns_site,
            b.id;


DROP VIEW V_RND_CNTRY_CAP_APR;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_RND_CNTRY_CAP_APR
(
   COUNTRY_ID,
   CAP,
   PERCENTAGE
)
AS
   SELECT COUNTRY_ID,
          cntry_site_settingval (COUNTRY_ID, 'CNTRY_RND_CAP', 'COUNTRY')
             AS CAP,
          PERCENTAGE
     FROM (SELECT a.COUNTRY_ID, PERCENTAGE
             FROM (  SELECT loc.Country_id,
                            cntry_site_settingval (loc.country_id,
                                                   'APP_CNTRY_RND_CAP',
                                                   'COUNTRY')
                               AS PERCENTAGE
                       FROM    usr_pat u
                            JOIN
                               v_drug_location loc
                            ON loc.id = u.sit_id
                   GROUP BY loc.Country_id) a);


DROP VIEW V_RND_COUNT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_RND_COUNT
(
   COUNTRY_ID,
   SITE_ID,
   SITE_CNT
)
AS
     SELECT loc.country_id,
            loc.id AS site_id,
            COUNT (DISTINCT usr.pat_id) site_cnt
       FROM usr_pat usr
            INNER JOIN v_drug_location loc
               ON loc.id = usr.sit_id
            INNER JOIN data d
               ON d.pat_id = usr.pat_id
            INNER JOIN pstat_vis v
               ON v.FIELD = d.FIELD
      WHERE v.VISIT_ID = 'RND'
   GROUP BY loc.country_id, loc.id;


DROP VIEW V_RND_PROJ_CAP_APR;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_RND_PROJ_CAP_APR
(
   CAP,
   PERCENTAGE
)
AS
   SELECT (SELECT VALUE AS value1
             FROM SETTING_VALUES
            WHERE Setting_id = 'PRJ_RND_CAP')
             AS cap,
          (SELECT VALUE
             FROM SETTING_VALUES
            WHERE Setting_id = 'APP_PRJ_RND_CAP')
             PERCENTAGE
     FROM DUAL;


DROP VIEW V_RND_SITE_CAP_APR;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_RND_SITE_CAP_APR
(
   LOC_ID,
   CAP,
   PERCENTAGE
)
AS
   SELECT ID AS LOC_ID,
          cntry_site_settingval (id, 'SITE_RND_CAP', 'SITE') AS CAP,
          PERCENTAGE
     FROM (SELECT a.id, PERCENTAGE
             FROM (  SELECT loc.id,
                            cntry_site_settingval (loc.id,
                                                   'APP_SITE_RND_CAP',
                                                   'SITE')
                               AS PERCENTAGE
                       FROM    usr_pat u
                            JOIN
                               v_drug_location loc
                            ON loc.id = u.sit_id
                   GROUP BY loc.id) a);


DROP VIEW V_ROLE_REPORTING;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_ROLE_REPORTING
(
   ID,
   DESCR,
   HAS_REPORTING_PERMISSION
)
AS
     SELECT rpl.ROL_ID AS ID,
            r.DESCR,
            MAX (
               CASE
                  WHEN rpl.PRM_ID IN
                          ('RC_JR_ADHOC', 'RC_JR_REPORTS', 'RC_VIEW_JRSERVER')
                  THEN
                     1
                  ELSE
                     0
               END)
               AS HAS_REPORTING_PERMISSION
       FROM adm_icrf4_if.roleprmlist rpl, adm_icrf4_if.roles r
      WHERE rpl.ROL_ID = r.ROL_ID AND R.PRJ_ID = 'P90020903'
   GROUP BY rpl.ROL_ID, r.DESCR
   ORDER BY rpl.ROL_ID;


DROP VIEW V_SCHEDULE_DISPLAY;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SCHEDULE_DISPLAY
(
   PAT_ID,
   NAME,
   DESCR,
   MIN_SOFT,
   MAX_SOFT,
   MIN_HARD,
   MAX_HARD
)
AS
   SELECT patwindow.pat_id,
          info.name,
          info.descr,
          patwindow.MIN_SOFT,
          patwindow.MAX_SOFT,
          patwindow.MIN_HARD,
          patwindow.MAX_HARD
     FROM V_PAT_VISIT_WINDOW patwindow
          INNER JOIN VISIT_INFO info
             ON info.visit_id = patwindow.visit_id
          INNER JOIN V_PAT_SCHEDULE_IMPL i
             ON     patwindow.PAT_ID = i.PAT_ID
                AND i.SCHEDULE_ID = info.SCHEDULE_ID;


DROP VIEW V_SCHED_UNSCHDED_REL;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SCHED_UNSCHDED_REL
(
   VISIT_ID,
   UNSCHED1,
   UNSCHED2,
   SCHEDORDER,
   UNSCHED1ORDER,
   UNSCHED2ORDER
)
AS
   SELECT VISIT_ID,
          'U1' || VISIT_ID AS UNSCHED1,
          'U2' || VISIT_ID AS UNSCHED2,
          LPAD (FORM, 2, '0') || LPAD (INSTANCE, 2, '0') || '0' AS SCHEDORDER,
          TO_NUMBER (LPAD (FORM, 2, '0') || LPAD (INSTANCE, 2, '0') || '1')
             AS UNSCHED1ORDER,
          TO_NUMBER (LPAD (FORM, 2, '0') || LPAD (INSTANCE, 2, '0') || '2')
             AS UNSCHED2ORDER
     FROM VISIT_INFO
    WHERE FORM = 3
   UNION
   SELECT VISIT_ID,
          'U1' || VISIT_ID AS UNSCHED1,
          'U2' || VISIT_ID AS UNSCHED2,
          LPAD (FORM, 2, '0') || LPAD (INSTANCE, 2, '0') || '0' AS SCHEDORDER,
          TO_NUMBER (LPAD (FORM, 2, '0') || LPAD (INSTANCE, 2, '0') || '1')
             AS UNSCHED1ORDER,
          TO_NUMBER (LPAD (FORM, 2, '0') || LPAD (INSTANCE, 2, '0') || '2')
             AS UNSCHED2ORDER
     FROM VISIT_INFO
    WHERE FORM = 5;


DROP VIEW V_SCHED_UNSCHED_SEQ;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SCHED_UNSCHED_SEQ
(
   VISIT_ID,
   FORM,
   INSTANCE,
   VISITSEQUENCE
)
AS
   SELECT VISIT_ID,
          FORM,
          INSTANCE,
          SEQ VISITSEQUENCE
     FROM V_DISPVISIT_SEQ;


DROP VIEW V_SCR_CNTRY_CAP_APR;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SCR_CNTRY_CAP_APR
(
   COUNTRY_ID,
   CAP,
   PERCENTAGE
)
AS
   SELECT COUNTRY_ID,
          cntry_site_settingval (COUNTRY_ID, 'CNTRY_SCR_CAP', 'COUNTRY')
             AS CAP,
          PERCENTAGE
     FROM (SELECT a.COUNTRY_ID, PERCENTAGE
             FROM (  SELECT loc.Country_id,
                            cntry_site_settingval (loc.country_id,
                                                   'APP_CNTRY_SCR_CAP',
                                                   'COUNTRY')
                               AS PERCENTAGE
                       FROM    usr_pat u
                            JOIN
                               v_drug_location loc
                            ON loc.id = u.sit_id
                   GROUP BY loc.Country_id) a);


DROP VIEW V_SCR_COUNT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SCR_COUNT
(
   COUNTRY_ID,
   SITE_ID,
   SITE_CNT
)
AS
     SELECT loc.country_id,
            loc.id AS site_id,
            COUNT (DISTINCT usr.pat_id) site_cnt
       FROM usr_pat usr
            INNER JOIN v_drug_location loc
               ON loc.id = usr.sit_id
            INNER JOIN data d
               ON d.pat_id = usr.pat_id
            INNER JOIN pstat_vis v
               ON v.FIELD = d.FIELD
      WHERE v.VISIT_ID = 'SCR'
   GROUP BY loc.country_id, loc.id;


DROP VIEW V_SCR_PROJ_CAP_APR;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SCR_PROJ_CAP_APR
(
   CAP,
   PERCENTAGE
)
AS
   SELECT (SELECT VALUE AS value1
             FROM SETTING_VALUES
            WHERE Setting_id = 'PRJ_SCR_CAP')
             AS cap,
          (SELECT VALUE
             FROM SETTING_VALUES
            WHERE Setting_id = 'APP_PRJ_SCR_CAP')
             PERCENTAGE
     FROM DUAL;


DROP VIEW V_SCR_SITE_CAP_APR;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SCR_SITE_CAP_APR
(
   LOC_ID,
   CAP,
   PERCENTAGE
)
AS
   SELECT ID AS LOC_ID,
          cntry_site_settingval (id, 'SITE_SCR_CAP', 'SITE') AS CAP,
          PERCENTAGE
     FROM (SELECT a.id, PERCENTAGE
             FROM (  SELECT loc.id,
                            cntry_site_settingval (loc.id,
                                                   'APP_SITE_SCR_CAP',
                                                   'SITE')
                               AS PERCENTAGE
                       FROM    usr_pat u
                            JOIN
                               v_drug_location loc
                            ON loc.id = u.sit_id
                   GROUP BY loc.id) a);


DROP VIEW V_SITE_ACTIVATION;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SITE_ACTIVATION
(
   ACTIVATION_TS,
   ACTIVATION,
   ACTIVATIONMS,
   ID
)
AS
     SELECT MIN (MODIFIED_AT) AS ACTIVATION_TS,
            TO_CHAR (MIN (MODIFIED_AT), 'yyyy-MM-dd') AS ACTIVATION,
              TO_NUMBER (
                   TO_DATE (TO_CHAR (MIN (MODIFIED_AT), 'yyyy-MM-dd'),
                            'yyyy-MM-dd')
                 - TO_DATE ('01-01-1970', 'DD-MM-YYYY'))
            * 86400000
               AS ACTIVATIONMS,
            ID
       FROM (SELECT MODIFIED_AT, STATUS_ID, ID FROM V_DRUG_LOCATION
             UNION ALL
             SELECT MODIFIED_AT, STATUS_ID, ID FROM DRUG_AUDIT_LOCATION)
      WHERE STATUS_ID = 'LocationStatus_ACTIVE'
   GROUP BY ID;


DROP VIEW V_SI_DATA;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DATA
(
   ID,
   PAT_ID,
   FIELD,
   FORM,
   PAGE,
   COUNTER,
   VALUE,
   SPEC_VALUE,
   COMMENTS,
   REASON,
   LOCKED,
   MODIFIED_TIMESTAMP,
   MODIFIED_BY_USER,
   CREATED_TIMESTAMP,
   CREATED_BY_USER,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          PAT_ID,
          FIELD,
          FORM,
          PAGE,
          COUNTER,
          VALUE,
          SPEC_VALUE,
          COMMENTS,
          REASON,
          LOCKED,
          SYS_EXTRACT_UTC (MODIFIED_TIMESTAMP) AS MODIFIED_TIMESTAMP,
          MODIFIED_BY_USER,
          SYS_EXTRACT_UTC (CREATED_TIMESTAMP) AS CREATED_TIMESTAMP,
          CREATED_BY_USER,
          MODIFIED_BY AS MODIFIED_BY_WORKER
     FROM DATA;


DROP VIEW V_SI_DRUG_BATCH;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_BATCH
(
   ID,
   NAME,
   BLOCKED,
   WAREHOUSE_BATCH_NAME,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          BLOCKED,
          WAREHOUSE_BATCH_NAME,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_BATCH;


DROP VIEW V_SI_DRUG_BATCH_COUNTRY;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_BATCH_COUNTRY
(
   ID,
   BATCH_ID,
   COUNTRY_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          BATCH_ID,
          COUNTRY_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_BATCH_COUNTRY;


DROP VIEW V_SI_DRUG_COHORT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_COHORT
(
   ID,
   NAME,
   DESCRIPTION,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          DESCRIPTION,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_COHORT;


DROP VIEW V_SI_DRUG_COHORT_ATTRIB;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_COHORT_ATTRIB
(
   ID,
   COHORT_ID,
   NAME,
   VALUE,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          COHORT_ID,
          NAME,
          VALUE,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_COHORT_ATTRIB;


DROP VIEW V_SI_DRUG_CONFIGURATION;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_CONFIGURATION
(
   ID,
   NAME,
   VALUE,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_CONFIGURATION;


DROP VIEW V_SI_DRUG_DOSE;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_DOSE
(
   ID,
   NAME,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_DOSE;


DROP VIEW V_SI_DRUG_ENROLMENT_CAT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_ENROLMENT_CAT
(
   ID,
   NAME,
   IS_DEFAULT,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          IS_DEFAULT,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_ENROLMENT_CAT;


DROP VIEW V_SI_DRUG_ENROLMENT_LEVEL;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_ENROLMENT_LEVEL
(
   ID,
   NAME,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_ENROLMENT_LEVEL;


DROP VIEW V_SI_DRUG_EXPECTED_QTY;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_EXPECTED_QTY
(
   ID,
   UNBLINDED_KIT_TYPE_ID,
   REQUESTED_QTY,
   SHIPMENT_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          UNBLINDED_KIT_TYPE_ID,
          REQUESTED_QTY,
          SHIPMENT_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_EXPECTED_QTY;


DROP VIEW V_SI_DRUG_FACTOR;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_FACTOR
(
   ID,
   NAME,
   SHORT_NAME,
   FACTOR_TYPE,
   DESCRIPTION,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          SHORT_NAME,
          FACTOR_TYPE,
          DESCRIPTION,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_FACTOR;


DROP VIEW V_SI_DRUG_FACTOR_VALUE;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_FACTOR_VALUE
(
   ID,
   NAME,
   VALUE,
   RATIO,
   DESCRIPTION,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          RATIO,
          DESCRIPTION,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_FACTOR_VALUE;


DROP VIEW V_SI_DRUG_KIT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_KIT
(
   ID,
   NAME,
   RECALL_DATE,
   LOCATION_ID,
   KIT_TYPE_ID,
   UNBL_KIT_TYPE_ID,
   SHIPMENT_ID,
   STATUS_ID,
   EXPIRATION_DATE,
   DISPENSE_DATE,
   PAT_ID,
   BATCH_ID,
   VERIFICATION_CODE,
   VERIFICATION_STATUS_ID,
   VISIT_ID,
   QUARANTINED,
   COUNT,
   SORT_KEY,
   FILEITEM_ID,
   MANUAL_DISPENSED,
   MANUFACTURING_LOT,
   BLOCK_NUMBER,
   REPLACES_KIT_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          RECALL_DATE,
          LOCATION_ID,
          KIT_TYPE_ID,
          UNBL_KIT_TYPE_ID,
          SHIPMENT_ID,
          STATUS_ID,
          EXPIRATION_DATE,
          DISPENSE_DATE,
          PAT_ID,
          BATCH_ID,
          VERIFICATION_CODE,
          VERIFICATION_STATUS_ID,
          VISIT_ID,
          QUARANTINED,
          COUNT,
          SORT_KEY,
          FILEITEM_ID,
          MANUAL_DISPENSED,
          MANUFACTURING_LOT,
          BLOCK_NUMBER,
          REPLACES_KIT_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_KIT;


DROP VIEW V_SI_DRUG_KIT_ATTRIB;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_KIT_ATTRIB
(
   ID,
   NAME,
   VALUE,
   KIT_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          KIT_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_KIT_ATTRIB;


DROP VIEW V_SI_DRUG_KIT_FILEITEM;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_KIT_FILEITEM
(
   ID,
   NAME,
   LINES,
   WORKER_ID,
   IMPORT_TIMESTAMP,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          LINES,
          WORKER_ID,
          IMPORT_TIMESTAMP,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_KIT_FILEITEM;


DROP VIEW V_SI_DRUG_KIT_FILEITEM_ATTRIB;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_KIT_FILEITEM_ATTRIB
(
   ID,
   NAME,
   VALUE,
   FILEITEM_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          FILEITEM_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_KIT_FILEITEM_ATTRIB;


DROP VIEW V_SI_DRUG_KIT_PROJECT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_KIT_PROJECT
(
   ID,
   KIT_ID,
   PROJECT_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          KIT_ID,
          PROJECT_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_KIT_PROJECT;


DROP VIEW V_SI_DRUG_KIT_TYPE;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_KIT_TYPE
(
   ID,
   NAME,
   DESCRIPTION,
   LABEL_MODE,
   DOSE,
   SUBCLASS,
   ENROLMENT_LEVEL_ID,
   BLINDED_KIT_TYPE_ID,
   ADDRESS_TYPE_ID,
   TEMP_CONTROLLED,
   RANGE_LOW_TEMP,
   RANGE_HIGH_TEMP,
   EXTRA_KIT_LOGIC,
   NON_DRUG,
   BLOCK_SHIPMENT,
   BLOCK_SIZE,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          DESCRIPTION,
          LABEL_MODE,
          DOSE,
          SUBCLASS,
          ENROLMENT_LEVEL_ID,
          BLINDED_KIT_TYPE_ID,
          CAST (ADDRESS_TYPE_ID AS INTEGER) ADDRESS_TYPE_ID,
          TEMP_CONTROLLED,
          RANGE_LOW_TEMP,
          RANGE_HIGH_TEMP,
          EXTRA_KIT_LOGIC,
          NON_DRUG,
          BLOCK_SHIPMENT,
          BLOCK_SIZE,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_KIT_TYPE;


DROP VIEW V_SI_DRUG_LOCATION;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_LOCATION
(
   ID,
   NAME,
   COUNTRY_ID,
   PROJECT_ID,
   STATUS_ID,
   SUBCLASS,
   ENROLMENT_CATEGORY_ID,
   LOCATION_SEQ_NUMBER,
   GRP_NUMBER,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT v.ID,
          v.NAME,
          v.COUNTRY_ID,
          v.PROJECT_ID,
          v.STATUS_ID,
          v.SUBCLASS,
          v.ENROLMENT_CATEGORY_ID,
          v.LOCATION_SEQ_NUMBER,
          v.GRP_NUMBER,
          l.MODIFIED_BY_USER,
          l.MODIFIED_TIMESTAMP,
          l.CREATED_BY_USER,
          l.CREATED_TIMESTAMP,
          v.MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_LOCATION l, V_DRUG_LOCATION v
    WHERE l.id(+) = v.id;


DROP VIEW V_SI_DRUG_LOCATION_ATTRIB;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_LOCATION_ATTRIB
(
   ID,
   NAME,
   VALUE,
   LOCATION_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          LOCATION_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_LOCATION_ATTRIB;


DROP VIEW V_SI_DRUG_PAT_VST_QTY_REQ;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_PAT_VST_QTY_REQ
(
   ID,
   PAT_ID,
   UNBL_KIT_TYPE_ID,
   QUANTITY,
   VISIT_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          PAT_ID,
          UNBL_KIT_TYPE_ID,
          QUANTITY,
          VISIT_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_PAT_VST_QTY_REQ;


DROP VIEW V_SI_DRUG_PRIORITY_ASSIGNMENT;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_PRIORITY_ASSIGNMENT
(
   ID,
   PRIORITY,
   UNBLINDED_KIT_TYPE_ID,
   QUANTITY,
   DOSE_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          PRIORITY,
          UNBLINDED_KIT_TYPE_ID,
          QUANTITY,
          DOSE_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_PRIORITY_ASSIGNMENT;


DROP VIEW V_SI_DRUG_PRIORITY_SUPPLY;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_PRIORITY_SUPPLY
(
   ID,
   PRIORITY,
   UNBL_KIT_TYPE_ID_FROM,
   UNBL_KIT_TYPE_ID_TO,
   QUANTITY,
   COUNTRY_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          PRIORITY,
          UNBL_KIT_TYPE_ID_FROM,
          UNBL_KIT_TYPE_ID_TO,
          QUANTITY,
          COUNTRY_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_PRIORITY_SUPPLY;


DROP VIEW V_SI_DRUG_RNDNO;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_RNDNO
(
   ID,
   PAT_NO,
   STATUS_ID,
   TREATMENTARM_ID,
   PAT_ID,
   VISIT_ID,
   UNBLINDED_AT,
   REASON_UNBLINDING,
   RANDOM_WEIGHT,
   RANDOM_SOURCE,
   SORT_KEY,
   RANDOMIZATION_ORDER,
   FILEITEM_ID,
   BLOCK,
   BLOCK_ASSIGNED,
   COHORT_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          PAT_NO,
          STATUS_ID,
          TREATMENTARM_ID,
          PAT_ID,
          VISIT_ID,
          UNBLINDED_AT,
          REASON_UNBLINDING,
          RANDOM_WEIGHT,
          RANDOM_SOURCE,
          SORT_KEY,
          RANDOMIZATION_ORDER,
          FILEITEM_ID,
          BLOCK,
          BLOCK_ASSIGNED,
          COHORT_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_RNDNO;


DROP VIEW V_SI_DRUG_RNDNO_ATTRIB;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_RNDNO_ATTRIB
(
   ID,
   NAME,
   VALUE,
   RNDNO_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          RNDNO_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_RNDNO_ATTRIB;


DROP VIEW V_SI_DRUG_RNDNO_FACTOR_VALUE;

/* Formatted on 9/18/2024 9:22:08 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_RNDNO_FACTOR_VALUE
(
   ID,
   NAME,
   VALUE,
   RNDNO_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          RNDNO_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_RNDNO_FACTOR_VALUE;


DROP VIEW V_SI_DRUG_RNDNO_FILEITEM;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_RNDNO_FILEITEM
(
   ID,
   NAME,
   LINES,
   WORKER_ID,
   IMPORT_TIMESTAMP,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          LINES,
          WORKER_ID,
          IMPORT_TIMESTAMP,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_RNDNO_FILEITEM;


DROP VIEW V_SI_DRUG_RNDNO_FILEITEM_A;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_RNDNO_FILEITEM_A
(
   ID,
   NAME,
   VALUE,
   FILEITEM_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          FILEITEM_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_RNDNO_FILEITEM_ATTRIB;


DROP VIEW V_SI_DRUG_SERVICE;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_SERVICE
(
   ID,
   NAME,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_SERVICE;


DROP VIEW V_SI_DRUG_SHIPMENT;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_SHIPMENT
(
   ID,
   NAME,
   SHIP_DATE,
   FROM_LOCATION_ID,
   TO_LOCATION_ID,
   SERVICE_ID,
   SENDER,
   STATUS_ID,
   REQUEST_DATE,
   ACKNOWLEDGEMENT_DATE,
   TEMP_CONTROLLED,
   TEMP_OUT_OF_RANGE,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          SHIP_DATE,
          FROM_LOCATION_ID,
          TO_LOCATION_ID,
          SERVICE_ID,
          SENDER,
          STATUS_ID,
          REQUEST_DATE,
          ACKNOWLEDGEMENT_DATE,
          TEMP_CONTROLLED,
          TEMP_OUT_OF_RANGE,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_SHIPMENT;


DROP VIEW V_SI_DRUG_SHIPMENT_ADDRESS;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_SHIPMENT_ADDRESS
(
   ID,
   SHIPMENT_ID,
   FNAME,
   MNAME,
   LNAME,
   TITLE,
   ORGANISATION,
   STREET,
   CITY,
   STATE,
   ZIP,
   COUNTRY_ID,
   PHONE,
   MPHONE,
   FAX,
   EMAIL,
   NOTES,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          SHIPMENT_ID,
          FNAME,
          MNAME,
          LNAME,
          TITLE,
          ORGANISATION,
          STREET,
          CITY,
          STATE,
          ZIP,
          COUNTRY_ID,
          PHONE,
          MPHONE,
          FAX,
          EMAIL,
          NOTES,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_SHIPMENT_ADDRESS;


DROP VIEW V_SI_DRUG_SHIPMENT_ATTRIB;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_SHIPMENT_ATTRIB
(
   ID,
   NAME,
   VALUE,
   SHIPMENT_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          SHIPMENT_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_SHIPMENT_ATTRIB;


DROP VIEW V_SI_DRUG_STATUS;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_STATUS
(
   ID,
   NAME,
   SUBCLASS,
   LOCATION_TYPE,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          SUBCLASS,
          LOCATION_TYPE,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_STATUS;


DROP VIEW V_SI_DRUG_SUPPLY_CONF;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_SUPPLY_CONF
(
   ID,
   ENROLMENT_LEVEL_ID,
   ENROLMENT_CATEGORY_ID,
   WAREHOUSE_ID,
   SUBCLASS,
   INITIAL_VALUE,
   MIN_VALUE,
   MAX_VALUE,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          ENROLMENT_LEVEL_ID,
          ENROLMENT_CATEGORY_ID,
          WAREHOUSE_ID,
          SUBCLASS,
          INITIAL_VALUE,
          MIN_VALUE,
          MAX_VALUE,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_SUPPLY_CONF;


DROP VIEW V_SI_DRUG_TRACK_LABELED;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_TRACK_LABELED
(
   ID,
   SHIPMENT_ID,
   KIT_ID
)
AS
   SELECT ID, SHIPMENT_ID, KIT_ID FROM V_DRUG_TRACK_LABELED;


DROP VIEW V_SI_DRUG_TREATMENTARM;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_TREATMENTARM
(
   ID,
   NAME,
   DESCRIPTION,
   STATUS_ID,
   DOSE,
   TREATMENTARM_TYPE,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          DESCRIPTION,
          STATUS_ID,
          DOSE,
          TREATMENTARM_TYPE,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_TREATMENTARM;


DROP VIEW V_SI_DRUG_UNBLINDING_LOG;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_UNBLINDING_LOG
(
   ID,
   WORKER_ID,
   RNDNO_ID,
   REASON_UNBLINDING,
   TYPE,
   UNBLINDED_AT,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          WORKER_ID,
          RNDNO_ID,
          REASON_UNBLINDING,
          TYPE,
          UNBLINDED_AT,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_UNBLINDING_LOG;


DROP VIEW V_SI_DRUG_UNPACKAGED_KIT;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_UNPACKAGED_KIT
(
   ID,
   NAME,
   KIT_TYPE_ID,
   UNBL_KIT_TYPE_ID,
   VERIFICATION_CODE,
   COUNT,
   SORT_KEY,
   FILEITEM_ID,
   BLOCK_NUMBER,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          KIT_TYPE_ID,
          UNBL_KIT_TYPE_ID,
          VERIFICATION_CODE,
          COUNT,
          SORT_KEY,
          FILEITEM_ID,
          BLOCK_NUMBER,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_UNPACKAGED_KIT;


DROP VIEW V_SI_DRUG_UNPKG_KIT_ATTRIB;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_DRUG_UNPKG_KIT_ATTRIB
(
   ID,
   NAME,
   VALUE,
   UNPACKAGED_KIT_ID,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          NAME,
          VALUE,
          UNPACKAGED_KIT_ID,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED AS MODIFIED_BY_WORKER
     FROM DRUG_UNPACKAGED_KIT_ATTRIB;


DROP VIEW V_SI_FIELD_DESCR;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_FIELD_DESCR
(
   ID,
   FIELD,
   FORM,
   MODULE,
   TYPE,
   DESCR,
   LOOP_NAME,
   LOOP_LEVEL,
   MAX_COUNTER,
   FLOW_NUMBER,
   CODE_TYPE,
   FLAGS,
   PAGENO,
   MAX_LENGTH,
   MODIFIED_TIMESTAMP,
   MODIFIED_BY_USER,
   CREATED_TIMESTAMP,
   CREATED_BY_USER,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          FIELD,
          FORM,
          MODULE,
          TYPE,
          DESCR,
          LOOP_NAME,
          LOOP_LEVEL,
          MAX_COUNTER,
          FLOW_NUMBER,
          CODE_TYPE,
          FLAGS,
          PAGENO,
          MAX_LENGTH,
          SYS_EXTRACT_UTC (MODIFIED_TIMESTAMP) AS MODIFIED_TIMESTAMP,
          MODIFIED_BY_USER,
          SYS_EXTRACT_UTC (CREATED_TIMESTAMP) AS CREATED_TIMESTAMP,
          CREATED_BY_USER,
          NULL AS MODIFIED_BY_WORKER
     FROM FIELD_DESCR;


DROP VIEW V_SI_FIELD_VALUE_LABELS;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_FIELD_VALUE_LABELS
(
   ID,
   FIELD,
   FORM,
   VALUE,
   LABEL,
   MODIFIED_TIMESTAMP,
   MODIFIED_BY_USER,
   CREATED_TIMESTAMP,
   CREATED_BY_USER,
   MODIFIED_BY_WORKER
)
AS
   SELECT f.ID,
          f.FIELD,
          f.FORM,
          DECODE (f.LABEL, NULL, s.VALUE, f.VALUE) AS VALUE,
          DECODE (f.LABEL, NULL, s.LABEL, f.LABEL) AS LABEL,
          SYS_EXTRACT_UTC (f.MODIFIED_TIMESTAMP) AS MODIFIED_TIMESTAMP,
          f.MODIFIED_BY_USER,
          SYS_EXTRACT_UTC (f.CREATED_TIMESTAMP) AS CREATED_TIMESTAMP,
          f.CREATED_BY_USER,
          NULL AS MODIFIED_BY_WORKER
     FROM FIELD_VALLAB f, VAL_SETS s
    WHERE f.VALUE = s.VAL_SET(+);


DROP VIEW V_SI_SETTING_VALUES;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_SETTING_VALUES
(
   ID,
   SETTING_ID,
   LOCATION_ID,
   PARAMETER_ID,
   VALUE,
   UNIT,
   MODIFIED,
   MODIFIED_BY,
   CREATED,
   CREATED_BY,
   CREATED_BY_USER,
   CREATED_TIMESTAMP,
   MODIFIED_BY_USER,
   MODIFIED_TIMESTAMP,
   MODIFIED_BY_WORKER
)
AS
   SELECT ID,
          SETTING_ID,
          LOCATION_ID,
          PARAMETER_ID,
          VALUE,
          UNIT,
          MODIFIED,
          MODIFIED_BY,
          CREATED,
          CREATED_BY,
          CREATED_BY_USER,
          CREATED_TIMESTAMP,
          MODIFIED_BY_USER,
          MODIFIED_TIMESTAMP,
          CASE
             WHEN MODIFIED_BY_USER = 'P90020903' THEN MODIFIED_BY
             ELSE NULL
          END
             AS MODIFIED_BY_WORKER
     FROM SETTING_VALUES;


DROP VIEW V_SI_USR_PAT;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_SI_USR_PAT
(
   ID,
   SIT_ID,
   SIGNED,
   INCLUDED,
   SCR_NO,
   PAT_NO,
   INITIALS,
   BIRTHDATE,
   WITHDRAWN_DATE,
   RANDOM_DATE,
   STATUS,
   STATUS_TS,
   MODIFIED_TIMESTAMP,
   MODIFIED_BY_USER,
   CREATED_TIMESTAMP,
   CREATED_BY_USER,
   MODIFIED_BY_WORKER
)
AS
   SELECT PAT_ID AS ID,
          SIT_ID,
          SIGNED,
          INCLUDED,
          SCR_NO,
          PAT_NO,
          INITIALS,
          BIRTHDATE,
          WITHDRAWN_DATE,
          RANDOM_DATE,
          STATUS,
          STATUS_TS,
          SYS_EXTRACT_UTC (MODIFIED_TIMESTAMP) AS MODIFIED_TIMESTAMP,
          MODIFIED_BY_USER,
          SYS_EXTRACT_UTC (CREATED_TIMESTAMP) AS CREATED_TIMESTAMP,
          CREATED_BY_USER,
          MODIFIED_BY AS MODIFIED_BY_WORKER
     FROM USR_PAT;


DROP VIEW V_USR_PAT_COHORT;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_USR_PAT_COHORT
(
   PAT_ID,
   COHORT_ID
)
AS
   SELECT PAT_ID, COHORT_ID FROM TMP_USR_PAT_COHORT;


DROP VIEW V_VIS_BASED_ON_PRE_VISIT;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_VIS_BASED_ON_PRE_VISIT
(
   VISIT_ID,
   SCHEDULE_ID,
   PREV_VIS_COMPLETED,
   PAT_ID
)
AS
     SELECT s1.VISIT_ID,
            s1.SCHEDULE_ID,
            MAX (
               CASE
                  WHEN     d.FORM = i2.FORM
                       AND d.PAGE = i2.INSTANCE
                       AND d.FIELD = v.FIELD
                       AND (s1.VISIT_NO = 0 OR d.VALUE IS NOT NULL)
                  THEN
                     1
                  ELSE
                     0
               END)
               "PREV_VIS_COMPLETED",
            d.PAT_ID
       FROM VISIT_SCHEDULE s1,
            VISIT_SCHEDULE s2,
            VISIT_INFO i1,
            VISIT_INFO i2,
            PSTAT_VIS v,
            DATA d
      WHERE     s2.SCHEDULE_ID = s1.SCHEDULE_ID
            AND (   s1.VISIT_NO = 0 AND s2.VISIT_NO = 0
                 OR s2.VISIT_NO = s1.VISIT_NO - 1)
            AND s2.VISIT_ID = i2.VISIT_ID
            AND s2.SCHEDULE_ID = i2.SCHEDULE_ID
            AND s1.VISIT_ID = i1.VISIT_ID
            AND s1.SCHEDULE_ID = i1.SCHEDULE_ID
            AND v.VISIT_ID = i2.VISIT_ID
            AND v.SCHEDULE_ID = i2.SCHEDULE_ID
   GROUP BY PAT_ID, s1.VISIT_ID, s1.SCHEDULE_ID;


DROP VIEW V_WAIVER;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_WAIVER
(
   PAT_ID,
   CONDITION_ID,
   VISIT_ID,
   FORM,
   INSTANCE,
   COUNTER
)
AS
   SELECT w.PAT_ID,
          w.CONDITION_ID,
          w.VISIT_ID,
          s.FORM,
          s.INSTANCE,
          s.COUNTER
     FROM WAIVER w, V_PAT_SCHEDULE s
    WHERE w.PAT_ID = s.PAT_ID AND w.VISIT_ID = s.VISIT_ID;


DROP VIEW V_WORKER_PERMISSIONS;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_WORKER_PERMISSIONS
(
   WRK_ID,
   PRM_ID
)
AS
   SELECT w.WRK_ID, r.PRM_ID
     FROM ADMIN_IF.WORKERS w, ADM_ICRF4_IF.ROLEPRMLIST r
    WHERE r.ROL_ID = w.ROL_ID;


DROP VIEW V_WRK_SITE;

/* Formatted on 9/18/2024 9:22:09 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE FORCE VIEW V_WRK_SITE
(
   WRK_ID,
   PRJ_ID,
   ENV_ID,
   SUB_ID,
   SUB_CAT,
   SUB_NAME,
   OBJ_ID,
   OBJ_CAT,
   OBJ_NAME
)
AS
   SELECT w.WRK_ID,
          g1.prj_id,
          g1.env_id,
          g1.grp_id sub_id,
          G1.CAT_ID sub_cat,
          g1.name sub_name,
          g2.grp_id obj_id,
          g2.cat_id obj_cat,
          g2.name obj_name
     FROM ADMIN_IF.groups g1, ADMIN_IF.groups g2, ADMIN_IF.workers w
    WHERE     (g1.grp_id, g2.grp_id) IN
                 (    SELECT CONNECT_BY_ROOT sbj_id, obj_id
                        FROM ADMIN_IF.supervision
                  CONNECT BY PRIOR obj_id = sbj_id)
          AND g1.grp_id = w.GRP_ID;


GRANT SELECT ON SPT_SI_RECIPIENT TO APPSUPPORT_RW;

GRANT SELECT ON SPT_SI_RECIPIENT TO DB_DATASUPPORT_RW;

GRANT SELECT ON SPT_SI_RECIPIENT TO PROJECT_ANALYST_RO;

GRANT SELECT ON SPT_SI_RECIPIENT TO PROJECT_ANALYST_RW;

GRANT SELECT ON SPT_SI_RECIPIENT TO PROJECT_SUPPORT_RW;
