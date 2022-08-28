---
title: "How to Automatically Rebase All Your Merge Requests on Gitlab with Jbang"
date: 2022-08-28T19:41:01+02:00
tags: ["java", "jbang","gitlab"]
categories: ["java"]
author: "@mikomatic"
---

In our current project we debated (too much :) ) about our merge strategy.

We finally settled with a fast-forward strategy. On GitLab, when you merge a MR on main, you must rebase all the other
MRs afterwards.
If your CI takes more than a couple of minutes, it is cumbersome and take unnecessary time to integrate our code.

I found this elegant solution
on [Medium](https://medium.com/ovrsea/how-to-automatically-rebase-all-your-merge-requests-on-gitlab-when-pushing-on-master-9b7c5119ac5f)
to automate rebase everytime someone merges on the main branch.
If you're looking for a quick solution, be sure to check that out.

While we liked this solution, we preferred using a label to identify MRs we wished to auto rebase.

I thought it would be fun to replicate it using Jbang. [The full code available on Github.](https://gist.github.com/mikomatic/8769da7f84a0da8749e9d166431d0d0a)

## Jbang

Jbang is a launcher script, that makes getting started with java very simple. It's like the standard Jshell (since JDK
11), but with super powers:

- Dependency declaration
- Include multiple files
- Easy IDE integration

For more information check out [these][0] [articles][2] or the [reference documentation][1].

## The Code

Let's create our script via jbang, using the cli template:

```bash
jbang init --template=cli autorebase.java
```

This enables to power of [picocli](https://picocli.info/) in our script (parameter parsing/validation).
Once the file is created we are going to use a gitlab java api client, so we must add the [Gitlab4j][4]
dependency.

```java
//DEPS org.gitlab4j:gitlab4j-api:5.0.1
```

From there the code is pretty straightforward:

```java
  @Override
  public Integer call() throws Exception {
    try (GitLabApi gitLabApi = buildGitlabApi()) {
      List<MergeRequest> mergeRequestList = gitLabApi.getMergeRequestApi()
          .getMergeRequests(projectId, Constants.MergeRequestState.OPENED);

      List<MergeRequest> openedMRList = mergeRequestList.stream()
          .filter(mr -> !Boolean.TRUE.equals(mr.getRebaseInProgress()))
          .filter(mr -> mr.getLabels().contains(AUTOREBASE_LABEL))
          .toList();

      for (MergeRequest mr : openedMRList) {
        Long mrIid = mr.getIid();
        System.out.println("Rebasing open MR [%s,%s]".formatted(mrIid, mr.getTitle()));

        if (!dryRun) {
          gitLabApi.getMergeRequestApi().rebaseMergeRequest(projectId, mrIid);
        }
      }
    }
    return 0;
  }
```

- 1-4 : We look for all opened MR on a given project
- 7-10: We filter by a specific label (but you can choose whatever fits your needs)
- 10+: We iterate over the MR list to rebase them

## Gitlab CI

The final part is integrating this script on your pipeline `.gitlab-ci.yml`

```yaml
🔄 gitlab-auto-rebase-mr:
  extends: .jbang-job
  script:
    - jbang autorebase.java --gitlab-url ${GITLAB_URL} --project-id ${CI_PROJECT_ID} -t ${ACCESS_TOKEN}
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

Of couse, your job image should contain a java + jbang.

## Conclusion

In this blog post we demonstrated how to integrate a simple java script in your gitlab pipeline using jbang.

While java is still verbose compared to the bash equivalent I feel the java counterpart offers many advantages:
- easier debugging
- better ide integration
- massive ecosystem (libraries and frameworks)

Hopefully your next custom script will integrate a bit of java in it, I know mine will!

[0]: https://www.infoq.com/news/2020/10/scripting-java-jbang/

[1]: https://www.jbang.dev/documentation/guide/latest/index.html

[2]: https://www.slideshare.net/RedHatDevelopers/jbang-unleash-the-power-of-java-for-shell-scripting

[4]: https://github.com/gitlab4j/gitlab4j-api