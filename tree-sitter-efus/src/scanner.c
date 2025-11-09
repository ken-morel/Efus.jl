#include <tree_sitter/parser.h>
#include <wctype.h>
#include <string.h>
#include <stdio.h>

enum TokenType {
  INDENT,
  DEDENT,
  NEWLINE,
};

typedef struct {
  uint16_t *indent_lengths;
  uint16_t indent_capacity;
  uint16_t indent_count;
} Scanner;

static void scanner_create(Scanner *scanner) {
  scanner->indent_capacity = 16;
  scanner->indent_count = 1;
  scanner->indent_lengths = (uint16_t *)malloc(scanner->indent_capacity * sizeof(uint16_t));
  scanner->indent_lengths[0] = 0;
}

static void scanner_destroy(Scanner *scanner) {
  free(scanner->indent_lengths);
}

static void scanner_reset(Scanner *scanner) {
  scanner->indent_count = 1;
  scanner->indent_lengths[0] = 0;
}

static unsigned scanner_serialize(Scanner *scanner, char *buffer) {
  unsigned i = 0;
  buffer[i++] = scanner->indent_count;
  memcpy(&buffer[i], scanner->indent_lengths, scanner->indent_count * sizeof(uint16_t));
  i += scanner->indent_count * sizeof(uint16_t);
  return i;
}

static void scanner_deserialize(Scanner *scanner, const char *buffer, unsigned length) {
  if (length == 0) {
    scanner_reset(scanner);
    return;
  }

  unsigned i = 0;
  scanner->indent_count = buffer[i++];
  memcpy(scanner->indent_lengths, &buffer[i], scanner->indent_count * sizeof(uint16_t));
}

static bool scan(Scanner *scanner, TSLexer *lexer, const bool *valid_symbols) {
  if (valid_symbols[DEDENT] && lexer->lookahead == 0) {
    if (scanner->indent_count > 1) {
      scanner->indent_count--;
      lexer->result_symbol = DEDENT;
      return true;
    }
  }

  if (lexer->lookahead == '\n') {
    lexer->advance(lexer, false);
    lexer->mark_end(lexer);
    lexer->result_symbol = NEWLINE;
    return true;
  }

  if (lexer->get_column(lexer) == 0) {
    uint32_t indent_length = 0;
    while (iswspace(lexer->lookahead)) {
      indent_length++;
      lexer->advance(lexer, false);
    }

    if (indent_length > scanner->indent_lengths[scanner->indent_count - 1]) {
      if (scanner->indent_count == scanner->indent_capacity) {
        scanner->indent_capacity *= 2;
        scanner->indent_lengths = (uint16_t *)realloc(scanner->indent_lengths, scanner->indent_capacity * sizeof(uint16_t));
      }
      scanner->indent_lengths[scanner->indent_count++] = indent_length;
      lexer->result_symbol = INDENT;
      return true;
    }

    if (indent_length < scanner->indent_lengths[scanner->indent_count - 1]) {
      scanner->indent_count--;
      while (indent_length < scanner->indent_lengths[scanner->indent_count - 1]) {
        scanner->indent_count--;
      }
      lexer->result_symbol = DEDENT;
      return true;
    }
  }

  return false;
}

void *tree_sitter_efus_external_scanner_create() {
  Scanner *scanner = (Scanner *)malloc(sizeof(Scanner));
  scanner_create(scanner);
  return scanner;
}

void tree_sitter_efus_external_scanner_destroy(void *payload) {
  Scanner *scanner = (Scanner *)payload;
  scanner_destroy(scanner);
  free(scanner);
}

unsigned tree_sitter_efus_external_scanner_serialize(void *payload, char *buffer) {
  Scanner *scanner = (Scanner *)payload;
  return scanner_serialize(scanner, buffer);
}

void tree_sitter_efus_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  Scanner *scanner = (Scanner *)payload;
  scanner_deserialize(scanner, buffer, length);
}

bool tree_sitter_efus_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
  Scanner *scanner = (Scanner *)payload;
  return scan(scanner, lexer, valid_symbols);
}
