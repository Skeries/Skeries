"""Utilities for extracting code blocks from HTML snippets."""

from __future__ import annotations

from html.parser import HTMLParser
from typing import List


class _CodeBlockExtractor(HTMLParser):
    """Collect text from ``<pre>`` and ``<code>`` blocks, tolerating nesting."""

    def __init__(self) -> None:
        super().__init__()
        self._depth = 0  # count nested pre/code instead of a simple boolean
        self._blocks: List[str] = []
        self._buf: List[str] = []

    def handle_starttag(self, tag: str, attrs) -> None:  # type: ignore[override]
        if tag.lower() in ("pre", "code"):
            if self._depth == 0:
                self._buf = []
            self._depth += 1

    def handle_endtag(self, tag: str) -> None:  # type: ignore[override]
        if tag.lower() in ("pre", "code") and self._depth > 0:
            self._depth -= 1
            if self._depth == 0:
                self._blocks.append("\n".join(self._buf))
                self._buf = []

    def handle_data(self, data: str) -> None:  # type: ignore[override]
        if self._depth > 0:
            self._buf.append(data)

    def blocks(self) -> List[str]:
        return self._blocks


def extract_code_blocks(html: str) -> List[str]:
    """Return text contained in ``<pre>`` and ``<code>`` blocks from *html*."""

    parser = _CodeBlockExtractor()
    parser.feed(html)
    parser.close()
    return parser.blocks()


__all__ = ["extract_code_blocks"]

