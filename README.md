# Post-Install Instructions

1. Install the Ploigos Software Factory Operator

2. Create a PloigosPlatform. **DO NOT CREATE A PLOIGOSPIPELINE**

3. Install Rekor
```
oc create -f https://raw.githubusercontent.com/ploigos/openshift-pipelines-quickstart/main/argo-cd-apps/base/software-supply-chain-platform/rekor.yml
```

4. Rename secret and configmap
 oc get cm -o yaml ploigos-platform-config-mvn > cm.yml
 vi cm.yml # change name to ploigos-platform-config
 oc apply -f cm.yml 
 oc get secret ploigos-platform-config-secrets-mvn -o yaml > secret.yml
 vi secret.yml # change name to ploigos-platform-config-secrets
 oc create -f secret.yml 

5. Change default image to ploigos-tool-maven in TriggerTemplate
oc get tt ploigos-workflow-ref-quarkus-mvn-fruit -o yaml > tt.yml
vi tt.yml 
      - name: workflowWorkerImageDefault
        value: quay.io/ploigos/ploigos-tool-maven:latest
oc create ...

6. Get gitea admin user
oc get secret gitea-admin-credentials -o yaml # get password
echo -n [whatever] | base64 -d # decode password
oc get route gitea

7. Clone demo app
git clone https://gitea-devsecops.apps.cluster-fd74.fd74.sandbox195.opentlc.com/platform/reference-quarkus-mvn.git
git checkout -b feature/demo
git push --set-upstream origin feature/demo

8. Login to gitea and create a PR

9. Create webhook in gitea for demo app
settings -> webhooks -> just like github

10. Install helm chart for everything pipeline
clone ploigos-charts
copy values.yml from this repo to the tekton everything-pipeline directory
helm install -f values.yaml everything-pipeline .

11. Update configmap and secret with new config for generate-evidence

 generate-evidence:
  - name: Generate and Push Evidence
    implementer: GenerateEvidence
    config:
      evidence-destination-url: https://nexus.apps.tssc.rht-set.com/repository/release-engineering-workflow-evidence/
      evidence-destination-username: sa-ploigos-ref-apps
  - name: Sign Evidence
    implementer: RekorSignEvidence
    config:
      rekor-server-url: https://rekor.apps.tssc.rht-set.com/

    generate-evidence:
    -   name: Generate and Push Evidence
        implementer: GenerateEvidence
        config:
            evidence-destination-password: [whatever]


1. Update configmap and secret with new config for audit-attestation

  audit-attestation:
  - name: Audit Attestation DEV
    implementer: OpenPolicyAgent
    environment-config:
      DEV:
        workflow-policy-uri: https://raw.githubusercontent.com/ploigos/ploigos-example-autogov-content/main/workflow-policy-dev.rego
      TEST:
        workflow-policy-uri: https://raw.githubusercontent.com/ploigos/ploigos-example-autogov-content/main/workflow-policy-test.rego
      PROD:
        workflow-policy-uri: https://raw.githubusercontent.com/ploigos/ploigos-example-autogov-content/main/workflow-policy-prod.rego


1. Update pgp private key for signing evidence
PKEY=$(sops -d ~/ploigos/demo/reference-quarkus-mvn/cicd/ploigos-integration-environment/tekton/everything/ploigos-step-runner-config/shared-config/config-secrets.yml  | yq .step-runner-config.global-defaults.signer-pgp-private-key)
cat platform-config-secret.yml | yq ".step-runner-config.global-defaults.signer-pgp-private-key = \"$PKEY\"" > /tmp/platform-config-secret.yml
oc create secret generic ploigos-platform-config-secrets-hack --from-file /tmp/platform-config-secret.yml


1. Remove ConfigLint step implementer from checked-in config.yml
yq -i 'del(.step-runner-config.validate-environment-configuration)' cicd/ploigos-software-factory-operator/ploigos-step-runner-config/config.yml
git commit -am "Remove ConfigLint StepImplementer"
git push


1. Update rekor url
 oc get cm -o yaml ploigos-platform-config-hack > ploigos-platform-config-hack.yml
replace 
          rekor-server-url: https://rekor.apps.tssc.rht-set.com/
with 
          rekor-server-url: https://rekor-server.sigstore.srv.cluster.local:3000/
oc apply -f ploigos-platform-config-hack.yml

