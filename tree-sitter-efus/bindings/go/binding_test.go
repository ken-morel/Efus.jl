package tree_sitter_efus_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_efus "github.com/ken-morel/ionicefus.jl/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_efus.Language())
	if language == nil {
		t.Errorf("Error loading Efus template parser grammar")
	}
}
