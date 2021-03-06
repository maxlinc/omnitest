# Crosstest - the polyglot testing tool

Crosstest is a tool from running tests and other tasks across a set of related projects. It's a tool for polyglots - the tests and tasks can be written in any language, using any tool. Crosstest may be useful for:
- Testing a set of related open-source projects (e.g. a set of plugins for a framework)
- Teams working on microservices or other sets of small projects
- Testing tools, SDKs or API bindings that have been ported to several programming languages

Crosstest can be used as a tool to run unrelated tests in each project, but it can also be used to build a compliance suite for projects that
are expected to implement the same features, like an SDK that has been ported to multiple programming languages. In those cases corsstest can
be used to build a compatibility test suite across the projects, including reports that compare the working features and detected behavior.

Crosstest was influenced by a number of polyglot projects, including [Travis-CI](travis-ci.org), [Docco](https://github.com/jashkenas/docco), [Slate](https://github.com/tripit/slate), and polyglot test-suites like the [JSON Schema Test Suite](https://github.com/json-schema/JSON-Schema-Test-Suite) and the [JSON-LD Test Suite](http://json-ld.org/test-suite/).

A lot of the crosstest implementation was influenced by [test-kitchen](http://kitchen.ci/), because in many ways crosstest is attempting to do for cross-project testing what test-kitchen does for cross-platform testing.

## Overview

Crosstest provides three main tools that work across projects:
- crosstask: Run a task or workflow in every project, even if they each project uses different languages and tools
- crosstest: Test code samples in each project against a common set of criteria
- crossdoc: Convert annotated code samples to lightweight markup documentation

## Installing Crosstest

Crosstest is distributed as a Ruby Gem. It is ideally installed using Bundler by adding this line to your Gemfile:

```shell
gem 'crosstest', '~> 0.1'
```

And then running `bundle install`.

It can also be installed without Bundler by running `gem install crosstest`.

**Note**: If installed with bundler it's best to always run `bundle exec crosstest ...` rather than just `crosstest ...`. The bundler documentation explains:

> In some cases, running executables without `bundle exec` may work, if the executable happens to be installed in your system and does not pull in any gems that conflict with your bundle.
>
> However, this is unreliable and is the source of considerable pain. Even if it looks like it works, it may not work in the future or on another machine.

## Defining a project set

You need to define a set of projects so crosstest can run tasks or tests across them. This is done with a `crosstest.yaml` file. The file defines the
name and location of each project, optionally including version control information.

Here's an example that defines projects named "ruby", "java" and "python":

```yaml
---
  projects:
    ruby:
      language: 'ruby'
      basedir: 'sdks/ruby'
      git:
        repo: 'https://github.com/crosstest/ruby_samples'
    java:
      language: 'java'
      basedir: 'sdks/java'
      git:
        repo: 'https://github.com/crosstest/java_samples'
    python:
      language: 'python'
      basedir: 'sdks/python'
      git:
        repo: 'https://github.com/crosstest/python_samples'
```

## Getting the projects

Crosstest needs to have a copy of the project before it can run any tasks or tests. If you already have the projects locally and configured
the `basedir` of each project to point to the existing location you can move on to the next step. If you don't have the projects locally but
configured the git repo then you can fetch them with the `crosstest clone` command.

```sh
$ bundle exec crosstest clone
-----> Starting Crosstest (v0.2.0)
       Cloning: git clone https://github.com/crosstest/ruby_samples -b master /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/ruby
       Executing git clone https://github.com/crosstest/ruby_samples -b master /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/ruby
       Cloning into '/Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/ruby'...
       Cloning: git clone https://github.com/crosstest/java_samples -b master /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java
       Executing git clone https://github.com/crosstest/java_samples -b master /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java
       Cloning into '/Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java'...
       Cloning: git clone https://github.com/crosstest/python_samples -b master /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/python
       Executing git clone https://github.com/crosstest/python_samples -b master /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/python
       Cloning into '/Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/python'...
-----> Crosstest is finished. (0m1.12s)
```

### Project groups

Most crosstest commands accept an argument that specifies to which projects you want to send the command. If omitted then the command is sent to all projects, but you can also specify a single project by name or a regular expression to select projects. You can also specify "all", which is the same behavior as not specifying any argument, but is neccessary if you want to supply additional arguments.

So in the example above you could use:
```sh
$ bundle exec crosstest clone ruby
# Just clones the ruby projct
$ bundle exec crosstest clone "(ruby|java)"
# Clones both ruby and java
$ bundle exec crosstest clone "*-plugin"
# Clones any projects with -plugin in their name
```

Coming soon...

There will likely be a feature added in the near future to explicitly define groups in the crosstest.yaml file, so that you can select projects based on a group name like "plugins" or "frontend" rather than using a regular expression.

## Crosstasking (via Psychic)

Crosstest needs to be able to run tasks in any of the projects before it can run tests. Crosstest uses [psychic](https://github.com/crosstest/psychic), to run tasks. Psychic creates a uniform interface for running similar tasks in different projects, delegating to project specific task runners (like Rake, Make, npm run, or gradle) when necessary.

The first task you probably want to run is `bootstrap` in order to make sure the projects project is ready to test. Generally the `bootstrap` task will invoke a dependency manager like Bundler, npm, or pip.

```sh
$ bundle exec crosstest bootstrap
-----> Starting Crosstest (v0.2.0)
-----> Bootstrapping ruby
       Executing bundle install
       Resolving dependencies...
       Your bundle is complete!
       Use `bundle show [gemname]` to see where a bundled gem is installed.
-----> Bootstrapping java
       Executing mvn clean install
       :compileJava UP-TO-DATE
       :processResources UP-TO-DATE
       :classes UP-TO-DATE
       :jar
       :assemble
       :compileTestJava UP-TO-DATE
       :processTestResources UP-TO-DATE
       :testClasses UP-TO-DATE
       :test UP-TO-DATE
       :check UP-TO-DATE
       :build

       BUILD SUCCESSFUL

       Total time: 4.4 secs
```

### Custom tasks

There are a few default tasks like `bootstrap` that are built into crosstest (and psychic). The default tasks exist to match common test workflows (like the Travis-CI stages or Maven lifecycle), but you can also have crosstest invoke custom tasks.

So you could tell crosstest to invoke custom tasks like `documentation`, `metrics`, `lint` or `gitstats`:

```sh
$ bundle exec crosstest task lint
-----> Starting Crosstest (v0.2.0)
-----> Running task lint for ruby
       Executing bundle exec rubocop -D
       warning: parser/current is loading parser/ruby21, which recognizes
       warning: 2.1.5-compliant syntax, but you are running 2.1.4.
       Inspecting 2 files
       ..

       2 files inspected, no offenses detected
-----> Running task lint for java
       Executing gradle checkstyleMain
       :compileJava UP-TO-DATE
       :processResources UP-TO-DATE
       :classes UP-TO-DATE
       :checkstyleMain[ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/HelloWorld.java:0: Missing package-info.java file.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/HelloWorld.java:1: Line is longer than 100 characters (found 101).
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/HelloWorld.java:3: Missing a Javadoc comment.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:1: Missing a Javadoc comment.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:2:1: warning: '{' should be on the previous line.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:4:3: warning: '{' should be on the previous line.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:24: warning: 'for' construct must use '{}'s.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:24:8: 'for' is not followed by whitespace.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:24:30: warning: ')' is preceded with whitespace.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:26: warning: 'for' construct must use '{}'s.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:26:8: 'for' is not followed by whitespace.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:27:28: warning: '(' is followed by whitespace.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:27:54: warning: ')' is preceded with whitespace.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:28: warning: 'for' construct must use '{}'s.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:28:8: 'for' is not followed by whitespace.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:29:28: warning: '(' is followed by whitespace.
       [ant:checkstyle] /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/src/main/java/Quine.java:29:33: warning: ')' is preceded with whitespace.
        FAILED

       FAILURE: Build failed with an exception.

       * What went wrong:
       Execution failed for task ':checkstyleMain'.
       > Checkstyle rule violations were found. See the report at: file:///Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/java/build/reports/checkstyle/main.xml

       * Try:
       Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output.

       BUILD FAILED

       Total time: 4.904 secs
-----> Running task lint for python
       Executing ./scripts/lint.sh
       New python executable in crosstest_python/bin/python
       Installing setuptools, pip...done.
       katas/hello_world.py:2:22: W292 no newline at end of file
       katas/quine.py:2:8: E228 missing whitespace around modulo operator
-----> Crosstest is finished. (0m8.49s)
```

This is equivalent to running `psychic task lint` in each directory. See [psychic](https://github.com/crosstest/psychic) for more details about how psychic decides what command to invoke for any given task.

### Workflows

Coming soon....

A workflow is a group of tasks that you want to run together on each project.

The "commit test" workflow is the most common. This is basically a workflow that runs all the tests and checks that should be run before commiting a change. The [Travis-CI lifecycle](http://docs.travis-ci.com/user/build-lifecycle/) and [Maven Lifecycle](http://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html) (excluding the "deploy" stage in both cases) are examples.

Another workflow I've seen is the "morning" workflow. This workflow makes sure each of the projects are ready to start development. This is often similar to a "commit test" workflow, but it will also make sure you have a clean development environment, have fetched the latest upstream changes (from both version control and dependency management systems).

Another possibility would be a "end of sprint" or "pre-release" workflow. This could be very different than the two examples above. It may focus on collecting metrics or building and publishing release notes.

## Crosstesting (via Skeptic)

The `crosstest test` command will run tests in each project, using spies to capture data and validate the behavior. Currently this is used for testing code samples in each project, and crosstest will capture the exit code, stdout and stderr. You can register additional "spies" with skeptic in order to capture additional information or perform additional validation. For example, there are spies that use the [Pacto](https://github.com/thoughtworks/pacto) project to capture HTTP requests and compare them with the RESTful services that were expected to be called for the scenario.

### Defining test scenarios

The `suites` section of crosstest.yaml defines the tests you want to run. The suites contain scenarios ("samples") and default properties to use as input while testing the code samples ("global_env" and "env" within suites).

```yaml
  global_env:                          # global_env defines input available for all scenarios
    LOCALE: <%= ENV['LANG'] %>         # templating is allowed
  suites:
    Katas:                             # "Katas" is the name of the first test suite
      samples:                         # Test scenarios within Katas
        - hello world
        - quine
    Environment:
      env:                             # Unlike global_env, these variables are only for the Katas suite
        COLOR: red
      samples:
        - echo_color
```

### Executing tests

The command `crosstest test` executes tests. It has two optional arguments:
- The first argument selects which projects you want to test, and works exactly the same as described in the crosstasking section.
- The second argument selects which scenarios you want to test. This is similar to selecting projects but works on scenarios. You can specify either an exact scenario name, a suite name, or a regular expression.

So you could run:

```sh
$ bundle exec crosstest test
# Tests everything
$ bundle exec crosstest test ruby "hello world"
# Only tests the "hello world" scenario for the "ruby" project
$ bundle exec crosstest test all "quine"
# Tests the "quine" scenario in all projects

### Reports

The test results are persisted (in the `.crosstest/` folder) so you don't need to run all the tests at once. This way you could test just one project at a time but still get a report showing the results for *all* projects when you're done. This is especially useful if you want to run the tests in parallel on different machines (on a CI server or using Vagrant).

Crosstest gives you a few different ways to view results.

#### List

The `crosstest list` command will give you an overview of the results as table. The default behavior is to display it as a colorized ASCII table, but you can use the `--format` flag to choose additional output formats like YAML or JSON. This is just a quick summary showing the result of testing each scenario:

```sh
$ bundle exec crosstest list
Test ID                        Suite        Scenario     Project  Status
katas-hello_world-ruby         Katas        hello world  ruby     Partially Verified (1 of 2)
katas-hello_world-java         Katas        hello world  java     Partially Verified (0 of 2)
katas-hello_world-python       Katas        hello world  python   Partially Verified (0 of 2)
katas-quine-ruby               Katas        quine        ruby     <Not Found>
katas-quine-java               Katas        quine        java     Partially Verified (0 of 2)
katas-quine-python             Katas        quine        python   Partially Verified (0 of 2)
environment-echo_color-ruby    Environment  echo_color   ruby     <Not Found>
environment-echo_color-java    Environment  echo_color   java     <Not Found>
environment-echo_color-python  Environment  echo_color   python   <Not Found>
```

#### Show

The `crosstest show` command will display much more detailed results for one or more test scenarios.

```sh
 bundle exec crosstest show python "hello world"

katas-hello_world-python:             Partially Verified (0 of 2)
  Test suite:                           Katas
  Test scenario:                        hello world
  Project:                              python
  Source:                               sdks/python/katas/hello_world.py
  Execution result:
    Exit Status:                          0
    Stdout:
    Stderr:
  Validations:
    Hello world validator:                x Failed
      Error message:
expected: "Hello, world!\n"
     got: ""

(compared using ==)

Diff:
@@ -1,2 +1 @@
-Hello, world!

    default validator:                    x Failed
      Error message:                        expected "" to end with "\n"
  Data from spies:
```

#### Dashboard

The command `crosstest generate dashboard` will an HTML dashboard with several reports. The default dashboard is described below, but the dashboard is built withtemplate can be customized and extended by writing a [Thor generator](https://github.com/erikhuda/thor/wiki/Generators).

The default dashboard will produce a "feature matrix" that is similar to the `crosstest list` command, but is sortable/filterable and where each result is linked to a detailed report that's similar to the `crosstest show` command.

### Crossdoc

The `crossdoc` command converts annotated sample code (possibly code tested with crosstest) to documentation. It's like a cross between [docco](http://jashkenas.github.io/docco/) and [pandoc](http://johnmacfarlane.net/pandoc/).

Now that the projects are defined you need to fetch the code before you can run any tasks or tests on the projects. If you already have

Once hte set of
In order to be able run tests in any project we first need to be able to run tasks in any project.

### Other features

There are other commands available in the crosstest suite of tests. Many of them are to subdivide `crosstest test` into phases so you can
partially test something (useful while developing tests). That includes:

```sh
Commands:
  crosstest bootstrap [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]  # Change scenario state to bootstraped. Running bootstrap scripts for the project
  crosstest detect [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]     # Find sample code that matches a test scenario. Attempts to locate a code sample with a filename that the test scenario name.
  crosstest exec [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]       # Change instance state to executed. Execute the code sample and capture the results.

#### Clean

You can use the `crosstest clean` command to remove results that have been persisted.

