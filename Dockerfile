FROM perl:latest

RUN apt update && apt install -y supervisor sqlite3

RUN useradd --system tuvix -d /opt/tuvix/
RUN mkdir -p /opt/tuvix/page/db /opt/tuvix/page/source
COPY Makefile.PL /opt/tuvix/Makefile.PL
COPY cpanfile /opt/tuvix/cpanfile
RUN chown -R tuvix.tuvix /opt/tuvix

WORKDIR /opt/tuvix
USER tuvix

ENV PERL5LIB /opt/tuvix/perl5/lib/perl5


RUN cpanm --local-lib=~/perl5 local::lib && eval "$(perl -i ~/perl5/lib/perl5/ -Mlocal::lib)"
RUN cpanm Mojo::Server::Hypnotoad
RUN cpanm  -M https://cpan.metacpan.org  --notest --installdeps .

# Add lib after pulling dependencies.
COPY --chown=tuvix lib/ /opt/tuvix/lib
COPY --chown=tuvix script/ /opt/tuvix/script
RUN perl Makefile.PL && make

COPY --chown=tuvix docker/source/* /opt/tuvix/page/source/
COPY --chown=tuvix docker/pub/ /opt/tuvix/page/pub
VOLUME /opt/docker/page

COPY --chown=tuvix docker/tuvix.conf /opt/tuvix/tuvix.conf

USER root
COPY docker/dbinit.sh /usr/local/bin/
COPY docker/supervisord.conf /etc/supervisor/supervisord.conf
USER tuvix

ENV PATH="/opt/tuvix/perl5/bin:${PATH}"

EXPOSE 8080

CMD ["/usr/bin/supervisord"]
