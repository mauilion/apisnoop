# TL;DR files

A brief description of key files in this repo and what they do

## cmd/tproxy-initializer/main.go

### what it does

#### main()
- loads in cluster config
- sets up kubernetes api client
- loads initializer configmap
- list and watch unitialized deployments across all namespaces
- override watchlist to set options.IncludeUninitialized to true
- setup an informer that calls initializeDeployment when new pods are added
- run the informer with a signal to stop it at a later time
- wait for a signal telling the program to stop (ie keyboard interrupt)
- tell the informer to stop
- exit

#### initializeDeployment()
- if there are no initializers for the deployment, return
- get the pending initializers for the deployment -- possibly returns empty set?
- if first pending initializers name is the tproxy initializer, return -- bug?
- deep copy the deployment object (hereby known as 'the working copy')
- remove initializer from pending set
- if an annotation is required, check for annotation on deployment. if it is
  not found then update the deployment with the initializer removed and return
- inject volume mounts and env vars from configmap into each container in the working copies template
- inject init containers defined in initializer configmap into the working copies template
- inject volumes defined in configmap into the working copies template
- set tproxy annotation to true in working copies template
- convert the deployment object and the working copy into json using json.Marshal
- create a patch to change the deployment object to working copy
- patch the running deployment using the kubernetes api and the patch

### Notes

- Config map is important - its where all the things that are injected live
- Injects volume mounts, env vars, init containers, and volumes
- Can set annotation name, config map name and namespace here
- Possibly a couple of bugs possible?

##  charts/tproxy/templates/initializer-configmap.yaml

### what it does

- injects only the container 'sidecar'
- volumes and volume mounts are used for injecting mitm certs into the ca certs dir
- injects the `http_proxy` and `https_proxy` env vars, but only when addStandardModeProxy is true (default false) 

## cmd/tproxy-podwatch/main.go

### what it does

#### main()
- watches for pods and adds them to a work queue

#### syncFirewall()
- basically synchronizes our firewall rules
- in our case its creating an iptables rule that is redirecting traffic going to 
  kubernetes api server host and port to mitmproxy container running on the same
  pod


## sidecar

### what it does
- adds some more iptables rules - nothing related though?

## mitmproxy/mitmproxy:3.0.3

- stock upstream container
- bundled into same pod as podwatch
