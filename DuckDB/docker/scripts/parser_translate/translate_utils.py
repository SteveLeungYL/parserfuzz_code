import os
class Token:
    def __init__(self, word, index):
        self.word = word
        self.index = index
        self._is_terminating_keyword = None

    @property
    def is_terminating_keyword(self):
        if self._is_terminating_keyword is not None:
            return self._is_terminating_keyword

        if "'" in self.word:
            self._is_terminating_keyword = True
            return self._is_terminating_keyword

        if is_identifier(self) is not None:
            self._is_terminating_keyword = False
            return self._is_terminating_keyword

        if not self.word[0].isalpha():
            self._is_terminating_keyword = True
            return self._is_terminating_keyword

        is_term = True
        for c in self.word:
            if c.isupper() or c == "_":
                continue
            else:
                # lower case
                is_term = False
        self._is_terminating_keyword = is_term
        return self._is_terminating_keyword

    def __str__(self) -> str:
        if self.is_terminating_keyword:
            if self.word.startswith("'") and self.word.endswith("'"):
                return self.word.strip("'")
            self.word = self.word.replace("_P", "")
            self.word = self.word.replace("_LA", "")
            return self.word

        return self.word

    def __repr__(self) -> str:
        return '{prefix}("{word}")'.format(
            prefix="Keyword" if self.is_terminating_keyword else "Token", word=self.word
        )

    def __gt__(self, other):
        other_index = -1
        if isinstance(other, Token):
            other_index = other.index

        return self.index > other_index

def is_identifier(cur_token):
    if cur_token.word == "IDENT":
        return "kIdentifier"
    elif cur_token.word == "SCONST":
        return "kStringLiteral"
    elif cur_token.word == "FCONST":
        return "kFloatLiteral"
    elif cur_token.word == "ICONST" or cur_token.word == "PARAM":
        return "kIntegerLiteral"
    elif cur_token.word == "BCONST" or cur_token.word == "XCONST":
        return "kBinLiteral"
    elif cur_token.word == "FALSE_P" or cur_token.word == "TRUE_P":
        return "kBoolLiteral"
    else:
        return None