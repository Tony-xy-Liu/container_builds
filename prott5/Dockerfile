FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-runtime

RUN old_umask=`umask` && umask 0000 && umask $old_umask

ADD ./load/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "-s", "-g", "--"]

COPY ./load/requirements.txt /opt/requirements.txt
RUN pip install --no-cache-dir -r /opt/requirements.txt
