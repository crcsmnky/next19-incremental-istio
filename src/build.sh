#!/bin/bash

set -e

PROJECT=clown-shoes-3000

for DIR in frontend backend-single backend-multiple; do
    gcloud builds submit --tag gcr.io/${PROJECT}/weather-${DIR}:1.0 --async ${DIR}/
done

gcloud builds submit --tag gcr.io/${PROJECT}/loadgenerator:1.0 --async loadgenerator/
