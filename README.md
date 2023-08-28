# xls2csv
convert microsoft xlsx to csv

### example

```sh
# convert to csv, skip first line and calculate statistics using xsv
xls2csv < sheet.xlsx | tail -n +2 | xsv stats
```

### build

Just build Dockerfile. Depends on [just](https://github.com/casey/just) for some trivial steps for extracting `xls2csv` executable from container to host.

```sh
just build
```

