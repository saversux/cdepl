# cdepl: A collection of scripts to simplify deployment of distributed applications

cdepl is a collection of scripts creating a framework to simplify deployment of
distributed applications to different (Linux) cluster setups. It creates an 
abstraction layer to the target cluster system for the application to deploy. 
This enables clear separation of the actual hardware to deploy to and the 
application getting deployed.

Different cluster (type) implementations map to specific cluster setups with
their dedicated environments. For example, the *localhost* type maps the 
abstraction layer to your current machine for quick testing or simple debugging 
tasks. If you use the *simple* cluster type, you can deploy to an arbitrary
cluster setup by providing a list of hostnames. Further types handle
environment specific features for each cluster system.

Applications are implemented in separate modules as well. With every application
offering different features and requiring different ways to control it, there
is no unified abstraction layer for them.
However, creating abstractions of tasks like "start app X on node 0" or 
"wait until app startup on node 0 finished" makes it easier to write small
and powerful deploy scripts.

# Features

* Fully bash scripted, using common Linux utilities (no further dependencies, 
not counting the application)
* Cluster abstraction layer supporting different cluster types
* Application abstraction layer to simplify common deployment tasks for the
target application
* Extensible: Write your own cluster or application modules
* Deploy script: Just a bash script with a simple framework but powerful 
environment

# Setup/Requirements

You can run the deployment either on a node of your cluster or even on your
development machine that has access to the cluster. Ssh is used for 
communication and requires passwordless auth to all cluster nodes from your
source machine. Furthermore, the currently implemented cluster types expect
you to have your folder containing your application data as well as the
output folder mounted on all cluster nodes (e.g. nfs).

Bash 4.x is required. All commands used are already installed on common Linux 
distributions.

# Deployment

Documented example (bash) scripts for deployment are available in the 
*examples* folder. 

To deploy, simply execute:
```bash
./cdepl.sh my_deploy_script.cdepl
```

# Writing your own deploy scripts

The *examples/null.cdepl* script is a bare skeleton to get started. It provides
all functions (with documentation) that are required by the framework. To get
an idea of how the deployment is executed, checkout the documented examples.
The examples also include all necessary steps that you have to apply to your
own script, too.

# Cluster modules

If you have a cluster setup that does not match or work with any of the 
currently implemented modules, you can implement your own. The *null* module in
the *cluster* folder contains a skeleton to get started with documentation
of all functions creating the abstraction layer. Checkout the existing 
implementations as well because it's very likely that you can copy/paste code
of the already implemented functions and solved problems.

# Application modules

Application modules do not have to implement a common abstraction layer. 
However, they should provide easy to use functions abstracting common tasks 
necessary for your application deployment, e.g. starting, waiting, shutdown,
error checking, ...
Take a look at the already implemented modules to get an idea of how these
tasks are abstracted.

# License

Copyright (C) 2017 Heinrich-Heine-Universitaet Duesseldorf, 
Institute of Computer Science, Department Operating Systems. 
Licensed under the [GNU General Public License](LICENSE.md).