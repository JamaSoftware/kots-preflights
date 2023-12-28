#!/bin/bash

# Function to log messages
log() {
    echo "[INFO] $1"
}

# Function to log error messages
logError() {
    echo "[ERROR] $1"
}

# Function to annotate the TenantFS PVC
annotate_pvc() {
    local tenantfs_sc=$(kubectl get pvc/tenantfs -o=jsonpath='{.spec.storageClassName}')
    if [ "$tenantfs_sc" != "longhorn" ]; then
            log "The tenantfs pvc will not be annotated since its storage class is $tenantfs_sc"
            return
    fi

    log "Annotating the TenantFS PVC to allow an access mode change during migration..."
    kubectl annotate pvc tenantfs kurl.sh/pvcmigrate-destinationaccessmode='ReadWriteOnce' --overwrite=true
    if [ $? -eq 0 ]; then
        log "Successfully annotated the TenantFS PVC."
    else
        logError "Failed to annotate the TenantFS PVC."
        exit 1
    fi
}

# Function to delete Oauth and Saml volumes to avoid issues during the process
delete_unused_pvc() {
    kubectl delete sts/saml sts/oauth
    kubectl delete pvc/volume-saml-0 pvc/volume-oauth-0
}

# Function to update Longhorn volume replicas
update_replicas() {
    local namespace="longhorn-system"
    local default_replicas=3
    # Check the number of nodes in the cluster
    local node_count=$(kubectl get nodes --no-headers | wc -l)

    if [ "$node_count" -ge "$default_replicas" ]; then
        log "There are $node_count nodes in the cluster. Will not scale down Longhorn volume replicas"
        return
    fi

    log "Fetching Longhorn volumes in the $namespace namespace..."
    local volumes=$(kubectl get volumes -n $namespace -o=jsonpath='{range .items[*]}{.metadata.name}{" "}{end}')

    local replicas=$node_count
    log "Updating spec.numberOfReplicas to $replicas for each volume..."
    for volume in $volumes; do
        kubectl patch volume $volume -n $namespace --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/numberOfReplicas\", \"value\": $replicas}]"
        if [ $? -eq 0 ]; then
            log "Successfully updated volume $volume."
        else
            logError "Failed to update volume $volume."
        fi
    done
}

# Function to remove stopped Longhorn replicas
remove_unscheduled_replicas() {
    log "Removing unscheduled Longhorn replicas..."
    kubectl get replicas -n longhorn-system -o=jsonpath='{range .items[?(@.spec.nodeID=="")]}{.metadata.name}{"\n"}' | xargs kubectl delete replicas -n longhorn-system || true
    log "All unscheduled Longhorn replicas have been removed."
}

# Function to remove pods in shutdown status to avoid upgrade issues
# if the cluster has been restarted and there are shutdown Longhorn pods
remove_shutdown_pods() {
    local namespace="longhorn-system"
    log "Removing Longhorn pods in shutdown status."
    kubectl get pods -n $namespace | grep Shutdown | awk '{print $1}' | xargs kubectl delete pod -n $namespace || true
    log "All Longhorn pods in shutdown status have been removed."
}

delete_unused_pvc
annotate_pvc
update_replicas
remove_unscheduled_replicas
remove_shutdown_pods