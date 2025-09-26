Proposal: Add "-Parameter <paramName>" to auto-generated Get-Help REMARKS

Summary
-------
When `Get-Help` is invoked without flags (or with `-Detailed`) PowerShell prints a short REMARKS section recommending `-Examples`, `-Detailed`, `-Full`, or `-Online`. This proposal adds `-Parameter <paramName>` to that list so users can discover parameter-level help more easily.

Suggested wording
-----------------
For interactive help, also try: `-Examples`, `-Detailed`, `-Full`, `-Online`, or `-Parameter <paramName>` (e.g. `Get-Help <Cmdlet> -Parameter Name`).

Rationale
---------
- Reduces friction: users often guess `Param`/`Params`/`Parameter` when trying to find parameter-level info.
- Low effort: change is a presentation tweak to the help generator; no behavioral change required if `-Parameter` output is already available.

Implementation notes
--------------------
- If `-Parameter` output isn't available in the same modes that show the REMARKS hint, limit the hint to modes that support parameter help, or ensure the generator produces parameter-level help for those modes.
- If maintainers want, we can draft a small patch to the help generator and attach it to the issue: https://github.com/PowerShell/PowerShell/issues/26100

Contact
-------
If you want me to draft the PR for the docs generator, say so and I will prepare a branch and link it here.
