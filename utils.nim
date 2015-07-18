import macros
import json
import tables

import types
import ql2
import datum

macro newQueryAst*(n: varargs[expr]): stmt =
  result = newNimNode(nnkStmtList, n)
  # new(result)
  result.add(newCall("new", ident("result")))

  # result.tt = TermType
  result.add(
    newAssignment(
      newDotExpr(ident("result"), ident("tt")),
      n[0]
    )
  )

  # result.args = @[]
  result.add(
    newAssignment(
      newDotExpr(ident("result"), ident("args")), prefix(newNimNode(nnkBracket), "@")
    )
  )

  # result.optargs = newTable[string, Mutabledatum]()
  var bracket = newNimNode(nnkBracketExpr)
  bracket.add(ident("newTable"))
  bracket.add(ident("string"))
  bracket.add(ident("RqlQuery"))

  #result.add(
  #  newAssignment(
  #    newDotExpr(ident("result"), ident("optargs")),
  #    newCall(bracket)
  #  )
  #)
  result.add(newCall("new", newDotExpr(ident("result"), ident("optargs"))))
  if n.len > 1:
    for i in 1..n.len-1:
      result.add(newCall("addArg", ident("result"), n[i]))

proc newQuery*(tt: TermType): RqlQuery {.inline.} =
  new(result)
  result.tt = tt
  result.args = @[]
  result.optargs = newTable[string, RqlQuery]()

proc newDatum*(t: MutableDatum): RqlQuery =
  new(result)
  result.tt = DATUM
  result.value = t

proc newDatum*[T](t: T): RqlQuery =
  newDatum(&t)


proc toJson*(r: RqlQuery): JsonNode =
  case r.tt
  of DATUM:
    result = %r.value
  else:
    result = newJArray()
    result.add(newJInt(r.tt.ord))
    var arr = newJArray()
    for x in r.args:
      arr.add(x.toJson)
    result.add(arr)
    if not r.optargs.isNil and r.optargs.len > 0:
      var obj = newJObject()
      for k, v in r.optargs.pairs:
        obj.fields.add((key: k, val: v.toJson))

      result.add(obj)
