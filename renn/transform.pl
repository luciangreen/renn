/*  transform.pl -- proof-carrying transformations of a renn build.

    Every change to a generated Prolog file after `renn build` must carry a
    proof that an independent checker accepted. The checker is mnns
    (`swipl optimise.pl IN OUT`): each of its stages (PLOp, the AIOC
    simplifier and Detlog) keeps a rewrite only when mnns' proof checker
    accepts it, and it reports the result on one MNN_OPTIMISE line.

    swipl renn/transform.pl transform BUILD FILE MNNS
        Optimise BUILD/FILE with mnns. The new file is kept only when the
        checker reports success for every stage, the manifest still verifies
        and the generated differential cases still pass; otherwise every file
        is restored. The original is kept as before-N-FILE and the change is
        recorded in verification.json under `transformations`.
    swipl renn/transform.pl check BUILD
        Check manifest hashes and that every transformation has an accepted
        checker report and chains to the current file hashes.
    swipl renn/transform.pl recheck BUILD MNNS
        As check, then re-run mnns on every before-N file and confirm it
        reproduces the recorded output.

    Prints RENN_TRANSFORM ... / RENN_PROOFS ok N, or RENN_PROOFS error Message
    and exits 1.
*/
:- use_module(library(http/json)).
:- use_module(library(sha)).
:- use_module(library(process)).
:- use_module(library(readutil)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).

:- initialization(main, main).

checker("mnns optimise").

main(Argv) :-
    catch(( command(Argv) -> true ; usage ), renn(Message), failed(Message)).

usage :-
    format(user_error, "Usage: swipl transform.pl transform BUILD FILE MNNS | check BUILD | recheck BUILD MNNS~n", []),
    halt(2).

failed(Message) :-
    format("RENN_PROOFS error ~w~n", [Message]),
    halt(1).

command([transform, Build, File, Mnns]) :- transform(Build, File, Mnns).
command([check, Build]) :-
    check_build(Build, Entries), length(Entries, N),
    format("RENN_PROOFS ok ~w~n", [N]).
command([recheck, Build, Mnns]) :-
    check_build(Build, Entries),
    maplist(recheck_entry(Build, Mnns), Entries),
    length(Entries, N),
    format("RENN_PROOFS ok ~w rechecked~n", [N]).

% ---------------------------------------------------------------- files, hashes, JSON
path(Build, Name, Path) :- atomic_list_concat([Build, '/', Name], Path).

read_bytes(Path, Bytes) :-
    setup_call_cleanup(open(Path, read, S, [type(binary)]),
                       read_stream_to_codes(S, Bytes), close(S)).
write_bytes(Path, Bytes) :-
    setup_call_cleanup(open(Path, write, S, [type(binary)]),
                       format(S, "~s", [Bytes]), close(S)).

sha256(Bytes, Hex) :-
    sha_hash(Bytes, Hash, [algorithm(sha256), encoding(octet)]),
    hash_atom(Hash, Atom), atom_string(Atom, Hex).
file_sha(Path, Hex) :- read_bytes(Path, B), sha256(B, Hex).

read_json(Path, Dict) :-
    (   catch(setup_call_cleanup(open(Path, read, S, [encoding(utf8)]),
                                 json_read_dict(S, Dict, [value_string_as(string)]),
                                 close(S)), _, fail)
    ->  true
    ;   throw(renn(invalid_json(Path)))
    ).
write_json(Path, Dict) :-
    setup_call_cleanup(open(Path, write, S, [encoding(utf8)]),
                       ( json_write_dict(S, Dict, [width(0)]), nl(S) ), close(S)).

% ---------------------------------------------------------------- the checker report
%   MNN_OPTIMISE ok changed=true size_before=40 size_after=36 plop=accepted simplify=2 detlog=proved detlog_steps=3
%   A stage is covered when its rewrite was accepted, or when it left the file
%   unchanged (unchanged, or a rejected proof whose candidate was discarded).
stage_ok(plop, [accepted, unchanged, rejected]).
stage_ok(detlog, [proved, unchanged, rejected, failed]).

parse_report(Line, Fields) :-
    split_string(Line, " ", " \n\r", Words0),
    exclude(==(""), Words0, Words),
    (   Words = ["MNN_OPTIMISE", "ok"|KVs]
    ->  true
    ;   throw(renn(checker_did_not_succeed(Line)))
    ),
    maplist(key_value, KVs, Pairs0),
    (   memberchk(detlog-_, Pairs0) -> Pairs = Pairs0    % older mnns has no Detlog stage
    ;   Pairs = [detlog-"unchanged"|Pairs0]
    ),
    dict_pairs(Fields, stages, Pairs),
    forall(member(K, [changed, plop, simplify]),
           ( get_dict(K, Fields, _) -> true ; throw(renn(report_has_no(K))) )),
    forall(stage_ok(Stage, Allowed),
           (   get_dict(Stage, Fields, V), atom_string(A, V), memberchk(A, Allowed)
           ->  true
           ;   get_dict(Stage, Fields, V2), throw(renn(stage_not_proved(Stage, V2)))
           )),
    (   number_string(N, Fields.simplify), integer(N), N >= 0 -> true
    ;   throw(renn(simplify_not_a_count(Fields.simplify)))
    ),
    (   memberchk(Fields.changed, ["true", "false"]) -> true
    ;   throw(renn(changed_not_boolean(Fields.changed)))
    ).

key_value(KV, K-V) :-
    (   sub_string(KV, B, 1, A, "=")
    ->  sub_string(KV, 0, B, _, KS), sub_string(KV, _, A, 0, V), atom_string(K, KS)
    ;   throw(renn(bad_report_field(KV)))
    ).

% ---------------------------------------------------------------- running mnns
run_checker(Mnns, SourceBytes, OutBytes, Line, Fields) :-
    path(Mnns, 'optimise.pl', Script0),
    (   exists_file(Script0) -> absolute_file_name(Script0, Script)
    ;   throw(renn(no_optimise_pl(Mnns)))
    ),
    tmp_file(renn_in, In0), atom_concat(In0, '.pl', In),
    tmp_file(renn_out, Out0), atom_concat(Out0, '.pl', Out),
    write_bytes(In, SourceBytes),
    swipl(Swipl),
    setup_call_cleanup(
        process_create(Swipl, [Script, In, Out], [stdout(pipe(S)), stderr(null), process(Pid)]),
        read_string(S, _, Stdout),
        close(S)),
    process_wait(Pid, exit(Code)),
    split_string(Stdout, "\n", "\r", Lines),
    (   include([L]>>sub_string(L, 0, _, _, "MNN_OPTIMISE"), Lines, Found), last(Found, Line) -> true
    ;   Line = "(no checker output)"
    ),
    (   Code =:= 0 -> true ; throw(renn(checker_failed(Line))) ),
    parse_report(Line, Fields),
    (   exists_file(Out) -> read_bytes(Out, OutBytes) ; throw(renn(checker_wrote_no_output)) ),
    catch(delete_file(In), _, true), catch(delete_file(Out), _, true).

swipl(Swipl) :-
    current_prolog_flag(executable, Exe),
    (   exists_file(Exe) -> Swipl = Exe ; Swipl = path(swipl) ).

checker_revision(Mnns, Rev) :-
    catch(( process_create(path(git), ['-C', Mnns, 'rev-parse', 'HEAD'],
                           [stdout(pipe(S)), stderr(null), process(Pid)]),
            read_string(S, _, R0), close(S), process_wait(Pid, exit(0)),
            split_string(R0, "", " \n", [Rev]), string_length(Rev, 40) ),
          _, fail), !.
checker_revision(_, "unknown").

% ---------------------------------------------------------------- checking a build
check_build(Build, Entries) :-
    path(Build, 'manifest.json', MPath),
    read_json(MPath, Manifest),
    Files = Manifest.files,
    dict_pairs(Files, _, FilePairs),
    forall(member(Name-Hash, FilePairs),
           (   path(Build, Name, P), exists_file(P), file_sha(P, Hash) -> true
           ;   throw(renn(sha256_mismatch(Name)))
           )),
    (   get_dict('verification.json', Files, _)
    ->  path(Build, 'verification.json', VPath), read_json(VPath, V),
        ( get_dict(transformations, V, Entries) -> true ; Entries = [] )
    ;   Entries = []
    ),
    (   is_list(Entries) -> true ; throw(renn(transformations_not_a_list)) ),
    foldl(check_entry(Files), Entries, 1-_{}, _-Current),
    dict_pairs(Current, _, CurrentPairs),
    forall(member(Name-Hash, CurrentPairs),
           (   get_dict(Name, Files, Hash) -> true
           ;   throw(renn(changed_after_checked_transformation(Name)))
           )),
    findall(B, ( member(E, Entries), atom_string(B, E.before_file) ), Befores),
    forall(( member(Name-_, FilePairs), sub_atom(Name, 0, _, _, 'before-') ),
           (   memberchk(Name, Befores) -> true
           ;   throw(renn(unreferenced_before_file(Name)))
           )).

check_entry(Files, Entry, I-Current0, I1-Current) :-
    I1 is I + 1,
    (   is_dict(Entry), get_dict(index, Entry, I) -> true ; throw(renn(bad_index(I))) ),
    checker(Checker),
    (   get_dict(checker, Entry, Checker) -> true ; throw(renn(no_checked_proof(I))) ),
    atom_string(File, Entry.file), atom_string(Before, Entry.before_file),
    (   get_dict(File, Files, _), get_dict(Before, Files, BeforeHash) -> true
    ;   throw(renn(files_not_in_manifest(I)))
    ),
    (   BeforeHash == Entry.before_sha256 -> true ; throw(renn(before_hash_mismatch(I))) ),
    (   get_dict(File, Current0, Prev) -> ( Prev == Entry.before_sha256 -> true ; throw(renn(broken_chain(I, File))) )
    ;   true
    ),
    parse_report(Entry.report, Fields),
    dict_pairs(Fields, _, FP), dict_pairs(Entry.stages, _, SP),
    (   FP == SP -> true ; throw(renn(stages_do_not_match_report(I))) ),
    put_dict(File, Current0, Entry.after_sha256, Current).

recheck_entry(Build, Mnns, Entry) :-
    path(Build, Entry.before_file, P),
    read_bytes(P, Before),
    run_checker(Mnns, Before, Out, _, _),
    sha256(Out, Hash),
    (   Hash == Entry.after_sha256 -> true
    ;   throw(renn(recheck_did_not_reproduce(Entry.file)))
    ).

% ---------------------------------------------------------------- transforming a file
transform(Build, File, Mnns) :-
    check_build(Build, Entries),
    path(Build, 'manifest.json', MPath), read_json(MPath, Manifest),
    (   get_dict(File, Manifest.files, _), file_name_extension(_, pl, File),
        \+ sub_atom(File, 0, _, _, 'before-')
    ->  true
    ;   throw(renn(not_a_generated_prolog_file(File)))
    ),
    path(Build, File, Target), read_bytes(Target, Source),
    run_checker(Mnns, Source, Output, Line, Fields),
    length(Entries, N0),
    (   ( Output == Source ; Fields.changed == "false" )
    ->  format("RENN_TRANSFORM unchanged ~w ~w transformations=~w~n", [File, Line, N0])
    ;   N is N0 + 1,
        format(atom(BeforeName), 'before-~w-~w', [N, File]),
        sha256(Source, BeforeHash), sha256(Output, AfterHash),
        checker(Checker), checker_revision(Mnns, Rev),
        Entry = _{index:N, file:File, checker:Checker, checker_revision:Rev,
                  before_file:BeforeName, before_sha256:BeforeHash,
                  after_sha256:AfterHash, report:Line, stages:Fields},
        path(Build, 'verification.json', VPath),
        read_bytes(VPath, SavedV), read_bytes(MPath, SavedM),
        path(Build, BeforeName, BPath),
        catch(apply_entry(Build, Manifest, Entry, Target, Output, BPath, Source, VPath, MPath),
              E,
              ( write_bytes(Target, Source), catch(delete_file(BPath), _, true),
                write_bytes(VPath, SavedV), write_bytes(MPath, SavedM),
                throw(E) )),
        format("RENN_TRANSFORM changed ~w ~w transformations=~w~n", [File, Line, N])
    ).

apply_entry(Build, Manifest, Entry, Target, Output, BPath, Source, VPath, MPath) :-
    write_bytes(BPath, Source),
    write_bytes(Target, Output),
    read_json(VPath, V0),
    ( get_dict(transformations, V0, Old) -> true ; Old = [] ),
    append(Old, [Entry], New),
    put_dict(transformations, V0, New, V),
    write_json(VPath, V),
    file_sha(VPath, VHash),
    atom_string(File, Entry.file), atom_string(Before, Entry.before_file),
    Files0 = Manifest.files,
    put_dict(_{}.put(File, Entry.after_sha256).put(Before, Entry.before_sha256)
                .put('verification.json', VHash), Files0, Files),
    put_dict(files, Manifest, Files, M),
    write_json(MPath, M),
    check_build(Build, _),
    run_cases(Build).

%   The generated differential cases must still pass on the transformed build.
run_cases(Build) :-
    path(Build, 'verification_cases.pl', Cases),
    (   exists_file(Cases) -> true ; throw(renn(no_verification_cases)) ),
    swipl(Swipl),
    process_create(Swipl, ['-q', '-s', 'verification_cases.pl', '-g', run_verification, '-t', halt],
                   [cwd(Build), stdout(null), stderr(null), process(Pid)]),
    process_wait(Pid, exit(Code)),
    (   Code =:= 0 -> true ; throw(renn(verification_cases_failed)) ).
