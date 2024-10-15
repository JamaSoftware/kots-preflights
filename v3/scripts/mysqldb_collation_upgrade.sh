#!/bin/bash
tenant_db="all"
dry_run="yes"
MYSQL_OLD_ENCODING="utf8mb3"
MYSQL_CHAR_ENCODING="utf8mb4"
MYSQL_COLL_ENCODING="utf8mb4_0900_ai_ci"
log_file='mysqldb_collation_migration.log'

print_help () {
    echo
    echo "******************************************************************"
    echo "*       MySQL database character set / collation migration             *"
    echo "******************************************************************"
    echo 
    echo "Usage: detecting if any database contain non-utf8mb4 char & collation database, tables and columns"
    echo "Convert all non-utf8mb4 char & collation of dbs, tables and columns to be single utf8mb4 version"
    echo "MySQL 8.0 or newer version to set character set / collation : utf8mb4/ utf8mb4_0900_ai_ci"
    echo "    -t: tenant id or database name"
    echo "    -u: mysql user"
    echo "    -p: mysql password"
    echo "    -d: dry run"
    echo "    -h: help"
    echo "    Dry run : "
    echo "      ./mysqldb_collation_upgrade.sh -t tenant_db -u db_user -p password"
    echo "    Execution as: "
    echo "      ./mysqldb_collation_upgrade.sh -t tenant_db -u db_user -p password -d no"
    echo "    Execution log file name: mysqldb_collation_migration.log"
    echo "    Run in background:"
    echo "      nohup ./mysqldb_collation_upgrade.sh -t tenant_db -u db_user -p password -d no &"
    
    
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
        d)dry_run=${OPTARG};;
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
                and s.schema_name = '${tenant_db}';"
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
        if [[ (${dry_run} == "no") ]]; then
            echo "Converting MySQL database ${tenant_id} to ${MYSQL_CHAR_ENCODING} and Collation  : ${MYSQL_COLL_ENCODING}" > ${log_file}
            echo "Starting" >> ${log_file}
            date >> ${log_file}
        else
            echo "Dry run    : ${dry_run}"
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
        check_duplicates_sql="SELECT count(*) duplicates FROM (SELECT CONVERT(userName USING utf8mb4), COUNT(*) FROM userbase GROUP BY CONVERT(userName USING utf8mb4) HAVING COUNT(*) > 1) dups;"
        show_duplicates_sql="SELECT userName,duplicate_count FROM (SELECT CONVERT(userName USING utf8mb4) userName, COUNT(*) duplicate_count FROM userbase GROUP BY CONVERT(userName USING utf8mb4) HAVING COUNT(*) > 1) dups;"
        dup_users=$(mysql -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --skip-column-names ${tenant_id} -e "${check_duplicates_sql}")

        if [[ (${dry_run} == "no") ]]; then
            echo "${tenant_id} is about ${check_non_mb4} non-utfmb4 items need to be fixed."  >> ${log_file}
            if  [[ $mysql_version == 8* ]] ; then
                echo "Before collation upgrade checking ... "  >> ${log_file}
                mysql -u ${user_name} --password=${mysql_pw} -e "${check_db_char_coll};${check_utf8mb3_table_char_sql};${check_utf8mb3_col_collation};${check_proc_collation}" >> ${log_file} 2>&1
            else
                mysql -u ${user_name} --password=${mysql_pw} -e "SELECT version() mysql_version;${check_db_char_coll};${check_utf8mb3_table_char_sql};${check_utf8mb3_col_collation};${check_proc_collation}" >> ${log_file} 2>&1
                echo "Your MySQL database server version is ${mysql_version}. Utf8mb4 character set/collation migration required MySQL 8.0.x or the newer version.">> ${log_file}
                exit 1
            fi

            if [ $dup_users -gt 0 ] ; then
                mysql -u ${user_name} --password=${mysql_pw} ${tenant_id} -e "${show_duplicates_sql};" >> ${log_file} 2>&1
                echo "${dup_users} duplicate user names are found! need to be manually fixed before collation upgrading!" >> ${log_file}
                exit 1
            fi
        else
            echo "${tenant_id} is about ${check_non_mb4} non-utfmb4 items need to be fixed."  
            echo "Before collation upgrade checking ... "
            if  [[ $mysql_version == 8* ]] ; then
                mysql -u ${user_name} --password=${mysql_pw} -e "${check_db_char_coll};${check_utf8mb3_table_char_sql};${check_utf8mb3_col_collation};${check_proc_collation}" 
            else
                mysql -u ${user_name} --password=${mysql_pw} -e "SELECT version() mysql_version;${check_db_char_coll};${check_utf8mb3_table_char_sql};${check_utf8mb3_col_collation};${check_proc_collation}" 
                echo "Your database server version is ${mysql_version}. MySQL 8.0.x or the newer version is required for utf8mb4 character set/collation migration."
            fi

            if [ $dup_users -gt 0 ] ; then
                mysql -u ${user_name} --password=${mysql_pw} ${tenant_id} -e "${show_duplicates_sql};"
                echo "${dup_users} duplicate user names are found! need to be manually fixed before collation upgrading!"  
            fi
        fi
       
        char_coll_convert_sql="SELECT 'SET FOREIGN_KEY_CHECKS = 0;' AS alter_statement 
        UNION SELECT 
            CONCAT('ALTER DATABASE ', SCHEMA_NAME,' CHARACTER SET ${MYSQL_CHAR_ENCODING} COLLATE ${MYSQL_COLL_ENCODING} ;') AS alter_statement 
        FROM 
            INFORMATION_SCHEMA.SCHEMATA 
        WHERE 
            DEFAULT_CHARACTER_SET_NAME <>'${MYSQL_CHAR_ENCODING}'
            AND DEFAULT_COLLATION_NAME <>'${MYSQL_COLL_ENCODING}'
            AND SCHEMA_NAME NOT IN('mysql','information_schema','performance_schema','sys','mysql_innodb_cluster_metadata')
            AND SCHEMA_NAME=@tenant_id
        UNION 
        SELECT
            DISTINCT CONCAT('ALTER TABLE ', TABLE_SCHEMA,'.',TABLE_NAME, ' CONVERT TO CHARACTER SET ${MYSQL_CHAR_ENCODING} COLLATE ${MYSQL_COLL_ENCODING};') AS alter_statement 
        FROM
        (
            SELECT
                DISTINCT C.TABLE_SCHEMA, C.TABLE_NAME
            FROM
                INFORMATION_SCHEMA.COLUMNS AS C
            JOIN INFORMATION_SCHEMA.TABLES AS T ON C.TABLE_NAME = T.TABLE_NAME AND C.TABLE_SCHEMA=T.TABLE_SCHEMA
            WHERE C.CHARACTER_SET_NAME <>'${MYSQL_CHAR_ENCODING}'
                AND C.COLLATION_NAME <> '${MYSQL_COLL_ENCODING}'
                AND C.TABLE_SCHEMA=@tenant_id
                AND C.TABLE_SCHEMA NOT IN('mysql','information_schema','performance_schema','sys','mysql_innodb_cluster_metadata')
                AND T.TABLE_TYPE = 'BASE TABLE'
                AND T.TABLE_NAME not like 'zzjama%'
                AND T.TABLE_NAME not like 'con%'       
            UNION SELECT
                DISTINCT TABLE_SCHEMA, TABLE_NAME
            FROM 
                INFORMATION_SCHEMA.TABLES AS T
            JOIN 
                INFORMATION_SCHEMA.COLLATION_CHARACTER_SET_APPLICABILITY AS C 
                ON C.COLLATION_NAME = T.TABLE_COLLATION
            WHERE C.CHARACTER_SET_NAME <> '${MYSQL_CHAR_ENCODING}'
                AND T.TABLE_COLLATION <> '${MYSQL_COLL_ENCODING}'
                AND TABLE_SCHEMA=@tenant_id 
                AND TABLE_SCHEMA NOT IN('mysql','information_schema','performance_schema','sys','mysql_innodb_cluster_metadata')
                AND TABLE_TYPE = 'BASE TABLE'
                AND TABLE_NAME not like 'zzjama%'
                AND TABLE_NAME not like 'con%'
        ) AS TABLE_UPDATES
        UNION SELECT 'SET FOREIGN_KEY_CHECKS = 1;' AS alter_statement;"
        char_convert_sql="USE ${tenant_id};SET @tenant_id='${tenant_id}';${char_coll_convert_sql}"

        check_table_char_sql="SELECT t.table_schema, count(t.table_name) total_tables,
            sum(if(co.character_set_name = '${MYSQL_CHAR_ENCODING}',1,0)) tbl_char_set_utfmb4, 
            sum(if(t.TABLE_COLLATION = '${MYSQL_COLL_ENCODING}',1,0)) tbl_coll_utfmb4_0900,
            sum(if(co.character_set_name = '${MYSQL_OLD_ENCODING}',1,0)) tbl_char_set_utfmb3,
            sum(if(co.character_set_name not like 'utf8%',1,0)) tbl_non_utf8_encoding
            FROM INFORMATION_SCHEMA.TABLES as t 
            JOIN INFORMATION_SCHEMA.COLLATIONS as co ON t.table_collation=co.collation_name
            WHERE t.table_schema = '${tenant_id}'
            AND t.table_name not like 'zzjama%'
            AND t.table_name not like 'con%'
            AND t.table_type = 'BASE TABLE'
            AND t.table_collation is not null
            GROUP BY t.table_schema"

            check_col_collation="SELECT t.table_schema, count(c.column_name) total_column,
            sum(if(c.character_set_name='${MYSQL_CHAR_ENCODING}',1,0)) col_char_set_utfmb4, 
            sum(if(c.collation_name = '${MYSQL_COLL_ENCODING}',1,0)) col_collation_utfmb4_0900,
            sum(if(c.character_set_name='${MYSQL_OLD_ENCODING}',1,0)) col_char_set_utfmb3,
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

        check_proc_collation_after="SELECT count(R.routine_name) as total_utf8mb3_proc
            FROM information_schema.ROUTINES AS R 
            INNER JOIN INFORMATION_SCHEMA.SCHEMATA AS S ON S.SCHEMA_NAME = R.ROUTINE_SCHEMA 
            WHERE S.DEFAULT_COLLATION_NAME = '${MYSQL_COLL_ENCODING}'
            AND DATABASE_COLLATION <> '${MYSQL_COLL_ENCODING}' 
            AND S.schema_name = '${tenant_id}' group by S.schema_name, DATABASE_COLLATION;"

        if [[ (${dry_run} == "no") ]]; then
            date >> ${log_file}
            check_non_mb4_table=$(mysql -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --skip-column-names -e "${non_mb4_table}")
            #echo ${check_non_mb4_table}
                if [[ (${check_non_mb4_table} -gt 0) ]]; then
                echo "Start converting ${tenant_id} tables character set and collation" >> ${log_file}
                errormessage=$(mysql --skip-column-names -u ${user_name} --password=${mysql_pw}  ${tenant_id}  -e "${char_convert_sql}" | mysql -u ${user_name} --password=${mysql_pw} 2>&1 )
                    if [ $? -eq 0 ]; then
                        echo "${tenant_id} table collation migration is successful!" >> ${log_file}
                        echo "All columns of ${tenant_id} had been converted to ${MYSQL_CHAR_ENCODING} and Collation ${MYSQL_COLL_ENCODING}!" >> ${log_file}
                    else 
                        echo "${errormessage}" >> ${log_file}
                        echo "${tenant_id} collation migration failed!" >> ${log_file}   
                    fi   
                fi
                check_non_mb4_proc=$(mysql -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --skip-column-names -e "${check_proc_collation_after}")
                #echo ${check_non_mb4_proc}
                    if [[ (${check_non_mb4_proc} -gt 0) ]]; then
                       mysqldump -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --no-data --no-create-info --single-transaction --routines --set-gtid-purged=OFF ${tenant_id} | grep -v "^ALTER DATABASE.*CHARACTER SET" | sed 's/utf8mb3/utf8mb4/g' > ${tenant_id}_routine.sql
                       mysql -u ${user_name} --password=${mysql_pw} ${tenant_id} <${tenant_id}_routine.sql
                       if [ $? -eq 0 ]; then
                        echo "${tenant_id} routines collation migration is successful!" >> ${log_file}
                        echo "All procedures/function of ${tenant_id} had been converted to ${MYSQL_CHAR_ENCODING} and Collation ${MYSQL_COLL_ENCODING}!" >> ${log_file}
                            rm ${tenant_id}_routine.sql
                       else 
                            echo "${tenant_id} restored routines failed!" >> ${log_file}   
                      fi
                    echo "End at:" >> ${log_file}
                    date >> ${log_file}
                fi
                check_non_mb4=$(mysql -u ${user_name} --password=${mysql_pw} --enable-cleartext-plugin --skip-column-names -e "${non_mb4_sql}")
                #echo ${check_non_mb4}
                if [[ (${check_non_mb4} -gt 0) ]]; then
                   echo "${tenant_id} still has some utf8mb3 collation in db!" >> ${log_file}       
                fi
            
        else 
            echo "Dry Run - DB character set and collation stay no change."
        fi
    else 
        echo "${tenant_id} is already in utf8mb4 characer set and collation." 
        echo "No database items need to be upgraded."
    fi

