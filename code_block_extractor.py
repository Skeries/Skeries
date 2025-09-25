"""Utilities for extracting code blocks from HTML.

This module provides `_CodeBlockExtractor`, a minimal HTMLParser subclass that
collects the textual content of nested ``<pre>``/``<code>`` elements.
"""

from __future__ import annotations

from html.parser import HTMLParser
from typing import List


class _CodeBlockExtractor(HTMLParser):
    """Collect text from ``<pre>`` and ``<code>`` blocks, tolerating nesting."""

    def __init__(self) -> None:
        super().__init__()
        # Count nested pre/code tags so we can handle nested structures.
        self._depth = 0
        self._blocks: List[str] = []
        self._buf: List[str] = []

    def handle_starttag(self, tag: str, attrs) -> None:  # type: ignore[override]
        if tag.lower() in {"pre", "code"}:
            if self._depth == 0:
                self._buf = []
            self._depth += 1

    def handle_endtag(self, tag: str) -> None:  # type: ignore[override]
        if tag.lower() in {"pre", "code"} and self._depth > 0:
            self._depth -= 1
            if self._depth == 0:
                self._blocks.append("\n".join(self._buf))
                self._buf = []

    def handle_data(self, data: str) -> None:  # type: ignore[override]
        if self._depth > 0:
            self._buf.append(data)

    def blocks(self) -> List[str]:
        """Return the collected code blocks in the order encountered."""

        return self._blocks.copy()
