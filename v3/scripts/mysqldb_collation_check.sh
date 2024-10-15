#!/bin/bash
tenant_db="all"
MYSQL_OLD_ENCODING="utf8mb3"
MYSQL_CHAR_ENCODING="utf8mb4"
MYSQL_COLL_ENCODING="utf8mb4_0900_ai_ci"

print_help () {
    echo
    echo "******************************************************************"
    echo "*       MySQL database character set / collation checking            *"
    echo "******************************************************************"
    echo 
    echo "Usage: Checking if this database contains non-utf8mb4 char & collation database, tables, columns, routines"
    echo "MySQL 8.0 or newer version are required to convert character set / collation to utf8mb4/ utf8mb4_0900_ai_ci"
    echo "    -t: tenant id or database name is required"
    echo "    -u: mysql user"
    echo "    -p: mysql password"
    echo "    -h: help"
    echo "    Execution as: "
    echo "      ./mysqldb_collation_check.sh -t tenant_db -u db_user -p password"
}

if [[ $1 == "help" ]]; then
    print_help
    exit 1
fi 

#echo "The arguments passed in are : $@"

while getopts t:u:p:d:h option
do 
    case "${option}"
        in
        t)tenant_db=${OPTARG};;
        u)user_name=${OPTARG};;
        p)mysql_pw=${OPTARG};;
        h)print_help && exit 1;; # Print helpFunction in case parameter is non-existent
    esac
done

if [ -z $user_name ] ; then
  echo "ERROR: $0 requires user name and pw as args"
 exit 1
fi

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

non_mb4_tenants_sql="SELECT s.schema_name
                FROM INFORMATION_SCHEMA.schemata s
                WHERE s.schema_name not in ('mysql','performance_schema','sys','mysql_innodb_cluster_metadata')
                and s.schema_name = '${tenant_db}'"
tenant_id=$(mysql -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --skip-column-names -e "${non_mb4_tenants_sql}")

if [ -z $tenant_id ] ; then
    echo "ERROR: database ${tenant_db} is not found!"
exit 1
fi

non_mb4_sql="SELECT (a.not_utf8mb4_count + b.not_utf8mb4_count + c.not_utf8mb4_count + d.not_utf8mb4_count) not_utf8mb4_count
            FROM (SELECT s.schema_name, SUM(IF(( s.default_character_set_name <> '${MYSQL_CHAR_ENCODING}' 
            OR s.default_collation_name <> '${MYSQL_COLL_ENCODING}'), 1, 0)) not_utf8mb4_count
            FROM information_schema.schemata s WHERE s.schema_name =  '${tenant_id}' GROUP  BY s.schema_name) a
            JOIN (SELECT t.table_schema,SUM(IF(( co.character_set_name <> '${MYSQL_CHAR_ENCODING}' 
            OR t.table_collation <> '${MYSQL_COLL_ENCODING}'), 1, 0)) not_utf8mb4_count
            FROM information_schema.TABLES AS t 
            JOIN information_schema.collations AS co ON t.table_collation = co.collation_name
            WHERE t.table_schema= '${tenant_id}' AND t.table_name NOT LIKE 'zzjama%' AND t.table_name NOT LIKE 'con%' AND t.table_type = 'BASE TABLE'
            GROUP  BY t.table_schema) b ON a.schema_name = b.table_schema
            JOIN (SELECT table_schema,SUM(IF(( character_set_name <> '${MYSQL_CHAR_ENCODING}' 
            OR collation_name <> '${MYSQL_COLL_ENCODING}'), 1, 0)) not_utf8mb4_count
            FROM information_schema.COLUMNS 
            WHERE table_schema= '${tenant_id}' AND table_name NOT LIKE 'zzjama%' AND table_name NOT LIKE 'con%'
            GROUP  BY table_schema) c ON c.table_schema = b.table_schema
            JOIN (SELECT  r.routine_schema,SUM(IF(r.database_collation <> '${MYSQL_COLL_ENCODING}', 1, 0)) not_utf8mb4_count
            FROM information_schema.routines AS r WHERE r.routine_schema= '${tenant_id}' 
            GROUP BY r.routine_schema) d ON d.routine_schema = c.table_schema;"

check_non_mb4=$(mysql -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --skip-column-names -e "${non_mb4_sql}")
if [[ (${check_non_mb4} > 0) ]]; then
    echo "${tenant_id} is about ${check_non_mb4} non-utfmb4 items need to be fixed."  
    echo "Start tenant collation checking ... "
else 
    echo "${tenant_id} is already in utf8mb4 characer set and collation." 
    echo "No database items need to be upgraded."
    exit $exit_code
fi
        
check_db_char_coll="SELECT s.schema_name table_schema,s.default_character_set_name db_char_set,s.default_collation_name db_collation,
        group_concat(distinct database_collation) stored_proc_collation
        FROM INFORMATION_SCHEMA.SCHEMATA AS s 
        JOIN information_schema.ROUTINES AS r ON s.SCHEMA_NAME = r.ROUTINE_SCHEMA 
        WHERE s.schema_name = '${tenant_id}'
        group by s.schema_name,s.default_character_set_name,s.default_collation_name"

check_utf8mb3_table_char_sql="SELECT t.table_schema, count(t.table_name) total_tables,
            sum(if(co.character_set_name = '${MYSQL_OLD_ENCODING}',1,0)) tbl_char_set_utfmb3, 
			sum(if(t.TABLE_COLLATION like 'utf8mb3_general_ci',1,0)) tbl_utfmb3_general_ci,
            sum(if(t.TABLE_COLLATION like 'utf8mb3_unicode_ci',1,0)) tbl_utfmb3_unicode_ci,
            sum(if(t.TABLE_COLLATION like 'utf8mb3_bin',1,0)) tbl_utfmb3_bin,
            sum(if(co.character_set_name not like 'utf8%',1,0)) tbl_non_utf8_encoding
            FROM INFORMATION_SCHEMA.TABLES as t 
            JOIN INFORMATION_SCHEMA.COLLATIONS as co ON t.table_collation=co.collation_name
            WHERE t.table_schema = '${tenant_id}'
            AND t.table_name not like 'zzjama%'
            AND t.table_name not like 'con%'
            AND t.table_type = 'BASE TABLE'
            AND t.table_collation is not null
            GROUP BY t.table_schema"
        
check_utf8mb3_col_collation="SELECT t.table_schema, count(c.column_name) total_column,
            sum(if(c.character_set_name='${MYSQL_OLD_ENCODING}',1,0)) col_char_set_utfmb3, 
            sum(if(c.collation_name like 'utf8mb3_general_ci',1,0)) col_utfmb3_general_ci,
            sum(if(c.collation_name like 'utf8mb3_unicode_ci',1,0)) col_utfmb3_unicode_ci,
            sum(if(c.collation_name like 'utf8mb3_bin',1,0)) col_utfmb3_bin,
            sum(if(c.character_set_name not like 'utf8%',1,0)) col_non_utf8_encoding
            FROM INFORMATION_SCHEMA.TABLES as t 
            JOIN INFORMATION_SCHEMA.COLLATIONS as co on t.TABLE_COLLATION=co.collation_name
            JOIN INFORMATION_SCHEMA.COLUMNS AS c ON c.Table_schema = t.table_schema AND c.table_name = t.table_name
            WHERE t.table_schema = '${tenant_id}'
            AND t.table_name not like 'zzjama%'
            AND t.table_name not like 'con%'
            AND t.table_type = 'BASE TABLE'
            AND t.table_collation is not null
            AND c.collation_name is not null
            GROUP BY t.table_schema"

non_mb4_table="SELECT sum(if((s.default_character_set_name <>'${MYSQL_CHAR_ENCODING}' OR co.character_set_name <> '${MYSQL_CHAR_ENCODING}' 
                OR c.character_set_name<>'${MYSQL_CHAR_ENCODING}'),1,0)) not_utfmb4_count
                FROM INFORMATION_SCHEMA.schemata s
                JOIN INFORMATION_SCHEMA.TABLES as t ON s.schema_name=t.table_schema
                JOIN INFORMATION_SCHEMA.COLLATIONS as co ON t.table_collation=co.collation_name
                JOIN INFORMATION_SCHEMA.COLUMNS AS c ON c.Table_schema = t.table_schema and c.table_name = t.table_name
                WHERE t.table_schema = '${tenant_id}'
                AND t.table_name not like 'zzjama%'
                AND t.table_name not like 'con%'
                AND t.table_type = 'BASE TABLE'
                GROUP BY t.table_schema;"

check_proc_collation="SELECT count(R.routine_name) as total_utf8mb3_proc
            FROM information_schema.ROUTINES AS R 
            INNER JOIN INFORMATION_SCHEMA.SCHEMATA AS S ON S.SCHEMA_NAME = R.ROUTINE_SCHEMA 
            WHERE DATABASE_COLLATION <> '${MYSQL_COLL_ENCODING}' 
            and S.schema_name = '${tenant_id}' group by S.schema_name, DATABASE_COLLATION; "

mysql_version=$(mysql -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --skip-column-names -e "SELECT version();")
if  [[ $mysql_version == 8* ]] ;
then
    mysql -u ${user_name} --password=${mysql_pw} -e "${check_db_char_coll};${check_utf8mb3_table_char_sql};${check_utf8mb3_col_collation};${check_proc_collation}" 
else
    mysql -u ${user_name} --password=${mysql_pw} -e "SELECT version() mysql_version;${check_db_char_coll};${check_utf8mb3_table_char_sql};${check_utf8mb3_col_collation};${check_proc_collation}" 
    echo "Your database server version is ${mysql_version}. MySQL 8.0.x or the newer version is required for utf8mb4 character set/collation migration."
fi

check_duplicates_sql="SELECT count(*) duplicates FROM (SELECT CONVERT(userName USING utf8mb4), COUNT(*) FROM userbase GROUP BY CONVERT(userName USING utf8mb4) HAVING COUNT(*) > 1) dups;"
show_duplicates_sql="SELECT userName,duplicate_count FROM (SELECT CONVERT(userName USING utf8mb4) userName, COUNT(*) duplicate_count FROM userbase GROUP BY CONVERT(userName USING utf8mb4) HAVING COUNT(*) > 1) dups;"
dup_users=$(mysql -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --skip-column-names ${tenant_id} -e "${check_duplicates_sql}")
if [ $dup_users -gt 0 ] ; then
    mysql -u ${user_name} --password=${mysql_pw} ${tenant_id} -e "${show_duplicates_sql};"
    echo "${dup_users} duplicate user names are found! need to be fixed before utf8mb4 collation migration..."   
fi


    

