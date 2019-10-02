COULD BE ADDED
===========
* Manpage lookup rate limiting (i.e. worker pool)
* Maybe built-in manpage parsing but that sounds hard
* Tests but probably not because who cares

NAME
====
Manpage Bot - a Discord-based interface to
              the Ubuntu manpage repo

SYNOPSIS
========
!man MANPAGE...

!man SECTION MANPAGE

DESCRIPTION
===========
Manpage Bot (MB for short) is a simple bot
that looks up and parses manpages from the
Ubuntu manpage repo.

Given one or more MANPAGE, MB will print
the description section of the MANPAGE(s)
and provide a URL to an online HTML version.
Like the regular man command, sections are
searched in order and the first found
manpage is shown.

Given a SECTION and a MANPAGE, MB will
print the MANPAGE in that SECTION (if it
exists), instead of searching.

AUTHOR
======
Written by erer1243 \#3478
