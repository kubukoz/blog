+++
title = "Asking better questions"
date = "2023-02-24"

[taxonomies]
tags = ["development"]

[extra]
disqus = true
+++

From the very first day I started learning how to program, I had questions. **So many questions!**

Thing is, after some time, as my career progressed, I ended up being on the receiving end of such questions more and more. That never changed - in fact, I'm used to people asking for help many times a day.

All of this is to say, I've asked and been asked probably thousands of questions - good ones, but also bad ones, and I would like to share a couple of tips on how to ask better questions.
These tips will not only help you **reach a solution sooner**, but possibly a **better solution altogether**.

<!-- more -->

# What's a question?

Before we get to the tips, I want to highlight what kind of questions this could be useful for.

In the context of this post, "asking a question" means any action that you perform to get help **from other people** in solving a problem.

This includes, but is not limited to:

- reporting an issue in a project ("the command X doesn't work", "can you add a Y function?")
- requesting assistance in your work ("my code crashes", "I can't publish to Maven Central")
- learning ("what does this function do?", "what's the best way to publish a Scala library?")

To sum up, the practices described here can be used in a variety of contexts.

# Due dilligence

Before submitting the question or issue, ensure you've done **as much as you reasonably could** by yourself. Reasonably - because nobody would want you to spend a week searching for an answer they could give you in five minutes.

Many Open Source projects will have a checklist for this, and you can make your own if you like. Here are a couple of things to try:

## Is this an XY problem?

The first thing you should check for is the possibility of asking a completely misguided question.

It's a common trap that you see a problem, come up with a solution, encounter a roadblock while trying to implement it... then get **hung up on that solution**.

Whereas it may be a genuinely legitimate way to get to your goal, it's a good idea to take a step back and ponder:

> Is this really the right way to approach this?

You may find **that it's not** - that you're jumping through hoops to make that solution match the problem, or trying to fit this problem into that solution.

If you're lucky, someone aware of this phenomenon will ask you: **Is this an XY problem?**

From [xyproblem.info][xyproblem]:

> The XY problem is asking about your attempted solution rather than your actual problem.
> This leads to enormous amounts of **wasted time and energy**, both on the part of people asking for help, and on the part of those providing help.

Once I learned about this, I started seeing myself and my peers fall into this trap [unreasonably often](https://en.wikipedia.org/wiki/Frequency_illusion), and I agree with the statement above - it can be a massive waste of time.
Being aware of this pitfall is incredibly useful: we can fight against it.

Consider if you're **asking the right question**. Give your audience a sneak peek of "the bigger picture" of what you're trying to get done.
This will allow them to suggest a better way to do that, if there is one.

## Search around

In general, exploration in search of a solution can be very productive, and serve as a great learning experience too.
There are many places to look in, though, so here are a couple of ideas to get you started.

**Search engines**

Use a search engine - it can be Google, Bing, DuckDuckGo, or whatever you use. Run some basic searches and sift through a couple of pages of the results.

**Knowledge bases**

For [OSS](https://en.wikipedia.org/wiki/Open-source_software) projects, this could be GitHub Issues or Discussions - maybe the question you meant to post has already been asked.
Maybe the bug you encountered has already been reported and then closed as "not a bug".
Who knows, maybe it's been fixed and will be available in the next release!

At work, you can often find useful nuggets of information on Slack and your team's Wiki.

**Documentation**

If you can find it, reach for the documentation. If you can't - you can start by asking for instructions on where to get it.

Documentation could also be code or a product brief. You may be able to gather some information about why what you're trying to do doesn't work, and maybe even figure out **a way to fix it** - always useful information to bring in a bug report.

## Update your software

Ensure that the problem is visible on **the latest available version** of the software you're having problems with.

Sometimes we use older versions of software without being aware of a more recent release,
or there's been a change in the project that **hasn't yet been released** - we can only try it out after switching to a snapshot/nightly distribution channel.
Doing that extra step to get these unreleased changes is usually not strictly necessary, but it may obviate the need for posting an issue, or at least for the maintainers to run that step for you.

Even if you're stuck on an older version, it's good to know whether the problem has already been solved.

## Maybe it's you

Sometimes we are just wrong and don't realize we're the ones making a mistake, especially after a long session of debugging.
**Stay humble**, take a break, look at the problem with fresh eyes and see if you find any flaws in your approach.

Nevertheless, **don't get blocked** - if you honestly see no way forward, asking for help is the right call.
If you're not sure about something, just mention that in the question - you don't have to know everything.
You can even start by asking an easier, more general question, just to validate your understanding - these questions tend to get answered quicker.

# Context

If you've done your research and still feel like you need help, now's the time to start writing: gather all the useful information about your problem, and try to materialize that in your question.

## How much is too much?

Some questions certainly require more insight into the problem, while some can be answered just based on a single sentence. I generally practice the following approach:

**Minimal, yet sufficient.**

That's deliberately vague - I'm afraid you'll have to figure out how much detail to provide on a case-by-case basis, but usually you'll need to post **more information for more complex issues**.

What I _can_ give you, though, is a blueprint.

## Storyline

Your question should tell a story. You're the main character, and the issue you're facing is the villain.

Focusing on your story's most important plot points will make it **easier to follow**, and help make sure you don't miss any crucial details.

### Prologue

Provide some background to explain where the main character is coming from, and what their motivation is.
State the problem you're trying to solve, what you're trying to achieve - **focus on the end goal**, not the implementation details (also see [the XY problem](#is-this-an-xy-problem)).

### Setup

Then, there's the setup of the story: **how did you run into this problem?**

Focus on the steps that took you there, without judgement: just state the facts of what you did that triggered the issue. How does the hero bump into the bad guy?

### Plot twist

You were expecting everything would go according to the plan, but **something else happened**. What does your ideal scenario look like, and what's the reality?

### The investigation

You've already tried to overcome the problem - share your past attempts, and explain **why you think they weren't successful**. It can be helpful to rule out distractions and dead ends.

Is there a pattern in what the issue looks like? Does it happen every time you retrace your steps, or was there something peculiar about that one attempt? (see also: [reproducible example](#reproducible))

Do you have any other information that could be relevant?

### The cliffhanger

After all, we're hoping to get a sequel - a response that explains it all, and a culmination of our characters' arcs.
Before you submit your story for print, you can tease the reader a bit, by telling them what will happen if the villain isn't stopped:

Is this issue critical for you? Does it block you? **Do you have a workaround** that you can apply in the meantime?
Any alternatives that you can use - while the issue is being figured out - will be helpful to others who find themselves in an identical situation.

Keep in mind, though - if you're going to mention that the issue is critical to you and your team, that doesn't give you any more right to a reply than anyone else. **[Don't act entitled](#be-kind)!**

# Example

An important part of every code-related question is an example. If you're asking a question in the style of "this doesn't work" or "I want to do X", **a good example is worth a thousand words**.

Not just _any_ example, though - it should be:

- complete (also called self-contained or standalone).
- minimal
- reproducible

Let's look at these traits in more detail.

## Complete

A good example specifies everything that's necessary to replicate the issue on another person's computer. This includes version numbers of relevant components, imports, compiler flags, your OS type... and **the exact steps to follow**.

Ideally, your example will be self-contained enough that to reproduce the issue, the person reading the report should be able to **run a single command** and see the same result as you did.
For example, a `nix run` call with a pinned [Nix Flake reference](https://blog.kubukoz.com/flakes-first-steps) is as complete as it gets. In the Scala ecosystem, recently it's been best practice to post [a scala-cli Gist](https://scala-cli.virtuslab.org/docs/cookbooks/gists/).

In case of open source projects, it can be very useful to write your reproduction in the style of a test case. Perhaps something that looks like this:

> When I do X, I see Y, but expect to see Z

If you want, you can actually submit a draft Pull Request with **a failing test** that does that.

## Minimal

Remove all unnecessary clutter from any examples you post.

This includes any unused imports or variables, library dependencies, local files, other pieces of your project, and so on.

Of course, if any of these is vital to reproducing the issue, you can leave them in, but make sure they can be used by anyone anytime. Anything else becomes a hindrance, so **stick to the essentials**.

## Reproducible

This may already be covered by the "complete" part, but consider whether your example will behave the same way tomorrow, in a leap year, on a Windows machine, or on Mars.

Okay, fine - it doesn't _actually_ have to run on Windows 💀 but it's imperative that the problem doesn't only happen "sometimes", or that you **make it blatantly obvious** that it does.

Last but not least, don't miss this crucial step:

### Actually run the reproduction

While you're minimizing an issue, it's quite easy to accidentally remove a **seemingly innocent, yet vital piece** of the setup that actually plays a role in the issue - making the code work as designed, instead of showcasing a problem.

I'm sometimes guilty of skipping this step myself (embarrassingly often, really), but I've also seen a number of people make the same mistake - after all, these examples are so small, so simple... how can they be wrong?

Do yourself a favor, add this step to your checklist: when posting a reproduction, make sure you actually run it **before you submit it**. If you're changing it after submission, **run it again**. Make sure the output matches what you reported.

# Communication style

Last but not least, we need to make sure someone actually reads our question and decides to help us. **Proper communication is key!**

## Be kind

This goes without saying: in a public forum, you're just a stranger on the Internet asking people to spend their time (a scarce resource) on _your needs_.
It doesn't mean you shouldn't ask your question, of course - **that's what these places are for**! Just be mindful of your tone and phrasing to make sure it doesn't come off as demanding or entitled.

Respect the time and effort of people who offer to help you: even if it's part of their job, you owe it to them not to abuse their good intentions.

## Be clear

Read your question in whole before you submit it.

If you have the time, do some basic editing. There is no _single_ right way to do it, and from this point you can go as far as you like (running a spellchecker, Grammarly, and so on), just like in any other form of writing.
See if you can remove unnecessary, ~~redundant~~ words, break up longer sentences ~~in your explanations~~ or split your paragraphs into sections.

However, **don't sweat it** - "perfect" is the enemy of "done", and the fact that you're trying is already going to get appreciated!

## Don't waste time

Regardless of whether it's a public forum or a work Slack, it's best to avoid wasting time. On that front, one of the worst offenders are [**roundtrips**](https://en.wikipedia.org/wiki/Round-trip_delay).
Minimize the amount of roundtrips by making your question complete (see the parts about [Due dilligence](#due-dilligence), [Context](#context)) - this will avoid unnecessary follow-up questions, and save time for both sides of the exchange.

The most extreme example of a useless roundtrip is sending a message that **just says "Hello"**. [Don't do it][nohello] - the person reading that message will be forced to wait for the "actual" message you send, before they can even begin to try and help you. Even worse, they may see your message, start doing something else, then have to context switch again after you follow up with the question.

Another example: "Does anybody here know X?" - that's not the question you _really_ want to ask, is it? Add the actual question in a thread or start with it in the first place.

# Use your judgement

> Learn the rules like a pro, so you can break them like an artist.
>
> -Pablo Picasso

Remember, these are just hints and ideas - you don't always have to follow all of them. In certain environments, you'll find it best not to overwhelm people with information about your issue (e.g. if you're asking for general advice on a Slack channel),
and sometimes you have to be more vague because of e.g. [NDA](https://en.wikipedia.org/wiki/Non-disclosure_agreement)s.

In synchronous, private conversations with a coworker you know well, you probably don't need to structure your messages as much as on a GitHub issue, and you can use less formal language as well.
You can also **assume more** about their knowledge of your problem and spare them the overview.

Keep these tips in mind, but ultimately you'll have to follow your gut.

# Summary

I hope these suggestions give you a baseline for the questions you'll ask in your career.
There's clearly more to it, and I'm not the first person to write about this problem either.

You'll find a lot of overlap with documents like ["How To Ask Questions The Smart Way"][smart-questions] - which is a good one, although I consider its tone a bit alienating to recommend it as a first point of contact.

Feel free to share this post with your peers if you wish they gave you better questions, just... [DBAA](https://youtu.be/0wsKxLyYU7E?t=145) 🙂
I also recommend checking out the other sources listed below.

Thanks for reading, and let me know what you think about the post!

Many thanks to my friends [Chris Kipp](https://github.com/ckipp01), [Olivier Mélois](https://github.com/baccata) and [Gabriel Volpe](https://github.com/gvolpe/) for reviewing this post.

# Sources

- [What I’ve learned in open source, and why I think you should contribute.](https://www.chris-kipp.io/slides/open-source)
- [How to Ask Questions The Smart Way][smart-questions]
- [Short, Self Contained, Correct (Compilable), Example](http://sscce.org/)
- [Short but complete programs](https://jonskeet.uk/csharp/complete.html)
- [Don't Just Say "Hello" In Chat][nohello]
- [The XY Problem][xyproblem]

[smart-questions]: http://www.catb.org/esr/faqs/smart-questions.html
[nohello]: https://www.nohello.com
[xyproblem]: https://xyproblem.info/
