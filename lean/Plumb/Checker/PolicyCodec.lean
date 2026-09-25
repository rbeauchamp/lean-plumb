import Lean.Data.Json
import PlumbPolicy.Codec

/-! Strict operational JSON parsing. Scalar syntax reuses Lean's parser; the container
recursion below is adapted from the Lean 4 repository's `src/Lean/Data/Json/Parser.lean` (notice as at
`v4.34.0`), modified to reject duplicate keys before insertion. Upstream notice, retained:

    Copyright (c) 2019 Gabriel Ebner. All rights reserved.
    Released under Apache 2.0 license as described in the file LICENSE.
    Authors: Gabriel Ebner, Marc Huisinga

The Apache 2.0 license text is `LICENSES/Apache-2.0.txt` in this repository.
The pure wire laws do not prove this text parser or external producer authenticity. -/
namespace Plumb.Checker.PolicyCodec
open Lean Std.Internal.Parsec Std.Internal.Parsec.String

mutual
private partial def value : Parser Json := do
  let c ← peek!
  if c == '[' then
    skip; ws
    if (← peek!) == ']' then skip; ws; return .arr #[]
    return .arr (← array #[])
  else if c == '{' then
    skip; ws
    if (← peek!) == '}' then skip; ws; return Json.mkObj []
    return Json.mkObj (← object [])
  else Json.Parser.anyCore

private partial def array (values : Array Json) : Parser (Array Json) := do
  let values := values.push (← value)
  let c ← any
  if c == ']' then ws; return values
  else if c == ',' then ws; array values
  else fail "unexpected character in array"

private partial def object (fields : List (String × Json)) : Parser (List (String × Json)) := do
  Json.Parser.lookahead (· == '"') "object key"
  skip
  let key ← Json.Parser.str
  if fields.any (·.1 == key) then fail s!"duplicate JSON field: {key}"
  ws
  Json.Parser.lookahead (· == ':') ":"
  skip; ws
  let fields := fields ++ [(key, ← value)]
  let c ← any
  if c == '}' then ws; return fields
  else if c == ',' then ws; object fields
  else fail "unexpected character in object"
end

def parse (text : String) : Except String Json :=
  Parser.run (do ws; let j ← value; eof; return j) text

/-- Exact object fields: optional data is encoded explicitly as null, never silently
omitted or supplemented by an unknown field. -/
def exactFields (j : Json) (expected : List String) : Except String Unit := do
  let fields ← j.getObj?
  let actual := fields.toList.map (·.1)
  unless actual.length == expected.length && expected.all actual.contains do
    throw "unknown or missing JSON object fields"

end Plumb.Checker.PolicyCodec
