FROM mcr.microsoft.com/powershell
RUN pwsh -c Set-PSRepository -Name 'PSGallery' -InstallationPolicy "Trusted" && \
    pwsh -c Install-Module Indented.Net.IP && \
    pwsh -c Set-PSRepository -Name 'PSGallery' -InstallationPolicy "Trusted" 