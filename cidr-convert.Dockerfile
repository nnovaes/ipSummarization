FROM golang
ENV OOS darwin
ENV GOARCH amd64 
VOLUME "/outbin"
COPY cidr-convert/* /cidr-convert/
WORKDIR /cidr-convert
RUN go build cidr-convert.go
