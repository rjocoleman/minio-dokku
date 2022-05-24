FROM minio/minio:RELEASE.2022-05-23T18-45-11Z

# Add user dokku with an individual UID
RUN adduser -u 1000 -g 1000 -m -U minio
USER minio

# Create data directory for the user, where we will keep the data
RUN mkdir -p /data

WORKDIR /app

EXPOSE 9000
EXPOSE 9001

# Run the server and point to the created directory
CMD ["server", "/data", "--console-address", ":9001"]
