# Get WPForms info on EPFL WordPresses fleet

This repository lists the steps to retrieve some information on the number of
WPForms / Payonline / Data installed on the EPFL's WordPresses.

## getFormsData

The [getFormsData.sh](./getFormsData.sh) script follow these steps:

1. Retrieve all the sites from [wp-veritas] that belong to the category
   "WPForms", with a [curl] request piped in [jq]:  
   `curl https://wp-veritas.epfl.ch/api/v1/categories/WPForms/sites | jq  '.[]'`
1. Construct the site's path from the URL (see the `URLtoPath` function). It
   handles four kinds of paths: `labs`, `inside`, `www` and `subdomains-lite`.
   Please note that `subdomains` are just for redirections and does not contain
   any websites.
1. Run a series of [wp cli] commands to fetch all relevant information and save
   them in a [CSV] file.

## getWPFormsInfo

The [getWPFormsInfo.sh](./getWPFormsInfo.sh) use the sites' list generated with
`getFormsData.sh` to query:

1. The installed version of `WPForms` and `WPForms-EPFL-Payonline` plugins.
1. The way they are installed (symlinked or not).

This script does not generate any report, but its output is straight forward.

## Misc

Get the numbers of sites that have WPForms installed:  
`curl https://wp-veritas.epfl.ch/api/v1/categories/WPForms/sites | jq  '. | length'`

[wp-veritas]: https://wp-veritas.epfl.ch
[curl]: https://curl.se/
[jq]: https://jqlang.github.io/jq/
[wp cli]: https://developer.wordpress.org/cli/commands/cli/
[csv]: https://en.wikipedia.org/wiki/Comma-separated_values
