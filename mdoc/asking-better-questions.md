+++
title = "Asking better questions"
date = "2023-02-05"

[taxonomies]
tags = ["development"]

[extra]
disqus = true
+++

From the very first day I started learning how to program, I had questions. **So many questions!**

Thing is, after some time, as my career progressed, I ended up being on the receiving end of such questions a lot of the time. That never changed - in fact, I'm used to people asking for help on a daily basis, if not more often.

All of this is to say, I've asked and been asked probably thousands of questions - good ones, but also bad ones, and I would like to share a couple tips on how to ask better questions.
These tips will not only help you **reach a solution sooner**, but possibly a **better solution altogether**.

<!-- more -->

- [What's a question?](#whats-a-question)
- [Due dilligence](#due-dilligence)
  - [Use a search engine](#use-a-search-engine)
  - [Search your knowledge base](#search-your-knowledge-base)
  - [Update your software](#update-your-software)
  - [Read the manual](#read-the-manual)
  - [Maybe it's you](#maybe-its-you)
- [Context](#context)
  - [Is this an XY problem?](#is-this-an-xy-problem)
  - [todo](#todo)
  - [Use your judgement](#use-your-judgement)
- [Reproduction](#reproduction)
- [Communication style](#communication-style)
  - [Be kind](#be-kind)
  - [Be clear](#be-clear)
  - [Respect their time](#respect-their-time)


# What's a question?

Before we get to the tips, I want to highlight what kind of questions this could be useful for.

In the context of this post, "asking a question" means any action that you perform to get help **from other people** in solving a problem.

This includes, but is not limited to:

- reporting an issue in a project ("the command X doesn't work", "can you add a Y function?")
- requesting assistance in your work ("my code crashes", "I can't publish to Maven Central")
- learning ("what does this function do?", "what's the best way to publish a Scala library?")

To sum up, the practices described here can be used in a variety of contexts.

# Due dilligence

Ensure you've done **as much as you reasonably could** by yourself. Reasonably - because nobody would want you to spend a week searching for an answer they could give you in five minutes.

Many Open Source projects will have a checklist for this, and you can make your own if you like. Here are a couple things to try:

## Use a search engine

It can be Google, Bing, DuckDuckGo, or whatever you use. Run some basic searches and sift through a couple pages of the results.

## Search your knowledge base

For [OSS](https://en.wikipedia.org/wiki/Open-source_software) projects, this could be GitHub Issues or Discussions - maybe the question you meant to post has already been asked.
Maybe the bug you encountered has already been reported and then closed as "not a bug".
Who knows, maybe it's been fixed and will be available in the next release!

At work, you can often find useful nuggets of information on Slack or your team's Wiki.

## Update your software

Ensure that the problem is visible on **the latest available version** of the software you're having problems with.

Sometimes we use older versions of software without being aware of a more recent release,
or there's been a change in the project that **hasn't yet been released** - we can only try it out after switching to a snapshot/nightly distribution channel.

Even if you're stuck on an older version, it's good to know whether the problem has been seen before.

## Read the manual

If you can find it, reach for the documentation. If you can't - you can start by asking about that.

Documentation could also be code or a product brief. You may be able to gather some information about why what you're trying to do doesn't work, and maybe even figure out **a way to fix it** - always useful information to bring in a bug report.

## Maybe it's you

Sometimes we just let our pride win and assume everyone is wrong - but not us, of course. **Stay humble**, remember that you're not a machine, and consider the possibility that it was, in fact, you.
Take a break, look at the problem with fresh eyes and see if you find any flaws in your approach.

Nevertheless, **don't get blocked** - if you honestly see no way forward, asking for help is the right call.
If you're not sure about something, just mention that in the question - you don't have to know everything. You can even start by asking an easier, more general question, just to validate your understanding.

# Context

## Is this an XY problem?

It's a common trap that you see a problem, come up with a solution, encounter a roadblock while trying to implement it... then get hung up on that solution.

Whereas it may be a genuinely legitimate way to get to your goal, it's a good idea to take a step back and ponder:

> Is this really the right way to approach this?

You may find that you're jumping through hoops to make that solution work for this problem, or trying to fit this problem into that solution.

If you're lucky, someone aware of this phenomenon will ask you: **Is this an XY problem?**

After [xyproblem.info](https://xyproblem.info):

> The XY problem is asking about your attempted solution rather than your actual problem.
> This leads to enormous amounts of **wasted time and energy**, both on the part of people asking for help, and on the part of those providing help.

Once I learned about this, I started seeing myself and my peers fall into this trap [unreasonably often](https://en.wikipedia.org/wiki/Frequency_illusion), and I agree with the statement above - it can be a massive waste of time.
Being aware of this pitfall is incredibly useful: we can fight against it. The best way is to start with context.

## todo

## Use your judgement

> Learn the rules like a pro, so you can break them like an artist.
>
> -Pablo Picasso

Remember, these are just hints and ideas - you don't always have to follow all of them. In certain environments, you'll find it best not to overwhelm people with information about your issue (e.g. if you're asking for general advice on a Slack channel),
and sometimes you have to be more vague because of e.g. [NDA](https://en.wikipedia.org/wiki/Non-disclosure_agreement)s.

Keep these tips in mind, but ultimately you'll have to follow your gut.

# Reproduction

todo

# Communication style

Last but not least, we need to make sure someone actually reads our question and decides to help us. **Proper communication is key!**

## Be kind

This goes without saying: in a public forum, you're just a stranger on the Internet asking people to spend their time (a scarce resource) on _your needs_.
It doesn't mean you shouldn't ask your question, of course - **that's what these places are for**! Just be mindful of your tone and phrasing to make sure it doesn't come off as demanding.

Respect the time and effort of people who offer to help you: even if it's part of their job, you owe it to them not to abuse their good intentions.

## Be clear

Read your question in whole before you submit it.

If you have the time, do some basic editing. There is no _single_ right way to do it, and from this point you can go as far as you like (running a spellchecker, Grammarly, and so on), just like in any other form of writing.
See if you can remove unnecessary, ~~redundant~~ words, break up longer sentences ~~in your explanations~~ or split your paragraphs into sections.

However, **don't sweat it** - "perfect" is the enemy of "done", and the fact that you're trying is already going to get appreciated!

## Respect their time


---

- communication style
  - be kind
    - especially to strangers who volunteer their work in a public forum
    - at work people are paid to help you, but also that's not their main task (usually) so be mindful
  - async-friendly
    - avoid "does anybody here know X?": that's not the question you were going to ask
    - avoid roundtrips
  - nohello.com
  - DUE DILLIGENCE
    - did you search engine?
    - did you search for existing issues?
    - are you on the latest version or have a really good reason not to be?
      - bonus points: try a snapshot
    - be humble
      - maybe you just fucked up?
- context
  - the XY problem: why it's important to give context on why you're trying to do this
  - how much context should you give?
    - for issues, usually as little as possible
    - for very strange problems, as much as possible, but keep it structured
    - follow your gut, just be aware that more may help + avoid TMI if it's redundant
  - main things (essential parts of a problem description):
    - what problem are you trying to solve / what are you trying to do? (bonus: why are you doing this? see xy problem)
    - how did you run into this problem?
    - what do you want to happen?
    - what actually happens?
  - what have you tried so far?
  - why do you think that doesn't work?
    - is the problematic behavior deterministic? can you point out anything that seems to affect it?
  - does this block you? how important is it?
- how to reproduce it
  - make it minimal
  - make it reproducible
  - make it complete (self-contained, standalone): libraries (concrete versions), imports
  - example of how to do this: `nix run` call (as reproducible as it gets) or `scala-cli` script
  - very important: ACTUALLY RUN THE EXAMPLE YOU'RE SENDING
    - i've seen people do this and I've done it too: the example I sent didn't actually reproduce the issue

Example

<!-- https://jonskeet.uk/csharp/complete.html -->

<!-- for issues: special case. If your issue is a bug or missing feature, write it as something that can be turned into a test: how to do it, what happens, what you expect to happen. Metals does this nicely. -->

https://www.chris-kipp.io/slides/open-source
