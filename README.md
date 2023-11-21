# Get WPForms info on EPFL Worpresses fleet

This repository lists the steps to retreive some information on the number of
WPForms / Payonline / Data installed on the EPFL Wordpresses.

The script should answer that kind of questions:

- How many site have WPForms installed?
- How many site have WPForms with payment?
- How many forms per site?
- How many forms entries per form?
- Does the form has upload fields?

## How To

The [getFormsData.sh](./getFormsData.sh) script follow these steps:

1. Retrieve all the sites from [wp-veritas] that belong to the category
   "WPForms", with a [curl] request piped in [jq]:  
   `curl https://wp-veritas.epfl.ch/api/v1/categories/WPForms/sites | jq  '.[]`
1. Construct the site's path from the URL (see the `URLtoPath` function). It
   handles 4 kind of paths: `labs`, `inside`, `www` and `subdomains-lite`.
   Please note that `subdomains` are just for redirections and does not contain
   any websites.
1. Run a bunch of [wp cli] commands to fetch all relevant information and save
   them in a [CSV] file.

## Misc

Get the numbers of sites that have WPForms installed :  
`curl https://wp-veritas.epfl.ch/api/v1/categories/WPForms/sites | jq  '. |  length'`

[wp-veritas]: https://wp-veritas.epfl.ch
[curl]: https://curl.se/
[jq]: https://jqlang.github.io/jq/
[wp cli]: https://developer.wordpress.org/cli/commands/cli/
[csv]: https://en.wikipedia.org/wiki/Comma-separated_values
