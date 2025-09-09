cilium install \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 \
	--set l2announcements.enabled=true \
    --set l2podAnnouncements.interface=enp2s0 \
    --set externalIPs.enabled=false\
    --set nodePort.enabled=false \
	--set ipam.operator.clusterPoolIPv4PodCIDRList="{10.244.0.0/16}" \
    --set ipam.operator.clusterPoolIPv4MaskSize=24
    