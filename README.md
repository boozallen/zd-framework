# basebah-poc

## Commands
```
sfdx force:org:create -f config/project-scratch-def.json -a <YOUR ALIAS NAME>
```
```
sfdx force:source:deploy -p "force-app/common/" -u <YOUR ALIAS NAME>
```
```
sfdx force:source:deploy -p "force-app/demo-app/main/default/classes/services" -u <YOUR ALIAS NAME>
```
```
sfdx force:apex:test:run --classnames "SampleServiceTest" --resultformat human -u <YOUR ALIAS NAME>
```