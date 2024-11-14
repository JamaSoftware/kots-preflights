#!/bin/bash
tenant_db="all"
host_ip="127.0.0.1"
port_num=3306

os=$(uname -s)
arch=$(uname -m)

cleanup(){
	if [ -f /tmp/LICENSE ]
	then
		rm /tmp/LICENSE
	fi
	if [ -f /tmp/README.md ]
	then
		rm /tmp/README.md
	fi
	if [ -f /tmp/key.pub ]
	then
		rm /tmp/key.pub
	fi
	if [ -f /tmp/troubleshoot-sbom.tgz ]
	then
		rm /tmp/troubleshoot-sbom.tgz*
	fi
	if [ -f /tmp/preflight ]
	then
		rm /tmp/preflight*
	fi
	if [ -f /tmp/support-bundle ]
	then
		rm /tmp/support-bundle*
	fi

	rm -Rf /tmp/airgap-database-preflight_linux

}


supportbundle_linux_os_x86_64(){
	echo "Analyzing requirements for Jama KOTS on Linux x86_64..."
	tar zxf airgap-database-preflight_linux.tar.gz -C /tmp
	tar zxf /tmp/airgap-database-preflight_linux/support-bundle/support-bundle_linux_amd64.tar.gz -C /tmp
	/tmp/support-bundle /tmp/airgap-database-preflight_linux/database-preflight.yml
	cleanup
}

supportbundle_linux_os_arm64(){
	echo "Analyzing requirements for Jama KOTS on Linux arm64..."
	tar zxf airgap-database-preflight_linux.tar.gz -C /tmp
	tar zxf /tmp/airgap-database-preflight_linux/support-bundle/support-bundle_linux_arm64.tar.gz -C /tmp
	/tmp/support-bundle /tmp/airgap-database-preflight_linux/database-preflight.yml
	cleanup
}



supportbundle(){

  export TMP_USERNAME=$user_name
  export TMP_PASS=$mysql_pw
  export TMP_TENANTID=$tenant_db
  export TMP_HOSTIP=$host_ip
  export TMP_PORTNUM=$port_num

	if [ "$os" == "Linux" ] && [ "$arch" == "x86_64" ]
	then
		supportbundle_linux_os_x86_64
	elif [ "$os" == "Linux" ] && ([ "$arch" == "arm64"] || [ "$arch" == "aarch64" ])
	then
		supportbundle_linux_os_arm64
	elif [ "$os" == "Darwin" ] && ([ "$arch" == "arm64" ] || [ "$arch" == "aarch64" ])
	then
		supportbundle_macos_arm64
	elif [ "$os" == "Darwin" ] && [ "$arch" == "x86_64" ]
	then
		supportbundle_macos_x86_64
	fi
}


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
    echo "    -i: remote server ip address"
    echo "    -o: port number"
    echo "    -h: help"
    echo "    Execution as: "
    echo "      ./airgap-database-server_linux.sh -t <tenant_db> -i <host_ip> -o <port_num> -u <db_user> -p <db_password>"
}

if [[ $1 == "help" ]]; then
    print_help
    exit 1
fi

#echo "The arguments passed in are : $@"

while getopts t:u:p:i:o:h option
do
    case "${option}"
        in
        t)tenant_db=${OPTARG};;
        u)user_name=${OPTARG};;
        p)mysql_pw=${OPTARG};;
        i)host_ip=${OPTARG};;
        o)port_num=${OPTARG};;
        h)print_help && exit 1;; # Print helpFunction in case parameter is non-existent
    esac
done

if [ -z $user_name ] ; then
  echo "ERROR: $0 requires user name and pw as args."
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



supportbundle
