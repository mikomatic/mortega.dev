---
title: "Intro to Playwright Web Automation Framework in Java"
date: 2022-01-30T18:04:33+01:00
tags: ["java", "playwright"]
categories: ["java"]
author: "@mikomatic"
---

In a recent project I found myself looking for a web automation framework.

I had the following requirements:
- A dev oriented framework: so no [Cucumber][cucumber], [FitNess][fitness] or other BDD Frameworks[^1]
- Preferably java based: I've had success using [Robot Framework][robot] with maven, and while integration isn't hard
, it was not seamless to say the least.
- Something easy to setup and "fast" (_one can dream_)

## What is Playwright ?

Playwright is a new web application framework, created by Microsoft, allowing engineers to
test their web applications with cross-browser support. Their stable Java API landed less than a year ago.

The feature list is huge just by reading the [docs][playwright-docs], here are some of them that I found 
particularly relevant:
- Auto-waiting on elements
- Network Interception
- Support for tricky scenarios like shadow-dom, iframes
- Test tracing via screenshots, videos and a specific tracing via a dedicated explorer
- API Testing (_similar to your good old REST client for preparing server side state in the system under test_)
- Code generation

and the list goes on and on ... 

### WebDriver vs DevTools Protocol

One particularity of Playwright is the use of the Chrome DevTools Protocol ([CDP][cdp]). 

Usually Webdriver is the de-facto standard, acting as a middleman between the browser and the testing framework.

![web driver](./images/playwright/playwright_webdriver.png)

Using the DevTools protocol allows a more direct control of browser, cutting the middleman and enabling Playwright to do some neat tricks like
interacting with the network (intercepting calls or emulating network conditions).
To my knowledge, it's the only framework in the JVM ecosystem using CDP.



### Faster tests

Playwright comes with `BrowserContexts` feature. This means each test can be isolated from each other, as if every tab
was in a new incognito mode.

By sharing the same browsers instance, we can also speed up our test suite by not paying the costly browser instanciation.

```java
// Create a new incognito browser context
BrowserContext context = browser.newContext();
// Create a new page inside context.
Page page = context.newPage();
```

## Where do I start ?

Let's start by adding the latest dependency to your project.

```xml
<dependency>
  <groupId>com.microsoft.playwright</groupId>
  <artifactId>playwright</artifactId>
  <version>${playwright.version}</version>
</dependency>
```

In the following sections we are going to talk about my favorite features.

## Code generation

I found the easiest way to get started was to use de code generation tool.

```powershell
# At the root of your project
mvn exec:java -e "-Dexec.mainClass=com.microsoft.playwright.CLI" "-Dexec.args=codegen https://google.com"
```

This command will download all the need browsers (_see configuration if you are behind a [corporate proxy][proxy_doc]_).
Then it will open your testing tab and the Playwright inspector, generating the code corresponding to the given user interactions
(even OAuth authentication).

<p>
<img loading="lazy" src="/images/playwright/playwright_recorder.JPG" alt="playwright inspector" width="400" height="400">
</p>

Maybe it's because I've been out of touch of web testing frameworks lately, but this blew me away 🔥[^2]. 
It's a great developer experience when you can benefit from code generation tools and refactor the
base code to your needs, adding needed assertions or refactoring to create readable abstractions via 
a [Page Object Model][page_object_model].

## Network interception

You can mock API endpoints, by handling requests in your test.

```java
// Using custom testData to as a response to this API call
page.route("**/api/fetch_data", route -> route.fulfill(new Route.FulfillOptions()
  .setStatus(200)
  .setBody(testData)));

page.navigate("https://example.com");
```

Mocking (in this case a stub) is great for out-of-process dependencies that you have no control over.

> Note: while writing this article I came across an excellent post describing [when to mock](https://enterprisecraftsmanship.com/posts/when-to-mock/), 
> clarifying also many related terms.

## Tracing 

Finally, I really loved the possibility to generate a trace of your testing script.

```java
Browser browser = chromium.launch();
BrowserContext context = browser.newContext();

// Setup tracing options
context.tracing().start(new Tracing.StartOptions()
        .setScreenshots(true)
        .setSnapshots(true));
Page page = context.newPage();
        
page.navigate("https://playwright.dev");
context.tracing().stop(new Tracing.StopOptions().setPath(Paths.get("trace.zip")));
```

The generated zip can be viewed via a command line

```powershell
mvn exec:java -e "-Dexec.mainClass=com.microsoft.playwright.CLI" "-Dexec.args=show-trace target/trace.zip"
```

or just by uploading it to https://trace.playwright.dev/.

<p>
<img loading="lazy" src="/images/playwright/playwright_trace.JPG" alt="playwright inspector">
</p>

- In the upper section, you can see the timeline of your tests
- On the left and center side you can see each action in your test
  - with an attached screenshot before and after the action
  - you can even see a little red dot indicating where the action took place (_e.g. a clicked button_)
- On the right section you can see network call, console logs and your tests script source code

Mind. Blown. 🤯

## Conclusion

Hopefully by now you have a nice overview of Playwright and what it can do for you.
We only scratched the surface but here are some take aways

- Great cross-browser, cross-os, cross-language library
- Simple setup and great developer experience for java 
- Very complete API and awesome tooling.

It may reconcile me with web automation frameworks, who would have thought !

You don't event have to use it for your UI tests, via the Request API you can just automate your 
REST calls to prepare your system for a manual test (_e.g. if you have a staging environment that you reset regularly_) and 
iterate from there. Or just test your API, if that fits your needs.

The only one missing key I found is a nice reporting output, existing only in the `node` implementation.

I hacked a project integrating Playwright with   Junit5 and Allure Reporting framework - code is available [on Github](https://github.com/mikomatic/playwright-demo) - 
but an out-of-box reporting tool would make this incredible tool even greater.

### Further reading

- [Playwright vs WebDriver: the future of web-automation](https://medium.com/slalom-build/playwright-vs-webdriver-the-future-of-browser-automation-854a7ae63218)
- [Playing with Playwright](https://applitools.com/blog/playwright-java/)

[^1]: I actually don't believe in Behaviour Driver Development testing frameworks anymore. Too often I've seen [anti-patterns](https://cucumber.io/blog/bdd/cucumber-antipatterns-part-one/) and miscommunications.
The business-friendly abstraction and implied additional work - translating human-readable scenarios to Java code - is not worth it in most
cases I've encountered. _change my mind !_
[^2]: One thing I found interesting is that playwright seems to rely more on `aria-label` and `text` attributes more than the `ìd`. Not sure
if this is true or why should it be ?

[cucumber]: https://cucumber.io/
[fitness]: http://docs.fitnesse.org/FrontPage
[robot]: https://robotframework.org/
[playwright-docs]: https://playwright.dev/java/docs/intro
[cdp]: https://developer.chrome.com/docs/devtools/overview/
[proxy_doc]: https://playwright.dev/java/docs/browsers#install-behind-a-firewall-or-a-proxy
[page_object_model]: https://playwright.dev/java/docs/pom