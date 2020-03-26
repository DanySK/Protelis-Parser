# Protelis-Parser
Parser for Protelis, the practical aggregate programming language

## Badges

### Info
![Travis (.com)](https://img.shields.io/travis/com/Protelis/Protelis-parser)
![CII Best Practices Summary](https://img.shields.io/cii/summary/3810)
![GitHub language count](https://img.shields.io/github/languages/count/Protelis/Protelis-parser)
![GitHub top language](https://img.shields.io/github/languages/top/Protelis/Protelis-parser)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/Protelis/Protelis-parser)
![GitHub repo size](https://img.shields.io/github/repo-size/Protelis/Protelis-parser)
![Maven Central](https://img.shields.io/maven-central/v/org.protelis/protelis.parser)
![GitHub contributors](https://img.shields.io/github/contributors/Protelis/Protelis-parser)

### Coverage
![Codacy coverage](https://img.shields.io/codacy/coverage/b27fc7ed29a944e1a17b148e58435d86)
![Code Climate coverage](https://img.shields.io/codeclimate/coverage/Protelis/Protelis-parser)
![Codecov](https://img.shields.io/codecov/c/github/Protelis/Protelis-parser)
*[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=coverage)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)*

### Quality
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b27fc7ed29a944e1a17b148e58435d86)](https://www.codacy.com/manual/danilo-pianini/Protelis-Parser?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=Protelis/Protelis-Parser&amp;utm_campaign=Badge_Grade)
![Code Climate coverage](https://img.shields.io/codeclimate/coverage/Protelis/Protelis-parser)
![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability-percentage/Protelis/Protelis-parser)
![Code Climate maintainability](https://img.shields.io/codeclimate/issues/Protelis/Protelis-parser)
![Code Climate maintainability](https://img.shields.io/codeclimate/tech-debt/Protelis/Protelis-parser)
[![CodeFactor](https://www.codefactor.io/repository/github/Protelis/Protelis-parser/badge)](https://www.codefactor.io/repository/github/Protelis/Protelis-parser)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=alert_status)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=bugs)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=code_smells)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=duplicated_lines_density)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=ncloc)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=reliability_rating)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=security_rating)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=sqale_index)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=Protelis_Protelis-parser&metric=vulnerabilities)](https://sonarcloud.io/dashboard?id=Protelis_Protelis-parser)

### Progress
![GitHub issues](https://img.shields.io/github/issues/Protelis/Protelis-parser)
![GitHub closed issues](https://img.shields.io/github/issues-closed/Protelis/Protelis-parser)
![GitHub pull requests](https://img.shields.io/github/issues-pr/Protelis/Protelis-parser)
![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed/Protelis/Protelis-parser)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/Protelis/Protelis-parser)
![GitHub commits since latest release (by date)](https://img.shields.io/github/commits-since/Protelis/Protelis-parser/latest/develop)
![GitHub last commit](https://img.shields.io/github/last-commit/Protelis/Protelis-parser)

## Required Eclipse plugins

* Xtext 2.7.3+
* Maven support via m2e
* git

## Project structure

* *alchemist.protelis.parent*:
  the build point, which should pull in all of the others
* *alchemist.protelis*:
  specifies the Protelis DSL and associated utilities using XText
* *alchemist.protelis.target*:
  specifies the Eclipse runtime environment that the DSL plugin should
  be compatible with.
* *alchemist.protelis.ui*:
  Contains the Eclipse plugin to support Protelis editing
* *alchemist.protelis.repository*:
  Packages for the automated install website for Eclipse
* *alchemist.protelis.tests*:
  Makes sure that you can fire up an instance of Eclipse that can
  load the plugin

## Develop and test the DSL and plugin using Eclipse

Once the repositories are imported, there will likely be a lot of errors.

* First, if there are "Plugin execution not covered by lifecycle configuration" errors, go to Eclipse Preferences > Maven > Errors/Warnings and switch this error type to warning.  This is OK because Eclipse uses its own build system, and can ignore these Maven problems (which are not due to the Maven configuration, but lack of certain current Eclipse/Maven integrations).
* Second, go to alchemist.protelis project and run src/it.unibo.alchemist.language.protelis/GenerateProtelis.mwe2 as an MWE2 workflow (ignoring the fact that there are errors).  This generates the DSL using Xtext, and should resolve all of the outstanding errors.

When successfully built, this should produce two artifacts:

1. The DSL parser, which is needed for running the Protelis VM
2. The Eclipse plugin, based on the parser, for making it easy to program in Protelis (plus packaging for distributing as an Eclipse plugin)

In order to test both of these at once (there is no separate test for just the DSL):

1. Go to the UI project and run as Eclipse application
2. In the new Eclipse application that launches and make a new Java project
3. Right click on the project and select: Configure > Add Xtext Nature
4. In the src folder, create a new file, named [something].pt (.pt means it is a Protelis file)
5. Write some Protelis code or hit Ctrl-space for autocompletion: you should be getting Protelis syntax evaluation and coloring

## Co-develop Protelis DSL and Protelis VM

In order to co-develop on the Protelis DSL and VM simultaneously, you will need to download the VM (project: Protelis) and link it with this DSL project.  Install following the instructions on that repository.

Once it has been installed, change the build path by right clicking on the Protelis project and selecting Build Path > Configure Build Path.  On the "Projects" tab, add the alchemist.protelis project.  Finally, in the "Order and Export" tab, move alchemist.protelis to the top, so that it will be loaded first in case of any conflicts.

Finally, still in the Protelis project, edit "build.gradle" and comment out the line
> compile "it.unibo.alchemist:alchemist.protelis:$protelisVersion"

by putting a "//" in front of it.  Finally, refresh the Gradle dependencies by right-clicking on the project and running Gradle > Refresh Dependencies.  This should remove the Gradle Dependency on the Protelis .jar file.

You can then test that everything is running correctly by running the Protelis JUnit tests.

## Prepare for a release

## How to prepare a working Eclipse environment

A working Eclipse environment is the best way to develop the parser, since it gives immediate feedback about errors.

### Obtaining Eclipse

### Installing required plugins

There are six sub-projects in this repository, all of which should be
imported into Eclipse.

Then what?
How do we know if it worked?

## Dealing with build problems
Maven: plugin lifecycle should be warning, no error
  Change this in Eclipse Preferences > Maven >

Maven needs to be at least version 3.3.3
