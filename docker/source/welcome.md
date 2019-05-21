title: Welcome


Welcome to the [tuvix](https://github.com/doddo/tuvix) docker container.

There are some recommended reading in the [config instructions](/posts/2019-05-21-configuration-instructions) page, which will help you get started in no time at all.

## what is this

This is a post, like, it's rendered from a markdown document.

it's stored in the db `/opt/tuvix/page/db/tuvix.db` and read from source `/opt/tuvix/page/source`, 
and finally it's reading all this from the config file `/opt/tuvix/tuvix.conf`. 

the db and source paths are specified in the config file, and if they are mounted read-write, it will persist
the data, but beware tha it will enrich the source documents with some metadata tags.

Anyhow: To publish new posts in a blog such like this one, drop a `markdown` document which has a `title:` "tag"
 at the very beginning, and it will publish it. Therefore the idea is that the source directory (and maybe the database file) should be mounted read write when running this container.


Furthermore, there is an additional `/opt/tuvix/page/pub` directory, which gets served by the web server.


![spoken](/spoken.png "Some ghosts served from the pub dir")


This whole project is derived from [Plerd](https://github.com/jmacdotorg/plerd) project which can render static pages, but this one creartes dynamic pages but uses `Plerd::Post`s as the source files, except with heavy modifications done to everything.
