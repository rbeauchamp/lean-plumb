module
public import VersoManual
public meta import Verso.Doc.Elab.Monad

/-! Site-owned Verso extension of the rule reference: a fenced `html` code block inserts
markup that the root package's generator escaped and admitted (`Regula.Site.htmlBlock`),
and the site's stylesheet. It adds no JavaScript. -/

public section
open Lean Elab
open Verso ArgParse Doc Elab Genre.Manual Html
open Verso.Output (Html)

namespace RegulaSite

/-- Site styles. Status is always carried by text or `+`/`-` markers as well as colour. -/
def css : String := r#"
.regula-edition { border-left: 4px solid #5b4bb7; background: #f4f2fc; padding: 0.4rem 0.9rem; margin: 1rem 0; font-size: 0.95em; }
.regula-edition p { margin: 0.25rem 0; }
.regula-scroll { overflow-x: auto; max-width: 100%; }
.regula-scroll:focus-visible { outline: 3px solid #0969da; outline-offset: 2px; }
main :not(pre) > code { overflow-wrap: anywhere; }
main :is(p, li, a) { overflow-wrap: break-word; }
table.regula-facts, table.regula-rules { border-collapse: collapse; width: 100%; margin: 1rem 0; }
.regula-index, .regula-example, table.regula-facts, table.regula-rules, figure.regula-file figcaption, .regula-filters, .regula-filters input { font-family: var(--verso-text-font-family); }
.regula-finding pre.regula-code { white-space: pre-wrap; overflow-wrap: anywhere; }
table.regula-facts caption, table.regula-rules caption { text-align: left; font-weight: 600; padding: 0.25rem 0; }
table.regula-facts th, table.regula-facts td, table.regula-rules th, table.regula-rules td {
  text-align: left; vertical-align: top; padding: 0.35rem 0.55rem; border-bottom: 1px solid #d8d8d8; overflow-wrap: anywhere; }
table.regula-facts th { width: 11rem; }
table.regula-rules thead th { border-bottom: 2px solid #999; }
table.regula-rules td, table.regula-rules th { min-width: 6rem; }
tr.regula-no-match { display: none; }
tr.regula-no-match td { font-weight: 600; }
.regula-muted { color: #57606a; font-size: 0.9em; }
pre.regula-code, pre.regula-diff { overflow-x: auto; background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 6px;
  padding: 0.75rem; font-size: 0.9em; line-height: 1.45; white-space: pre; }
.regula-diff del, .regula-diff ins, .regula-diff .regula-keep { display: inline-block; min-width: 100%; text-decoration: none; }
.regula-diff del { background: #ffebe9; }
.regula-diff ins { background: #dafbe1; }
.regula-diff .regula-keep { color: #57606a; }
figure.regula-file { margin: 1rem 0; }
figure.regula-file figcaption { font-size: 0.9em; margin-bottom: 0.25rem; overflow-wrap: anywhere; }
.regula-finding { border: 1px solid #d0d7de; border-left: 4px solid #b3261e; border-radius: 6px; padding: 0.5rem 0.75rem; margin: 0.75rem 0; }
.regula-finding p { margin: 0.25rem 0; overflow-wrap: anywhere; }
.regula-badge { display: inline-block; border: 1px solid #6e7781; border-radius: 999px; padding: 0 0.5rem; font-size: 0.85em; }
.regula-impact-incomplete { border-style: dashed; }
.regula-status { font-weight: 600; }
.regula-example h3 { margin-top: 1.5rem; }
.regula-filters fieldset { border: 1px solid #d0d7de; border-radius: 6px; margin: 0.5rem 0; padding: 0.4rem 0.75rem; }
.regula-filters legend { font-weight: 600; padding: 0 0.25rem; }
.regula-choice { display: inline-block; margin: 0.15rem 0.9rem 0.15rem 0; }
.regula-filters input:focus-visible { outline: 3px solid #0969da; outline-offset: 2px; }
.regula-filters input:checked + label { font-weight: 700; text-decoration: underline; }
.regula-filters input[type=reset] { font: inherit; padding: 0.25rem 0.75rem; }
"#

block_extension Block.rawHtml (html : String) where
  data := Json.str html
  extraCss := [css]
  traverse _ _ _ := pure none
  toHtml :=
    some <| fun _ _ _ data _ => do
      let .str html := data
        | reportError "Expected string JSON for raw HTML" *> pure .empty
      pure (Html.text false html)
  toTeX := none

/-- A fenced `html` block: its contents are inserted verbatim into the HTML output. Only the
root generator writes such blocks, from escaped data. -/
@[code_block]
meta def html : CodeBlockExpanderOf Unit
  | (), str => ``(Verso.Doc.Block.other (Block.rawHtml $(quote str.getString)) #[])

end RegulaSite
