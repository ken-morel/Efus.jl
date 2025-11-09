/**
 * @file A tree-sitter grammar parser for the efus mini language
 * @author Engon Ken Morel <engonken8@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "efus",

  extras: $ => [
    $.comment,
    /[ \t\r]/, // Allow whitespace, but NOT newlines
  ],

  rules: {
    source_file: $ => repeat($._statement),

    _statement: $ => choice(
      $.if_statement,
      $.for_statement,
      $.snippet_definition,
      seq($.component_call, $._newline),
      seq($.expression, $._newline), // For standalone expressions like julia_block
      $.blank_line
    ),

    blank_line: $ => $._newline,

    expression: $ => repeat1(choice(
      $._value,
      // Allow operators as part of an expression
      '+', '-', '*', '/', '>', '<', '==', '!=', '&&', '||', '!', '~', '^', '%',
      '|', '&', '<<', '>>', '>>>', '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '<<=', '>>=', '>>>=',
      '?', ':', '...', '=>', '->', '::', '.', '..', '...',
    )),

    component_call: $ => seq(
      field('name', $.identifier),
      repeat(choice(
        $.property_assignment,
        $.grouped_property_assignment,
        $.splat_operator
      ))
    ),

    property_assignment: $ => seq(
      field('key', $.identifier),
      '=',
      field('value', $._value)
    ),

    grouped_property_assignment: $ => seq(
      field('group', $.identifier),
      ':',
      field('key', $.identifier),
      '=',
      field('value', $._value)
    ),

    splat_operator: $ => seq($.identifier, '...'),

    if_statement: $ => seq(
      'if',
      field('condition', $.expression),
      $._newline,
      repeat($._statement),
      repeat($.else_if_clause),
      optional($.else_clause),
      'end',
      $._newline
    ),

    else_if_clause: $ => seq(
      'elseif',
      field('condition', $.expression),
      $._newline,
      repeat($._statement)
    ),

    else_clause: $ => seq(
      'else',
      $._newline,
      repeat($._statement)
    ),

    for_statement: $ => seq(
      'for',
      field('iterator', $.for_iterator),
      'in',
      field('collection', $.expression),
      $._newline,
      repeat($._statement),
      optional($.else_clause),
      'end',
      $._newline
    ),

    for_iterator: $ => choice(
      field('name', $.identifier),
      $.for_destructuring
    ),

    for_destructuring: $ => seq(
      '(',
      separated_list1(',', field('name', $.identifier)),
      ')'
    ),

    julia_block: $ => seq(
      '(' ,
      repeat(choice(
        /[^()]+/, 
        $.julia_block
      )),
      ')'
    ),

    vector: $ => seq(
      '[' ,
      repeat(choice(
        /[^\\\[\\\]]+/, 
        $.vector
      )),
      ']'
    ),

    snippet_definition: $ => prec(1, seq(
      field('name', $.identifier),
      '(' ,
      optional($._parameters),
      ')',
      $._newline,
      repeat($._statement),
      'end',
      $._newline
    )),

    _parameters: $ => separated_list1(',', $.parameter),

    parameter: $ => seq(
      field('name', $.identifier),
      optional(seq('::', field('type', $.identifier))),
      optional(seq('=', field('default', $._value)))
    ),

    _value: $ => choice(
      $.string_literal,
      $.number_literal,
      $.boolean_literal,
      $.identifier,
      $.julia_block,
      $.vector
    ),

    string_literal: $ => /"[^\"]*"/, // may contain julia $ and $()
    number_literal: $ => /\d+(\.\d*)?/, // supports 12e48, +23e-38pc
    boolean_literal: $ => choice('true', 'false'),
    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    comment: $ => token(seq('#', /[^\n]*/)),

    _newline: $ => '\n',
  },

  conflicts: $ => [
    [$.property_assignment, $.grouped_property_assignment],
  ],

  word: $ => $.identifier,
});

function separated_list1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
