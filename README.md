# Zero Dependency Framework (ZDF)

[Production/Developer Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tHu000002hDtvIAE)<br />
[Sandbox Install](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tHu000002hDtvIAE)

## About
The Zero Dependencies Framework (ZDF) enables scratch org development in any environment because it reduces the required dependent metadata to deploy code into a scratch org down to zero. This framework solves the most prevalent problem in the Salesforce ecosystem: decoupling dependencies in environments that have many development teams/firms. This allows individuals to carve off small pieces of functionality to deploy to a scratch org without requiring other teams/projects to also adopt it.

## Problem
Dependency management for apex-based applications and limited mocking capabilities on platform makes scratch org development and other CI/CD solutions challenging for large enterprise orgs, especially ones that have been around for several years. Most of these orgs suffer from the following impediments to development
Many sandboxes to keep track of (and the refreshes that must happen)
Slow unit tests (5+ min to run some single unit tests)
Any attempt to do scratch orgs ends up in a black hole of dependencies that keep developers from being able to carve out the needed pieces for just the story/work item they are working on

## Why is this a problem?
Shared environments cause people to overwrite each other’s work, coordinate shared resources, slow down the feedback loop, and give an overall feeling of apprehension to any mistakes made there because it can potentially block your teammates. A fast, safe space to make mistakes leads to learning and innovation across the board.

## Feature Summary
Mockable and StubInvocable – enables mocking/stubbing of individual methods instead of entire instances, including void methods via the StubInvocable <br />

VirtualCallable – as an implementation of the System.Callable interface, it funnels all method calls through the call() method. This enables easy mocking/spying and a common method for interacting with classes in the framework <br />

CallableFactory – centralizes the location and type for retrieving classes, which makes mocking/stubbing entire class dependencies simple and intuitive. A class just needs to implement System.Callable to be useable by the CallableFactory and therefore the rest of the framework <br />

DatabaseService – abstracts the System.Database class away so that database operations are all funneled through one location. This class defaults to user mode and is also accessible from a lwc out of the box. <br />

Record class – enables generic instantiation of records in salesforce, as well as generically allows the user to operate on fields. These two abilities remove the need to have the sObject itself present in the org. There is an idea out there to incorporate this natively into Apex. <br />

Configuration class – centralizes the repetitive structure of custom metadata doing key value pairs. Removes need for custom metadata records to exist in unit tests. <br />

Transaction class – a lift from the apex-common library to facilitate transaction management. In apex-common it is referred to as unit of work, but was renamed here for clarity. <br />

Security Validator- enables securing Apex classes down to the individual method declaratively <br />

## Use this framework if you want to:
- Carve off small pieces of functionality from a large org and deploy to a scratch org
- Take advantage of method-level mocking rather than entire instances
- Reduce compile-time dependencies down to zero
- Leverage a small, lightweight framework with a specific purpose: scratch org enablement
- Play nicely with other frameworks (trigger actions, nebula logger, etc)
- Align with standard Apex Enterprise Patterns:
    - Selector: ZD_DatabaseService
    - Domain: ZD_Record
    - Service: ZD_VirtualCallable
    - Unit of Work: ZD_Transaction


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