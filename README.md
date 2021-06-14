# Mardiie-Cloudflare_REST_ipupdate
A script written in Bash to automate the process of updating your dynamic IP address to CloudFlare's DNS service.

**1.**
Download the script, unit and timer file.\
Extract these files to a directory of your choice.

**2.**
Edit the script file and fill in the email, key and workdir variable.\
*#workdir will be the directory you've placed the script in.

**3.**
Create a file called "records" in the script directory. \
Each first line should be the domain name to update, each second line should be the CloudFlare REST API URL.

Example:
> domain.tld \
> https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dns_records/372e67954025e0ba6aaa6d586b9e0b59 \
> sub.domain.tld \
> https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dns_records/372e67954025e0ba6aaa6d586b9e0b59

Check out the CloudFlare API documentation for more info.\
https://api.cloudflare.com/#dns-records-for-a-zone-create-dns-record

**4.**
Edit the unit file to reflect your work directory in the ExecStart line.

**5.**
Import the unit and timer file to one of your systemd dirs.

**6.**
Run:
```
systemctl enable cf_rest_updater.timer
systemctl start cf_rest_updater.timer
```
