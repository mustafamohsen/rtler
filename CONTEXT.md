# RTLer Context

RTLer converts Arabic-script source text into visual compatibility text for apps that do not handle right-to-left layout or Arabic shaping correctly. This context names the text concepts the transform is allowed to trade on.

## Language

**Logical text**:
Normal Unicode text in reading order, suitable for editing, search, accessibility, and linguistic processing.
_Avoid_: Source string, clean text

**Visual compatibility text**:
Text arranged and shaped so it is more likely to look correct in a non-RTL or non-shaping renderer. It is paste-ready output, not the source of truth.
_Avoid_: Fixed text, converted text

**Arabic-script text**:
Text written with Arabic-script characters, including Arabic, Urdu, and Persian cases supported by RTLer.
_Avoid_: Arabic-only text

**Arabic presentation form**:
A Unicode compatibility character that encodes a visual Arabic-script glyph form such as isolated, initial, medial, final, or lam-alef.
_Avoid_: Glyph, shaped character

**Presentation form table**:
The single source of truth for Arabic presentation forms, reverse normalization, lam-alef forms, and joining facts used by the transform.
_Avoid_: Mapping helpers, shape table

**LTR literal**:
A left-to-right run inside Arabic-script text that should keep its internal order, such as a URL, email, number, handle, hashtag, version, or filename.
_Avoid_: Token, Latin chunk

## Example dialogue

Dev: "The Persian yeh output is wrong after normalization."

Domain expert: "Check the presentation form table. The same table should explain how logical text becomes visual compatibility text and how existing Arabic presentation forms normalize back before shaping."

Dev: "Should I patch the visual output directly?"

Domain expert: "No. Keep logical text as the source of truth, then regenerate visual compatibility text from the table. LTR literals should keep their own order inside the line."
