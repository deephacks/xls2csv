#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>
#include <unistd.h>
#include "xlsxio_read.h"
#include "xlsxio_version.h"

struct xlsx_data {
  xlsxioreader xlsxioread;
  FILE* dst;
  int nobom;
  const char* newline;
  char separator;
  char quote;
  const char* filename;
};

int sheet_row_callback(size_t row, size_t maxcol, void* callbackdata) {
  struct xlsx_data* data = (struct xlsx_data*)callbackdata;
  fprintf(data->dst, "%s", data->newline);
  return 0;
}

int sheet_cell_callback(size_t row, size_t col, const XLSXIOCHAR* value, void* callbackdata) {
  struct xlsx_data* data = (struct xlsx_data*)callbackdata;
  if (col > 1)
    fprintf(data->dst, "%c", data->separator);
  if (value) {
    // print quoted value?
    if (data->quote && (strchr(value, data->quote) || strchr(value, data->separator) || strchr(value, '\n') || strchr(value, '\r'))) {
      const char* p = value;
      fprintf(data->dst, "%c", data->quote);
      while (*p) {
        // duplicate quote character
        if (*p == data->quote)
          fprintf(data->dst, "%c%c", *p, *p);
        // otherwise just print character
        else
          fprintf(data->dst, "%c", *p);
        p++;
      }
      fprintf(data->dst, "%c", data->quote);
    } else {
      fprintf(data->dst, "%s", value);
    }
  }
  return 0;
}

int xlsx_list_sheets_callback(const char* name, void* callbackdata) {
  char* filename;
  struct xlsx_data* data = (struct xlsx_data*)callbackdata;
  // determine output file
  if ((filename = (char*)malloc(strlen(data->filename) + strlen(name) + 6)) == NULL) {
    fprintf(stderr, "Memory allocation error\n");
  } else {
    if ((data->dst = stdout) == NULL) {
      fprintf(stderr, "Error creating output file: %s\n", filename);
    } else {
      // write UTF-8 BOM header
      if (!data->nobom)
        fprintf(data->dst, "\xEF\xBB\xBF");
      // process data
      xlsxioread_process(data->xlsxioread, name, XLSXIOREAD_SKIP_EMPTY_ROWS, sheet_cell_callback, sheet_row_callback, data);
      // close output file
      fclose(data->dst);
    }
    // clean up
    free(filename);
  }
  return 0;
}

int main(int argc, char* argv[]) {
  int i;
  char* param;
  xlsxioreader xlsxioread;
  struct xlsx_data sheetdata = {
    .nobom = 0,
    .newline = "\r\n",
    .separator = ',',
    .quote = '"',
  };
  
  if (argc < 2 && (xlsxioread = xlsxioread_open_filehandle(STDIN_FILENO)) != NULL) {
    sheetdata.xlsxioread = xlsxioread;
    sheetdata.filename = "";
    // iterate through available sheets
    xlsxioread_list_sheets(xlsxioread, xlsx_list_sheets_callback, &sheetdata);
    // close .xlsx file
    xlsxioread_close(xlsxioread);
  } else if ((xlsxioread = xlsxioread_open(argv[1])) != NULL) {
    sheetdata.xlsxioread = xlsxioread;
    sheetdata.filename = argv[1];
    // iterate through available sheets
    xlsxioread_list_sheets(xlsxioread, xlsx_list_sheets_callback, &sheetdata);
    // close .xlsx file
    xlsxioread_close(xlsxioread);
  } else {
    fprintf(stderr, "xls2csv error: %s\n", "stdin");
    return 1;
  }
  return 0;
}
