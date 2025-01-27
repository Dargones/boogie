// RUN: %parallel-boogie "%s" > "%t"
// RUN: %diff "%s.expect" "%t"

type Tid;

var {:layer 0,1} t: int;           // next ticket to issue
var {:layer 0,2} s: int;           // current ticket permitted to critical section
var {:layer 1,2} cs: Option Tid;   // current thread in critical section
var {:layer 1,2} T: [int]bool;     // set of issued tickets

// ###########################################################################
// Invariants

function {:inline} Inv1 (tickets: [int]bool, ticket: int): (bool)
{
  (forall i: int :: tickets[i] <==> i < ticket)
}

function {:inline} Inv2 (tickets: [int]bool, ticket: int, lock: Option Tid): (bool)
{
  lock is None || tickets[ticket]
}

// ###########################################################################
// Yield invariants

yield invariant {:layer 2} YieldSpec (tid: Lval Tid);
invariant cs is Some && cs->t == tid->val;

yield invariant {:layer 1} Yield1 ();
invariant Inv1(T, t);

yield invariant {:layer 2} Yield2 ();
invariant Inv2(T, s, cs);

// ###########################################################################
// Test driver

yield procedure {:layer 2} main ({:layer 1,2} {:linear_in} _tids: Lset Tid)
requires call Yield1();
requires call Yield2();
{
  var {:layer 1,2} tid: Lval Tid;
  var {:layer 1,2} tids: Lset Tid;

  tids := _tids;
  while (*)
  invariant {:yields} true;
  invariant call Yield1();
  invariant call Yield2();
  {
    call {:layer 1,2} tid, tids := Allocate(tids);
    async call Customer(tid);
  }
}

pure procedure {:inline 1} Allocate({:linear_in} _tids: Lset Tid) returns (tid: Lval Tid, tids: Lset Tid)
{
  tids := _tids;
  assume {:layer 1,2} tids->dom != MapConst(false);
  call {:layer 1,2} tid := Lval_Get(tids, Choice(tids->dom));
}

// ###########################################################################
// Procedures and actions

yield procedure {:layer 2} Customer ({:layer 1,2} tid: Lval Tid)
requires call Yield1();
requires call Yield2();
{
  while (*)
  invariant {:yields} true;
  invariant call Yield1();
  invariant call Yield2();
  {
    call Enter(tid);
    par Yield1() | Yield2() | YieldSpec(tid);
    call Leave(tid);
  }
}

yield procedure {:layer 2} Enter ({:layer 1,2} tid: Lval Tid)
preserves call Yield1();
preserves call Yield2();
ensures   call YieldSpec(tid);
{
  var m: int;

  call m := GetTicket(tid);
  call WaitAndEnter(tid, m);
}

right action {:layer 2} AtomicGetTicket (tid: Lval Tid) returns (m: int)
modifies T;
{ assume !T[m]; T[m] := true; }
yield procedure {:layer 1} GetTicket ({:layer 1} tid: Lval Tid) returns (m: int)
refines AtomicGetTicket;
preserves call Yield1();
{
  call m := GetTicket#0();
  call {:layer 1} T := Copy(T[m := true]);
}

atomic action {:layer 1} AtomicGetTicket#0 () returns (m: int)
modifies t;
{ m := t; t := t + 1; }
yield procedure {:layer 0} GetTicket#0 () returns (m: int);
refines AtomicGetTicket#0;

atomic action {:layer 2} AtomicWaitAndEnter (tid: Lval Tid, m:int)
modifies cs;
{ assume m == s; cs := Some(tid->val); }
yield procedure {:layer 1} WaitAndEnter ({:layer 1} tid: Lval Tid, m:int)
refines AtomicWaitAndEnter;
preserves call Yield1();
{
  call WaitAndEnter#0(m);
  call {:layer 1} cs := Copy(Some(tid->val));
}

atomic action {:layer 1} AtomicWaitAndEnter#0 (m:int)
{ assume m == s; }
yield procedure {:layer 0} WaitAndEnter#0 (m:int);
refines AtomicWaitAndEnter#0;

atomic action {:layer 2} AtomicLeave (tid: Lval Tid)
modifies cs, s;
{ assert cs == Some(tid->val); s := s + 1; cs := None(); }
yield procedure {:layer 1} Leave ({:layer 1} tid: Lval Tid)
refines AtomicLeave;
preserves call Yield1();
{
  call Leave#0();
  call {:layer 1} cs := Copy(None());
}

atomic action {:layer 1} AtomicLeave#0 ()
modifies s;
{ s := s + 1; }
yield procedure {:layer 0} Leave#0 ();
refines AtomicLeave#0;
