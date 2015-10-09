(** This is a command line front program for the flashcards library.

    To understand how the program works, start by working back from [main].
*)

open Core.Std
open Flashcards

(** Helper to clear the screen. *)
let clear_screen () =
  if Sys.os_type = "Win32" then
    ignore (Sys.command "cls")
  else (* unix *)
    ignore (Sys.command "clear")

(** Prints a default prompt and waits for user response. *)
let prompt () =
  printf "\n * Press ENTER to continue *\n%!";
  ignore (In_channel.input_line stdin)

(** A visually stunning divider. *)
let print_divider () = print_endline 
    "-------------------------------------------------------------------------------"

(** Prints the deck header. *)
let print_header deck =
  clear_screen ();
  print_divider ();
  printf "Cards left: %d\n" (List.length (Deck.cards deck));
  print_divider ()

(** Prints the front/question card. *)
let print_front card =
  printf "Question: %s\n" (Card.front card);
  print_divider ()

(** Prints the question and multiple choices. *)
let print_front_and_choices card choices =
  print_front card;
  printf "Choices:\n\n";
  for i=0 to List.length choices - 1 do
    printf "%d: %s\n" (i + 1) (List.nth_exn choices i)
  done;
  print_divider ()

(** Shows the answer to the question. *)
let show_answer card =
  printf "\n * Press ENTER to see answer *\n%!";
  ignore (In_channel.input_line stdin);
  printf "Correct answer: %s\n" (Card.back card)

(** Yes or no user prompt. *)
let yn_prompt ?(msg="\nCorrect? [Y/n]") () =
  print_string msg;
  flush_all ();
  match In_channel.input_line stdin with
  | None -> true
  | Some answer -> match answer with
    |"n" | "N" -> false
    | _        -> true

(** Get's response to multiple choice card and checks the answer. *)    let rec check_answer ?(msg="Select choice number: ") answer =
  let invalid () =
    printf "Invalid input!\n%!";
    check_answer answer
  in
  print_string msg;
  flush_all ();
  try
    match In_channel.input_line stdin with
    | Some response ->
      Int.of_string response = answer
    | None -> invalid ()
  with _ -> 
    invalid ()

(** General card I/O. If no multiple choices, ask user if they
    got it correct. Otherwise, checks multiple choice. *)
let print_card_and_ask (card, (list, answer)) =
  match (List.length list) with
  | 0 -> 
    print_front card;
    show_answer card;    
    yn_prompt ()
  | _ -> 
    print_front_and_choices card list;
    check_answer (answer + 1)

(** Process correct answer + notify. *)                  
let print_correct_answer deck choices =
  printf "\nCorrect!\n%!";
  Deck.correct_answer deck;
  match choices = 0 with
  | true -> ()
  | false -> prompt ()

(** Process incorrect answer + notify. *)                  
let print_incorrect_answer deck card choices =
  printf "\nWrong!\n\nCorrect answer is -> %s\n\n%!" (Card.back card);
  Deck.incorrect_answer deck card;
  match choices = 0 with
  | true -> ()
  | false -> prompt ()

(** Prints all the missed cards. *)                    
let print_all_missed deck =
  List.iter (Deck.missed deck)
    ~f:(fun x ->
        if snd x = 1 then 
          printf "%s\n" (Card.to_string (fst x))
        else 
          printf "%s -> %d times\n" (Card.to_string (fst x)) (snd x)
      )

(** Prints the score. *)
let score deck =
  let missed = Deck.total_missed deck in
  let size = Deck.deck_size deck in
  sprintf "Score: %.0f%% -> Missed %d of %d\n" 
    (Deck.percentage size missed) missed size

(** Print the finish message. *)          
let print_finish_deck deck =
  printf "\n\nFinished!\n";
  print_endline (score deck);
  if (Deck.incorrect deck) > 0 then
    begin
      printf "You missed the following cards:\n";
      print_all_missed deck
    end;
  print_newline ()

(** Load the deck, print it out, reset it, and return the deck. *)                
let setup_deck filename choices =
  let deck = Deck.load_simple_deck filename in
  printf "Loaded %s\n" filename;
  let len = List.length (Deck.cards deck) in
  if not (Deck.has_multiple_choices deck choices) then
    raise Deck.Not_enough_multiple_choices;
  List.iter (Deck.cards deck) 
    ~f:(fun x -> print_endline (Card.to_string x));
  printf "\nTotal cards: %d\n" len;
  Deck.reset deck;
  prompt ();
  deck

(** The main deck loop. We get the next card, print it, and get user 
    response until done. *)    
let rec deck_loop deck choices =
  try
    let (card, (list, answer)) = 
      Deck.top_card_exn ~multiple_choices:choices deck
    in
    print_header deck;
    match print_card_and_ask (card, (list, answer)) with
    | true ->
      print_correct_answer deck choices;
      deck_loop deck choices
    | false ->
      print_incorrect_answer deck card choices;
      deck_loop deck choices
  with Deck.No_more_cards -> 
    print_finish_deck deck

(* let deck1 = Deck.create "Dogs" [
   Card.create "Archie" "Troll";
   Card.create "Samantha" "Rat";
   Card.create "Rajah" "Darkie";
   Card.create "Flipper" "Dolphin";
   Card.create "Smokey" "Dragon";
   ];;

   let deck2 = Deck.load_simple_deck "oxford1-vocab-002.txt";;
*)

(** Main entry point. *)                      
let main filename choices () =
  Random.self_init (); (* seed random generator *)
  try
    let choices = choices in
    let deck = setup_deck filename choices in
    deck_loop deck choices;
  with Deck.Not_enough_multiple_choices ->
    print_endline "Not enough cards for that many multiple choices."

let command =
  Command.basic
    ~summary:"A command line flashcards program."
    ~readme:(fun () ->
        "The filename should be a simple flashcard text file and the choices are 
how many multiple choices to offer per card.  Choose 0 for choices if you 
just want basic flashcards without any multiple choices.")
    Command.Spec.(
      empty 
      +> anon ("filename" %: file)
      +> anon ("choices" %: int)
    )
    main;;

if !Sys.interactive then () else 
  Command.run ~version:"1.0" ~build_info:"dionysius.rossi@gmail.com" command;;
