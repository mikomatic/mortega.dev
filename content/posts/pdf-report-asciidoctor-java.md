---
title: "Generate PDF Documents in your Spring Boot App with AsciidoctorJ"
date: 2022-01-16T10:26:10+01:00
tags: ["asciidoc", "pdf", "java"]
---

In a recent project I worked there was a need to generate PDF documents.

The document itself required to display information about a complex domain hierarchical object, containing ~100+ attributes and other child objects.
Before the existing application came to place, most users were manually creating Word documents to handle this requirement (with all the copy-pasting and human errors that one can imagine).

## Existing solutions

The JVM ecosystem offers many possibilities to generate printable documents, to name a few:

- [Birt](https://eclipse.github.io/birt-website/)
- [JasperReports](https://www.jaspersoft.com/products/jasperreports-library)
- [iText](https://itextpdf.com/en/products/itext-7)
- [PDFBox](https://pdfbox.apache.org/)

While these libraries certainly offer battle-tested solutions and many features (some have been around for ~20 years !) for small or even medium project I find them a bit excessive.
(_Disclaimer: I only have experience with the first two, that you won't find in my CV_ 😀)

I also have found that either the documentation is outdated, the learning curve is steep, the code is very low-level, only commercial licence is available or a combination of all the above.

## Why Asciidoc can be good choice

Asciidoc is a lightweight markup language, where you only focus on content rather than layout.
It's offer a mature ecosystem to writing articles, documentation, books, and so on, with output formats ranging from `HTML` to `ePub` (and of course `PDF`).
It can easily integrate images, diagrams, code.

I have been using it for years for the technical documentation of personal and non-personal projects.

## Show me the code

> If you are in a hurry you can check the code directly on [Github](https://github.com/mikomatic/asciidoctorj-pdf-demo)

Integrating `Asciidoctor` into your app is as simple as adding a maven (or gradle) dependency

```xml
<dependency>
    <groupId>org.asciidoctor</groupId>
    <artifactId>asciidoctorj</artifactId>
    <version>${asciidoctorj.version}</version>
</dependency>

<dependency>
    <groupId>org.asciidoctor</groupId>
    <artifactId>asciidoctorj-pdf</artifactId>
    <version>${asciidoctorj.pdf.version}</version>
</dependency>
```

Now let's see how you can generate a document :

```java
// 1. Create Asciidoctor factory
try (Asciidoctor asciidoctor = Asciidoctor.Factory.create()) { 

  // 2. Define common attributes (you can even define a theme, more on that later)
  Attributes attributes = Attributes.builder()<2>
      .attribute("pdf-theme", theme) // optional theme
      .attribute("doctype", "book")
      .attribute("icons", "font")
      .build();

  //Set PDF backend
  Options options = Options.builder()
      .backend("pdf")<3>
      .attributes(attributes)
      .toFile(outputLocation.toFile()).build();

  // Do the actual conversion, where `asciidocContent` is a string containing a ASCIIDOC template
  asciidoctor.convert(asciidocContent, options);<4>
}
```

That's pretty much it !

The `asciidocContent` can come from a "static" file on your classpath (or anywhere really).
For more dynamic document, it is possible to use any templating engine (in our project we used [mustache](https://github.com/spullara/mustache.java)).

It is possible to provide customization to the default theme, while it is not as powerful as other solutions, it can be good enough for most needs.
Several examples can be found [on github](https://github.com/asciidoctor/asciidoctor-pdf/tree/main/examples).

Themes can also be packaged as `jar` for easier distribution.
The [documentation](https://github.com/asciidoctor/asciidoctor-pdf/blob/main/docs/theming-guide.adoc) is quite detailed.

## Caveats

While this solution has served me well, it does come with some limitations:

* Customization can be quite limited depending on your needs.
* While diagrams as text is very practical, it does currently need an external dependency (graphviz, mermaid) present on your `PATH`.
* Last but not least, the dependency that wraps a JRuby runtime does not work well in UBER jars (nested jars)
  * For Spring Boot apps, this can be solved via `requiresUnpack` option of `spring-boot-maven-plugin`. [➡️Documentation](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#howto.build.extract-specific-libraries-when-an-executable-jar-runs)
  * For Quarkus, this is not possible yet [#issue](https://github.com/asciidoctor/asciidoctorj/issues/1047)

A quick demo project demonstrating the possibilities of this solution, with a custom theme,
is available [on github](https://github.com/mikomatic/asciidoctorj-pdf-demo).

### Further reading

- A good "Getting started" guide on [baeldung](https://www.baeldung.com/asciidoctor)
- [Another post](https://blog.ninja-squad.com/2022/01/06/generate-pdf-documents-in-java/) I found using `iText` for _very_ simple documents.