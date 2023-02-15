---
title: "Exploring maven incremental builds with maven-build-cache-extension"
date: 2023-02-14T15:46:34+01:00
tags: ["maven", "oss"]
categories: ["maven"]
author: "@mikomatic"
---

With the release of maven [3.9.0](https://maven.apache.org/docs/3.9.0/release-notes.html), it is now
possible to leverage the `maven-build-cache-extension` to benefit from incremental builds in your maven project.

This feature can improve build time (in your local workflow and your CI). It caches module builds, avoiding
unnecessary and/or expensive tasks:

> The idea of the build cache is to calculate key from module inputs, store outputs in cache and restore them later
> transparently to the standard Maven core. In order to calculate the key cache engine analyzes source code, build flow,
> plugins and their parameters. This allows to deterministically associate each project state with unique key and
> restore
> up-to-date (not changed) projects from cache and rebuild out-of-date(changed) ones. Restoring artifacts associated
> with
> a particular project state improves build times by avoiding re-building unnecessary modules.[...]
>
> From [plugin documentation](https://maven.apache.org/extensions/maven-build-cache-extension/index.html)

Let's dive into the easiest way to getting started.

{{< toc >}}

## Installing the extension

As any other maven extension, you can load it via `.mvn/extensions.xml` or by modifying your `pom.xml`.

If your using the `.mvn/extensions.xml` approach, you can use following configuration file:

```xml

<extensions xmlns="http://maven.apache.org/EXTENSIONS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/EXTENSIONS/1.0.0 http://maven.apache.org/xsd/core-extensions-1.0.0.xsd">

    <extension>
        <groupId>org.apache.maven.extensions</groupId>
        <artifactId>maven-build-cache-extension</artifactId>
        <version>1.0.0</version>
    </extension>

</extensions>
```

This solution offers more flexibility as you can configure the extension via a `maven-build-cache-config.xml`
file stored in the `.mvn` folder. If no configuration file is found, sensible defaults will be used.

If you are using the `pom.xml` approach, you can add the plugin to your `project->build->extensions`.

```xml

<project>
    ...
    <build>
        <extensions>
            <extension>
                <groupId>org.apache.maven.extensions</groupId>
                <artifactId>maven-build-cache-extension</artifactId>
                <version>1.0.0</version>
            </extension>
        </extensions>
    </build>
    ...
</project>
```

## Running maven with the extension

### Cache miss

When running _any_[^1] maven goal with the extension, you should see new information printed on your maven console

```bash
# Running a maven goal
mvn clean test
[...]
# Enabling cache and hash algorithm
[INFO] Cache configuration is not available at configured path C:\<REDACTED>\.mvn\maven-build-cache-config.xml, cache is enabled with defaults
[INFO] Using XX hash algorithm for cache
[...]
# For each module ...
[INFO] Going to calculate checksum for project [groupId=com.example, artifactId=demo]
[INFO] Scanning plugins configurations to find input files. Probing is enabled, values will be checked for presence in file system
[INFO] Found 3 input files. Project dir processing: 16, plugins: 8 millis
[INFO] Project inputs calculated in 58 ms. XX checksum [596f60b3f5056d7d] calculated in 25 ms.
[INFO] Attempting to restore project com.example:demo from build cache
[INFO] Remote cache is incomplete or missing, trying local build for com.example:demo
[INFO] Local build was not found by checksum 596f60b3f5056d7d for com.example:demo

```

We can see that there is a lot going on here. The extension:

- detects default configuration with `XX` hashing algorithm
- calculates module build execution checksum based on input files and plugin configuration
- searches a corresponding build cache
- If no cache is found, build continues (_cache miss_)

Build cache information is stored in your `~/.m2` repository, under a `build-cache` folder. This can be useful to debug
any cache errors.

For every module a
file `buildinfo.xml` ([ref](https://maven.apache.org/extensions/maven-build-cache-extension/build-cache-build.html)) is
stored containing cache data (project input, maven execution) and produced artifacts.

### Cache hit

Running the same command again will re-use the previously stored build.

```bash
# Running a maven goal
mvn clean test
[...]
# Enabling cache and hash algorithm
[INFO] Cache configuration is not available at configured path C:\<REDACTED>\.mvn\maven-build-cache-config.xml, cache is enabled with defaults
[INFO] Using XX hash algorithm for cache
[...]
# For each module ...
[INFO] Going to calculate checksum for project [groupId=com.example, artifactId=demo]
[INFO] Scanning plugins configurations to find input files. Probing is enabled, values will be checked for presence in file system
[INFO] Found 3 input files. Project dir processing: 13, plugins: 6 millis
[INFO] Project inputs calculated in 39 ms. XX checksum [596f60b3f5056d7d] calculated in 16 ms.
[INFO] Attempting to restore project com.example:demo from build cache
[INFO] Remote cache is incomplete or missing, trying local build for com.example:demo
[INFO] Local build found by checksum 596f60b3f5056d7d
[INFO] Found cached build, restoring com.example:demo from cache by checksum 596f60b3f5056d7d
[INFO] Skipping plugin execution (cached): resources:resources
[INFO] Skipping plugin execution (cached): compiler:compile
[INFO] Skipping plugin execution (cached): resources:testResources
[INFO] Skipping plugin execution (cached): compiler:testCompile
[INFO] Skipping plugin execution (cached): surefire:test
```

We can see that maven totally skips `compile` and `test` execution, re-using cached data.

This also work by a per-module cache, meaning that in a multi-module maven project, only affected modules will be built.

## Performance improvements

I did some minor testing, by running `mvn clean verify -DskipTests` on two projects:

- A minimal spring-boot app created via https://start.spring.io/
- Building my current project: a multi-module projet with +15 modules, ranging from spring boot apps to common libs,
  generated code source, etc ...

{{< alert info>}}
💬 **Note**: this is not a serious benchmark, and is provided just to give an example and
showcase usage. _I'm purposely ignoring tests since i don't have the patience to run them on my current "low resource"
laptop_ 😅
{{< /alert >}}

| project                | 1st      | 2nd (no modification) | 3rd (modifying one module) |
|------------------------|----------|-----------------------|----------------------------|
| minimal mono-module    | ~7.4 s   | ~0.9 s                | `n/a`                      |
| real life multi-module | ~120.2 s | ~16 s                 | ~25s                       |

I saw x4-10 performance improvements on my build, that will be more significant if we take tests into
consideration _which we should **always** be doing anyway_. I'm instantly sold 🚀.

## Alternatives

Before testing this plugin I used mainly two techniques to speed up my maven build (Nicolas Fränkel has a [nice write-up
on this](https://blog.frankel.ch/faster-maven-builds/1/)).

- The first is the [maven daemon](https://github.com/apache/maven-mvnd): this project aims at faster maven builds by
  simplifying parallel builds. It does not provide incremental builds provided by this extension.

  The good news is that it can by used **in addition** to this extension, for faster build extravaganza (check related
  [github issue](https://github.com/apache/maven-mvnd/issues/788) - _targeted for release `0.10.x`_).

- The second is the use of maven reactor options to build only specific modules. _Eg._
  running `mvn -pl :module1 --also-make` will build the specific `module1` while also building required project[^2] (
  ignoring the rest).

  While this a neat trick that i use everyday in by local and CI build, it still does not benefit from the cache
  performance improvements provided by the extension.

I love that with this extension I can still benefit from these tools, and still gain on massive build improvements.

## Troubleshooting

I found the two best ways to handle errors for now are:

- Manually deleting cache folder, located at `~/.m2/build-cache`
- Disabling the extension via command line `-Dmaven.build.cache.enabled=false`

## Conclusion

Leveraging `maven-build-cache-extension` in your Maven project can significantly improve build times by
avoiding unnecessary or expensive tasks. Hopefully by following the steps outlined in this article, you can easily get
started and benefit from faster build times in your local workflow and CI.

The extension is fairly new, there might be some edge cases to resolve, but it's a bright step in the right direction,
while we wait for maven 4.

If you find any issues on the plugin, don't hesitate get involved, raise on issue on
the [dedicated Apache JIRA](https://issues.apache.org/jira/projects/MBUILDCACHE/). This really feels like the future of
maven ❤️.

## 📝 References

- Github Repo: https://github.com/apache/maven-build-cache-extension
- Official Docs: https://maven.apache.org/extensions/maven-build-cache-extension/

[^1]: any "standard" maven goal, there seems to be some [issues](https://issues.apache.org/jira/browse/MBUILDCACHE-38)
when running custom goals.
[^2]: For more information,
check [this blog post](https://blog.sonatype.com/2009/10/maven-tips-and-tricks-advanced-reactor-options/) or the
brand-new [official docs](https://maven.apache.org/guides/mini/guide-multiple-modules-4.html)