# Zero Dependency Framework

[Production/Developer Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tHu000002hCg4IAE)
[Sandbox Install](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tHu000002hCg4IAE)

## Commands
```
sf org create scratch -f config/project-scratch-def.json -a <YOUR ALIAS NAME>
```
```
sf project start deploy -d force-app -o <YOUR ALIAS NAME>
```
```
sf run apex test --test-level "RunLocalTests" --result-format human --code-coverage -w 2 -o <YOUR ALIAS NAME>
```