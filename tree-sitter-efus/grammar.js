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
    /[ \t\r]/, // Allow whitespace, but not newlines
  ],

  rules: {
    source_file: $ => repeat(seq(optional($._statement), $._newline)),

    _statement: $ => choice(
      $._identifier_statement,
      $.if_statement,
      $.for_statement,
      $.julia_block
    ),

    _identifier_statement: $ => choice(
      $.snippet_definition,
      $.component_call
    ),

    component_call: $ => seq(
      field('name', $.identifier),
      repeat(choice(
        $.property_assignment,
        $.grouped_property_assignment,
        $.splat_operator,
      )),
      optional($._block),
    ),

    property_assignment: $ => seq(
      field('key', $.identifier),
      '=',
      field('value', $._value),
    ),

    grouped_property_assignment: $ => seq(
      field('group', $.identifier),
      ':',
      field('key', $.identifier),
      '=',
      field('value', $._value),
    ),

    splat_operator: $ => seq($.identifier, '...'),

    if_statement: $ => seq(
      'if',
      field('condition', $.julia_expression),
      $._block,
      repeat($.else_if_clause),
      optional($.else_clause),
      'end',
    ),

    else_if_clause: $ => seq(
      'elseif',
      field('condition', $.julia_expression),
      $._block,
    ),

    else_clause: $ => seq(
      'else',
      $._block,
    ),

    for_statement: $ => seq(
      'for',
      field('iterator', $.julia_expression),
      $._block,
      optional($.else_clause),
      'end',
    ),

    julia_block: $ => seq(
      '(' ,
      field('code', repeat(choice(/[^()]+/, seq('(', repeat(choice(/[^()]+/, $.julia_block)), ')')))),
      ')',
    ),

    snippet_definition: $ => prec(1, seq(
      field('name', $.identifier),
      '(' ,
      optional($._parameters),
      ')',
      $._block,
      'end',
    )),

    _parameters: $ => separated_list1(',', $.parameter),

    parameter: $ => seq(
      field('name', $.identifier),
      optional(seq('::', field('type', $.identifier))),
      optional(seq('=', field('default', $._value))),
    ),

    _value: $ => choice(
      $.string_literal,
      $.number_literal,
      $.boolean_literal,
      $.julia_expression_in_value,
      $.identifier,
      $.julia_block,
    ),

    string_literal: $ => /"[^"]*"/, 
    number_literal: $ => /\d+(\.\d*)?/, 
    boolean_literal: $ => choice('true', 'false'),
    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    julia_expression: $ => /[^
]+/, 
    julia_expression_in_value: $ => /[^
	 ,)]+/, 

    _block: $ => seq(
      $._indent,
      repeat(seq($._statement, $._newline)),
      $._dedent,
    ),

    comment: $ => token(seq('#', /.*/)),
  },

  externals: $ => [
    $._indent,
    $._dedent,
    $._newline,
  ],

  conflicts: $ => [
    [$.property_assignment, $.grouped_property_assignment],
  ],

  word: $ => $.identifier,
});

function separated_list1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}