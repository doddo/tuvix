[![Build Status](https://travis-ci.org/doddo/tuvix.svg?branch=master)](https://travis-ci.org/doddo/tuvix)

# Tuvix

Tuvix is a top modern social media weblog software based on [Plerd](https://github.com/jmacdotorg/plerd) (Ultralight Dropbox-friendly Markdown-based blogging), except instead of rendering a static site like Plerd does, it uses [Mojolicious](https://mojolicious.org/) (An amazing real-time web framework) to render a dynamic web page. 
This means that infinite scrolling and other great stuff works out of the box (but could potentially be turned of in favour of more traditional pagination in a future release version).
Furthermore, while Plerd is ultralight Tuvox is more focused on being (somewhat) feature-rich, (atleast feature-richer) for example it supports the powerful [Instaplerd](https://github.com/doddo/instaplerd) extension, so that you swiftly can spin up a photoblog (or rather a hybrid, since it'll accept markdown and jpegs both as source files)

## How to install

```bash
curl -fsSL https://cpanmin.us | perl - --installdeps .
perl Makefile.PL
make
make test
# make install
```

## How it works

It works much the same as Plerd does, but instead of rendering the Plerd::Posts into a html webpage, it stores it in a Database. Likely it will work with any database which can be managed by [DBIx::Class](https://metacpan.org/pod/DBIx::Class) (but that might require extra modules), but Sqlite is the "supported" one (insofar as any such thing as support can be talked about in this context) which fits the philosophy of Plerd nicely because you can store all the stuff in dropbox and so forth.

## More extensive documentation

There will be more exhaustive documentation here, in detail describing all the settings and configurations possible, as well as some nginx reverse proxy for SSL termination usw but that will have to wait for there is currently no such things as this program is under construction still.

## How to run

You can fire up the app in three simple steps. First is editing `tuvix.conf` to add some config directives (which will soon be documented), then deploy the SQL schema aswell as publish the source directory with:

```bash
$ script/plerdall_db.pl --config /home/petter/git/tuvix/tuvix.conf \
    --deploy-schema \
    --drop-tables
```
Then finally start it either through plain `script/tuvix daemon` or for production sites with hypnotoad like this:

```
$ hypnotoad script/tuvix
Starting hot deployment for Hypnotoad server 32023.
```


### Start the job queue

Webmentions (not 100% implemented) as well as the directory watcher  and other such slow processes are handled with the the [Minion](https://mojolicious.org/perldoc/Minion) Job queue system.

```
script/tuvix minion worker
```

The directory watcher, which watches a specidied (in the config) directory for changes and publishes source files can be started by enqueuing to the job queue:

```bash
script/tuvix minion job --enqueue watch_directory
1
```


# LICENSE

Copyright (C) Petter H

This library is released under the MIT license. 


# AUTHOR

Petter H <dr.doddo@gmail.com>

# CREDITS

* [Jason McIntosh](http://jmac.org/):  Most of the templates have been ported from [Plerds templates](https://github.com/jmacdotorg/plerd/tree/master/t/templates) which is originally written by Jason McIntosh. Thet have been re-written from .tt => .ep format but have otherwise been left intact so as to maintain the same look and feel as Pled does. 

