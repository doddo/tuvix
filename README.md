[![Build Status](https://travis-ci.org/doddo/tuvix.svg?branch=master)](https://travis-ci.org/doddo/tuvix)

# Tuvix

Tuvix is a top modern weblog software based on [Plerd](https://github.com/jmacdotorg/plerd) except instead of rendering a static site like Plerd does, this one uses [Mojolicious](https://mojolicious.org/) (An amazing real-time web framework). This means that infinite scrolling and other great stuff works out of the box (but could potentially be turned of in favour of more traditional pagination in a future release version).
Furthermore, while Plerd is ultralight Tuvox is more focused on being (somewhat) feature-rich, (atleast feature-richer) for example it supports the [Instaplerd](https://github.com/doddo/instaplerd), so that you swiftly can spin up a photoblog (or a hybrid since it'll accept markdown and jpegs as source files)

## How to install

```bash
curl -fsSL https://cpanmin.us | perl - --installdeps .
perl Makefile.PL
make
make test
make install
```

## How it works

It works much the same as Plerd does, but instead of rendering the Plerd::Posts into a html webpage, it stores it in a Database. Likely it will work with any database which can be managed by [DBIx::Class](https://metacpan.org/pod/DBIx::Class) (but that might require extra modules), but Sqlite is the "supported" one (insofar as any such thing as support can be talked about in this context) which fits the philosophy of Plerd nicely because you can store all the stuff in dropbox and so forth.

## More extensive documentation

There will be more exhaustive documentation here, in detail describing all the settings and configurations possible, as well as some nginx reverse proxy for SSL termination usw but that will have to wait for there is currently no such things as this program is under construction still.

# LICENSE

Copyright (C) Petter H

This library is released under the MIT license. 


# AUTHOR

Petter H <dr.doddo@gmail.com>

# CREDITS

* [Jason McIntosh](http://jmac.org/):  Most of the templates have been ported from [Plerds templates](https://github.com/jmacdotorg/plerd/tree/master/t/templates) which is originally written by Jason McIntosh. Thet have been re-written from .tt => .ep format but have otherwise been left intact so as to maintain the same look and feel as Pled does. 

