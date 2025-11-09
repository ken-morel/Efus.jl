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
    source_file: $ => repeat($.statement),

    statement: $ => choice(
      $.if_statement,
      $.for_statement,
      $.snippet_definition,
      $.component_call,
      $.julia_block,
      $.blank_line
    ),

    blank_line: $ => $._newline,

    // An expression is anything that can be on a line by itself
    expression: $ => choice(
      $.julia_expression,
      $.vector,
      $.numeric,
      $.string,
    ),

    component_call: $ => seq(
      field('name', $.identifier),
      repeat(choice(
        $.property_assignment,
        $.grouped_property_assignment,
        $.splat
      )),
      optional('\n'),
    ),

    property_assignment: $ => seq(
      field('key', $.identifier),
      optional(seq(
        ':',
        field('key', $.identifier),
      )),
      '=',
      field('value', $.expression)
    ),
    
    splat: $ => seq($.identifier, '...'),

    if_statement: $ => seq(
      'if',
      field('condition', $.julia_expression_newline),
      repeat($.statement),
      repeat($.else_if_clause),
      optional($.else_clause),
      'end',
    ),

    else_if_clause: $ => seq(
      'elseif',
      field('condition', $.julia_expression_newline),
      $._newline,
      repeat($.statement)
    ),

    else_clause: $ => seq(
      'else',
      $._newline,
      repeat($.statement)
    ),

    for_statement: $ => seq(
      'for',
      field('iterator', $.for_iterator),
      'in'
      $._newline,
      repeat($._statement),
      optional($.else_clause),
      'end',
      $._newline
    ),
    for_iterator: $ => choice(
      $.for_iterator_name,
      $.for_iterator_desctuct,

    ),
    for_iterator_name: $ => field('name', $.identifier),
    for_iterator_desctuct: $ => seq(
      '(',
      field('name',$.identifier),
      repeat(seq(
        field('name', $.identifier),
        ','
      )),
      ')'
    ),

    // A block of Julia code in parentheses
    julia_block: $ => seq(
      '(' ,
      repeat(choice(
        /[^()]+/, 
        $.julia_block
      )),
      ')'
    ),

    // A vector in square brackets
    vector: $ => seq(
      '[' ,
      seperated_list1(',', $.expression),
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
    
    string: $ => /"[^\"]*"/, // may contain julia $ and $() 
    numeric: $ => /\d+(\.\d*)?/, // supports 12e48, +23e-38pc
    boolean_literal: $ => choice('true', 'false'),
    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    comment: $ => token(seq('#', /[^\n]*/)),

    _newline: $ => '\n',
  },

    word: $ => $.identifier,
});

function separated_list1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
