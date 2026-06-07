# shellcheck disable=all
set export
set dotenv-load

HOME     := env_var("HOME")
BIN_DIR  := env_var_or_default("XDG_BIN_HOME", HOME / ".local" / "bin")

IMAGE := "xls2csv"

default: build test install

build: docker-build-linux
  just run-linux "gcc xls2csv.c -static \
    /usr/local/musl/lib/libxlsxio_read.a \
    /usr/local/musl/lib/libxlsxio_write.a \
    /usr/local/musl/lib/libexpat.a \
    /usr/lib/x86_64-linux-gnu/libminizip.a \
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
install:
  sudo install -v -m755 xls2csv-linux {{BIN_DIR}}/xls2csv

# run command inside container, mounting current dir as working dir
run-linux +cmd:
  docker run -i --rm -v "$(pwd):/app" -w /app "{{IMAGE}}:linux" bash -c '{{cmd}}'
