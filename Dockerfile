# Base image: ubuntu:22.04
FROM ubuntu:22.04

# ARGs
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG TARGETPLATFORM=linux/amd64,linux/arm64
ARG DEBIAN_FRONTEND=noninteractive

# neo4j 5.5.0 installation and some cleanup
RUN apt-get update && \
    apt-get install -y wget gnupg software-properties-common && \
    wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add - && \
    echo 'deb https://debian.neo4j.com stable latest' > /etc/apt/sources.list.d/neo4j.list && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y nano unzip neo4j=1:5.5.0 python3-pip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# TODO: Complete the Dockerfile

# Copy the all files to container
# COPY . /cse511/ 


# Step 1: Instead of Copy from current directory we need to download data_loader file from github and dataset from the link given in pdf
#   1. DataSet: download a file in bash to cse511 folder - link : https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2022-03.parquet
#   2. data_loader: git clone inside docker container with github tokens

RUN apt-get update && apt-get install -y git
RUN git clone -b data_loader 'https://oauth:{{github_personal_access_token}}@github.com/CSE511-SPRING-2023/ptiwar23-project-2.git' cse511

RUN wget -O - https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2022-03.parquet > /cse511/yellow_tripdata_2022-03.parquet

# -username 'Pravin2720' -password '{{github_personal_access_token}}'
# RUN cp ptiwar23-project-2/ /cse511/

# Step 2: Install the dependancies
RUN pip3 install pyarrow && pip3 install pandas && pip3 install neo4j
# RUN pip3 install requests

# Step 3: Setup Neo4j Password: project2phase1

# ENV NEO4J_AUTH=neo4j/project2phase1
RUN neo4j-admin dbms set-initial-password project2phase1

RUN echo 'server.default_listen_address=0.0.0.0' >> /etc/neo4j/neo4j.conf

# Install and setup neo4j GDS plugin
RUN wget https://graphdatascience.ninja/neo4j-graph-data-science-2.3.1.zip 

# Unzip the plugin and move the jar file to the plugins directory
RUN unzip neo4j-graph-data-science-2.3.1.zip 

RUN mv neo4j-graph-data-science-2.3.1.jar /var/lib/neo4j/plugins/

# Clean up the downloaded zip file and extracted directory
RUN rm -rf neo4j-graph-data-science-2.3.1.zip neo4j-graph-data-science-2.3.1/

# RUN wget -O - https://github.com/neo4j-contrib/neo4j-graph-algorithms/releases/download/3.5.4.0/graph-algorithms-algo-3.5.4.0.jar > /var/lib/neo4j/plugins/graph-algorithms-algo-3.5.4.0.jar
# RUN echo 'dbms.security.procedures.unrestricted=gds.*' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.security.procedures.unrestricted=my.extensions.example,my.procedures.*,gds.*' >> /etc/neo4j/neo4j.conf


# Step 4: run data_loader.py file
# Run the data loader script
# Set the working directory
WORKDIR /cse511
RUN chmod +x /cse511/data_loader.py && \
    neo4j start && \
    python3 data_loader.py && \
    neo4j stop


# Expose neo4j ports
EXPOSE 7474 7687

# Start neo4j service and show the logs on container run
CMD ["/bin/bash", "-c", "neo4j start && tail -f /dev/null"]
