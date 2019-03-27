# Next 19: Incremental Istio

This repo contains a series of demos/tutorials as part of [Next 19: HYB102 Incrementally Adopting Istio](https://cloud.withgoogle.com/next/sf/sessions?session=HYB102).

## Setup

First, create a Kubernetes cluster with Istio pre-installed (and set `auth=MTLS_PERMISSIVE`):
```
gcloud beta container clusters create inc-istio \
    --addons=Istio --istio-config=auth=MTLS_PERMISSIVE \
    --cluster-version=latest --machine-type=n1-standard-2 \
    --num-nodes=4  --enable-stackdriver-kubernetes
```

Next, grab the cluster credentials and create some namespaces (`traffic`, `security`, `legacy`) we'll use later on:
- `gcloud container clusters get-credentials inc-istio`
- `for NS in traffic security legacy; do kubectl create ns $NS; done`

For our sample app [weatherinfo](https://github.com/crcsmnky/weatherinfo) you'll need to make sure
- The container images are in your project
- You've created the necessary secrets in your cluster

Go clone that repo, build the images, and create the secret. Then come back here and continue. 

*Note* you will need to create the `openweathermap` in each namespace (`traffic`, `security`, `legacy`).

## Traffic Management

Now that you're setup, let's try using an incremental approach for adopting Istio for some basic traffic management. 

*Note* we are **not** auto-injecting the sidecar `istio-proxy` at this time, that will come later.

To start, deploy the `weatherinfo` app:
- `kubectl apply -n traffic -f manifests/weather-deployment.yaml`

Confirm that worked by forwarding the `weather-frontend` port and opening a browser to [http://localhost:5000](http://localhost:5000) and hitting Refresh a few times - you should see a 50/50 split between `weather-backend-single` and `weather-backend-multiple`:
- `kubectl port-forward -n traffic deployment/weather-frontend 5000`

Next, apply traffic rules to do a 90/10 split between `weather-backend-single` and `weather-backend-multiple`:
- `kubectl apply -n traffic -f traffic/weather-backend-rules.yaml`

Now, you'll need to update the `weather-frontend` deployment to use `istio-ingressgateway` as the backend, instead of `weather-backend`:
- `kubectl apply -n traffic -f traffic/weather-deployment-ingressgateway.yaml`

Finally, restart that port-forwarding from before so you can see `weather-frontend` now using the 90/10 split we specified via [http://localhost:5000](http://localhost:5000):
- `kubectl port-forward -n traffic deployment/weather-frontend 5000`

**Note** the approach we've used here is for demonstration purposes. In production environments you'd want to take great care before exposing backend services through the `istio-ingressgateway` using additional configuration parameters in your `Gateway` and `VirtualService` rules.

## Security

Now let's incrementally deploy mutual TLS authentication between our Pods. First, start by updating the `secure` namespace to auto-inject `istio-proxy`:
- `kubectl label ns secure istio-injection=enabled`

Next, deploy the `Gateway`, `VirtualService`, `DestinationRule`, and `ServiceEntry` objects that will setup our `weatherinfo` app, and then deploy the app itself:
- `kubectl -n secure apply -f security/weather-rules.yaml`
- `kubectl -n secure apply -f manifests/weather-deployment.yaml`

Now let's start the incremental mTLS rollout. The first step is to set `weather-backend` into `PERMISSIVE` mode. This mode allows clients that **can** do mTLS to use it, and allows clients that **cannot** use mTLS to continue without it:
- `kubectl -n secure apply -f security/mtls-backend-permissive.yaml`

Next activate mTLS between `weather-frontend` and `weather-backend`:
- `kubectl -n secure apply -f security/mtls-backend-mutual.yaml`

So now, inside of your deployment, all services are using mTLS to authenticate. But what about legacy clients? Deploy a simple Pod to the `legacy` namespace and we can test out what happens:
- `kubectl apply -n legacy -f security/sleep.yaml`
- `SLEEP=$(kubectl get pod -n legacy -l app=sleep -o jsonpath="{.items..metadata.name}")`

Then `exec` into that Pod and run some `curl` commands to confirm non-mTLS clients still work:
- `kubectl exec -n legacy -it $SLEEP /bin/bash`
- `curl http://weather-backend.secure:5000/api/weather`

Finally, update the `Policy` to `STRICT` mode, meaning only mTLS-enabled services can talk to `weather-backend`:
- `kubectl apply -f security/mtls-backend-strict.yaml`

Go back and try the `exec` and `curl` commands again, and you'll see that you can't connect to the `weather-backend` any longer from a Pod without `istio-proxy`.

## Telemetry
- TODO
