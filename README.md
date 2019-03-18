# Next 19: Incremental Istio

## Setup
- Create cluster(s) with Istio set to MTLS_PERMISSIVE
- `gcloud beta container clusters create inc-istio --addons=Istio --istio-config=auth=MTLS_PERMISSIVE --cluster-version=latest --machine-type=n1-standard-2 --num-nodes=4 --async --enable-stackdriver-kubernetes`
- `kubectl create namespace` for traffic, security, legacy
- `kubectl create secret generic openweathermap --from-literal=apikey=[YOUR OWM API KEY]` for traffic, security, legacy, default

## Traffic Management
- No sidecar injection

- `kubectl apply -f kubernetes/deployment.yaml`
- Confirm `kubectl port-forward deployment/weather-frontend 5000:5000`

- `kubectl apply -n traffic -f istio/traffic/ingressgateway-backend.yaml`
- `kubectl apply -n traffic -f istio/traffic/deployment-ingressgateway.yaml`
- Confirm `curl http://INGRESSGATEWAY_IP/api/weather`
- Confirm `kubectl port-forward -n traffic deployment/weather-frontend 5000:5000`

## Security
- `kubectl label ns secure istio-injection=enabled`
- `kubectl -n secure apply -f istio/security/services-rules.yaml`
- `kubectl -n secure apply -f kubernetes/deployment.yaml`
- `kubectl -n secure apply -f istio/security/mtls-backend-permissive.yaml`
- `kubectl -n secure apply -f istio/security/mtls-mutual.yaml`
- Use `curl` from `sleep` Pod to show that legacy clients can still connect to API
- `kubectl apply -f istio/security/mtls-backend-strict.yaml`
- Use `curl` from `sleep` Pod to show that legacy clients cannot connect to API


## Telemetry
- 

## Load Generator
- 