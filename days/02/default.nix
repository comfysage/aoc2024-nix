let
  lib = import ../../getlib.nix;

  inherit (lib)
    filter
    splitString
    toInt
    last
    length
    ;
  inherit (builtins) elemAt;

  raw = builtins.readFile ./input.txt;
  izzy_raw = builtins.readFile ./izzy_input.txt;

  abs = x: if x < 0 then (-x) else x;
  dropLast = l: lib.lists.sublist 0 (length l - 1) l;

  # markReport :: list -> [int [int] boolean]
  markReport =
    report:
    let
      start = elemAt report 0;
    in
    lib.lists.foldl'
      (
        prev: next:
        let
          prevValue = elemAt prev 0;
          prevDiffs = elemAt prev 1;
          prevSafe = elemAt prev 2;
        in
        if !prevSafe then
          prev
        else
          let
            diff = (next - prevValue);
            prevDiff = last prevDiffs;
          in
          [
            next
            (prevDiffs ++ [ diff ])
            (
              (prevDiff == null || ((prevDiff > 0 && diff > 0) || (prevDiff < 0 && diff < 0)))
              && (
                let
                  absDiff = abs diff;
                in
                (absDiff > 0 && absDiff <= 3)
              )
            )
          ]
      )
      [
        start # value
        [ null ] # diff
        true # safe
      ]
      (lib.lists.drop 1 report);

  markReportWithSafety =
    report:
    let
      isSafe =
        prevDiff: diff:
        (
          ((prevDiff > 0 && diff > 0) || (prevDiff < 0 && diff < 0))
          && (
            let
              absDiff = abs diff;
            in
            (absDiff > 0 && absDiff <= 3)
          )
        );
      mark =
        list:
        let
          len = length list;
          map' =
            n:
            if n == 0 then
              {
                current = elemAt list n;
                diff = null;
                unsafe = 0;
              }
            else
              let
                prevresult = map' (n - 1);
                prev = prevresult.current;
                prevDiff = prevresult.diff;
                unsafe = prevresult.unsafe;
                current = elemAt list n;

                diff = prev - current;
                safe = prevDiff == null || isSafe prevDiff diff;
              in
              if safe then
                { inherit current diff unsafe; }
              else
                {
                  inherit (prevresult) current diff;
                  unsafe = unsafe + 1;
                };
        in
        map' (len - 1);
    in
    mark report;

  solve' =
    input: solver:
    splitString "\n" input
    |> filter (str: str != "")
    |> map (splitString " ")
    |> map (v: map toInt v)
    |> solver;

  solve1 =
    input:
    solve' input (
      reports: reports |> map (report: markReport report |> last) |> lib.lists.count (v: v)
    );

  solve2 =
    input:
    solve' input (
      reports:
      reports
      |> map (
        report: markReportWithSafety report |> (result: result.unsafe) |> (fails: builtins.lessThan fails 2)
      )
      |> lib.lists.count (v: v)
    );

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
      ''
        7 6 4 2 1
        1 2 7 8 9
        9 7 6 2 1
        1 3 2 4 5
        8 6 4 4 1
        1 3 6 7 9
      ''
      2
    ];
  }
  {
    name = "part1 test izzy";
    f = solve1;
    input = [
      izzy_raw
      524
    ];
  }
  {
    name = "part1";
    f = solve1;
    input = [
      raw
      524
    ];
  }
  {
    name = "part2 test";
    f = solve2;
    input = [
      ''
        7 6 4 2 1
        1 2 7 8 9
        9 7 6 2 1
        1 3 2 4 5
        8 6 4 4 1
        1 3 6 7 9
      ''
      4
    ];
  }
  {
    name = "part2 test b";
    f = solve2;
    input = [
      ''
35 37 38 41 43 41
64 66 69 71 72 72
45 47 50 51 52 53 55 59
36 39 41 43 44 41 44
42 45 46 44 42
82 85 86 87 88 86 86
42 45 46 45 47 51
      ''
      4
    ];
  }
  {
    name = "part2 test izzy";
    f = solve2;
    input = [
      izzy_raw
      569
    ];
  }
  {
    name = "part2";
    f = solve2;
    input = [
      raw
      null
    ];
  }
]
