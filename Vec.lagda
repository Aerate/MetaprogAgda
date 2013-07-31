%if False

\begin{code}

module Vec where

postulate
      Level : Set
      lzero  : Level
      lsuc   : Level -> Level
      lmax   : Level -> Level -> Level

{-# BUILTIN LEVEL     Level #-}
{-# BUILTIN LEVELZERO lzero  #-}
{-# BUILTIN LEVELSUC  lsuc   #-}
{-# BUILTIN LEVELMAX  lmax   #-}

_o_ : forall {i j k}
        {A : Set i}{B : A -> Set j}{C : (a : A) -> B a -> Set k} ->
        (f : {a : A}(b : B a) -> C a b) ->
        (g : (a : A) -> B a) ->
        (a : A) -> C a (g a)
f o g = \ a -> f (g a)

id : forall {k}{X : Set k} -> X -> X
id x = x
\end{code}

%endif

%format Set = "\D{Set}"
%format Set1 = Set "_{\D{1}}"
%format List = "\D{List}"
%format <> = "\C{\langle\rangle}"
%format , = "\red{,}\,"
%format Nat = "\D{Nat}"
%format zero = "\C{zero}"
%format suc = "\C{suc}"
%format id = "\F{id}"
%format o = "\F{\circ}"

It might be easy to mistake this chapter for a bland introduction to
dependently typed programming based on the yawning-already example of
lists indexed by their length, known to their friends as
\emph{vectors}, but in fact, vectors offer us a way to start analysing
data structures into `shape and contents'. Indeed, the typical
motivation for introducing vectors is exactly to allow types to
express shape invariants.


\subsection{Zipping Lists of Compatible Shape}

Let us remind ourselves of the situation with ordinary \emph{lists},
which we may define in Agda as follows:
\nudge{Agda has a very simple lexer and very few special characters.
To a first approximation, ()\{\}; stand alone and everything else must be delimited with whitespace. }
\begin{code}
data List (X : Set) : Set where
  <>    :                 List X
  _,_   : X -> List X ->  List X

infixr 4 _,_
\end{code}

%if False
\begin{code}
record Sg {l : Level}(S : Set l)(T : S -> Set l) : Set l where
  constructor _,_
  field
    fst : S
    snd : T fst
open Sg
_*_ : {l : Level} -> Set l -> Set l -> Set l
S * T = Sg S \ _ -> T

record One {l : Level} : Set l where
  constructor <>
open One
\end{code}
%endif

%format Sg = "\D{\Upsigma}"
%format fst = "\F{fst}"
%format snd = "\F{snd}"
%format * = "\F{\times}"
%format One = "\D{One}"
%format zip0 = "\F{zip}"

The classic operation which morally involves a shape invariant is |zip0|, taking
two lists, one of |S|s, the other of |T|s, and yielding a list of pairs in the product
|S * T| formed from elements \emph{in corresponding positions}. The trouble, of course,
is ensuring that positions correspond.
\nudge{The braces indicate that |S| and |T| are \emph{implicit arguments}. Agda will try
to infer them unless we override manually.}
\begin{code}
zip0 : {S T : Set} -> List S -> List T -> List (S * T)
zip0 <>        <>        = <>
zip0 (s , ss)  (t , ts)  = (s , t) , zip0 ss ts
zip0 _         _         = <>  -- a dummy value, for cases we should not reach
\end{code}

\paragraph{Overloading Constructors} Note that I have used `|,|' both
for tuple pairing and as list `cons'. Agda permits the overloading of
constructors, using type information to disambiguate them. Of course,
just because overloading is permitted, that does not make it
compulsory, so you may deduce that I have overloaded deliberately. As
data structures in the memory of a computer, I think of pairing and
consing as the same, and I do not expect data to tell me what they
mean. I see types as an external rationalisation imposed upon the raw
stuff of computation, to help us check that it makes sense (for
multiple possible notions of sense) and indeed to infer details (in
accordance with notions of sense). Those of you who have grown used to
thinking of type annotations as glorified comments will need to
retrain your minds to pay attention to them.

Our |zip0| function imposes a `garbage in? garbage out!' deal, but
logically, we might want to ensure the obverse: if we supply
meaningful input, we want to be sure of meaningful output. But what is
meaningful input? Lists the same length!  Locally, we have a
\emph{relative} notion of meaningfulness. What is meaningful output?
We could say that if the inputs were the same length, we expect output
of that length. How shall we express this property? We could
externalise it in some suitable program logic, first explaining what
`length' is.

\nudge{The number of c's in |suc| is a long standing area of open
warfare.}
\nudge{Agda users tend to use lowercase-vs-uppercase to distinguish things in |Set|s from things which are or manipulate |Set|s.}
\nudge{The pragmas let you use Arabic numerals.}
\begin{code}
data Nat : Set where
  zero  :         Nat
  suc   : Nat ->  Nat

{-# BUILTIN NATURAL Nat #-}
{-# BUILTIN ZERO zero #-}
{-# BUILTIN SUC suc #-}
\end{code}

%format length = "\F{length}"
\begin{code}
length : {X : Set} -> List X -> Nat
length <>        = zero
length (x , xs)  = suc (length xs)
\end{code}

Informally,\footnote{by which I mean, not to a computer}
we might state and prove something like
\[
  \forall |ss|, |ts|.\;
  |length ss| = |length ts| \Rightarrow |length (zip0 ss ts) = length ss|
\]
by structural induction~\citep{burstall:induction} on |ss|, say.
Of course, we could just as well have concluded that
|length (zip0 ss ts) = length ts|, and if we carry on |zip0|ping, we
shall accumulate a multitude of expressions known to denote the same
number.

Matters get worse if we try to work with matrices as lists of lists (a
matrix is a column of rows, say).  How do we express rectangularity?
Can we define a function to compute the dimensions of a matrix? Do we
want to?  What happens in degenerate cases? Given \(m\), \(n\), we
might at least say that the outer list has length \(m\) and that all
the inner lists have length \(n\). Talking about matrices gets easier
if we imagine that the dimensions are \emph{prescribed}---to be checked,
not measured.


\section{Vectors}

Dependent types allow us to \emph{internalize} length invariants in
lists, yielding \emph{vectors}. The index describes the shape of the
list, thus offers no real choice of constructors.

%format Vec = "\D{Vec}"
\begin{code}
data Vec (X : Set) : Nat -> Set where
  <>   :                               Vec X zero
  _,_  : {n : Nat} -> X -> Vec X n ->  Vec X (suc n)
\end{code}

\paragraph{Parameters and indices.} In the above definition, the
element type is abstracted uniformly as |X| across the whole
thing. The definition could be instantiated to any particular set |X|
and still make sense, so we say that |X| is a \emph{parameter} of the
definition. Meanwhile, |Vec|'s second argument varies in each of the
three places it is instantiated, so that we are really making a
mutually inductive definition of the vectors at every possible length,
so we say that the length is an \emph{index}. In an Agda |data|
declaration head, arguments left of |:| (|X| here) scope over all
constructor declarations and must be used uniformly in constructor
return types, so it is sensible to put parameters left of
|:|. However, as we shall see, such arguments may be freely
instantiated in \emph{recursive} positions, so we should not presume
that they are necessarily parameters.

%format zip1 = zip0
Let us now develop |zip1| for vectors, stating the length invariant
in the type.

\begin{spec}
zip1 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip1 ss ts = ?
\end{spec}

The length argument and the two element types are marked implicit by
default, as indicated by the |{..}| after the |forall|.  We write a
left-hand-side naming the explicit inputs, which we declare equal to
an unknown |?|. Loading the file with |[C-c C-l]|, we find that Agda
checks the unfinished program, turning the |?| into labelled braces,
%format (HOLE (x) n) = { x } "\!_{" n "}"
%format GAP = "\;"
\begin{spec}
zip1 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip1 ss ts = (HOLE GAP 0)
\end{spec}
and tells us, in the information window,
\begin{spec}
?0 : Vec (.S * .T) .n
\end{spec}
that the type of the `hole' corresponds to the return type we wrote.
The dots before |S|, |T|, and |n| indicate that these variables exist behind the
scenes, but have not been brought into scope by anything in the program text:
Agda can refer to them, but we cannot.

If we click between the braces to select that hole, and issue keystroke
|[C-c C-,]|, we will gain more information about the goal:
%format Goal = "\mathkw{Goal}"
\begin{spec}
Goal  : Vec (Sg .S (\ _ → .T)) .n
-- \hspace*{-0.3in}------------------------------------------------------------------
ts    : Vec .T .n
ss    : Vec .S .n
.T    : Set
.S    : Set
.n    : Nat
\end{spec}
revealing the definition of |*| used in the goal, about which more shortly,
but also telling us about the types and visibility of variables in the
\emph{context}.

Our next move is to \emph{split} one of the inputs into cases. We can see from the
type information |ss  : Vec .S .n| that we do not know the length of |ss|, so it
might be given by either constructor. To see if Agda agrees, we type |ss| in the
hole and issue the `case-split' command |[C-c C-c]|.

\begin{spec}
zip1 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip1 ss ts = (HOLE (ss [C-c C-c]) 0)
\end{spec}

Agda responds by editing our source code, replacing the single line of
defintion by two more specific cases.

\begin{spec}
zip1 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip1 <> ts = (HOLE GAP 0)
zip1 (x , ss) ts = (HOLE GAP 1)
\end{spec}

Moreover, we gain the refined type information
\begin{spec}
?0  : Vec (.S * .T) 0
?1  : Vec (.S * .T) (suc .n)
\end{spec}
which goes to show that the type system is now tracking what information
is learned about the problem by inspecting |ss|. This capacity for
\emph{learning by testing} is the paradigmatic characteristic of dependently
typed programming.

Now, when we split |ts| in the |0| case, we get
\begin{spec}
zip1 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip1 <> <> = (HOLE GAP 0)
zip1 (x , ss) ts = (HOLE GAP 1)
\end{spec}
and in the |suc| case,
\begin{spec}
zip1 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip1 <> <> = (HOLE GAP 0)
zip1 (x , ss) (x1 , ts) = (HOLE GAP 1)
\end{spec}
as the more specific type now determines the shape. Sadly, Agda is not
very clever\nudge{It's not even as clever as Epigram.} about choosing names,
but let us persevere. We have now made sufficient analysis of the input to
determine the output, and shape-indexing has helpfully ruled out shape mismatch.
It is now so obvious what must be output that Agda can figure it out for itself.
If we issue the keystroke |[C-c C-a]| in each hole, a type-directed program
search robot called `Agsy' tries to find an expression which will fit in the hole,
asssembling it from the available information without further case analysis.
We obtain a complete program.

\begin{spec}
zip1 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip1 <> <> = <>
zip1 (x , ss) (x1 , ts) = (x , x1) , zip1 ss ts
\end{spec}

I tend to $\alpha$-convert and realign such programs manually, yielding
\begin{code}
zip1 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip1 <>         <>        = <>
zip1 (s , ss)   (t , ts)  = (s , t) , zip1 ss ts
\end{code}


%format iso = "\cong"

What just happened? We made |Vec|, a version of |List|, indexed by
|Nat|, and suddenly became able to work with `elements in
corresponding positions' with some degree of precision. That worked
because |Nat| describes the \emph{shape} of lists: indeed |Nat iso
List One|, instantiating the |List| element type to the type |One|
with the single element |<>|, so that the only information present is
the shape. Once we fix the shape, we acquire a fixed notion of
position.


%format vec = "\F{vec}"
%format vapp = "\F{vapp}"
\begin{exe}[|vec|]
Complete the implementation of
\begin{spec}
vec : forall {n X} -> X -> Vec X n
vec {n} x = ?
\end{spec}
using only control codes and arrow keys.
\nudge{Why is there no specification?}
%if False
\begin{code}
vec : forall {n X} -> X -> Vec X n
vec {zero} x = <>
vec {suc n} x = x , vec x
\end{code}
%endif
(Note the brace notation, making the implicit |n| explicit. It is not unusual
for arguments to be inferrable at usage sites from type information, but
none the less computationally relevant.)
\end{exe}

%format vapp = "\F{vapp}"
\begin{exe}[vector application]
Complete the implementation of
\begin{spec}
vapp :  forall {n S T} -> Vec (S -> T) n -> Vec S n -> Vec T n
vapp fs ss = ?
\end{spec}
using only control codes and arrow keys. The function should apply
the functions from its first input vector to the arguments in corresponding
positions from its second input vector, yielding values in corresponding positions
in the output.
%if False
\begin{code}
vapp :  forall {n S T} -> Vec (S -> T) n -> Vec S n -> Vec T n
vapp <> <> = <>
vapp (f , fs) (s , ss) = f s , vapp fs ss
\end{code}
%endif
\end{exe}

%format vmap = "\F{vmap}"
%format zip2 = zip0
\begin{exe}[|vmap|]
Using |vec| and |vapp|, define the functorial `map' operator for vectors,
applying the given function to each element.
\begin{spec}
vmap : forall {n S T} -> (S -> T) -> Vec S n -> Vec T n
vmap f ss = ?
\end{spec}
%if False
\begin{code}
vmap : forall {n S T} -> (S -> T) -> Vec S n -> Vec T n
vmap f ss = vapp (vec f) ss
\end{code}
%endif
Note that you can make Agsy notice a defined function by writing its name
as a hint in the relevant hole before you |[C-c C-a]|.
\end{exe}

\begin{exe}[|zip2|]
Using |vec| and |vapp|, give an alternative definition of |zip2|.
\begin{spec}
zip2 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip2 ss ts = ?
\end{spec}
%if False
\begin{code}
zip2 : forall {n S T} -> Vec S n -> Vec T n -> Vec (S * T) n
zip2 ss ts = vapp (vapp (vec _,_) ss) ts
\end{code}
%endif
\end{exe}


\section{Applicative and Traversable Structure}

%format EndoFunctor = "\D{EndoFunctor}"
%format Applicative = "\D{Applicative}"
%format Monad = "\D{Monad}"
%format map = "\F{map}"
%format pure = "\F{pure}"
%format <*> = "\F{\circledast}"
%format _<*>_ = "\_\!" <*> "\!\_"
%format itsEndoFunctor = "\F{itsEndoFunctor}"
%format applicativeVec = "\F{applicativeVec}"
%format endoFunctorVec = "\F{endoFunctorVec}"
%format applicativeFun = "\F{applicativeFun}"
%format itsApplicative = "\F{itsApplicative}"
%format return = "\F{return}"
%format >>= = "\F{>\!\!>\!\!=}"
%format _>>=_ = "\_\!" >>= "\!\_"

The |vec| and |vapp| operations from the previous section equip
vectors with the structure of an \emph{applicative functor}.
\nudge{For now, I shall just work in |Set|, but we should remember
to break out and live, categorically, later.}
Before we get to |Applicative|, let us first say what is an |EndoFunctor|:
\nudge{Why |Set1|?}
\begin{code}
record EndoFunctor (F : Set -> Set) : Set1 where
  field
    map  : forall {S T} -> (S -> T) -> F S -> F T
open EndoFunctor {{...}}
\end{code}
The above record declaration creates new types |EndoFunctor F| and a new
\emph{module}, |EndoFunctor|, containing a function, |EndoFunctor|.|map|,
which projects the |map|
field from a record. The |open| declaration brings |map| into top level scope,
and the |{{...}}| syntax indicates that |map|'s record argument is an
\emph{instance argument}. Instance arguments are found by searching the context
for something of the required type, succeeding if exactly one candidate is found.

Of course, we should ensure that such structures should obey the functor laws,
with |map| preserving identity and composition. Dependent types allow us to
state and prove these laws, as we shall see shortly.

First, however, let us refine |EndoFunctor| to |Applicative|.
\begin{code}
record Applicative (F : Set -> Set) : Set1 where
  infixl 2 _<*>_
  field
    pure    : forall {X} -> X -> F X
    _<*>_   : forall {S T} -> F (S -> T) -> F S -> F T
  itsEndoFunctor : EndoFunctor F
  itsEndoFunctor = record { map = _<*>_ o pure }
open Applicative {{...}}
\end{code}
The |Applicative F| structure decomposes |F|'s |map| as the ability to make
`constant' |F|-structures and closure under application.

Given that instance arguments are collected from the context, let us seed
the context with suitable candidates for |Vec|:
\begin{code}
applicativeVec  : forall {n} -> Applicative \ X -> Vec X n
applicativeVec  = record { pure = vec; _<*>_ = vapp }
endoFunctorVec  : forall {n} -> EndoFunctor \ X -> Vec X n
endoFunctorVec  = itsEndoFunctor
\end{code}
Indeed, the definition of |endoFunctorVec| already makes use of way
|itsEndoFunctor| searches the context and finds |applicativeVec|.

There are lots of applicative functors about the place. Here's another
famous one:
\begin{code}
applicativeFun : forall {S} -> Applicative \ X -> S -> X
applicativeFun = record
  {  pure    = \ x s -> x              -- also known as K (drop environment)
  ;  _<*>_   = \ f a s -> f s (a s)    -- also known as S (share environment)
  }
\end{code}

Monadic structure induces applicative structure:
\begin{code}
record Monad (F : Set -> Set) : Set1 where
  field
    return  : forall {X} -> X -> F X
    _>>=_   : forall {S T} -> F S -> (S -> F T) -> F T
  itsApplicative : Applicative F
  itsApplicative = record
    {  pure   = return
    ;  _<*>_  = \ ff fs -> ff >>= \ f -> fs >>= \ s -> return (f s) }
open Monad {{...}}
\end{code}

%format monadVec =  "\F{monadVec}"
\begin{exe}[|Vec| monad]
Construct a |Monad| satisfying the |Monad| laws
\begin{spec}
monadVec : {n : Nat} -> Monad \ X -> Vec X n
monadVec = ?
\end{spec}
such that |itsApplicative| agrees extensionally with |applicativeVec|.
%if False
\begin{code}
monadVec : {n : Nat} -> Monad \ X -> Vec X n
monadVec = record
  {   return  = pure
  ;   _>>=_   = \ fs k -> diag (map k fs)
  }  where
     tail : forall {n X} -> Vec X (suc n) -> Vec X n
     tail (x , xs) = xs
     diag : forall {n X} -> Vec (Vec X n) n -> Vec X n
     diag <>                = <>
     diag ((x , xs) , xss)  = x , diag (map tail xss)
\end{code}
%endif
\end{exe}

\begin{exe}[|Applicative| identity and composition]
Show by construction that the identity endofunctor is |Applicative|, and that
the composition of |Applicative|s is |Applicative|.
\end{exe}

\begin{exe}[|Applicative| product]
Show by construction that the pointwise product of |Applicative|s is
|Applicative|.
\end{exe}

%format Traversable = "\D{Traversable}"
%format traverse = "\F{traverse}"
%format traversableVec = "\F{traversableVec}"
\begin{code}
record Traversable (F : Set -> Set) : Set1 where
  field
    traverse :  forall {G S T}{{_ : Applicative G}} ->
                (S -> G T) -> F S -> G (F T)
open Traversable {{...}}
\end{code}

%format vtr = "\F{vtr}"
\begin{code}
traversableVec : {n : Nat} -> Traversable \ X -> Vec X n
traversableVec = record { traverse = vtr } where
  vtr :  forall {n G S T}{{_ : Applicative G}} ->
         (S -> G T) -> Vec S n -> G (Vec T n)
  vtr f <>        = pure <>
  vtr f (s , ss)  = pure _,_ <*> f s <*> vtr f ss
\end{code}

%format transpose = "\F{transpose}"
\begin{exe}[|transpose|]
Implement matrix transposition in one line.
\begin{spec}
transpose : forall {m n X} -> Vec (Vec X n) m -> Vec (Vec X m) n
transpose = ?
\end{spec}
%if False
\begin{code}
transpose : forall {m n X} -> Vec (Vec X n) m -> Vec (Vec X m) n
transpose = traverse id
\end{code}
%endif
\end{exe}

\begin{exe}[|Traversable| functors]
Show that |Traversable| is closed under identity and composition.
What other structure does it preserve?
\end{exe}


\section{Normal Functors}

A \emph{normal} functor is given, up to isomorphism, by a set of \emph{shapes}
and a function which assigns to each shape a \emph{size}. It is interpreted
as the \emph{dependent pair} of a shape, |s|, and a vector of elements whose
length is the size of |s|.

%format Normal = "\D{Normal}"
%format Shape = "\F{Shape}"
%format size = "\F{size}"
%format / = "\C{/}"
%format _/_ = "\_\!" / "\!\_"
%format <! = "\F{\llbracket}"
%format !> = "\F{\rrbracket}"
%format !>N = !> "_{\F{N}}"
%format <!_!>N = <! "\!" _ "\!" !>N
\begin{code}
record Normal : Set1 where
  constructor _/_
  field
    Shape  : Set
    size   : Shape -> Nat
  <!_!>N : Set -> Set
  <!_!>N X = Sg Shape \ s -> Vec X (size s)
open Normal
\end{code}

