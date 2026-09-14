import VersoManual
import Docs
open Verso.Genre Manual
def main := manualMain (%doc Docs) (config := { emitTeX := false, emitHtmlSingle := .immediately, emitHtmlMulti := .no })
