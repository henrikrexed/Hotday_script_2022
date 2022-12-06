# Hotday 2022 deployment script

This repository will contains all the scripts to deploy the training environment for Hotday
This repository is based on 2 popular Demo platform provided  :
- The Online Boutique
- Otel-demo

**Online Boutique** is a cloud-native microservices demo application.
Online Boutique consists of a 10-tier microservices application. The application is a
web-based e-commerce app where users can browse items,
add them to the cart, and purchase them.
The Google HipsterShop is a microservice architecture using several langages :
* Go 
* Python
* Nodejs
* C#
* Java


## Prerequisite
The following tools need to be install on your machine :

- jq
- kubectl
- git
- helm

## Getting started locally
### 1. Dynatrace Tenant - start a trial
If you don't have any Dyntrace tenant , then i suggest to create a trial using the following link : [Dynatrace Trial](https://bit.ly/3KxWDvY)
Once you have your Tenant save the Dynatrace (including https) tenant URL in the variable `DT_TENANT_URL` (for example : https://dedededfrf.live.dynatrace.com)
```
DT_TENANT_URL=<YOUR TENANT URL>
```


### 2. Create the Dynatrace API Tokens
The dynatrace operator will require to have several tokens:
* Token to deploy and configure the various components
* Token to ingest metrics and Traces

#### Token to deploy
Create a Dynatrace token ( left menu Access TOken/Create a new token), this token requires to have the following scope:
* Create ActiveGate tokens
* Read entities
* Read Settings
* Write Settings
* Access problem and event feed, metrics and topology
* Read configuration
* Write configuration
* Paas integration - installer downloader
* ingest metrics
* ingest logs
* ingest OpenTelemetry traces
```
DATA_INGEST_TOKEN=<YOUR TOKEN VALUE>
ENVIRONMENT_URL=<DT TENANT url without https>
```

## run the deployment script
```
chmod 777 deployment.sh
./deployment.sh --environment-url "$ENVIRONMENT_URL" --api-token "$DATA_INGEST_TOKEN"
```



