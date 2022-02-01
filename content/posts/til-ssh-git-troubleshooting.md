---
title: "til: SSH Connexion troubleshooting"
date: 2022-01-30T01:13:53+01:00
categories: ["til"]
tags: ["git", "ssh"]
author: "@mikomatic"
---

A few weeks ago several developers on our team were unable to connect to our Gitlab instance using the SSH protocol.
Their `git` commands kept asking for password with no apparent error.

It was a bit strange because nothing had changed in their setup (or at least, that's what they thought). Most of them
recreated their ssh keys, which seemed to correct the problem, and we all moved on - it seemed a PEBKAC[^1] issue.

I didn't gave it much thought until it happened to me too 😅.

The [gitlab documentation][1] offers a path forward:

```bash {hl_lines=[9]}
# Options -T to Disable pseudo-tty allocation.
# Options -v to set verbose mode. Multiple -v options increase the verbosity.  
# The maximum is 3.
ssh -Tv git@example.com

# ouput
debug1: Next authentication method: publickey
debug1: Offering public key: /home/user/.ssh/id_rsa RSA ... agent
debug1: send_pubkey_test: no mutual signature algorithm
debug1: No more authentication methods to try.
```

The `no mutual signature algorithm` when offering my public `ìd_rsa` indicates that `ssh-rsa` is not enabled.

For me this happened after updating my Git version, and after digging a bit I found out that Git updated its OpenSSH
version to 8.8 since [version 2.33.1][git]. Furthermore, reading [OpenSSH 8.8 release notes][openssh] I found the root
cause (_emphasis mine_):

> This release disables RSA signatures using the SHA-1 hash algorithm by default. [...]
>
> For most users, this change should be invisible and there is no need to replace ssh-rsa keys. [...]
>
> _Incompatibility is more likely when connecting to older SSH implementations that have not been upgraded
> or have not closely tracked improvements in the SSH protocol.
> For these cases, it may be necessary to selectively re-enable RSA/SHA1 to allow connection and/or user
> authentication via the HostkeyAlgorithms and PubkeyAcceptedAlgorithms options_.

This seems to be exactly my case, as I was interacting with a server using OpenSSH `6.x`. 

Two solutions are offered. Either generate a new key using a more robust algorithm[^2] (which I did)

```bash
$ ssh-keygen -t ed25519 -C "your_email@example.com"
```

or re-enable `RSA SHA-1` support on the affected ssh client (**not recommended**)

```bash
#In ~/.ssh/config
PubkeyAcceptedAlgorithms +ssh-rsa
```

So while, the solution was actually the same as other teams members, i'm glad i actually understood the _why_.

### Further reading

- Troubleshooting
  Git [on BitBucket support page](https://confluence.atlassian.com/bitbucketserverkb/ssh-rsa-key-rejected-with-message-no-mutual-signature-algorithm-1026057701.html)
- Github article
  on [improving git protocol security](https://github.blog/2021-09-01-improving-git-protocol-security-github/)

[^1]: _Problem Exists Between Keyboard And Chair_
[^2]: Gitlab/Github recommend [ED25519 keys](https://docs.gitlab.com/ee/ssh/#ed25519-ssh-keys)

[1]: https://docs.gitlab.com/ee/ssh/#password-prompt-with-git-clone
[git]: https://github.com/git-for-windows/git/releases/tag/v2.33.1.windows.1
[openssh]: https://www.openssh.com/txt/release-8.8