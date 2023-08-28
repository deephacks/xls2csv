
IMAGE := "xls2csv"

build-linux: docker-build-linux
  just run-linux "gcc xls2csv.c -static \
    /usr/local/musl/lib/libxlsxio_read.a \
    /usr/local/musl/lib/libxlsxio_write.a \
    /usr/local/musl/lib/libexpat.a \
    /usr/local/lib/libminizip.a \
    /usr/local/musl/lib/libz.a \
    -pthread -DBUILD_XLSXIO_STATIC -O3 \
    -o xls2csv-linux \
    && strip xls2csv-linux"
  # extract executable built in previous step to host by calling just task 'run' below
  sudo chown $(id -u):$(id -g) xls2csv-linux


# build the xls2csv executable
docker-build-linux:
  docker build -t "{{IMAGE}}:linux" .

test:
  ./xls2csv-linux < example.xlsx
  ./xls2csv-linux example.xlsx

# build and extract from container, then install the xls2csv executable on host
install: docker-build-linux
  sudo install -v -m755 xls2csv /usr/local/bin

# run command inside container, mounting current dir as working dir
run-linux +cmd:
  docker run -it --rm -v "$(pwd):/app" -w /app "{{IMAGE}}:linux" bash -c '{{cmd}}'
