# Deploying LaMachine on Kubernetes

You can easily deploy LaMachine Docker containers on a Kubernetes cluster. This
directory contains several templates you can use to accomplish this. Basic familiarity with both Docker and Kubernetes is assumed.

* ``Dockerfile`` - A template Dockerfile for a personalised LaMachine image, in this Dockerfile we configure LaMachine for a specific deployment, and optionally configure some extra software.

After adapting this template, you can run ``docker build .`` in the directory containing your Dockerfile. Push your image to an image registry (e.g. Docker Hub) to make it available to Kubernetes.

* ``deployment.yml`` - A kubernetes deployment template for LaMachine.
* ``ingress.yml`` -  This manages external access to services in a cluster.
* ``service.yml`` - This sets up a HTTP service for LaMachine.

We assume the entire service to be behind a reverse proxy that takes care of HTTPS, so the kubernetes service we set up here is merely HTTP.

Apply these using: ``kubectl apply -f deployment.yml ingress.yml service.yml``

If you have a kubernetes pod running using LaMachine, and you want a shell on it, you can do something like:

``kubectl exec lamachine-deployment-7569cd44b8-gdm7s -t -i -- bash -l``
