kubectl exec -n postgres -it postgres-0 -- psql -U postgres -d postgres -h localhost -W


psql -U postgres -d immich -h localhost -W


ALTER SYSTEM SET password_encryption = 'md5';
SELECT pg_reload_conf();

ALTER ROLE immich WITH PASSWORD 'immichadmin123!';

GRANT ALL ON SCHEMA public TO immich;

SELECT rolname, rolpassword
  FROM pg_authid
 WHERE rolname = 'immich';
-- rolpassword가 'md5...' 형태로 출력되어야 합니다.