FROM golang
ENV OOS linux
ENV GOARCH amd64 
COPY cidr-convert/ /cidr-convert/
WORKDIR /cidr-convert
RUN go build cidr-convert.go


FROM mcr.microsoft.com/powershell
COPY --from=0 /cidr-convert/cidr-convert /bin/
RUN chmod +x /bin/cidr-convert && \
    pwsh -c Set-PSRepository -Name 'PSGallery' -InstallationPolicy "Trusted" && \
    pwsh -c Install-Module Indented.Net.IP && \
    pwsh -c Set-PSRepository -Name 'PSGallery' -InstallationPolicy "Trusted" 
VOLUME [ "summarize" ]
WORKDIR /summarize
COPY *.ps* /summarize/script/
COPY *.txt /summarize/data/
COPY summarizeIP.sh /summarize/script/
RUN chmod +x /summarize/script/*.ps1 && chmod +x /summarize/script/*.sh
ENTRYPOINT [ "/summarize/script/summarizeIP.sh"]


