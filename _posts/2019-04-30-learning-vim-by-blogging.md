---
layout: post
cover: 'assets/images/learning-vim-bg.jpg'
navigation: True
title: Learning vim by blogging
date: 2019-04-30 14:00
tags:
  - vim
  - text-editors
subclass: 'post tag-test tag-content'
logo: 'assets/images/jk_white.svg'
author: kubukoz
disqus: true
categories: kubukoz
---

I decided that writing about something is one of the easiest ways to learn it for a longer period of time. In this blog post, which I hope to update once in a while, I'l be sharing my findings about Vim (neovim).

This post will be written exclusively in (variants of) Vim.

## Go to the next/previous occurrence of a character

To go to the next occurrence of a character, use `t` (sets the cursor before the character) or `f` (on the character). To find the previous one, use `T` (after the character) or `F` (on the character).

For example, in this line:

```scala
def foo = bar<cursor> + 5
```

If I want to select `= bar` (space included), I can press `F=`.

## Copy/paste to clipboard

To copy to the buffer inside Vim, you press `y` after selecting some text. To copy it to the clipboard, you use `"*y`. Similarly with `p` for pasting.

## Go to first/last line of file

Press `gg` / `G`.

## Go to beginning/end of line

Press `^` / `$`.
