#!/bin/bash

os=$(uname -s)
arch=$(uname -m)

current_version="_0.0.1"

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
	if [ -f /tmp/airgap-host-preflight_linux ]
	then
		rm /tmp/airgap-host-preflight_linux*
	fi

}


supportbundle_linux_os_x86_64(){
	echo "Analyzing requirments for Jama KOTS on Linux x86_64..."
	tar zxf airgap-host-preflight_linux$current_version.tar.gz -C /tmp
	tar zxf /tmp/airgap-host-preflight_linux/support-bundle/support-bundle_linux_amd64.tar.gz -C /tmp
	/tmp/support-bundle /tmp/airgap-host-preflight_linux/host-preflight.yml
	cleanup
}

supportbundle_linux_os_arm64(){
	echo "Analyzing requirments for Jama KOTS on Linux arm64..."
	tar zxf airgap-host-preflight_linux$current_version.tar.gz -C /tmp
	tar zxf /tmp/airgap-host-preflight_linux/support-bundle/support-bundle_linux_arm64.tar.gz -C /tmp
	/tmp/support-bundle /tmp/airgap-host-preflight_linux/host-preflight.yml
	cleanup
}




supportbundle(){
	if [ "$os" == "Linux" ] && [ "$arch" == "x86_64" ]
	then
		supportbundle_linux_os_x86_64
	elif [ "$os" == "Linux" ] && ([ "$arch" == "arm64"] || [ "$arch" == "aarch64" ])
	then
		supportbundle_linux_os_arm64
	fi
}

supportbundle