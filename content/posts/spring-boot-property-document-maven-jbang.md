---
title: "Document your Spring Boot properties with Jbang"
date: 2023-06-13T10:26:10+01:00
tags: ["jbang", "spring-boot", "java"]
categories: ["java"]
author: "@mikomatic"
---

One of my favorites low-key features of Spring Boot is the ability to map configuration properties from
your `application.{yml|properties}`
into Java Beans using `@ConfigurationProperties` annotation :

- It allows type-safe configuration binding
- It allows also easy validation using — with the standard JSR-380 specification.

Furthermore, using `spring-boot-configuration-processor`, you can generate a configuration metadata in a JSON file,
which provides useful information on how to use the properties.

While this is mostly useful for your IDE to provide autocompletion and usage, in this post we are going to look at how
to leverage this mechanism to document your custom properties in any format using [jbang](https://www.jbang.dev/).

{{< alert info>}}
If you are in a hurry, you can check directly the
code [➡️ here](https://github.com/mikomatic/jbang-catalog#spring-boot-property-documenter)
{{< /alert >}}

{{< toc >}}

## Creating a demo project

First let's create a very simple Spring Boot application. I generated one
using https://start.spring.io ([🔗 example configuration][1]).

First let's start by defining our custom application properties.

```java

@Component
@ConfigurationProperties("my-service")
public class MyProperties {

  /** enable a feature */
  private boolean enabled;

  private final Other other = new Other();

  // getters & setters omitted for brevity
  public static class Other {

    /** another documenter property */
    private String someProperty = "a default value";

    // getters & setters omitted for brevity
  }
}


```

Let's note a few things:

- our properties are included in a standard java bean class
- documentation is provided via our usual javadoc
- 💡tip: we define our custom properties in a given namespace. This is to ensure it does not clash with
  other properties from spring core or a `starter-*` dependency

{{< alert info>}}
We can activate our bean with standard property scanning (using `@ConfigurationPropertiesScan`), annotating your
properties as a `@Component` _as in this example_, or by explicitly declaring it
with `@EnableConfigurationProperties`. [Check the official documentation.](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config.typesafe-configuration-properties)
{{< /alert >}}

## Generating metadata file

To generate a metadata files, let's follow the [instructions for maven][3], by adding the needed dependency in
our `pom.xml` (_configuration is provided for gradle users too_).

```xml

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```

Now to generate the configuration metadata, a standard `mvn compile` command should generate our file in the build
folder: `META-INF/spring-configuration-metadata.json`.
It should look something like this :

```json
{
  "groups": [
    {
      "name": "my-service",
      "type": "com.example.demo.MyProperties",
      "sourceType": "com.example.demo.MyProperties"
    }
  ],
  "properties": [
    {
      "name": "my-service.enabled",
      "type": "java.lang.Boolean",
      "description": "enable a feature",
      "sourceType": "com.example.demo.MyProperties",
      "defaultValue": false
    }
  ]
}
```

The generated file contains our property name, value and description.

The configuration metadata format could also contain deprecation information, or even hints with possible values for a
given property. You could even provide manual hints via an additional file. Be sure to check
the [official docs!](https://docs.spring.io/spring-boot/docs/current/reference/html/configuration-metadata.html#appendix.configuration-metadata.format).

## Documenting our configuration properties

Now that we have a `json` file containing all the information we need, it would be nice to have a script that can:

- parse the `json` data from one or many files
- aggregate it (in case of multiple files)
- export it to a file using a templating engine (to support any format: `markdown`, `html`, `asciidoc`)

This is exactly what I did using JBang, that I
discovered [not so long ago](https://www.mortega.dev/posts/how-to-automatically-rebase-all-your-merge-requests-on-gitlab-jbang-august-2022/).

This time around I discovered that you can publish your scripts and easily share them with the world 🎉

### Using the script

The source code is available
on [github](https://github.com/mikomatic/jbang-catalog/blob/main/springPropertyDocumenter.java).

Using
jbang's [implicit alias catalog](https://www.jbang.dev/documentation/guide/latest/alias_catalogs.html#implicit-alias-catalogs)
you can call the script as easily as a single shell command.

```bash
jbang springPropertyDocumenter@mikomatic -o generated-docs.md
```

This will download the script (you have to trust the source thought 😏), parse your current folder looking
for `META-INF/spring-configuration-metadata.json` files and generates a markdown version using a default template.
Then it outputs the result to `generated-docs.md`

Result should look like this (_with your favorite markdown editor_):

<p>
<img loading="lazy" src="/images/springDocumenter/result.png" alt="spring documenter result">
</p>

### Options

As any command line application, usage is provided via the `-h` options:

```shell
❯ jbang springPropertyDocumenter@mikomatic -h        
Usage: springPropertyDocumenter [-hV] -o=<output> [-t=<templateFile>]
                                [-m=<metadataLocationFolders>]...
Document spring boot properties based on property metadata
  -h, --help              Show this help message and exit.
  -m, --metadata-location-folders=<metadataLocationFolders>
                          Folder(s) containing spring boot configuration
                            metadata files (defaults to current folder)
  -o, --output=<output>   Markdown file output filename
  -t, --template=<templateFile>
                          an optional mustache template
  -V, --version           Print version information and exit.
```

- `-m`, `--metadata-location-folders`: provides folders containing spring boot configuration
  metadata files (defaults to current folder)
- `-t`, `--template`: provides a [`mustache`](https://mustache.github.io/) template file if you want to customize
  the output, instead of the default one.
  This could be useful if you want to export you documentation in another format (`asciidoc`, `html` ...).
- `-o`, `--output`: the exported filename

I should probably document what variables are available in case of providing a custom template,
but hopefully the source code is a good starting point for the moment.

## Conclusion

In conclusion, the article demonstrates the power of Spring Boot's `@ConfigurationProperties` combined with
the `spring-boot-configuration-processor`.

We explored how to leverage this mechanism to document custom properties using JBang.

This approach could greatly simplify the documentation process by automating the extraction of property information and
generating documentation in a desired format. It enhances the developer experience by providing autocomplete and usage
information in IDEs and ensures that custom properties are well-documented and easily accessible to other team members.

Hope you found this useful, until next time 👋!

## References

- https://docs.spring.io/spring-boot/docs/current/reference/html/configuration-metadata.html
- https://www.baeldung.com/spring-boot-configuration-metadata

[1]: https://start.spring.io/#!type=maven-project&language=java&platformVersion=3.1.0&packaging=jar&jvmVersion=17&groupId=com.example&artifactId=demo&name=demo&description=Demo%20project%20for%20Spring%20Boot&packageName=com.example.demo&dependencies=configuration-processor,lombok

[2]: https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config.typesafe-configuration-properties

[3]: https://docs.spring.io/spring-boot/docs/current/reference/html/configuration-metadata.html#appendix.configuration-metadata.annotation-processor.configuring