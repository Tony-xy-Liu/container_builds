FROM perl:5.16.3
# scope var from global

# I believe this is to avoid permission issues with 
# manipulating added files to places like /opt
RUN old_umask=`umask` \
    && umask 0000 \
    && umask $old_umask

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ADD ./lib/tini /tini
RUN chmod +x /tini
    
# singularity doesn't use the -s flag, and that causes warnings.
# -g kills process group on ctrl+C
ENTRYPOINT ["/tini", "-s", "-g", "--"]

# gapmind src
COPY ./lib/PaperBLAST /app/PaperBLAST

# hmmer setup
COPY ./lib/hmmer-3.3.1 /app/hmmer-3.3.1
RUN cd /app/hmmer-3.3.1 \
    && ./configure --prefix /app/PaperBLAST \
    && make && make install

# perl modules
RUN rm /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian/ jessie main" >> /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian/ jessie-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --force-yes --no-install-recommends \
    libdbi-perl \
    libdbd-sqlite3-perl \
    libwww-perl \
    bioperl \
    libdb-dev \
    && rm -rf /var/lib/apt/lists/*
RUN cpanm FindBin Getopt::Long List::Util \
    CGI HTML::Entities IO::Handle File::stat Time::HiRes \
    JSON IO::String \
    DB_File
RUN cpanm LWP::Simple
RUN cpanm XML::LibXML

# more dependencies
COPY ./lib/db/path.aa /app/PaperBLAST/tmp/path.aa
COPY ./lib/db/path.carbon /app/PaperBLAST/tmp/path.carbon
COPY ./lib/diamond /app/PaperBLAST/bin/

# gapmind setup
RUN cd /app/PaperBLAST \
    && mkdir fbrowse_data \
    && mkdir private \
    && mkdir -p tmp/downloaded \
    && bin/extractHmms.pl tmp/path.aa/steps.db tmp/path.aa \
    && bin/extractHmms.pl tmp/path.carbon/steps.db tmp/path.carbon \
    && bin/diamond makedb --in tmp/path.aa/curated.faa -d tmp/path.aa/curated.faa.dmnd \
    && bin/diamond makedb --in tmp/path.carbon/curated.faa -d tmp/path.carbon/curated.faa.dmnd

# expose executables to path
ENV PATH /app/PaperBLAST/bin:/app/PaperBLAST/cgi:$PATH

RUN cpanm DBI Bio::SeqIO
RUN cpanm DBD::SQLite