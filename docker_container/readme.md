
# Build container
docker build -t single-server .

docker run -d -p 22:22 -p 1883:1883 -p 8086:8086 -p 3000:3000 single-server
