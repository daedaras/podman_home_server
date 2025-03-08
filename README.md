<a id="readme-top"></a>

# Podman Home Server

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <!-- <li><a href="#roadmap">Roadmap</a></li> -->
    <!-- <li><a href="#contributing">Contributing</a></li> -->
    <li><a href="#license">License</a></li>
    <!-- <li><a href="#contact">Contact</a></li> -->
    <!-- <li><a href="#acknowledgments">Acknowledgments</a></li> -->
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About the Project

Easily install & setup your own home server using rootless podman systemd units (quadlet). This installation contains several components:

- home-assistant
- esphome
- mosquitto broker
- nodered
- nextcloud

The setup was tested on **arch-linux**, but it should be fairly easy to adapt for other distros.

<p align="right"><a href="#readme-top">back to top</a></p>

## Important Notes

This is supposed to run in your home network only. Some of the settings are not secure (e.g. nodered is not setup with a admin & password and exposing it to the internet would make it accessible to anyone).

<span style="color:red"><b>!!!The install scripts will drop and overwrite the following directories/files:</b></span>

- /etc/nginx/nginx.conf
- /etc/nginx/sites
- /etc/nginx/ssl
- ~/.config/containers/systemd/hass
- ~/.config/containers/systemd/nodered
- ~/.config/containers/systemd/nextcloud

and create following images:

- localhost/nextcloud_nginx
- localhost/nextcloud_php
- localhost/nextcloud_postgres
- localhost/nextcloud_redis

and containers:

- nodered
- esphome
- hass-hass
- hass-mosquitto
- nextcloud-nginx
- nextcloud-php
- nextcloud-postgres
- nextcloud-redis

and volumes:

- nodered-data
- hass-esphome
- hass-config
- hass-media
- hass-mosquitto-config
- hass-mosquitto-data
- hass-mosquitto-log
- nextcloud-collabora
- nextcloud-web
- nextcloud-data
- nextcloud-pgdata

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

Please make sure following components/packages are installed:

- podman >=5.0 (only tested with 5.3.1)
- nginx with brotli support

*On arch-linux you can just run the *install_on_arch_with_tools.sh* script and the prerequisites will be fulfilled. The script is using *sudo* where required and will once ask for the password.

### Installation

1. Copy the example envfiles and adjust them to your needs  
   - *container/envfiles/example.hass.env -> container/envfiles/hass.env*
   - *container/envfiles/example.nextcloud.env -> container/envfiles/nextcloud.env*
   - *container/envfiles/example.proxy.env -> container/envfiles/proxy.env*
1. On arch-linux run the *install_on_arch.sh* (optionally with --additional-tools).
   On other distros please make sure you fulfill the prerequisites and run the *install.sh* script.
1. Setup your home-assistant user on the main page: [https://\<HOSTNAME\>/](https://\<HOSTNAME\>/)
1. \[Optionally\] Install the self signed certificate on your client to get rid of ssl errors (browser restart will be required afterwards):
    - On Mac:

      ```bash
      # replace <HOSTNAME> with your HOSTNAME setting
      HOSTNAME="<HOSTNAME>"
      # download certificate
      </dev/null openssl s_client -connect $HOSTNAME:443 -servername $HOSTNAME | openssl x509 > /tmp/$HOSTNAME.cert
      # install certificate
      sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/$HOSTNAME.cert
      ```

    - On Linux:

      ```bash
      # replace <HOSTNAME> with HOSTNAME setting
      HOSTNAME="<HOSTNAME>"
      sudo bash -c "openssl s_client -connect $HOSTNAME:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM > $HOSTNAME.crt"
      sudo mv $HOSTNAME.crt /usr/local/share/ca-certificates/
      sudo update-ca-certificates
      ```

    - On Arch-Linux:

      ```bash
      # replace <HOSTNAME> with HOSTNAME setting
      HOSTNAME="<HOSTNAME>"
      sudo bash -c "openssl s_client -connect $HOSTNAME:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM > $HOSTNAME.crt"
      sudo mv $HOSTNAME.crt /etc/ca-certificates/trust-source/anchors/
      sudo trust extract-compat
      ```

    - On Windows (powershell):

      ```powershell
      # replace <HOSTNAME> with HOSTNAME setting
      $HOSTNAME="<HOSTNAME>"
      # download certificate
      $webRequest = [Net.WebRequest]::Create("https://$HOSTNAME")
      try { $webRequest.GetResponse() } catch {}
      $cert = $webRequest.ServicePoint.Certificate
      $bytes = $cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
      Set-Content -value $bytes -encoding byte -path "$pwd\$HOSTNAME.cert"
      # install certificate
      Import-Certificate -FilePath "$pwd\$HOSTNAME.cert" -CertStoreLocation Cert:\LocalMachine\Root
      ```

<p align="right"><a href="#readme-top">back to top</a></p>

<!-- USAGE -->
## Usage

All pages should be available via the following urls:

- home-assistant: [https://\<HOSTNAME\>/](https://\<HOSTNAME\>/)
- esphome:        [https://\<HOSTNAME\>/esphome>](https://\<HOSTNAME\>/esphome>)
- nextcloud:      [https://\<HOSTNAME\>/nextcloud>](https://\<HOSTNAME\>/nextcloud>)
- node-red:       [https://\<HOSTNAME\>/nodered>](https://\<HOSTNAME\>/nodered>)

<!-- CONTRIBUTING -->
<!-- ## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Top contributors:

<a href="https://github.com/othneildrew/Best-README-Template/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=othneildrew/Best-README-Template" alt="contrib.rocks image" />
</a>

<p align="right"><a href="#readme-top">back to top</a></p> -->

<!-- LICENSE -->
## License

Distributed under the Unlicense License. See `LICENSE` for more information.

<p align="right"><a href="#readme-top">back to top</a></p>

<!-- CONTACT -->
<!-- ## Contact

Your Name - [@your_twitter](https://twitter.com/your_username) - email@example.com

Project Link: [https://github.com/your_username/repo_name](https://github.com/your_username/repo_name)

<p align="right"><a href="#readme-top">back to top</a></p> -->

<!-- ACKNOWLEDGMENTS -->
<!-- ## Acknowledgments

Use this space to list resources you find helpful and would like to give credit to. I've included a few of my favorites to kick things off! 

<p align="right"><a href="#readme-top">back to top</a></p>-->
