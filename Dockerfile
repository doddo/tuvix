FROM perl:latest

RUN useradd --system tuvix -d /opt/tuvix/
RUN mkdir -p /opt/tuvix/page/{db,source}
COPY . /opt/tuvix/
RUN chown -R  tuvix.tuvix /opt/tuvix

WORKDIR /opt/tuvix
USER tuvix

ENV PERL5LIB /opt/tuvix/perl5/lib/perl5


RUN cpanm --local-lib=~/perl5 local::lib && eval $(perl -i ~/perl5/lib/perl5/ -Mlocal::lib)
RUN cpanm Mojo::Server::Hypnotoad
RUN cpanm  -M https://cpan.metacpan.org  --notest --installdeps .
RUN perl  Makefile.PL && make


COPY tuvix.conf.example /opt/tuvix/tuvix.conf


ENTRYPOINT /opt/tuvix/perl5/bin/hypnotoad -f script/tuvix
