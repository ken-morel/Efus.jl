from unittest import TestCase

from tree_sitter import Language, Parser
import tree_sitter_efus


class TestLanguage(TestCase):
    def test_can_load_grammar(self):
        try:
            Parser(Language(tree_sitter_efus.language()))
        except Exception:
            self.fail("Error loading Efus template parser grammar")
