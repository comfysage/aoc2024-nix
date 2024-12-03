let
  lib = import ../../getlib.nix;

  inherit (lib) length elemAt;
  inherit (builtins) split filter isString;

  raw = builtins.readFile ./input.txt;

  solve1 =
    input:
    let
      reg = "[(]([[:digit:]]+),([[:digit:]]+)[)].*";
    in
    input
    |> split "mul"
    |> filter isString
    |> map (x: x |> builtins.match reg)
    |> filter (x: !(builtins.isNull x))
    |> map (tuple: tuple |> map builtins.fromJSON)
    |> builtins.foldl' (prev: next: next |> builtins.foldl' (acc: n: acc * n) 1 |> (n: prev + n)) 0;

  solve2 =
    input:
    let
      reg = "[(]([[:digit:]]+),([[:digit:]]+)[)].*";
      do_dont_reg = "(do(n't){0,1})()";
    in
    input
    |> split do_dont_reg
    |>
      builtins.foldl'
        (
          prev: next:
          if prev.do then
            if isString next then
              {
                inherit (prev) do;
                str = prev.str + next;
              }
            else if builtins.isList next && (elemAt next 0) == "don't" then
              {
                inherit (prev) str;
                do = false;
              }
            else
              prev
          else if builtins.isList next && (elemAt next 0) == "do" then
            {
              inherit (prev) str;
              do = true;
            }
          else
            prev

        )
        {
          str = "";
          do = true;
        }
    |> (x: x.str)
    |> split "mul"
    |> filter isString
    |> map (x: x |> builtins.match reg)
    |> filter (x: !(builtins.isNull x))
    |> map (tuple: tuple |> map builtins.fromJSON)
    |> builtins.foldl' (prev: next: next |> builtins.foldl' (acc: n: acc * n) 1 |> (n: prev + n)) 0;

  testfn =
    f: input: expect:
    let
      result = f input;
      pass = result == expect;
    in
    if pass then
      "PASS ( ${toString result} )"
    else
      "FAIL ( ${toString result} ) expected ( ${toString expect} )";
  testall =
    list:
    let
      len = length list;
      map' =
        n:
        if n == len then
          "== ALL TEST PASS =="
        else
          let
            test = elemAt list n;
            inherit (test) name f input;
            raw = elemAt input 0;
            expected = elemAt input 1;
            result = f raw;
          in
          if expected == null then
            "${name} :: PASS ( ${toString result} )"
          else
            let
              pass = result == expected;
            in
            if pass then
              map' (n + 1)
            else
              "${name} :: FAIL ( ${toString result} ) expected ( ${toString expected} )";
    in
    map' 0;
in
testall [
  {
    name = "part1 test";
    f = solve1;
    input = [
      "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"
      161
    ];
  }
  {
    name = "part1";
    f = solve1;
    input = [
      raw
      160672468
    ];
  }
  {
    name = "part2 test";
    f = solve2;
    input = [
      "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"
      48
    ];
  }
  {
    name = "part2";
    f = solve2;
    input = [
      raw
      84893551
    ];
  }
]
