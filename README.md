# Tools For Decommissioning Atom

Use with extreme caution.

## Generating synclists

``` mkdir -p sync && egrep -ho 'href="[^"]+' *.xml | cut -f2 -d'"' | split -a3 - sync/synclist. && mmv sync/* sync/*.txt```
