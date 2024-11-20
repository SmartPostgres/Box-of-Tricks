# Contributing to the Box of Tricks

First of all, welcome! We're excited that you'd like to contribute. How would you like to help?

* [I'd like to report a bug](#how-to-report-bugs)
* [I'd like someone else to build something](#how-to-request-features)
* [I'd like to build a new feature myself](#how-to-build-features-yourself)

## How to Report Bugs

Check out the issues list. Search for what you're interested in - there may already be an issue for it. 

Make sure to search through [closed issues list](https://github.com/SmartPostgres/Box-of-Tricks/issues?q=is%3Aissue+is%3Aclosed), too, because we may have already fixed the bug in the development branch. To try the most recent version of the code that we haven't released to the public yet, [download the dev branch version](https://github.com/SmartPostgres/Box-of-Tricks/tree/dev).

If you can't find a similar issue, go ahead and open your own. Include as much detail as you can - what you're seeing now, and what you'd expect to see instead.

## How to Request Features

Open source is community-built software. Anyone is welcome to build things that would help make their job easier. Open source isn't free development, though. Working on these scripts is hard work. If you just waltz in and say, "Someone please bake me a cake," you're probably not going to get a cake.

If you want something, you're going to either need to build it yourself, or convince someone else to devote their free time to your feature request. You can do that by sponsoring development (offering to hire a developer to build it for you), or getting people excited enough that they volunteer to build it for you.

And good news! Lots of people have contributed their code over time. Here's how to get started.

## How to Build Features Yourself

When you're ready to start coding, discuss it with the community. Check the issues list (including the closed issues) because folks may have tried it in the past, or the community may have decided it's not a good fit for these tools.

If you can't find it in an existing issue, open a new Github issue for it. Outline what you'd like to do, why you'd like to do it, and optionally, how you'd think about coding it. This just helps make sure other users agree that it's a good idea to add to these tools. Other folks will respond to the idea, and if you get a warm reception, go for it!

After your Github issue has gotten good responses from a couple of volunteers who are willing to test your work, get started by forking the project and working on your own server. The Github instructions are below - it isn't exactly easy, and we totally understand if you're not up for it. Thing is, we can't take code contributions via text requests - Github makes it way easier for us to compare your work versus the changes other people have made, and merge them all together.

Note that if you're not ready to get started coding in the next week, or if you think you can't finish the feature in the next 30 days, you probably don't want to bother opening an issue. You're only going to feel guilty over not making progress, because we'll keep checking in with you to see how it's going. We don't want to have stale "someday I'll build that" issues in the list - we want to keep the open issues list easy to scan for folks who are trying to troubleshoot bugs and feature requests.

### Code Requirements and Standards

We're not picky at all about style, but a few things to know:

Your code needs to compile & run on all currently supported versions of Postgres. It's okay if functionality degrades, like if not all features are available, but at minimum the code has to compile and run.

Your code must handle:

* Unusual object names (tables & indexes with spaces, commas, etc)
* Different date formats - for guidance: https://xkcd.com/1179/

We know that's a pain, but that's the kind of thing we find out in the wild. Of course you would never build a server like that, but...

### How to Check In Your Code

Rather than give you step-by-step instructions here, we'd rather link you to the work of others:

* [How to fork a GitHub repository and contribute to an open source project](https://blog.robsewell.com/blog/how-to-fork-a-github-repository-and-contribute-to-an-open-source-project/)
