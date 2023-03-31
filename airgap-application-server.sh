#!/bin/bash

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
	if [ -f /tmp/airgap-host-preflight ]
	then
		rm /tmp/airgap-host-preflight*
	fi

}


supportbundle_linux_os_x86_64(){
	echo "Analyzing requirments for Jama KOTS on Linux x86_64..."
	tar zxf airgap-host-preflight.zip -C /tmp
	tar zxf /tmp/airgap-host-preflight/support-bundle/support-bundle_linux_amd64.tar.gz -C /tmp
	/tmp/support-bundle /tmp/airgap-host-preflight/host-preflight.yml
	cleanup
}

supportbundle_linux_os_arm64(){
	echo "Analyzing requirments for Jama KOTS on Linux arm64..."
	tar zxf airgap-host-preflight.zip -C /tmp
	tar zxf /tmp/airgap-host-preflight/support-bundle/support-bundle_linux_arm64.tar.gz -C /tmp
	/tmp/support-bundle /tmp/airgap-host-preflight/host-preflight.yml
	cleanup
}

supportbundle_macos_arm64(){
	echo "Analyzing requirments for Jama KOTS on macOS arm64..."
	tar zxf airgap-host-preflight.zip -C /tmp
	tar zxf /tmp/airgap-host-preflight/support-bundle/support-bundle_darwin_arm64.tar.gz -C /tmp
	/tmp/support-bundle /tmp/airgap-host-preflight/host-preflight.yml
	cleanup
}

supportbundle_macos_x86_64(){
	echo "Analyzing requirments for Jama KOTS on macOS x86_64..."
	tar zxf airgap-host-preflight.zip -C /tmp
	tar zxf /tmp/airgap-host-preflight/support-bundle/support-bundle_darwin_amd64.tar.gz -C /tmp
	/tmp/support-bundle /tmp/airgap-host-preflight/host-preflight.yml
	cleanup
}


supportbundle(){
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

supportbundle