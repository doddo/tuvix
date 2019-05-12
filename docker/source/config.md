title: Configuration instructions
type: page


Here is some documentation about how to configure [tuvix](https://github.com/doddo/tuvix).



## <a id="runningindocker"></a>Running in Docker with dropbox

Just like [plerd](https://github.com/jmacdotorg/plerd#using-plerd-with-dropbox), also tuvix is created to run with such services like Dropbox or OneDrive usw. 

The idea is then, that you simply upload the source files (markdown or any other supported format) into the source directory, and then it becomes automatically published.


### preparations (in Dropbox)

Here's how to configure a Dropbox backed Tuvix installation in Docker.

* In dropbox create the following directories `tuvix/{db,pub,source}`:
* create the following configuration and upload to `tuvix/tuvix.conf` :


<pre>
{
  db => ["dbi:SQLite:/dbox/Dropbox/tuvix/db/tuvix.db","",""],

  db_opts => {
    RaiseError     => 1,
    sqlite_unicode => 1,
  },

  minion_workers   => 10,
  
  # starts the directory_watcher, watching source_path
  watch_source_dir => 1,
  
  # some uri:s created will want to contain this, if running on other port
  # than 443 or 80, (this will be fixed before GA release)
  listening_port_in_uris => 1,

  # if put behind reverse proxy, put the actual base URI here
  base_uri         => 'http://localhost:8080',
  
  path             => '/dbox/Dropbox/tuvix',
  source_path      => '/dbox/Dropbox/tuvix/source',
  publication_path => '/dbox/Dropbox/tuvix/pub',
  title            => 'Example Tuvix Installation',
  author_name      => 'Foobar',
  author_email     => 'foo@bar.re',
  
  author_photo     => '/assets/generic_face.png' 
}
</pre>



create also some sort of initial "hello world" post or something, and put it in the `tuvix/source` directory:

    title: Hello World!
    
    This is welcome post
    
    only the `title: ` part is mandatory (and strictly not markdown fmt.).
    All other makdown syntax works more or less as expected.



Now it will look something like this 

    tuvix
    ├── db
    │   └── tuvix.db         # created automatically (absent before first run)
    ├── pub                  # stuff put in here will be served under /
    ├── source               # this dir is constantly watched for changes
    │   └── hello_world.md   # example post
    └── tuvix.conf           # The config file


### Run the containers
First is the [janeczku/dropbox](https://hub.docker.com/r/janeczku/dropbox/) container. Start it with `DBOX_UID` and `DBOX_GID` both set to `999` (the user running the tuvix stuff)
    
    sudo docker run \
               --name=dropbox \
               -e DBOX_UID=999 \
               -e DBOX_GID=999 \
             janeczku/dropbox
    
    
Something like that. Then with this in place, start the `doddo/tuvix` container with something like:
    
    sudo docker run \
              --name=tuvix
              -e MOJO_CONFIG=/dbox/Dropbox/tuvix/tuvix.conf \ 
              --volumes-from dropbox \
              -p 8080:8080 \
            doddo/tuvix 
    

And you can go visit the http://localhost:8080 and you're done.




 ## <a id="reverseproxy"></a>Reverse Proxy setup 


It's documented [here](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Nginx) how to configure nginx or apache2 as a reverse proxy.


Here you can terminate ssl and what ever such things, as no such support is in Tuvix. 

Basically the instructions in there are solid, but the caveat is that in `plerd.conf`, 

the `base_uri` should reflect the `server_name` in the reverse proxy setup. Also protocol, like

SSL (so `https://exaxmple.com` if blog is served in ssl )  

	location / {
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection "Upgrade";
		proxy_set_header Host $host;
		proxy_pass http://127.0.0.1:8080;
	        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
		proxy_redirect     off;
		proxy_set_header   Host $host;
	}
